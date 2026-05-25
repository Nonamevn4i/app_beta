import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
  String aiStatus = "AI Core online. Gemini API Ready.";
  late GenerativeModel _model;

  @override
  void initState() {
    super.initState();
    // FIX AI OFFLINE: Hãy thay chuỗi dưới đây bằng API Key lấy miễn phí từ Google AI Studio của bạn
    const String geminiApiKey = "AIzaSyYourActualGoogleGeminiApiKeyGoesHere"; 
    
    try {
      _model = GenerativeModel(
        model: 'gemini-1.5-flash', // Sử dụng model thế hệ mới mượt mà, tiết kiệm tài nguyên
        apiKey: geminiApiKey,
      );
    } catch (e) {
      setState(() {
        aiStatus = "AI Core offline. Gemini API key configuration failed.";
      });
    }
  }

  // FIX LỖI 1: Hàm kích hoạt Launch Overlay an toàn chống sập app
  void _launchOverlay() async {
    // 1. Kiểm tra xem máy đã cấp quyền vẽ trên ứng dụng khác chưa
    bool isGranted = await FlutterOverlayWindow.isPermissionGranted();
    
    if (!isGranted) {
      // Nếu chưa có quyền, gọi hệ thống mở cài đặt lên để bật
      await FlutterOverlayWindow.requestPermission();
      return;
    }

    // 2. Nếu đã có quyền, kiểm tra xem overlay đang chạy hay đóng
    bool? isActive = await FlutterOverlayWindow.isActive();
    if (isActive == true) {
      await FlutterOverlayWindow.closeOverlay();
    } else {
      // Khởi chạy Cửa sổ nổi an toàn với các cấu hình tối ưu chống Crash
      await FlutterOverlayWindow.showOverlay(
        enableDrag: true,
        overlayTitle: "NEXUS Monitor",
        overlayContent: "System performance monitoring active",
        flag: OverlayFlag.clickThrough,
        alignment: OverlayAlignment.centerLeft,
        visibility: NotificationVisibility.visibilityPublic,
        positionGravity: PositionGravity.left,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("NEXUS Overlay Controller")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(aiStatus, style: TextStyle(color: aiStatus.contains("online") ? Colors.green : Colors.red, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _launchOverlay,
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15)),
              child: const Text("LAUNCH OVERLAY HUD", style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}

