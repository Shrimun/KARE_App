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
            bool wasListening = _isListening;
            setState(() => _isListening = false);
            // Auto-submit after voice input completes
            if (wasListening && _questionCtrl.text.trim().isNotEmpty && _voiceActive) {
              Future.delayed(const Duration(milliseconds: 800), () {
                if (_questionCtrl.text.trim().isNotEmpty) {
                  _submit();
                }
              });
            }
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

    // Handle greetings and common conversational phrases without calling API
    final lowerQuestion = question.toLowerCase();
    final greetings = ['hello', 'hi', 'hey', 'greetings', 'good morning', 'good afternoon', 'good evening', 'howdy', 'hii', 'hiii', 'hlo'];
    final howAreYou = ['how are you', 'how r u', 'how are u', 'how r you', 'whatsup', 'what\'s up', 'sup', 'wassup'];
    final thanks = ['thank you', 'thanks', 'thank u', 'thnx', 'thankyou', 'ty'];
    
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

    final api = Provider.of<AuthProvider>(context, listen: false).api;
    
    try {
      // Detect if this is a calculation question
      final calculationKeywords = ['calculate', 'computation', 'compute', 'find', 'determine', 'what is my', 'how much'];
      final academicKeywords = ['marks', 'grade', 'attendance', 'percentage', 'cgpa', 'gpa', 'score', 'internal', 'external'];
      
      final isCalculationQuestion = calculationKeywords.any((kw) => lowerQuestion.contains(kw)) && 
                                     academicKeywords.any((kw) => lowerQuestion.contains(kw));
      
      // Enhance question for calculation requests to guide AI properly
      String questionToSend = question;
      if (isCalculationQuestion) {
        // Keep this very short to stay under 500-char API limit
        questionToSend =
        '$question. Use the university regulation documents to calculate this and give only the final answer. Do not show formulas or steps.';
      }
      
      // Send question to API
      final res = await api.askQuestion(question: questionToSend);
      final rawAnswer =
          res['answer']?.toString() ?? res['data']?.toString() ?? 'No answer';
      
      // AGGRESSIVELY clean up the raw answer - remove ALL chunk markers and metadata
      String cleanedAnswer = rawAnswer.trim();

      // Remove mathematical formulas (lines containing = with numbers/variables) if any sneak through
      if (isCalculationQuestion) {
        cleanedAnswer = cleanedAnswer.replaceAll(RegExp(r'\n[^.!?\n]*=[^.!?\n]*\n', caseSensitive: false), '\n');
        cleanedAnswer = cleanedAnswer.replaceAll(RegExp(r'\([^)]*=[^)]*\)', caseSensitive: false), '');
        cleanedAnswer = cleanedAnswer.replaceAll(RegExp(r'[A-Za-z\s]+\s*=\s*\([^)]+\)\s*[*xX]\s*\d+', caseSensitive: false), '');
      }
      
      // Remove ONLY the metadata phrases, NOT the entire content/calculations
      // This preserves marks calculation, attendance formulas, and grade explanations
      cleanedAnswer = cleanedAnswer.replaceAll(RegExp(r'(based on|according to|as per|from|using|in|of)\s+(the\s+)?(uploaded\s+)?(regulation|document|file|pdf|text)s?', caseSensitive: false), '');
      cleanedAnswer = cleanedAnswer.replaceAll(RegExp(r'(the\s+)?(uploaded\s+)(regulation|document|file|pdf)s?', caseSensitive: false), '');
      cleanedAnswer = cleanedAnswer.replaceAll(RegExp(r'answer from (this|the|a)\s+(regulation|document|file|pdf)', caseSensitive: false), '');
      
      // Remove introductory phrases that mention source documents
      cleanedAnswer = cleanedAnswer.replaceAll(RegExp(r'^[^.!?]*(uploaded|regulation\s+document)[^.!?]*[:.]\s*', caseSensitive: false), '');
      cleanedAnswer = cleanedAnswer.replaceAll(RegExp(r'(let me|i will|i can)\s+(check|refer to|look at|use)\s+(the\s+)?(uploaded|regulation|document)[^.!?]*[:.]\s*', caseSensitive: false), '');
      
      // AGGRESSIVE chunk removal - removes patterns like "chunk_88", "chunksa_26 and 104, 105, 138", "chunks_92 and 103"
      // This regex captures the entire sequence including comma/and-separated numbers
      cleanedAnswer = cleanedAnswer.replaceAll(
        RegExp(r'chunks?\w*[_\s]*\d+(?:\s*(?:,|and)\s*\d+)*', caseSensitive: false),
        '',
      );
      
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

      // If backend could not calculate percentage from context, try to calculate locally from user data
      final lowerAnswer = cleanedAnswer.toLowerCase();
      if (lowerAnswer.contains('cannot calculate your percentage based on the provided context') ||
          lowerAnswer.contains('no specific information about your grades, marks, or relevant data in the passages')) {
        // Try to extract numbers from the original question
        final lowerQuestion = question.toLowerCase();
        final numberMatches = RegExp(r'\d+\.?\d*').allMatches(question).toList();

        if (numberMatches.length >= 2) {
          final nums = numberMatches
              .map((m) => double.tryParse(m.group(0)!) ?? 0)
              .toList();
          final first = nums[0];
          final second = nums[1] == 0 ? 1 : nums[1];

          // Decide what to calculate based on keywords
          String resultText;
          if (lowerQuestion.contains('attendance')) {
            final pct = (first / second * 100).toStringAsFixed(2);
            resultText = 'Your attendance percentage is $pct%';
          } else if (lowerQuestion.contains('mark') || lowerQuestion.contains('score') || lowerQuestion.contains('grade')) {
            final pct = (first / second * 100).toStringAsFixed(2);
            resultText = 'Your marks percentage is $pct%';
          } else if (lowerQuestion.contains('cgpa') || lowerQuestion.contains('gpa')) {
            final avg = nums.reduce((a, b) => a + b) / nums.length;
            resultText = 'Your CGPA is ${avg.toStringAsFixed(2)}';
          } else {
            final pct = (first / second * 100).toStringAsFixed(2);
            resultText = 'The percentage is $pct%';
          }

          cleanedAnswer = resultText;
        } else {
          // Fallback: ask user to provide data in a clear format
          cleanedAnswer =
              'To calculate your percentage, I need your details. Please type it like:\n\n'
              '- Calculate marks 420 out of 500\n'
              '- Calculate attendance 45 out of 60\n'
              '- Calculate CGPA 8.5 9.0 8.0 7.5';
        }
      }
      
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
                      ? const Color(0xFF03045E)
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
