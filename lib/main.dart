import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'models/employee.dart';
import 'providers/employee_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/language_provider.dart';
import 'providers/absence_provider.dart';
import 'providers/conge_provider.dart';
import 'services/notification_service.dart';
import 'widgets/main_navigation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(EmployeeAdapter());
  
  tz.initializeTimeZones();
  await NotificationService().init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => EmployeeProvider()..init()),
        // On force le monde sombre par défaut pour le style "Lux" si l'utilisateur l'apprécie
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider(create: (_) => AbsenceProvider()),
        ChangeNotifierProvider(create: (_) => CongeProvider()),
      ],
      child: Consumer<ThemeProvider>(builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'Mes employés',
          // Retour au mode dynamique contrôlé par le themeProvider
          themeMode: themeProvider.mode,
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFFD4AF37), // Or
              primary: const Color(0xFFD4AF37),
              surface: Colors.white,
            ),
            scaffoldBackgroundColor: const Color(0xFFF4F6F8), // Fond très clair et doux
            cardColor: Colors.white,
            dialogBackgroundColor: Colors.white,
            textTheme: GoogleFonts.outfitTextTheme(Theme.of(context).textTheme),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFFD4AF37), // Accent Or Premium
              primary: const Color(0xFFD4AF37),
              secondary: const Color(0xFFE5CC80),
              brightness: Brightness.dark,
              surface: const Color(0xFF141416), // Charbon très sombre (verre)
            ),
            scaffoldBackgroundColor: const Color(0xFF0D0D0E), // Fond Noir Très Profond
            cardColor: const Color(0xFF1A1A1C),
            dialogBackgroundColor: const Color(0xFF1A1A1C),
            textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme),
            appBarTheme: const AppBarTheme(
              centerTitle: true,
              elevation: 0,
              backgroundColor: Colors.transparent, // AppBar Transparente pour le luxe
              scrolledUnderElevation: 0,
            ),
            bottomSheetTheme: const BottomSheetThemeData(
              backgroundColor: Color(0xFF141416),
            ),
          ),
          home: const MainNavigation(),
          debugShowCheckedModeBanner: false,
        );
      }),
    );
  }
}
