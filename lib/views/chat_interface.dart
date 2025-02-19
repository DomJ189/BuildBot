import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../services/openai_service.dart';
import '../services/chat_service.dart';
import '../models/chat.dart';
import 'package:uuid/uuid.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

class ChatInterface extends StatefulWidget {
  const ChatInterface({super.key});

  @override
  _ChatInterfaceState createState() => _ChatInterfaceState();
}

class _ChatInterfaceState extends State<ChatInterface> {
  final _controller = TextEditingController();
  final List<Map<String, String>> _messages = [];
  late OpenAiService _openAiService;
  final ChatService _chatService = ChatService();
  String? _currentChatId;
  String? _currentChatTitle;
  bool _isBotTyping = false;
  final ScrollController _scrollController = ScrollController();
  bool _isScrollToBottomButtonVisible = false;
  
  @override
  void initState() {
    super.initState();
    final openAiApiKey = dotenv.env['OPENAI_API_KEY'];
    if (openAiApiKey == null) {
      print('Error: OPENAI_API_KEY not found in .env file');
      return;
    }
    _openAiService = OpenAiService(openAiApiKey);
    
    // Check if there's an existing chat to load
    final chatService = Provider.of<ChatService>(context, listen: false);
    if (chatService.currentChat != null) {
      _loadChat(chatService.currentChat!);
    } else {
      _createNewChat();
    }
    _scrollController.addListener(() {
      setState(() {
        _isScrollToBottomButtonVisible = _scrollController.offset < _scrollController.position.maxScrollExtent - 100;
      });
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _createNewChat() {
    final chatService = Provider.of<ChatService>(context, listen: false);
    _currentChatId = const Uuid().v4();
    chatService.setCurrentChat(null);
    setState(() {
      _messages.clear();
    });
  }

  void _loadChat(Chat chat) {
    final chatService = Provider.of<ChatService>(context, listen: false);
    chatService.setCurrentChat(chat);
    setState(() {
      _currentChatId = chat.id;
      _currentChatTitle = chat.title;
      _messages.clear();
      _messages.addAll(chat.messages);
    });
  }

  void _sendMessage() async {
    final userMessage = _controller.text.trim();
    if (userMessage.isEmpty) return;

    setState(() {
      _messages.add({'sender': 'user', 'message': userMessage});
      _controller.clear();
      _isBotTyping = true;
    });

    // Save after user message (first message sets the title)
    await _saveCurrentChat();

    try {
      final botMessage = await _openAiService.fetchResponse(userMessage);
      setState(() {
        _messages.add({'sender': 'bot', 'message': botMessage});
        _isBotTyping = false;
      });
      // Save after bot response (title remains the same)
      await _saveCurrentChat();
    } catch (e) {
      print('Error in _sendMessage: $e');
      setState(() {
        _isBotTyping = false;
        _messages.add({
          'sender': 'bot', 
          'message': 'Error fetching response. Please check your API key and try again.'
        });
      });
    }

    _scrollToBottom();
  }

  // New method to extract topic from the message
  String _extractTopic(String message) {
    // Convert to lowercase for case-insensitive matching
    final lowerMessage = message.toLowerCase();

    // Define keyword patterns
    const patterns = {
      'cpu|processor|intel|amd|ryzen|core i\\d': 'CPU Comparison',
      'gpu|graphics card|nvidia|rtx|amd radeon': 'Graphics Cards',
      'gaming|esports|fps|frame rate': 'Gaming Performance',
      'motherboard|mainboard|socket': 'Motherboards',
      'ram|memory|ddr\\d': 'Memory Configuration',
      'ssd|hdd|storage|nvme': 'Storage Solutions',
      'cooling|aio|air cooler|thermal paste': 'Cooling Systems',
      'psu|power supply|wattage': 'Power Supplies',
      'budget build|cheap|affordable': 'Budget Builds',
      'workstation|rendering|3d modeling': 'Workstation Setup'
    };

    // Check for matches
    for (final entry in patterns.entries) {
      if (RegExp(entry.key).hasMatch(lowerMessage)) {
        return entry.value;
      }
    }

    // Fallback: Use first 5 meaningful words
    final words = message.split(RegExp(r'\s+')).where((w) => w.length > 3).take(5).join(' ');
    return words.isNotEmpty ? '$words...' : 'General Inquiry';
  }

  Future<void> _saveCurrentChat() async {
    if (_currentChatId == null || _messages.isEmpty) return;

    // Only set the title if it hasn't been set yet and we have the first message
    if (_currentChatTitle == null && _messages.length == 1) {
        _currentChatTitle = _extractTopic(_messages.first['message'] ?? '');
    }

    final chat = Chat(
        id: _currentChatId!,
        title: _currentChatTitle ?? 'General Inquiry',
        createdAt: DateTime.now(),
        messages: _messages,
    );

    await _chatService.saveChat(chat);
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkTheme = themeProvider.currentTheme.brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: themeProvider.currentTheme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: themeProvider.currentTheme.appBarTheme.backgroundColor,
        title: Text(
          "What can I help with?",
          style: TextStyle(color: themeProvider.currentTheme.textTheme.titleLarge?.color),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: themeProvider.currentTheme.iconTheme.color),
            onPressed: _createNewChat,
            tooltip: 'New Chat',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                ListView.builder(
                  controller: _scrollController,
                  itemCount: _messages.length + (_isBotTyping ? 1 : 0),
                  padding: EdgeInsets.all(16),
                  itemBuilder: (context, index) {
                    if (_isBotTyping && index == _messages.length) {
                      return Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          margin: EdgeInsets.only(bottom: 16, right: 64),
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDarkTheme ? Color(0xFF1A1A1A) : Colors.grey[200],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AnimatedTextKit(
                                animatedTexts: [
                                  TyperAnimatedText(
                                    '...',
                                    textStyle: TextStyle(
                                      fontSize: 32,
                                      color: isDarkTheme ? Colors.white : Colors.black,
                                    ),
                                    speed: Duration(milliseconds: 200),
                                  ),
                                ],
                                repeatForever: true,
                                pause: Duration(milliseconds: 500),
                                isRepeatingAnimation: true,
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    final message = _messages[index];
                    return Align(
                      alignment: message['sender'] == 'user'
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: EdgeInsets.only(
                          bottom: 16,
                          left: message['sender'] == 'user' ? 64 : 0,
                          right: message['sender'] == 'user' ? 0 : 64,
                        ),
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDarkTheme
                              ? (message['sender'] == 'user'
                                  ? Color(0xFF424242)
                                  : Color(0xFF1A1A1A))
                              : (message['sender'] == 'user'
                                  ? Colors.blue
                                  : Colors.grey[200]),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          message['message']!,
                          style: TextStyle(
                            color: isDarkTheme
                                ? Colors.white
                                : (message['sender'] == 'user'
                                    ? Colors.white
                                    : Colors.black),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                if (_isScrollToBottomButtonVisible)
                  Positioned(
                    bottom: 80,
                    right: 16,
                    child: FloatingActionButton(
                      onPressed: _scrollToBottom,
                      backgroundColor: isDarkTheme ? Colors.white : Colors.blue,
                      child: Icon(
                        Icons.arrow_downward,
                        color: isDarkTheme ? Colors.black : Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Container(
            margin: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDarkTheme ? Color(0xFF2D2D2D) : Colors.grey[200],
              borderRadius: BorderRadius.circular(25),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: "Type a message...",
                      hintStyle: TextStyle(
                        color: isDarkTheme ? Colors.grey[400] : Colors.grey[600],
                      ),
                      border: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                    ),
                    style: TextStyle(
                      color: isDarkTheme ? Colors.white : Colors.black,
                    ),
                    minLines: 1,
                    maxLines: 3,
                  ),
                ),
                Container(
                  margin: EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: isDarkTheme ? Colors.white : Colors.blue,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: Icon(
                      Icons.send,
                      color: isDarkTheme ? Color(0xFF2D2D2D) : Colors.white,
                      size: 24,
                    ),
                    padding: EdgeInsets.all(12),
                    onPressed: _sendMessage,
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

