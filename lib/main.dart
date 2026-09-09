import 'package:flutter/material.dart';

import 'screen/splash_screen.dart';
import 'services/theme_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ThemeController.load();
  runApp(const MemoraApp());
}

class MemoraApp extends StatelessWidget {
  const MemoraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.mode,
      builder: (context, themeMode, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Memora',
          themeMode: themeMode,
          theme: MemoraTheme.light(),
          darkTheme: MemoraTheme.dark(),
          home: const SplashScreen(),
        );
      },
    );
  }
}
