import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'widgets/sidebar.dart';
import 'pages/home_page.dart';
import 'pages/chat_history_page.dart';
import 'pages/history_results_page.dart';
import 'pages/settings_page.dart';
import 'pages/about_page.dart';
import 'services/hive_service.dart';
import 'services/task_service.dart';
import 'services/chat_history_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 初始化 window_manager
  await windowManager.ensureInitialized();
  WindowOptions windowOptions = const WindowOptions(
    size: Size(1280, 720),
    minimumSize: Size(800, 600),
    center: true,
    title: 'Prompt Writer',
  );
  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  // 初始化 Hive
  await Hive.initFlutter();
  
  // 初始化服务
  try {
    await HiveService.init();
    await TaskService.init();
    await ChatHistoryService.init();
  } catch (e) {
    print('服务初始化错误: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Prompt Writer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6750A4),
          brightness: Brightness.light,
        ),
        fontFamily: 'Microsoft YaHei',
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6750A4),
          brightness: Brightness.dark,
        ),
        fontFamily: 'Microsoft YaHei',
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const HomePage(),
    const ChatHistoryPage(),
    const HistoryResultsPage(),
    const SettingsPage(),
    const AboutPage(),
  ];

  void _onIndexChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Row(
        children: [
          Sidebar(
            currentIndex: _currentIndex,
            onIndexChanged: _onIndexChanged,
          ),
          Expanded(
            child: _pages[_currentIndex],
          ),
        ],
      ),
    );
  }
}
