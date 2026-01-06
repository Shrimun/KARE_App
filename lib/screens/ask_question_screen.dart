import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';
import '../providers/auth_provider.dart';
import '../widgets/error_dialog.dart';

class AskQuestionScreen extends StatefulWidget {
  const AskQuestionScreen({super.key});

  @override
  State<AskQuestionScreen> createState() => _AskQuestionScreenState();
}

class _AskQuestionScreenState extends State<AskQuestionScreen> {
  final _questionCtrl = TextEditingController();
  final _scrollController = ScrollController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  // Current chat messages
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;

  // Chat history - list of chat sessions
  final List<ChatSession> _chatHistory = [];
  int _currentChatIndex = -1; // -1 means current new chat

  late stt.SpeechToText _speech;
  late FlutterTts _flutterTts;
  bool _isListening = false;
  bool _speechEnabled = false;
  bool _voiceActive = false;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _flutterTts = FlutterTts();
    _initSpeech();
    _initTts();
  }

  void _initSpeech() async {
    try {
      _speechEnabled = await _speech.initialize(
        onStatus: (status) {
          debugPrint('Speech status: $status');
          if (status == 'done' || status == 'notListening') {
            bool wasListening = _isListening;
            setState(() => _isListening = false);
            // Auto-submit after voice input completes
            if (wasListening && _questionCtrl.text.trim().isNotEmpty && _voiceActive) {
              Future.delayed(const Duration(milliseconds: 500), () {
                _submit();
              });
            }
          }
        },
        onError: (val) {
          debugPrint('Speech error: $val');
          setState(() => _isListening = false);
        },
      );
      debugPrint('Speech initialized: $_speechEnabled');
      setState(() {});
    } catch (e) {
      debugPrint("Speech init error: $e");
      setState(() => _speechEnabled = false);
    }
  }

  void _initTts() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setPitch(1.0);
  }

  Future<void> _speak(String text) async {
    await _flutterTts.speak(text);
  }

  void _listen() async {
    if (!_isListening) {
      // Request microphone permission
      var status = await Permission.microphone.status;
      debugPrint('Microphone permission status: $status');
      
      if (!status.isGranted) {
        status = await Permission.microphone.request();
        debugPrint('Microphone permission after request: $status');
        if (!status.isGranted) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Microphone permission denied')),
            );
          }
          return;
        }
      }

      if (_speechEnabled) {
        setState(() {
          _isListening = true;
          _voiceActive = true;
        });
        _questionCtrl.clear();
        await _flutterTts.stop();
        
        try {
          await _speech.listen(
            onResult: (val) {
              debugPrint('Speech result: ${val.recognizedWords}');
              setState(() {
                _questionCtrl.text = val.recognizedWords;
              });
            },
            listenFor: const Duration(seconds: 30),
            pauseFor: const Duration(seconds: 8),
            partialResults: true,
            cancelOnError: true,
            listenMode: stt.ListenMode.confirmation,
          );
        } catch (e) {
          debugPrint('Listen error: $e');
          setState(() => _isListening = false);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: $e')),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Speech recognition not available')),
          );
        }
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  void _saveCurrentChatToHistory() {
    if (_messages.isNotEmpty) {
      final firstQuestion = _messages.firstWhere(
        (msg) => msg.isUser,
        orElse: () => ChatMessage(text: 'Chat', isUser: true),
      ).text;
      
      final chatTitle = firstQuestion.length > 30 
          ? '${firstQuestion.substring(0, 30)}...' 
          : firstQuestion;
      
      _chatHistory.insert(0, ChatSession(
        title: chatTitle,
        messages: List.from(_messages),
        timestamp: DateTime.now(),
      ));
      
      // Keep only last 20 chats
      if (_chatHistory.length > 20) {
        _chatHistory.removeLast();
      }
    }
  }

  void _startNewChat() {
    _saveCurrentChatToHistory();
    setState(() {
      _messages.clear();
      _currentChatIndex = -1;
    });
    Navigator.pop(context); // Close drawer
  }

  void _loadChatFromHistory(int index) {
    _saveCurrentChatToHistory();
    setState(() {
      _messages.clear();
      _messages.addAll(_chatHistory[index].messages);
      _currentChatIndex = index;
    });
    Navigator.pop(context); // Close drawer
    _scrollToBottom();
  }

  @override
  void dispose() {
    _speech.cancel();
    _flutterTts.stop();
    _questionCtrl.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _formatAnswer(String answer, String question) {
    // Remove extra whitespace and normalize
    answer = answer.trim();
    
    // Clean up any chunk markers or extra newlines
    answer = answer.replaceAll(RegExp(r'\n{3,}'), '\n\n');
    answer = answer.replaceAll(RegExp(r'\s{2,}'), ' ');
    
    // Detect if user wants brief/short answer
    final briefKeywords = ['briefly', 'brief', 'short', 'shortly', 'quick', 'quickly', 
                          'summary', 'summarize', 'in short', 'tl;dr', 'concise'];
    final wantsBrief = briefKeywords.any((keyword) => 
        question.toLowerCase().contains(keyword));
    
    // If answer is short (less than 80 chars), return as is
    if (answer.length < 80) return answer;

    // Check if answer already contains numbered points or bullet points
    if (answer.contains(RegExp(r'^\s*[\d•\-\*]+[\.\)]\s', multiLine: true))) {
      return answer;
    }

    // If user wants brief answer, keep it short - just return first 1-2 sentences
    if (wantsBrief) {
      final sentences = answer
          .split(RegExp(r'(?<=[.!?])\s+'))
          .where((s) => s.trim().isNotEmpty && s.trim().length > 10)
          .toList();
      
      if (sentences.length >= 2) {
        // Return only first 2 sentences for brief answers
        return sentences.take(2).join(' ');
      }
      return answer; // Return as is if can't split
    }

    // For normal (non-brief) requests, format longer answers as bullet points
    
    // Try to split by numbered lists first (e.g., "1.", "2.", etc.)
    if (answer.contains(RegExp(r'\d+\.\s'))) {
      final parts = answer.split(RegExp(r'(?=\d+\.\s)'))
          .where((s) => s.trim().isNotEmpty)
          .toList();
      if (parts.length >= 2) {
        return parts.map((p) {
          // Remove the number and replace with bullet
          return '• ${p.replaceFirst(RegExp(r'^\d+\.\s*'), '').trim()}';
        }).join('\n\n');
      }
    }

    // Split by sentence delimiters (period, exclamation, question mark)
    final sentences = answer
        .split(RegExp(r'(?<=[.!?])\s+'))
        .where((s) => s.trim().isNotEmpty && s.trim().length > 10)
        .toList();
    
    // If we have multiple sentences (2 or more for longer text), format as bullet points
    if (sentences.length >= 2 && answer.length > 150) {
      return sentences.map((s) {
        // Clean up the sentence
        String cleaned = s.trim();
        // Don't add extra period if already ends with punctuation
        if (!cleaned.endsWith('.') && !cleaned.endsWith('!') && !cleaned.endsWith('?')) {
          cleaned = '$cleaned.';
        }
        return '• $cleaned';
      }).join('\n\n');
    }

    // For medium length answers, try to split by semicolons, colons, or commas
    if (answer.contains(';') || answer.contains(':')) {
      final parts = answer.split(RegExp(r'[;:]'))
          .where((p) => p.trim().isNotEmpty && p.trim().length > 15)
          .toList();
      if (parts.length >= 3) {
        return parts.map((p) => '• ${p.trim()}').join('\n\n');
      }
    }

    // Try splitting by "and" or "or" for lists
    if (answer.length > 200 && (answer.split(', and ').length > 2 || answer.split(', or ').length > 2)) {
      final parts = answer.split(RegExp(r',\s*(?:and|or)\s*'))
          .where((p) => p.trim().isNotEmpty && p.trim().length > 10)
          .toList();
      if (parts.length >= 3) {
        return parts.map((p) => '• ${p.trim()}').join('\n\n');
      }
    }

    // If answer is very long (more than 300 chars), try to break into paragraphs
    if (answer.length > 300) {
      final paragraphs = answer.split('\n')
          .where((p) => p.trim().isNotEmpty && p.trim().length > 20)
          .toList();
      if (paragraphs.length >= 2) {
        return paragraphs.map((p) => '• ${p.trim()}').join('\n\n');
      }
    }

    return answer;
  }

  Future<void> _submit() async {
    final question = _questionCtrl.text.trim();
    if (question.isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(text: question, isUser: true));
      _isLoading = true;
    });
    _questionCtrl.clear();
    _scrollToBottom();

    final api = Provider.of<AuthProvider>(context, listen: false).api;
    try {
      final res = await api.askQuestion(question: question);
      final rawAnswer =
          res['answer']?.toString() ?? res['data']?.toString() ?? 'No answer';
      
      // AGGRESSIVELY clean up the raw answer - remove ALL chunk markers and metadata
      String cleanedAnswer = rawAnswer.trim();
      
      // Remove phrases like "answer from this pdf", "from the pdf", "from this document" etc.
      cleanedAnswer = cleanedAnswer.replaceAll(RegExp(r'answer from (this|the) (pdf|document|file|text)', caseSensitive: false), '');
      cleanedAnswer = cleanedAnswer.replaceAll(RegExp(r'from (this|the) (pdf|document|file|text)', caseSensitive: false), '');
      cleanedAnswer = cleanedAnswer.replaceAll(RegExp(r'based on (this|the) (pdf|document|file|text)', caseSensitive: false), '');
      cleanedAnswer = cleanedAnswer.replaceAll(RegExp(r'according to (this|the) (pdf|document|file|text)', caseSensitive: false), '');
      
      // Remove chunk references like "chunk_88", "chunk 128", "chunks: 88, 128" etc.
      cleanedAnswer = cleanedAnswer.replaceAll(RegExp(r'chunk[_\s]*\d+', caseSensitive: false), '');
      cleanedAnswer = cleanedAnswer.replaceAll(RegExp(r'chunks?[:\s]+[\d,\s]+', caseSensitive: false), '');
      
      // Remove any [bracketed] metadata or markers
      cleanedAnswer = cleanedAnswer.replaceAll(RegExp(r'\[[^\]]*chunk[^\]]*\]', caseSensitive: false), '');
      cleanedAnswer = cleanedAnswer.replaceAll(RegExp(r'\[[^\]]*source[^\]]*\]', caseSensitive: false), '');
      cleanedAnswer = cleanedAnswer.replaceAll(RegExp(r'\[[^\]]*ref[^\]]*\]', caseSensitive: false), '');
      
      // Remove {json} artifacts and metadata
      cleanedAnswer = cleanedAnswer.replaceAll(RegExp(r'\{[^\}]*chunk[^\}]*\}', caseSensitive: false), '');
      cleanedAnswer = cleanedAnswer.replaceAll(RegExp(r'\{[^\}]*source[^\}]*\}', caseSensitive: false), '');
      
      // Remove "Source:", "Reference:", "Citation:" metadata
      cleanedAnswer = cleanedAnswer.replaceAll(RegExp(r'(source|reference|citation|ref)[:\s]+[^\n]*', caseSensitive: false), '');
      
      // Clean up extra whitespace, newlines, and punctuation artifacts
      cleanedAnswer = cleanedAnswer.replaceAll(RegExp(r'\n{3,}'), '\n\n'); // Normalize newlines
      cleanedAnswer = cleanedAnswer.replaceAll(RegExp(r'\s{2,}'), ' '); // Normalize spaces
      cleanedAnswer = cleanedAnswer.replaceAll(RegExp(r'^[,;:\s]+'), ''); // Remove leading punctuation
      cleanedAnswer = cleanedAnswer.replaceAll(RegExp(r'[,;\s]+$'), ''); // Remove trailing punctuation
      cleanedAnswer = cleanedAnswer.trim();
      
      // Format the answer based on question context (brief vs detailed)
      final formattedAnswer = _formatAnswer(cleanedAnswer, question);
      
      setState(() {
        _messages.add(ChatMessage(text: formattedAnswer, isUser: false));
        _isLoading = false;
      });
      _scrollToBottom();

      if (_voiceActive) {
        _speak(formattedAnswer);
        _voiceActive = false;
      }
    } catch (e) {
      setState(() => _isLoading = false);
      showDialog(
        context: context,
        builder: (_) => ErrorDialog(message: e.toString()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final padding = size.width * 0.04;
    
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFfdf0d5),
      drawer: Drawer(
        child: Container(
          color: const Color(0xFFfdf0d5),
          child: Column(
            children: [
              DrawerHeader(
                decoration: const BoxDecoration(
                  color: Color(0xFF003049),
                ),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.chat_bubble_outline, color: Colors.white, size: 48),
                      SizedBox(height: 12),
                      Text(
                        'Chat History',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton.icon(
                  onPressed: _startNewChat,
                  icon: const Icon(Icons.add),
                  label: const Text('New Chat'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFc1121f),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Divider(),
              ),
              Expanded(
                child: _chatHistory.isEmpty
                    ? const Center(
                        child: Text(
                          'No chat history yet',
                          style: TextStyle(color: Colors.black54),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _chatHistory.length,
                        itemBuilder: (context, index) {
                          final chat = _chatHistory[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: const Color(0xFF669bbc),
                              child: Text(
                                '${index + 1}',
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            title: Text(
                              chat.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF003049),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            subtitle: Text(
                              _formatTimestamp(chat.timestamp),
                              style: const TextStyle(color: Colors.black54, fontSize: 12),
                            ),
                            onTap: () => _loadChatFromHistory(index),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                setState(() {
                                  _chatHistory.removeAt(index);
                                });
                              },
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
      appBar: AppBar(
        backgroundColor: const Color(0xFFfdf0d5),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Color(0xFF003049)),
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer();
          },
        ),
        title: const Text(
          'AI Assistant',
          style: TextStyle(color: Color(0xFF003049)),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: size.width * 0.3,
                          height: size.width * 0.3,
                          decoration: BoxDecoration(
                            color: const Color(0xFF003049),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.chat_bubble_outline,
                            size: size.width * 0.15,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: size.height * 0.02),
                        const Text(
                          'Ask me anything!',
                          style: TextStyle(
                            color: Colors.black54,
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: EdgeInsets.all(padding),
                    itemCount: _messages.length + (_isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (_isLoading && index == _messages.length) {
                        // Show loading bubble
                        return _LoadingBubble();
                      }
                      return _ChatBubble(message: _messages[index]);
                    },
                  ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            padding: EdgeInsets.symmetric(horizontal: padding, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _questionCtrl,
                    decoration: InputDecoration(
                      hintText: 'Type your question...',
                      hintStyle: TextStyle(color: const Color(0xFF003049).withOpacity(0.5)),
                      filled: true,
                      fillColor: const Color(0xFFfdf0d5),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    style: const TextStyle(color: Colors.black),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _submit(),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: _isListening ? const Color(0xFF780000) : const Color(0xFFc1121f),
                  child: IconButton(
                    icon: Icon(_isListening ? Icons.mic_off : Icons.mic, color: Colors.white),
                    onPressed: _listen,
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: const Color(0xFFc1121f),
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: _submit,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _formatTimestamp(DateTime timestamp) {
  final now = DateTime.now();
  final diff = now.difference(timestamp);
  
  if (diff.inMinutes < 1) {
    return 'Just now';
  } else if (diff.inHours < 1) {
    return '${diff.inMinutes}m ago';
  } else if (diff.inDays < 1) {
    return '${diff.inHours}h ago';
  } else if (diff.inDays < 7) {
    return '${diff.inDays}d ago';
  } else {
    return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
  }
}

class ChatSession {
  final String title;
  final List<ChatMessage> messages;
  final DateTime timestamp;

  ChatSession({
    required this.title,
    required this.messages,
    required this.timestamp,
  });
}

class ChatMessage {
  final String text;
  final bool isUser;

  ChatMessage({required this.text, required this.isUser});
}

class _ChatBubble extends StatelessWidget {
  final ChatMessage message;

  const _ChatBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment:
            message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser)
            CircleAvatar(
              backgroundColor: const Color(0xFF669bbc),
              radius: 16,
              child: const Icon(Icons.smart_toy, size: 18, color: Colors.white),
            ),
          if (!message.isUser) const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: message.isUser
                    ? const Color(0xFF003049)
                    : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: message.isUser
                      ? const Radius.circular(20)
                      : const Radius.circular(4),
                  bottomRight: message.isUser
                      ? const Radius.circular(4)
                      : const Radius.circular(20),
                ),
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  color: message.isUser ? Colors.white : Colors.black,
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
            ),
          ),
          if (message.isUser) const SizedBox(width: 8),
          if (message.isUser)
            CircleAvatar(
              backgroundColor: const Color(0xFF003049),
              radius: 16,
              child: const Icon(Icons.person, size: 18, color: Colors.white),
            ),
        ],
      ),
    );
  }
}

class _LoadingBubble extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFF669bbc),
            radius: 16,
            child: const Icon(Icons.smart_toy, size: 18, color: Colors.white),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(20),
                topRight: const Radius.circular(20),
                bottomLeft: const Radius.circular(4),
                bottomRight: const Radius.circular(20),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _DotAnimation(delay: 0),
                const SizedBox(width: 4),
                _DotAnimation(delay: 200),
                const SizedBox(width: 4),
                _DotAnimation(delay: 400),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DotAnimation extends StatefulWidget {
  final int delay;

  const _DotAnimation({required this.delay});

  @override
  State<_DotAnimation> createState() => _DotAnimationState();
}

class _DotAnimationState extends State<_DotAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _animation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) {
        _controller.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: const Color(0xFF669bbc).withOpacity(0.7),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
