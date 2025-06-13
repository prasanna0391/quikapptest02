import 'package:flutter/foundation.dart';

@immutable
class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final List<SearchResult>? searchResults;
  final List<Map<String, String>>? links;
  final List<String>? keywords;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.searchResults,
    this.links,
    this.keywords,
  });

  Map<String, dynamic> toJson() => {
    'text': text,
    'isUser': isUser,
    'timestamp': timestamp.toIso8601String(),
    'links': links,
    'searchResults': searchResults?.map((r) => r.toJson()).toList(),
    'keywords': keywords,
  };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
    text: json['text'] as String,
    isUser: json['isUser'] as bool,
    timestamp: DateTime.parse(json['timestamp'] as String),
    links: json['links'] != null 
      ? List<Map<String, String>>.from(
          (json['links'] as List).map((e) => Map<String, String>.from(e))
        )
      : null,
    searchResults: json['searchResults'] != null
      ? List<SearchResult>.from(
          (json['searchResults'] as List).map((e) => SearchResult.fromJson(e))
        )
      : null,
    keywords: json['keywords'] != null
      ? List<String>.from(json['keywords'] as List)
      : null,
  );

  @override
  bool operator ==(Object other) =>
    identical(this, other) ||
    other is ChatMessage &&
    runtimeType == other.runtimeType &&
    text == other.text &&
    isUser == other.isUser &&
    timestamp == other.timestamp;

  @override
  int get hashCode => Object.hash(text, isUser, timestamp);
}

@immutable
class SearchResult {
  final String title;
  final String content;
  final String url;
  final List<String> matchedKeywords;
  final int index;

  const SearchResult({
    required this.title,
    required this.content,
    required this.url,
    required this.matchedKeywords,
    required this.index,
  });

  Map<String, dynamic> toJson() => {
    'title': title,
    'content': content,
    'url': url,
    'matchedKeywords': matchedKeywords,
    'index': index,
  };

  factory SearchResult.fromJson(Map<String, dynamic> json) => SearchResult(
    title: json['title'] as String,
    content: json['content'] as String,
    url: json['url'] as String,
    matchedKeywords: List<String>.from(json['matchedKeywords'] as List),
    index: json['index'] as int,
  );
} 