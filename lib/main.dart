import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'ai_chat_page.dart';

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
  late final WebViewController _controller;

  final List<Map<String, String>> topics = [
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

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF0F172A))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            _controller.runJavaScript("""
              setTimeout(function() {
                window.dispatchEvent(new Event('resize'));
                if (typeof init === 'function') init();
              }, 500);
            """);
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Physics Lab",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF1E293B),
        iconTheme: const IconThemeData(color: Colors.white),
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
                  "Physics Lab\nБөлімдер",
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
                itemCount: topics.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    leading: const Icon(
                      Icons.science_outlined,
                      color: Color(0xFF60a5fa),
                    ),
                    title: Text(
                      topics[index]['name']!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                    onTap: () {
                      _controller.loadFlutterAsset(
                        'assets/www/${topics[index]['file']}',
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
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF7C3AED),
        icon: const Icon(Icons.smart_toy, color: Colors.white),
        label: const Text(
          "AI Chat",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AiChatPage()),
          );
        },
      ),
      body: SafeArea(
        child: WebViewWidget(controller: _controller),
      ),
    );
  }
}