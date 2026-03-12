import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: PhysicsApp(),
  ));
}

class PhysicsApp extends StatefulWidget {
  const PhysicsApp({super.key});

  @override
  State<PhysicsApp> createState() => _PhysicsAppState();
}

class _PhysicsAppState extends State<PhysicsApp> {
  static const String _openAiUrl = 'https://api.openai.com/v1/chat/completions';

  late final WebViewController _controller;
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _apiKeyController = TextEditingController();
  final ScrollController _chatScrollController = ScrollController();

  final List<Map<String, String>> _topics = [
    {'name': 'Басты бет', 'file': 'index.html'},
    {'name': '1. Кинематика', 'file': 'kinematics.html'},
    {'name': '2. Динамика', 'file': 'dynamics.html'},
    {'name': '3. Ньютон заңдары', 'file': 'newton.html'},
    {'name': '4. Сақталу заңдары', 'file': 'energy.html'},
    {'name': '5. Тербелістер', 'file': 'waves.html'},
    {'name': '6. Молекулалық физика', 'file': 'mkt.html'},
    {'name': '7. Термодинамика', 'file': 'thermodynamics.html'},
    {'name': '8. Электростатика', 'file': 'electrostatics.html'},
    {'name': '9. Тұрақты ток', 'file': 'current.html'},
    {'name': '10. Магнит өрісі', 'file': 'magnetism.html'},
    {'name': '11. Оптика', 'file': 'optics.html'},
    {'name': '12. Атомдық физика', 'file': 'atom.html'},
    {'name': '13. Ядролық физика', 'file': 'nuclear.html'},
  ];

  final List<_ChatMessage> _messages = [
    const _ChatMessage(
      role: _ChatRole.assistant,
      text: 'Сәлем! Мен сенің физика бойынша ИИ көмекшіңмін. Сұрағыңды жаза бер.',
    ),
  ];

  bool _isChatLoading = false;

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF0F172A))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            _controller.runJavaScript('''
              setTimeout(function() {
                window.dispatchEvent(new Event('resize'));
                if (typeof init === 'function') init();
              }, 500);
            ''');
          },
        ),
      )
      ..loadFlutterAsset('assets/www/index.html');

    if (_controller.platform is AndroidWebViewController) {
      AndroidWebViewController.enableDebugging(true);
      (_controller.platform as AndroidWebViewController)
          .setMediaPlaybackRequiresUserGesture(false);
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _apiKeyController.dispose();
    _chatScrollController.dispose();
    super.dispose();
  }

  Future<void> _showApiKeyDialog() async {
    _apiKeyController.text = _apiKeyController.text.trim();

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('OpenAI API кілті'),
          content: TextField(
            controller: _apiKeyController,
            obscureText: true,
            decoration: const InputDecoration(
              hintText: 'sk-... ',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Жабу'),
            ),
            FilledButton(
              onPressed: () {
                setState(() {
                  _apiKeyController.text = _apiKeyController.text.trim();
                });
                Navigator.pop(context);
              },
              child: const Text('Сақтау'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _sendMessage() async {
    if (_isChatLoading) return;

    final userText = _messageController.text.trim();
    if (userText.isEmpty) return;

    if (_apiKeyController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Алдымен OpenAI API кілтін енгізіңіз.')),
      );
      await _showApiKeyDialog();
      return;
    }

    setState(() {
      _messages.add(_ChatMessage(role: _ChatRole.user, text: userText));
      _isChatLoading = true;
      _messageController.clear();
    });

    _scrollChatToBottom();

    try {
      final response = await http.post(
        Uri.parse(_openAiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${_apiKeyController.text.trim()}',
        },
        body: jsonEncode({
          'model': 'gpt-4o-mini',
          'messages': [
            {
              'role': 'system',
              'content':
                  'You are a helpful physics tutor. Keep answers short, practical, and student-friendly in Kazakh or Russian depending on user language.',
            },
            ..._messages
                .where((message) => message.role != _ChatRole.system)
                .map((message) => {
                      'role': message.role == _ChatRole.user ? 'user' : 'assistant',
                      'content': message.text,
                    }),
          ],
          'temperature': 0.4,
        }),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final choices = data['choices'] as List<dynamic>?;
        final answer = choices != null && choices.isNotEmpty
            ? (choices.first['message']?['content'] as String? ?? '').trim()
            : '';

        setState(() {
          _messages.add(
            _ChatMessage(
              role: _ChatRole.assistant,
              text: answer.isEmpty
                  ? 'Кешіріңіз, қазір жауап ала алмадым. Қайтадан сұрап көріңіз.'
                  : answer,
            ),
          );
        });
      } else {
        setState(() {
          _messages.add(
            _ChatMessage(
              role: _ChatRole.assistant,
              text:
                  'Қате: ${response.statusCode}. API кілтін тексеріп, қайта көріңіз.',
            ),
          );
        });
      }
    } catch (_) {
      setState(() {
        _messages.add(
          const _ChatMessage(
            role: _ChatRole.assistant,
            text: 'Желі қатесі. Интернетті тексеріп, қайта көріңіз.',
          ),
        );
      });
    } finally {
      setState(() {
        _isChatLoading = false;
      });
      _scrollChatToBottom();
    }
  }

  void _scrollChatToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_chatScrollController.hasClients) {
        _chatScrollController.animateTo(
          _chatScrollController.position.maxScrollExtent + 140,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Physics Lab',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1E293B),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            tooltip: 'API кілті',
            onPressed: _showApiKeyDialog,
            icon: const Icon(Icons.key_rounded),
          ),
        ],
      ),
      drawer: Drawer(
        backgroundColor: const Color(0xFF0F172A),
        child: Column(
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF2563eb), Color(0xFF7c3aed)],
                ),
              ),
              child: Center(
                child: Text(
                  'Physics Lab\nБөлімдер',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: _topics.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    leading: const Icon(
                      Icons.science_outlined,
                      color: Color(0xFF60a5fa),
                    ),
                    title: Text(
                      _topics[index]['name']!,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    onTap: () {
                      _controller.loadFlutterAsset(
                        'assets/www/${_topics[index]['file']}',
                      );
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              flex: 3,
              child: WebViewWidget(controller: _controller),
            ),
            Container(
              color: const Color(0xFF0B1220),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: const BoxDecoration(
                      border: Border(
                        top: BorderSide(color: Color(0xFF1F2937)),
                        bottom: BorderSide(color: Color(0xFF1F2937)),
                      ),
                    ),
                    child: const Text(
                      'ИИ Чат (Физика көмекшісі)',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 220,
                    child: ListView.builder(
                      controller: _chatScrollController,
                      padding: const EdgeInsets.all(12),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final message = _messages[index];
                        final isUser = message.role == _ChatRole.user;
                        return Align(
                          alignment:
                              isUser ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(10),
                            constraints: const BoxConstraints(maxWidth: 320),
                            decoration: BoxDecoration(
                              color: isUser
                                  ? const Color(0xFF2563EB)
                                  : const Color(0xFF1E293B),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              message.text,
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _messageController,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'Сұрағыңызды жазыңыз...',
                              hintStyle:
                                  const TextStyle(color: Color(0xFF94A3B8)),
                              filled: true,
                              fillColor: const Color(0xFF1E293B),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            onSubmitted: (_) => _sendMessage(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        FilledButton(
                          onPressed: _isChatLoading ? null : _sendMessage,
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF2563EB),
                            padding: const EdgeInsets.all(14),
                          ),
                          child: _isChatLoading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.send_rounded),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _ChatRole { system, user, assistant }

class _ChatMessage {
  const _ChatMessage({required this.role, required this.text});

  final _ChatRole role;
  final String text;
}
