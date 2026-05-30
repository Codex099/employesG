import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'services/sync_service.dart';
import 'services/auth_service.dart';
import 'screens/splash_screen.dart';
import 'package:intl/date_symbol_data_local.dart';

// ── Brand palette (extracted from Firefly logo) ──────────────
const kPrimaryDark  = Color(0xFF0B5F7A); // dark teal
const kPrimary      = Color(0xFF0891B2); // cyan-600
const kPrimaryLight = Color(0xFF22D3EE); // cyan-300
const kAccent       = Color(0xFF14B8A6); // teal-400
const kSurface      = Color(0xFFEFF8FB); // very light cyan-tint

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ar', null);

  final authService = AuthService();
  await authService.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SyncService()),
        ChangeNotifierProvider.value(value: authService),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final syncService = Provider.of<SyncService>(context);

    return MaterialApp(
      title: 'نظام إدارة العمال',
      debugShowCheckedModeBanner: false,
      themeMode: syncService.isDarkMode ? ThemeMode.dark : ThemeMode.light,

      // ── Light theme ──────────────────────────────────────
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: kPrimary,
          primary: kPrimary,
          secondary: kAccent,
          surface: kSurface,
        ),
        useMaterial3: true,
        textTheme: GoogleFonts.almaraiTextTheme(Theme.of(context).textTheme),
        cardTheme: const CardThemeData(
          color: Colors.white,
          surfaceTintColor: Colors.white,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: kPrimary,
          foregroundColor: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: kPrimary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ),

      // ── Dark theme ───────────────────────────────────────
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          brightness: Brightness.dark,
          seedColor: kPrimary,
          primary: kPrimary,
          secondary: kAccent,
          surface: const Color(0xFF071820),
        ),
        useMaterial3: true,
        textTheme: GoogleFonts.almaraiTextTheme(ThemeData.dark().textTheme),
        cardTheme: const CardThemeData(
          color: Color(0xFF0D2030),
          surfaceTintColor: Color(0xFF0D2030),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: kPrimary,
          foregroundColor: Colors.white,
        ),
      ),

      home: const SplashScreen(),
    );
  }
}