// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:math';

import '../../core/constants/colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/gemini_assistant_provider.dart';

class AIAssistantScreen extends StatefulWidget {
  const AIAssistantScreen({super.key});

  @override
  State<AIAssistantScreen> createState() => _AIAssistantScreenState();
}

class _AIAssistantScreenState extends State<AIAssistantScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [];

  bool _isTyping = false;
  bool _hasError = false;
  final int _maxRetries = 3;

  @override
  void initState() {
    super.initState();
    _loadGreeting();
  }

  void _loadGreeting() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final geminiProvider = context.read<GeminiAssistantProvider>();

      if (!geminiProvider.isInitialized && !geminiProvider.isInitializing) {
        await geminiProvider.initialize();
      }

      if (!mounted) return;

      final user = context.read<AuthProvider>().currentUser;
      final userName =
          user?.name.trim().isNotEmpty == true ? user!.name.trim() : 'there';
      final userType = user?.type.toString().split('.').last ?? 'user';

      _addAssistantMessage(
        "Hello $userName 👋\n\n"
        "I'm your AI Copilot for AI Ration Mitra.\n\n"
        "As a $userType, I can help you with:\n"
        "• Feature guidance and tutorials\n"
        "• Troubleshooting issues\n"
        "• Best practices\n"
        "• Account and data queries\n\n"
        "Just ask me anything!",
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  bool get _canSend => _controller.text.trim().isNotEmpty && !_isTyping;

  Future<void> _sendMessage({int retryCount = 0}) async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final user = context.read<AuthProvider>().currentUser;

    setState(() {
      _messages.add(_ChatMessage.user(
        text,
        timestamp: DateTime.now(),
      ));
      _controller.clear();
      _isTyping = true;
      _hasError = false;
    });

    _scrollToBottom();

    try {
      final gemini = context.read<GeminiAssistantProvider>();
      final reply = await gemini
          .getResponse(
            text,
            userType: user?.type,
            userName: user?.name,
            userId: user?.id,
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () => null,
          );

      if (!mounted) return;

      setState(() {
        if (reply != null) {
          _messages.add(
            _ChatMessage.assistant(
              reply.text,
              suggestedRoute: reply.suggestedRoute,
              steps: reply.steps,
              timestamp: DateTime.now(),
            ),
          );
          _hasError = false;
        } else {
          final errorMsg =
              gemini.error ?? "Connection timeout. Please try again.";
          _messages.add(
            _ChatMessage.assistant(
              errorMsg,
              isError: true,
              timestamp: DateTime.now(),
            ),
          );
          _hasError = true;
        }
        _isTyping = false;
      });
    } catch (e) {
      if (!mounted) return;

      // Retry logic for transient errors
      if (retryCount < _maxRetries &&
          (e.toString().contains('timeout') ||
              e.toString().contains('SocketException') ||
              e.toString().contains('Connection'))) {
        await Future.delayed(Duration(seconds: 1 + retryCount));
        if (mounted) {
          _messages.removeLast(); // Remove failed attempt
          await _sendMessage(retryCount: retryCount + 1);
        }
        return;
      }

      setState(() {
        _messages.add(
          _ChatMessage.assistant(
            "Sorry, I encountered an error: ${e.toString().split(':').first}\n\nPlease try again or refresh the app.",
            isError: true,
            timestamp: DateTime.now(),
          ),
        );
        _isTyping = false;
        _hasError = true;
      });
    }

    _scrollToBottom();
  }

  void _addAssistantMessage(String text) {
    setState(() {
      _messages.add(_ChatMessage.assistant(
        text,
        timestamp: DateTime.now(),
      ));
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 80,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  Widget _chatBubble(_ChatMessage message) {
    final isUser = message.role == "user";
    final timeStr = DateFormat('HH:mm').format(message.timestamp);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            const CircleAvatar(
              radius: 16,
              backgroundColor: Colors.black87,
              child: Icon(Icons.smart_toy, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isUser
                        ? AppColors.saffron
                        : (message.isError
                            ? Colors.red.shade100
                            : Colors.white),
                    borderRadius: BorderRadius.circular(16),
                    border: message.isError
                        ? Border.all(color: Colors.red.shade300)
                        : null,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.07),
                        blurRadius: 6,
                      )
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (message.isError)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 8),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.error_outline,
                                  color: Colors.red, size: 16),
                              SizedBox(width: 6),
                              Text('Error',
                                  style: TextStyle(
                                      color: Colors.red,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12)),
                            ],
                          ),
                        ),
                      Text(
                        message.text,
                        style: TextStyle(
                          color: isUser
                              ? Colors.white
                              : (message.isError
                                  ? Colors.red.shade900
                                  : Colors.black87),
                        ),
                      ),
                      if (message.steps.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        const Text(
                          "Steps:",
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                        ...message.steps.asMap().entries.map(
                              (e) => Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  "${e.key + 1}. ${e.value}",
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                            )
                      ],
                      if (message.suggestedRoute != null) ...[
                        const SizedBox(height: 10),
                        OutlinedButton(
                          onPressed: () => Navigator.pushNamed(
                            context,
                            message.suggestedRoute!,
                          ),
                          child: const Text(
                            "Open Feature",
                            style: TextStyle(fontSize: 12),
                          ),
                        )
                      ],
                      if (!isUser && !message.isError) ...[
                        const SizedBox(height: 8),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Tooltip(
                              message: 'Copy message',
                              child: IconButton(
                                icon: const Icon(Icons.copy, size: 16),
                                onPressed: () {
                                  // Copy functionality can be implemented here
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text('Copied to clipboard')),
                                  );
                                },
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Tooltip(
                              message: 'Helpful',
                              child: IconButton(
                                icon: const Icon(Icons.thumb_up_outlined,
                                    size: 16, color: Colors.green),
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content:
                                            Text('Thanks for the feedback!')),
                                  );
                                },
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Tooltip(
                              message: 'Not helpful',
                              child: IconButton(
                                icon: const Icon(Icons.thumb_down_outlined,
                                    size: 16, color: Colors.red),
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text(
                                            'We\'ll improve our responses')),
                                  );
                                },
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    timeStr,
                    style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                        fontStyle: FontStyle.italic),
                  ),
                ),
              ],
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            const CircleAvatar(
              radius: 16,
              backgroundColor: Colors.orange,
              child: Icon(Icons.person, color: Colors.white, size: 18),
            ),
          ] else
            const SizedBox(width: 24),
        ],
      ),
    );
  }

  Widget _typingIndicator() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: Colors.black87,
            child: Icon(Icons.smart_toy, color: Colors.white, size: 18),
          ),
          SizedBox(width: 10),
          _TypingAnimation(),
        ],
      ),
    );
  }

  Widget _inputBar(GeminiAssistantProvider gemini) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              blurRadius: 8,
              color: Colors.black.withOpacity(0.08),
              offset: const Offset(0, -2),
            )
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_hasError)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline,
                          color: Colors.red.shade700, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Connection issue. Retrying...',
                          style: TextStyle(
                              color: Colors.red.shade700, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: TextField(
                      controller: _controller,
                      minLines: 1,
                      maxLines: 5,
                      enabled: !_isTyping,
                      onChanged: (_) => setState(() {}),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                      decoration: InputDecoration(
                        hintText: _isTyping
                            ? "Waiting for response..."
                            : "Ask anything...",
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.saffron, Color(0xffff8f00)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: IconButton(
                    icon: _isTyping
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.send, color: Colors.white),
                    onPressed: _canSend ? _sendMessage : null,
                  ),
                )
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GeminiAssistantProvider>(
      builder: (context, gemini, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text("AI Copilot"),
            flexibleSpace: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.saffron,
                    Color(0xffff8f00),
                  ],
                ),
              ),
            ),
            actions: [
              if (_messages.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Clear conversation',
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Clear Conversation?'),
                        content: const Text(
                            'This will delete all messages in this chat.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Cancel'),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              setState(() => _messages.clear());
                              Navigator.pop(ctx);
                              _addAssistantMessage(
                                  'Conversation cleared. How can I help you?');
                            },
                            child: const Text('Clear'),
                          ),
                        ],
                      ),
                    );
                  },
                )
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: _messages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.smart_toy_outlined,
                              size: 64,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No messages yet',
                              style: TextStyle(
                                  color: Colors.grey.shade600, fontSize: 16),
                            ),
                          ],
                        ),
                      )
                    : Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.grey.shade100,
                              Colors.white,
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                        child: ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(14),
                          itemCount: _messages.length + (_isTyping ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index >= _messages.length) {
                              return _typingIndicator();
                            }
                            return _chatBubble(_messages[index]);
                          },
                        ),
                      ),
              ),
              _inputBar(gemini),
            ],
          ),
        );
      },
    );
  }
}

class _TypingAnimation extends StatefulWidget {
  const _TypingAnimation();

  @override
  State<_TypingAnimation> createState() => _TypingAnimationState();
}

class _TypingAnimationState extends State<_TypingAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(
        3,
        (index) => AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final offset =
                sin((_controller.value * pi * 2) - (index * pi / 3)) * .5 + 0.5;
            return Transform.translate(
              offset: Offset(0, -offset * 5),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.grey,
                  shape: BoxShape.circle,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ChatMessage {
  final String role;
  final String text;
  final String? suggestedRoute;
  final List<String> steps;
  final DateTime timestamp;
  final bool isError;

  const _ChatMessage({
    required this.role,
    required this.text,
    this.suggestedRoute,
    this.steps = const [],
    required this.timestamp,
    this.isError = false,
  });

  factory _ChatMessage.user(String text, {required DateTime timestamp}) {
    return _ChatMessage(
      role: "user",
      text: text,
      timestamp: timestamp,
    );
  }

  factory _ChatMessage.assistant(
    String text, {
    String? suggestedRoute,
    List<String> steps = const [],
    required DateTime timestamp,
    bool isError = false,
  }) {
    return _ChatMessage(
      role: "assistant",
      text: text,
      suggestedRoute: suggestedRoute,
      steps: steps,
      timestamp: timestamp,
      isError: isError,
    );
  }
}
