import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'services/sync_service.dart';
import 'services/auth_service.dart';
import 'services/notification_poll_service.dart';
import 'services/sheets_service.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'utils/translations.dart';
import 'screens/splash_screen.dart';

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

  final syncService = SyncService();
  final notifService = NotificationPollService(
    sheets: SheetsService(),
    showDevice: syncService.showNotification,
  );
  await notifService.init();
  notifService.startPolling();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: syncService),
        ChangeNotifierProvider.value(value: authService),
        ChangeNotifierProvider.value(value: notifService),
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
      onGenerateTitle: (context) => 'app_title'.tr(context),
      debugShowCheckedModeBanner: false,
      locale: Locale(syncService.locale),
      supportedLocales: const [
        Locale('ar'),
        Locale('fr'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
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
        cardTheme: CardThemeData(
          color: Colors.white,
          surfaceTintColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 0,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: kPrimary,
          foregroundColor: Colors.white,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: kPrimary,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF0FAFF),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: kPrimaryLight.withOpacity(0.3),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: kPrimary, width: 2.0),
          ),
        ),
      ),

      // ── Dark theme ───────────────────────────────────────
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          brightness: Brightness.dark,
          seedColor: kPrimary,
          primary: kPrimaryLight,
          secondary: kAccent,
          surface: const Color(0xFF0F172A), // Modern dark blue
        ),
        useMaterial3: true,
        textTheme: GoogleFonts.almaraiTextTheme(ThemeData.dark().textTheme),
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        cardTheme: CardThemeData(
          color: const Color(0xFF1E293B), // Soft dark contrast
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 0,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: kPrimary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: kPrimary,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white.withOpacity(0.05),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: Colors.white.withOpacity(0.1),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: kPrimaryLight, width: 2.0),
          ),
        ),
      ),

      home: const SplashScreen(),
    );
  }
}