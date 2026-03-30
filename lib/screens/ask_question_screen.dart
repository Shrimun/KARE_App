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

  Future<void> _initSpeech() async {
    try {
      // Request microphone permission first
      var status = await Permission.microphone.status;
      if (!status.isGranted) {
        status = await Permission.microphone.request();
      }
      
      _speechEnabled = await _speech.initialize(
        onStatus: (status) {
          debugPrint('Speech status: $status');
          if (status == 'done' || status == 'notListening') {
            setState(() => _isListening = false);
            // Removed auto-submit here so it waits until the user speaks completely and manually submits
          }
        },
        onError: (val) {
          debugPrint('Speech error: $val');
          setState(() => _isListening = false);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Voice error: ${val.errorMsg}')),
            );
          }
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
      // Check microphone permission
      var status = await Permission.microphone.status;
      debugPrint('Microphone permission status: $status');
      
      if (!status.isGranted) {
        status = await Permission.microphone.request();
        debugPrint('Microphone permission after request: $status');
        if (!status.isGranted) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Microphone permission is required for voice input'),
                duration: Duration(seconds: 3),
              ),
            );
          }
          return;
        }
      }

      // Check if speech is available
      if (!_speechEnabled) {
        await _initSpeech();
        if (!_speechEnabled) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Speech recognition is not available on this device'),
                duration: Duration(seconds: 3),
              ),
            );
          }
          return;
        }
      }

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
            if (mounted) {
              setState(() {
                _questionCtrl.text = val.recognizedWords;
              });
            }
          },
          listenFor: const Duration(seconds: 60),
          pauseFor: const Duration(seconds: 8),
          partialResults: true,
          cancelOnError: true,
          listenMode: stt.ListenMode.confirmation,
        );
      } catch (e) {
        debugPrint('Listen error: $e');
        setState(() {
          _isListening = false;
          _voiceActive = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Voice input error. Please try again.'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } else {
      // Stop listening
      setState(() {
        _isListening = false;
        _voiceActive = false;
      });
      await _speech.stop();
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

    // Remove repeated chunks of newlines
    answer = answer.replaceAll(RegExp(r'\n{3,}'), '\n\n');
    
    // Check if user wants a brief answer
    final briefKeywords = ['briefly', 'brief', 'short', 'shortly', 'quick', 'quickly', 
                          'summary', 'summarize', 'in short', 'tl;dr', 'concise'];
    final wantsBrief = briefKeywords.any((keyword) => 
        question.toLowerCase().contains(keyword));
    
    if (wantsBrief) {
      final sentences = answer
          .split(RegExp(r'(?<=[.!?])\s+'))
          .where((s) => s.trim().isNotEmpty)
          .toList();
      
      if (sentences.length >= 2) {
        return sentences.take(2).join(' ');
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

    // Handle greetings and common conversational phrases without calling API
    final lowerQuestion = question.toLowerCase();
    final greetings = ['hello', 'hi', 'hey', 'greetings', 'good morning', 'good afternoon', 'good evening', 'howdy', 'hii', 'hiii', 'hlo'];
    final howAreYou = ['how are you', 'how r u', 'how are u', 'how r you', 'whatsup', 'what\'s up', 'sup', 'wassup'];
    final thanks = ['thank you', 'thanks', 'thank u', 'thnx', 'thankyou', 'ty'];
    final helpRequests = ['help', 'help me', 'i need help', 'can you help me', 'assist me', 'can you help', 'what can you do', 'what can you help me with', 'how can you help'];
    
    if (greetings.any((g) => lowerQuestion == g || lowerQuestion.startsWith('$g ') || lowerQuestion.startsWith('$g!'))) {
      setState(() {
        _messages.add(ChatMessage(
          text: 'Hello! 👋 How can I help you today?',
          isUser: false,
        ));
        _isLoading = false;
      });
      _scrollToBottom();
      return;
    }
    
    if (howAreYou.any((phrase) => lowerQuestion.contains(phrase))) {
      setState(() {
        _messages.add(ChatMessage(
          text: 'I\'m doing great, thank you! How can I assist you with your studies?',
          isUser: false,
        ));
        _isLoading = false;
      });
      _scrollToBottom();
      return;
    }
    
    if (thanks.any((t) => lowerQuestion == t || lowerQuestion.startsWith('$t ') || lowerQuestion.startsWith('$t!'))) {
      setState(() {
        _messages.add(ChatMessage(
          text: 'You\'re welcome! Feel free to ask anything else! 😊',
          isUser: false,
        ));
        _isLoading = false;
      });
      _scrollToBottom();
      return;
    }

    if (helpRequests.any((h) => lowerQuestion == h || lowerQuestion == '$h!' || lowerQuestion == '$h?')) {
      setState(() {
        _messages.add(ChatMessage(
          text: 'I am here to help you! 🎓\n\nYou can ask me about:\n• University regulations and policies\n• Calculating grades, marks, and CGPA\n• Rules for exams and attendance\n• General academic queries\n\nWhat do you need assistance with today?',
          isUser: false,
        ));
        _isLoading = false;
      });
      _scrollToBottom();
      return;
    }

    final api = Provider.of<AuthProvider>(context, listen: false).api;
    
    try {
      // Send question to API as is, allowing the AI to calculate and explain naturally.
      final res = await api.askQuestion(question: question);
      final rawAnswer =
          res['answer']?.toString() ?? res['data']?.toString() ?? 'I could not find an answer to that.';
      
      String cleanedAnswer = rawAnswer.trim();

      // Clean up common AI / RAG engine artifacts
      cleanedAnswer = cleanedAnswer.replaceAll(RegExp(r'chunks?\w*[_\s]*\d+(?:\s*(?:,|and)\s*\d+)*', caseSensitive: false), '');
      cleanedAnswer = cleanedAnswer.replaceAll(RegExp(r'\[[^\]]*chunk[^\]]*\]', caseSensitive: false), '');
      cleanedAnswer = cleanedAnswer.replaceAll(RegExp(r'\[[^\]]*source[^\]]*\]', caseSensitive: false), '');
      cleanedAnswer = cleanedAnswer.replaceAll(RegExp(r'\[[^\]]*ref[^\]]*\]', caseSensitive: false), '');
      cleanedAnswer = cleanedAnswer.replaceAll(RegExp(r'\{[^\}]*chunk[^\}]*\}', caseSensitive: false), '');
      cleanedAnswer = cleanedAnswer.replaceAll(RegExp(r'\{[^\}]*source[^\}]*\}', caseSensitive: false), '');
      cleanedAnswer = cleanedAnswer.replaceAll(RegExp(r'(source|reference|citation|ref)[:\s]+[^\n]*', caseSensitive: false), '');

      // Remove introductory filler phrases that mention documents
      cleanedAnswer = cleanedAnswer.replaceAll(RegExp(r'(based on|according to|as per|from|using|in|of)\s+(the\s+)?(uploaded\s+)?(regulation|document|file|pdf|text)s?', caseSensitive: false), '');
      cleanedAnswer = cleanedAnswer.replaceAll(RegExp(r'(the\s+)?(uploaded\s+)(regulation|document|file|pdf)s?', caseSensitive: false), '');
      cleanedAnswer = cleanedAnswer.replaceAll(RegExp(r'answer from (this|the|a)\s+(regulation|document|file|pdf)', caseSensitive: false), '');
      cleanedAnswer = cleanedAnswer.replaceAll(RegExp(r'^[^.!?]*(uploaded|regulation\s+document)[^.!?]*[:.]\s*', caseSensitive: false), '');
      
      cleanedAnswer = cleanedAnswer.trim();
      
      // Format the answer
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

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Add Attachment',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.secondary,
                child: const Icon(Icons.insert_drive_file, color: Colors.white),
              ),
              title: const Text('File'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('File picker coming soon!')),
                );
              },
            ),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.secondary,
                child: const Icon(Icons.image, color: Colors.white),
              ),
              title: const Text('Image'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Image picker coming soon!')),
                );
              },
            ),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.secondary,
                child: const Icon(Icons.camera_alt, color: Colors.white),
              ),
              title: const Text('Camera'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Camera coming soon!')),
                );
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final padding = size.width * 0.04;
    
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      drawer: Drawer(
        child: Container(
          color: Theme.of(context).scaffoldBackgroundColor,
          child: Column(
            children: [
              DrawerHeader(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
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
                    backgroundColor: Theme.of(context).colorScheme.primary,
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
                              backgroundColor: Theme.of(context).colorScheme.secondary,
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
                                color: Colors.black87,
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
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.menu, color: Theme.of(context).colorScheme.primary),
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer();
          },
        ),
        title: Text(
          'AI Assistant',
          style: TextStyle(color: Theme.of(context).colorScheme.primary),
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
                            color: Theme.of(context).colorScheme.primary,
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
              color: Colors.white.withOpacity(0.96),
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
                CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                  child: IconButton(
                    icon: const Icon(Icons.add, color: Colors.white),
                    onPressed: _showAttachmentOptions,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _questionCtrl,
                    decoration: InputDecoration(
                      hintText: 'Type your question...',
                      hintStyle: TextStyle(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.25),
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    style: const TextStyle(color: Colors.black),
                    maxLines: 5,
                    minLines: 1,
                    textInputAction: TextInputAction.newline,
                    keyboardType: TextInputType.multiline,
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: _isListening
                      ? Theme.of(context).colorScheme.secondary
                      : Theme.of(context).colorScheme.primary,
                  child: IconButton(
                    icon: Icon(_isListening ? Icons.mic_off : Icons.mic, color: Colors.white),
                    onPressed: _listen,
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primary,
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
              backgroundColor: Theme.of(context).colorScheme.secondary,
              radius: 16,
              child: const Icon(Icons.smart_toy, size: 18, color: Colors.white),
            ),
          if (!message.isUser) const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: message.isUser
                    ? Theme.of(context).colorScheme.primary
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
              backgroundColor: Theme.of(context).colorScheme.primary,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.secondary,
            radius: 16,
            child: const Icon(Icons.smart_toy, size: 18, color: Colors.white),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(20),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                _DotAnimation(delay: 0),
                SizedBox(width: 4),
                _DotAnimation(delay: 200),
                SizedBox(width: 4),
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
          color: Theme.of(context).colorScheme.secondary.withOpacity(0.7),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
