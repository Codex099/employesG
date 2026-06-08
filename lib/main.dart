import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart' hide Trans;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'models/employee.dart';
import 'models/absence.dart';
import 'models/pending_action.dart';
import 'services/sync_service.dart';
import 'services/auth_service.dart';
import 'services/notification_poll_service.dart';
import 'services/sheets_service.dart';
import 'services/connectivity_service.dart';
import 'services/pending_queue_service.dart';
import 'utils/translations.dart';
import 'screens/splash_screen.dart';

// ── Brand palette ──────────────
const kPrimaryDark  = Color(0xFF0B5F7A); 
const kPrimary      = Color(0xFF0891B2); 
const kPrimaryLight = Color(0xFF22D3EE); 
const kAccent       = Color(0xFF14B8A6); 
const kSurface      = Color(0xFFEFF8FB); 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ar', null);

  await Hive.initFlutter();
  Hive.registerAdapter(AbsenceTypeAdapter());
  Hive.registerAdapter(AbsenceAdapter());
  Hive.registerAdapter(PendingActionAdapter());
  Hive.registerAdapter(EmployeeAdapter());

  await Hive.openBox('settings');
  await Hive.openBox<Employee>('employees');
  await Hive.openBox<Absence>('absences');
  await Hive.openBox<PendingAction>('pendingQueue');

  Get.put(SheetsService());
  Get.put(ConnectivityService());
  Get.put(PendingQueueService());
  Get.put(SyncService());

  final authService = AuthService();
  await authService.init();

  // Temporary stub for showDevice to avoid compiling error
  final notifService = NotificationPollService(
    sheets: Get.find<SheetsService>(),
    showDevice: (title, body, {int id = 0}) async {
      // Stub
    },
  );
  await notifService.init();
  notifService.startPolling();

  runApp(
    MultiProvider(
      providers: [
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
    // ValueListenableBuilder listens ONLY to the Hive 'settings' box.
    // This means only the Theme wrapper rebuilds when dark mode changes,
    // NOT the whole GetMaterialApp (which would trigger re-fetches).
    return ValueListenableBuilder(
      valueListenable: Hive.box('settings').listenable(keys: ['isDarkMode']),
      builder: (context, box, _) {
        final isDark = box.get('isDarkMode', defaultValue: false) as bool;
        return GetMaterialApp(
          onGenerateTitle: (context) => 'app_title'.tr(context),
          debugShowCheckedModeBanner: false,
          locale: const Locale('ar'),
          builder: (context, child) {
            return Theme(
              data: isDark ? _darkTheme : _lightTheme(context),
              child: child!,
            );
          },
          supportedLocales: const [
            Locale('ar'),
            Locale('fr'),
          ],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const SplashScreen(),
        );
      },
    );
  }

  ThemeData _lightTheme(BuildContext context) => ThemeData(
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
  );

  ThemeData get _darkTheme => ThemeData(
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: kPrimary,
      brightness: Brightness.dark,
      primary: kPrimaryLight,
      secondary: kAccent,
      surface: const Color(0xFF1E293B),
    ),
    scaffoldBackgroundColor: const Color(0xFF0F172A),
    useMaterial3: true,
    textTheme: GoogleFonts.almaraiTextTheme(ThemeData.dark().textTheme),
    cardTheme: CardThemeData(
      color: const Color(0xFF1E293B),
      surfaceTintColor: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 0,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: kPrimaryLight,
      foregroundColor: Color(0xFF0F172A),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF1E293B),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.white10),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: kPrimaryLight, width: 2.0),
      ),
    ),
  );
}