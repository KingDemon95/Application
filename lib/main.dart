import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';
import 'screens/pengingat_detail_screen.dart';
import 'services/notification_service.dart';

final navigatorKey = GlobalKey<NavigatorState>();

// ThemeProvider global — bisa diakses dari mana saja
final themeProvider = ThemeProvider();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await NotificationService().init();

  runApp(const ValenxApp());
}

class ValenxApp extends StatefulWidget {
  const ValenxApp({super.key});

  @override
  State<ValenxApp> createState() => _ValenxAppState();
}

class _ValenxAppState extends State<ValenxApp> {
  @override
  void initState() {
    super.initState();
    // Rebuild saat theme berubah
    themeProvider.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Valenx',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeProvider.mode,
      navigatorKey: navigatorKey,
      home: const SplashScreen(),
      onGenerateRoute: (settings) {
        if (settings.name == '/pengingat-detail') {
          final args = settings.arguments as Map<String, dynamic>?;
          return MaterialPageRoute(
            builder: (_) => PengingatDetailScreen(
              pengingatId: args?['pengingatId'] ?? '',
              namaObat: args?['namaObat'] ?? '',
            ),
          );
        }
        return null;
      },
    );
  }
}