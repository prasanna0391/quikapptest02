import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html_parser;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'chat_message.dart';
import 'chat_response.dart';
import 'dart:math' as math;

@immutable
class ContentSection {
  final String text;
  final String type;
  final int relevance;

  const ContentSection({
    required this.text,
    required this.type,
    this.relevance = 0,
  });
}

@immutable
class KnowledgeBaseEntry {
  final String url;
  final String title;
  final List<String> headings;
  final List<String> paragraphs;
  final DateTime timestamp;
  final String domain;

  KnowledgeBaseEntry({
    required this.url,
    required this.title,
    required this.headings,
    required this.paragraphs,
    required this.domain,
  }) : timestamp = DateTime.now();

  bool get isStale => DateTime.now().difference(timestamp).inMinutes > 30;

  Map<String, dynamic> toJson() => {
    'url': url,
    'title': title,
    'headings': headings,
    'paragraphs': paragraphs,
    'timestamp': timestamp.toIso8601String(),
    'domain': domain,
  };

  factory KnowledgeBaseEntry.fromJson(Map<String, dynamic> json) => KnowledgeBaseEntry(
    url: json['url'] as String,
    title: json['title'] as String,
    headings: List<String>.from(json['headings'] as List),
    paragraphs: List<String>.from(json['paragraphs'] as List),
    domain: json['domain'] as String,
  );
}

class ChatService {
  static const String _storageKey = 'chat_history';
  static const String _knowledgeBaseKey = 'knowledge_base';
  static const int _chunkSize = 5;
  static const Duration _rateLimitDelay = Duration(milliseconds: 100);
  
  final Map<String, KnowledgeBaseEntry> _knowledgeBase = {};
  final List<ChatMessage> _chatHistory = [];
  final Set<String> _crawledUrls = {};
  
  late final String _currentUrl;
  late final String _currentDomain;
  KnowledgeBaseEntry? _currentPageEntry;
  final StreamController<List<ChatMessage>> _chatStreamController = 
      StreamController<List<ChatMessage>>.broadcast();
  
  Stream<List<ChatMessage>> get chatStream => _chatStreamController.stream;
  List<ChatMessage> get chatHistory => List.unmodifiable(_chatHistory);
  
  bool _isInitialized = false;
  Completer<void>? _initCompleter;

  ChatService(String initialUrl) {
    _currentUrl = initialUrl;
    _currentDomain = Uri.parse(initialUrl).host;
    _initializeService();
  }

  Future<void> _initializeService() async {
    if (_isInitialized) return;
    
    _initCompleter = Completer<void>();
    try {
      await _loadStoredData();
      await _parseCurrentPage();
      _isInitialized = true;
      _initCompleter?.complete();
    } catch (e) {
      _initCompleter?.completeError(e);
      debugPrint('Error initializing service: $e');
    }
  }

  Future<void> ensureInitialized() async {
    if (_isInitialized) return;
    await _initCompleter?.future;
  }

  Future<void> _loadStoredData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final historyJson = prefs.getString(_storageKey);
      if (historyJson != null) {
        final List<dynamic> historyList = jsonDecode(historyJson);
        _chatHistory.addAll(
          historyList.map((item) => ChatMessage.fromJson(item as Map<String, dynamic>))
        );
        _chatStreamController.add(_chatHistory);
      }

      final knowledgeJson = prefs.getString(_knowledgeBaseKey);
      if (knowledgeJson != null) {
        final Map<String, dynamic> knowledgeMap = 
            jsonDecode(knowledgeJson) as Map<String, dynamic>;
        knowledgeMap.forEach((key, value) {
          final entry = KnowledgeBaseEntry.fromJson(value as Map<String, dynamic>);
          if (!entry.isStale) {
            _knowledgeBase[key] = entry;
            _crawledUrls.add(key);
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading stored data: $e');
    }
  }

  Future<void> _saveData() async {
    if (!_isInitialized) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final historyJson = jsonEncode(_chatHistory.map((msg) => msg.toJson()).toList());
      await prefs.setString(_storageKey, historyJson);

      final knowledgeJson = jsonEncode(
        Map.fromEntries(
          _knowledgeBase.entries.map((e) => MapEntry(e.key, e.value.toJson()))
        )
      );
      await prefs.setString(_knowledgeBaseKey, knowledgeJson);
    } catch (e) {
      debugPrint('Error saving data: $e');
    }
  }

  void dispose() {
    _chatStreamController.close();
    _initCompleter = null;
  }

  Future<void> clearHistory() async {
    await ensureInitialized();
    _chatHistory.clear();
    _chatStreamController.add(_chatHistory);
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }

  Future<void> updateCurrentUrl(String newUrl) async {
    await ensureInitialized();
    _currentUrl = newUrl;
    _currentDomain = Uri.parse(newUrl).host;
    await _parseCurrentPage();
  }

  Future<void> _addMessage(ChatMessage message) async {
    await ensureInitialized();
    _chatHistory.add(message);
    _chatStreamController.add(_chatHistory);
    unawaited(_saveData());
  }

  Future<void> _parseCurrentPage() async {
    if (_knowledgeBase[_currentUrl]?.isStale == false) {
      _currentPageEntry = _knowledgeBase[_currentUrl];
      return;
    }

    try {
      final response = await http.get(Uri.parse(_currentUrl));
      if (response.statusCode != 200) return;

      final content = await compute(_extractContent, response.body);
      
      _currentPageEntry = KnowledgeBaseEntry(
        url: _currentUrl,
        title: content['title'] as String,
        headings: List<String>.from(content['headings'] as List),
        paragraphs: List<String>.from(content['paragraphs'] as List),
        domain: _currentDomain,
      );
      
      _knowledgeBase[_currentUrl] = _currentPageEntry!;
      unawaited(_saveData());

      unawaited(_parseLinkedPages(html_parser.parse(response.body)));
    } catch (e) {
      debugPrint('Error parsing current page $_currentUrl: $e');
    }
  }

  static Map<String, dynamic> _extractContent(String html) {
    final document = html_parser.parse(html);
    final titleElement = document.getElementsByTagName('title').firstOrNull;
    final title = titleElement?.text.trim() ?? 'Untitled Page';
    final headings = <String>[];
    final paragraphs = <String>[];

    for (var tag in ['h1', 'h2', 'h3', 'h4', 'h5', 'h6']) {
      for (var element in document.getElementsByTagName(tag)) {
        final headingText = element.text.trim();
        if (headingText.isNotEmpty) {
          headings.add(headingText);
        }
      }
    }

    for (var element in document.getElementsByTagName('p')) {
      final paragraphText = element.text.trim();
      if (paragraphText.isNotEmpty && paragraphText.split(' ').length > 3) {
        paragraphs.add(paragraphText);
      }
    }

    return {
      'title': title,
      'headings': headings,
      'paragraphs': paragraphs,
    };
  }

  Future<void> _parseLinkedPages(dom.Document document) async {
    final urlsToProcess = _extractValidUrls(document);
    final chunks = _createUrlChunks(urlsToProcess);

    for (final chunk in chunks) {
      final futures = chunk.map((url) {
        _crawledUrls.add(url);
        return _fetchAndParsePage(url);
      });
      
      await Future.wait(futures);
      await Future.delayed(_rateLimitDelay);
    }
  }

  Set<String> _extractValidUrls(dom.Document document) {
    final baseUri = Uri.parse(_currentUrl);
    final urlsToProcess = <String>{};

    for (var tag in document.getElementsByTagName('a')) {
      final href = tag.attributes['href'];
      if (href == null || href.isEmpty) continue;

      try {
        final nextUrl = baseUri.resolve(href).toString();
        final nextUri = Uri.parse(nextUrl);
        
        if (nextUri.host == _currentDomain && 
            !_crawledUrls.contains(nextUrl) &&
            nextUrl != _currentUrl &&
            _knowledgeBase[nextUrl]?.isStale != false) {
          urlsToProcess.add(nextUrl);
        }
      } catch (e) {
        debugPrint('Error parsing URL $href: $e');
      }
    }

    return urlsToProcess;
  }

  List<List<String>> _createUrlChunks(Set<String> urls) {
    final chunks = <List<String>>[];
    final urlList = urls.toList();
    
    for (var i = 0; i < urlList.length; i += _chunkSize) {
      chunks.add(
        urlList.sublist(
          i, 
          i + _chunkSize > urlList.length ? urlList.length : i + _chunkSize
        )
      );
    }

    return chunks;
  }

  Future<void> _fetchAndParsePage(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) return;

      final content = await compute(_extractContent, response.body);
      
      _knowledgeBase[url] = KnowledgeBaseEntry(
        url: url,
        title: content['title'] as String,
        headings: List<String>.from(content['headings'] as List),
        paragraphs: List<String>.from(content['paragraphs'] as List),
        domain: _currentDomain,
      );
      
      unawaited(_saveData());
    } catch (e) {
      debugPrint('Error fetching page $url: $e');
    }
  }

  Future<void> processUserMessage(String userMessage) async {
    await _addMessage(ChatMessage(
      text: userMessage,
      isUser: true,
      timestamp: DateTime.now(),
    ));

    final lowerMessage = userMessage.toLowerCase();
    final response = await _generateResponse(lowerMessage, userMessage);

    await _addMessage(ChatMessage(
      text: response.message,
      isUser: false,
      links: response.links,
      timestamp: DateTime.now(),
    ));
  }

  Future<ChatResponse> _generateResponse(String lowerMessage, String originalMessage) async {
    // Greetings
    if (_isGreeting(lowerMessage)) {
      return ChatResponse(
        message: 'Hello! 👋\nWelcome to $_currentDomain\nI am an Intelligent Assistant. \nHow can I help you today?',
      );
    }

    // About queries
    if (_isAboutQuery(lowerMessage)) {
      return await _getAboutResponse();
    }

    // Contact queries
    if (_isContactQuery(lowerMessage)) {
      return await _getContactResponse();
    }

    // General search for products or content
    return await _getSearchResponse(originalMessage);
  }

  bool _isGreeting(String message) {
    const greetings = {
      'hi',
      'hello',
      'hey',
      'hai',
      'halo',
      'howdy',
      'greetings',
    };
    return greetings.any(message.contains);
  }

  bool _isAboutQuery(String message) {
    const aboutQueries = {
      'about',
      'about us',
      'who are you',
      'what is this',
      'company info',
      'tell me about',
      'who we are',
      'info',
    };
    return aboutQueries.any(message.contains);
  }

  bool _isContactQuery(String message) {
    const contactQueries = {
      'contact',
      'contact us',
      'get in touch',
      'reach out',
      'lets talk',
      'talk to us',
      'address',
      'phone',
      'email',
      'help',
    };
    return contactQueries.any(message.contains);
  }

  Future<ChatResponse> _getAboutResponse() async {
    if (_currentPageEntry == null) {
      await _parseCurrentPage();
    }

    var aboutContent = '';
    var aboutUrl = '';
    var aboutTitle = '';
    
    // First try to find an about page
    for (final entry in _knowledgeBase.values) {
      final url = entry.url.toLowerCase();
      if (url.contains('about') && !entry.isStale) {
        aboutContent = _extractRelevantSnippet(entry.paragraphs.take(2).join('. '), 'about');
        aboutUrl = entry.url;
        aboutTitle = entry.title;
        break;
      }
    }

    // If no about page found, use current page content
    if (aboutContent.isEmpty && _currentPageEntry != null) {
      aboutContent = _extractRelevantSnippet(_currentPageEntry!.paragraphs.take(2).join('. '), 'about');
      aboutUrl = _currentUrl;
      aboutTitle = _currentPageEntry!.title;
    }

    if (aboutContent.isEmpty) {
      return ChatResponse(
        message: 'I apologize, but I could not find detailed information about $_currentDomain. You may want to check the website navigation for an About page.',
      );
    }

    return ChatResponse(
      message: '''**$aboutTitle**

$aboutContent

[${aboutUrl}](${aboutUrl})''',
      // buttons: [{
      //   'text': 'View More',
      //   'url': aboutUrl,
      // }],
      // links: [{
      //   'url': aboutUrl,
      //   'title': aboutUrl,
      // }],
    );
  }

  Future<ChatResponse> _getContactResponse() async {
    if (_currentPageEntry == null) {
      await _parseCurrentPage();
    }

    var contactInfo = '';
    var contactUrl = '';
    var contactTitle = '';

    // Try to find contact page
    for (final entry in _knowledgeBase.values) {
      final url = entry.url.toLowerCase();
      if (url.contains('contact') && !entry.isStale) {
        contactUrl = entry.url;
        contactTitle = entry.title;
        for (final paragraph in entry.paragraphs) {
          if (_containsContactInfo(paragraph)) {
            contactInfo = _extractRelevantSnippet(paragraph, 'contact');
            break;
          }
        }
        break;
      }
    }

    // If no contact info found, search in current page
    if (contactInfo.isEmpty && _currentPageEntry != null) {
      for (final paragraph in _currentPageEntry!.paragraphs) {
        if (_containsContactInfo(paragraph)) {
          contactInfo = _extractRelevantSnippet(paragraph, 'contact');
          contactUrl = _currentUrl;
          contactTitle = _currentPageEntry!.title;
          break;
        }
      }
    }

    if (contactInfo.isEmpty) {
      return const ChatResponse(
        message: 'I apologize, but I could not find specific contact information. You may want to check the website\'s contact page directly.',
      );
    }

    return ChatResponse(
      message: '''**$contactTitle**

$contactInfo

[${contactUrl}](${contactUrl})''',
      // buttons: [{
      //   'text': 'View More',
      //   'url': contactUrl,
      // }],
      // links: [{
      //   'url': contactUrl,
      //   'title': contactUrl,
      // }],
    );
  }

  bool _containsContactInfo(String text) {
    final lowerText = text.toLowerCase();
    return lowerText.contains('email') ||
           lowerText.contains('@') ||
           lowerText.contains('phone') ||
           lowerText.contains('tel') ||
           lowerText.contains('address') ||
           lowerText.contains('contact');
  }

  Future<ChatResponse> _getSearchResponse(String query) async {
    final relevantContent = await _findRelevantContent(query);
    
    if (relevantContent.isEmpty) {
      return ChatResponse(
        message: "I couldn't find any information about that on $_currentDomain. Could you try rephrasing your question?",
      );
    }

    final messageLines = <String>[];
    final searchResults = <SearchResult>[];
    final allTerms = <String>{};
    final queryWords = query.toLowerCase().split(' ').where((w) => w.length > 2);
    
    // Generate similar terms and variations
    for (final word in queryWords) {
      allTerms.add(word);
      allTerms.addAll(_generateSimilarWords(word));
    }
    
    // Add related terms section
    if (allTerms.length > 1) {
      messageLines.add('**Related keywords found:** ${allTerms.join(', ')}');
      messageLines.add('');
    }
    
    messageLines.add('Here are the most relevant results:');
    messageLines.add('');

    var index = 1;
    for (final entry in relevantContent.entries) {
      final content = entry.value;
      final title = _knowledgeBase[entry.key]?.title ?? 'Untitled';
      final matchedKeywords = allTerms.where((term) => 
        content.text.toLowerCase().contains(term.toLowerCase()) ||
        title.toLowerCase().contains(term.toLowerCase())
      ).toList();

      searchResults.add(SearchResult(
        title: title,
        content: content.text,
        url: entry.key,
        matchedKeywords: matchedKeywords,
        index: index,
      ));

      messageLines.addAll([
        '$index. **$title**',
        content.text,
        '[View more](${entry.key})',
        '',
      ]);

      index++;
    }

    return ChatResponse(
      message: messageLines.join('\n'),
      searchResults: searchResults,
      keywords: allTerms.toList(),
    );
  }

  Future<Map<String, ContentSection>> _findRelevantContent(String query) async {
    query = query.toLowerCase();
    final results = <String, ContentSection>{};
    final words = query.split(' ').where((w) => w.length > 2).toList();
    final similarWords = <String, Set<String>>{};
    
    // Generate similar words for each search term
    for (final word in words) {
      similarWords[word] = _generateSimilarWords(word);
    }
    
    for (final entry in _knowledgeBase.values) {
      if (entry.domain != _currentDomain || entry.isStale) continue;

      var maxRelevance = 0;
      ContentSection? bestMatch;
      String? matchedText;
      final List<String> matchedTerms = [];

      // Check title
      final lowerTitle = entry.title.toLowerCase();
      if (lowerTitle.contains(query)) {
        maxRelevance = 100;
        matchedText = entry.paragraphs.isNotEmpty ? entry.paragraphs.first : entry.title;
        bestMatch = ContentSection(
          text: _extractRelevantSnippet(matchedText, query),
          type: 'title',
          relevance: 100,
        );
      }

      // Check paragraphs if no title match or lower relevance
      if (maxRelevance < 80) {
        for (final paragraph in entry.paragraphs) {
          final lowerParagraph = paragraph.toLowerCase();
          var relevance = 0;
          final localMatchedTerms = <String>[];
          
          // Calculate relevance based on word matches and similar words
          for (final word in words) {
            if (lowerParagraph.contains(word)) {
              relevance += 20;
              localMatchedTerms.add(word);
            } else {
              // Check for similar words
              for (final similar in similarWords[word]!) {
                if (lowerParagraph.contains(similar)) {
                  relevance += 15; // Slightly lower score for similar matches
                  localMatchedTerms.add(similar);
                  break;
                }
              }
            }
          }

          // If this paragraph is more relevant than current best match
          if (relevance > maxRelevance) {
            maxRelevance = relevance;
            matchedText = paragraph;
            matchedTerms.clear();
            matchedTerms.addAll(localMatchedTerms);
            bestMatch = ContentSection(
              text: _extractRelevantSnippet(paragraph, query),
              type: 'paragraph',
              relevance: relevance,
            );
          }
        }
      }

      if (bestMatch != null && maxRelevance >= 15) { // Lower threshold to include similar matches
        results[entry.url] = bestMatch;
      }
    }

    // Sort results by relevance and take top 5
    final sortedResults = Map.fromEntries(
      results.entries.toList()
        ..sort((a, b) => b.value.relevance.compareTo(a.value.relevance))
        ..take(5)
    );

    return sortedResults;
  }

  Set<String> _generateSimilarWords(String word) {
    final similar = <String>{};
    final lower = word.toLowerCase();
    
    // Add common variations
    similar.add(lower);
    similar.add(word.toUpperCase());
    similar.add('${word[0].toUpperCase()}${word.substring(1).toLowerCase()}');
    
    // Add hyphenated and space variations
    if (word.contains('-')) {
      similar.add(word.replaceAll('-', ' '));
      similar.add(word.replaceAll('-', ''));
    } else if (word.contains(' ')) {
      similar.add(word.replaceAll(' ', '-'));
      similar.add(word.replaceAll(' ', ''));
    } else {
      // Try common prefix/suffix variations
      if (word.endsWith('s')) similar.add(word.substring(0, word.length - 1));
      if (word.endsWith('es')) similar.add(word.substring(0, word.length - 2));
      if (word.endsWith('ing')) similar.add(word.substring(0, word.length - 3));
      if (word.endsWith('ed')) similar.add(word.substring(0, word.length - 2));
    }
    
    return similar;
  }

  String _extractRelevantSnippet(String text, String query) {
    final sentences = text.split(RegExp(r'[.!?]+\s+')); 
    final lowerQuery = query.toLowerCase();
    final queryWords = lowerQuery.split(' ').where((w) => w.length > 2).toSet();
    
    // Score each sentence based on query word matches
    var bestScore = 0;
    var bestSentenceIndex = 0;
    
    for (var i = 0; i < sentences.length; i++) {
      final lowerSentence = sentences[i].toLowerCase();
      var score = 0;
      
      // Direct query match
      if (lowerSentence.contains(lowerQuery)) {
        score += 100;
      }
      
      // Individual word matches
      for (final word in queryWords) {
        if (lowerSentence.contains(word)) {
          score += 20;
        }
        // Check similar words
        for (final similar in _generateSimilarWords(word)) {
          if (lowerSentence.contains(similar)) {
            score += 15;
          }
        }
      }
      
      if (score > bestScore) {
        bestScore = score;
        bestSentenceIndex = i;
      }
    }
    
    // Take 2-3 sentences starting from the best matching one
    final startIdx = bestSentenceIndex;
    final endIdx = math.min(startIdx + 3, sentences.length);
    
    var snippet = sentences.sublist(startIdx, endIdx).join('. ').trim();
    if (snippet.length > 300) {
      snippet = '${snippet.substring(0, 297)}...';
    }
    
    return snippet;
  }
} 