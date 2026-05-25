import 'package:flutter/material.dart';
import 'app.dart';
import 'screens/overlay_screen.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

void main() {
  runApp(const App());
}

/// Overlay entry point required by flutter_overlay_window package.
/// Runs as a separate isolate when the floating overlay is spawned.
@pragma('vm:entry-point')
void overlayMain() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: OverlayScreen(),
  ));
}
