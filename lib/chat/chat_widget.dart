import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter/gestures.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'chat_message.dart';
import 'chat_service.dart';
import 'dart:convert';
import 'voice_input_card.dart';

class ChatWidget extends StatefulWidget {
  final InAppWebViewController webViewController;
  final String currentUrl;
  final Function(bool) onVisibilityChanged;

  const ChatWidget({
    super.key,
    required this.webViewController,
    required this.currentUrl,
    required this.onVisibilityChanged,
  });

  @override
  State<ChatWidget> createState() => _ChatWidgetState();
}

class _ChatWidgetState extends State<ChatWidget> {
  late final ChatService _chatService;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isLoading = false;
  bool _isListening = false;
  bool _showVoiceCard = false;

  @override
  void initState() {
    super.initState();
    _chatService = ChatService(widget.currentUrl);
    _chatService.chatStream.listen((_) {
      _scrollToBottom();
    });
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    try {
      bool available = await _speech.initialize(
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            setState(() => _isListening = false);
          }
        },
        onError: (error) {
          setState(() => _isListening = false);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $error')));
        },
      );
      if (!available) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Speech recognition not available')),
        );
      }
    } catch (e) {
      debugPrint('Speech initialization error: $e');
    }
  }

  Future<void> _startListening() async {
    try {
      if (!_isListening) {
        bool available = await _speech.initialize();
        if (available) {
          setState(() {
            _isListening = true;
            _showVoiceCard = true;
          });
          await _speech.listen(
            onResult: (result) {
              setState(() {
                _messageController.text = result.recognizedWords;
                if (result.finalResult) {
                  _isListening = false;
                  if (_messageController.text.isNotEmpty) {
                    // _handleSend();
                    _showVoiceCard = false;
                  }
                }
              });
            },
          );
        }
      } else {
        setState(() {
          _isListening = false;
          _showVoiceCard = false;
        });
        _speech.stop();
      }
    } catch (e) {
      setState(() {
        _isListening = false;
        _showVoiceCard = false;
      });
      debugPrint('Speech recognition error: $e');
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _chatService.dispose();
    _speech.stop();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  Future<void> _handleSend() async {
    final message = _messageController.text.trim();
    if (message.isEmpty || _isLoading) return;

    _messageController.clear();
    setState(() => _isLoading = true);

    try {
      await _chatService.processUserMessage(message);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleLinkTap(
    String url, {
    List<String>? highlightKeywords,
  }) async {
    try {
      await widget.webViewController.loadUrl(
        urlRequest: URLRequest(url: WebUri(url)),
      );

      if (highlightKeywords != null && highlightKeywords.isNotEmpty) {
        // Add a delay to let the page load before highlighting
        await Future.delayed(const Duration(milliseconds: 500));
        final js =
            '''
          function highlightKeywords(keywords) {
            const body = document.body;
            const walker = document.createTreeWalker(
              body, 
              NodeFilter.SHOW_TEXT,
              null,
              false
            );
            
            const matches = [];
            let node;
            while (node = walker.nextNode()) {
              const text = node.textContent.toLowerCase();
              if (keywords.some(kw => text.includes(kw.toLowerCase()))) {
                matches.push(node);
              }
            }
            
            matches.forEach(node => {
              const span = document.createElement('span');
              span.className = 'keyword-highlight';
              span.style.backgroundColor = '#FFEB3B';
              span.style.transition = 'background-color 3s ease';
              node.parentNode.insertBefore(span, node);
              span.appendChild(node);
              
              setTimeout(() => {
                span.style.backgroundColor = 'transparent';
                setTimeout(() => {
                  const parent = span.parentNode;
                  parent.insertBefore(span.firstChild, span);
                  parent.removeChild(span);
                }, 3000);
              }, 100);
            });
          }
          highlightKeywords(${jsonEncode(highlightKeywords)});
        ''';
        await widget.webViewController.evaluateJavascript(source: js);
      }

      if (mounted) {
        widget.onVisibilityChanged(false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading URL: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Stack(
      children: [
        Center(
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              width: size.width * 0.9,
              height: size.height * 0.9,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Colors.white,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildHeader(),
                  Expanded(child: _buildChatList()),
                  _buildInputArea(),
                ],
              ),
            ),
          ),
        ),
        if (_showVoiceCard)
          Positioned.fill(
            child: Container(
              color: Colors.black54,
              child: VoiceInputCard(
                isListening: _isListening,
                recognizedText: _messageController.text,
                onClose: () {
                  setState(() {
                    _isListening = false;
                    _showVoiceCard = false;
                  });
                  _speech.stop();
                },
                onResult: (String text) {},
              ),
            ),
          ),
      ],
    );
  }

  String _getCleanHost(Uri uri) {
    final host = uri.host;
    return host.startsWith('www.') ? host.substring(4) : host;
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        children: [
          const Icon(Icons.chat, color: Colors.white),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Assistant',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          //  Expanded(
          //   child: Text(
          //     '${_getCleanHost(Uri.parse(widget.currentUrl))} Assistant',
          //     style: const TextStyle(
          //       color: Colors.white,
          //       fontSize: 18,
          //       fontWeight: FontWeight.bold,
          //     ),
          //   ),
          // ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.white),
            onPressed: () async {
              await _chatService.clearHistory();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Chat history cleared')),
                );
              }
            },
            tooltip: 'Clear Chat',
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => widget.onVisibilityChanged(false),
            tooltip: 'Close Chat',
          ),
        ],
      ),
    );
  }

  Widget _buildChatList() {
    return StreamBuilder<List<ChatMessage>>(
      stream: _chatService.chatStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Text('No messages yet. Start a conversation!'),
          );
        }

        final messages = snapshot.data!;
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.all(16),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final message = messages[index];
            return _buildMessageBubble(message);
          },
        );
      },
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.isUser;
    final bubbleColor = isUser
        ? Theme.of(context).primaryColor.withOpacity(0.1)
        : Colors.grey.shade100;
    final textColor = isUser ? Theme.of(context).primaryColor : Colors.black87;
    final alignment = isUser
        ? CrossAxisAlignment.end
        : CrossAxisAlignment.start;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: alignment,
        children: [
          Row(
            mainAxisAlignment: isUser
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            children: [
              if (!isUser) ...[
                CircleAvatar(
                  backgroundColor: Theme.of(context).primaryColor,
                  radius: 16,
                  child: const Icon(
                    Icons.assistant,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.7,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: bubbleColor,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isUser ? 16 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 16),
                    ),
                    border: Border.all(
                      color: isUser
                          ? Theme.of(context).primaryColor.withOpacity(0.2)
                          : Colors.grey.shade300,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SelectableText.rich(
                        TextSpan(children: _parseMessageText(message.text)),
                        style: TextStyle(color: textColor, fontSize: 16),
                      ),
                      if (message.searchResults != null &&
                          message.searchResults!.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        ...message.searchResults!.map(
                          (result) => Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${result.index}. ${result.title}',
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                result.content,
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ElevatedButton(
                                onPressed: () => _handleLinkTap(
                                  result.url,
                                  highlightKeywords: result.matchedKeywords,
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Theme.of(
                                    context,
                                  ).primaryColor,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                ),
                                child: const Text('View More'),
                              ),
                              const SizedBox(height: 16),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              if (isUser) ...[
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: Theme.of(context).primaryColor,
                  radius: 16,
                  child: const Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ],
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              _formatTimestamp(message.timestamp),
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  List<InlineSpan> _parseMessageText(String text) {
    final spans = <InlineSpan>[];
    final linkPattern = RegExp(r'\[(.*?)\]\((.*?)\)');
    final boldPattern = RegExp(r'\*\*(.*?)\*\*');

    var currentIndex = 0;

    while (currentIndex < text.length) {
      // Try to find the next markdown element
      final linkMatch = linkPattern.firstMatch(text.substring(currentIndex));
      final boldMatch = boldPattern.firstMatch(text.substring(currentIndex));

      // Find which comes first
      final linkStart = linkMatch?.start ?? text.length;
      final boldStart = boldMatch?.start ?? text.length;

      if (linkStart < boldStart) {
        // Add text before the link
        if (linkStart > 0) {
          spans.add(
            TextSpan(
              text: text.substring(currentIndex, currentIndex + linkStart),
            ),
          );
        }

        // Add the link
        spans.add(
          TextSpan(
            text: linkMatch![1],
            style: TextStyle(
              color: Theme.of(context).primaryColor,
              decoration: TextDecoration.underline,
            ),
            recognizer: TapGestureRecognizer()
              ..onTap = () => _handleLinkTap(linkMatch[2]!),
          ),
        );

        currentIndex += linkMatch.end;
      } else if (boldStart < text.length) {
        // Add text before the bold
        if (boldStart > 0) {
          spans.add(
            TextSpan(
              text: text.substring(currentIndex, currentIndex + boldStart),
            ),
          );
        }

        // Add the bold text
        spans.add(
          TextSpan(
            text: boldMatch![1],
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        );

        currentIndex += boldMatch.end;
      } else {
        // Add remaining text
        spans.add(TextSpan(text: text.substring(currentIndex)));
        break;
      }
    }

    return spans;
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Microphone Button with Wave Animation
          Stack(
            alignment: Alignment.center,
            children: [
              if (_isListening)
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(seconds: 1),
                  builder: (context, value, child) {
                    return Container(
                      width: 40 + (value * 10),
                      height: 40 + (value * 10),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.red.withOpacity(0.3 - (value * 0.3)),
                      ),
                    );
                  },
                  onEnd: () {
                    setState(() {
                      // Restart animation
                      if (_isListening) {
                        setState(() {});
                      }
                    });
                  },
                ),
              FloatingActionButton(
                onPressed: _startListening,
                mini: true,
                backgroundColor: _isListening
                    ? Colors.red
                    : Colors.grey.shade200,
                child: Icon(
                  _isListening ? Icons.mic : Icons.mic_none,
                  color: _isListening ? Colors.white : Colors.grey.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
          // Text Input Field
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.grey.shade300, width: 1),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: _isListening
                            ? 'Listening...'
                            : 'Type your message...',
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                      onSubmitted: (_) => _handleSend(),
                    ),
                  ),
                  // Send Button
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: FloatingActionButton(
                      onPressed: _isLoading ? null : _handleSend,
                      mini: true,
                      backgroundColor: Theme.of(context).primaryColor,
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Icon(Icons.send, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
