import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'services/sync_service.dart';
import 'screens/home_screen.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ar', null);
  runApp(
    ChangeNotifierProvider(
      create: (context) => SyncService(),
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
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2563eb),
          primary: const Color(0xFF2563eb),
          surface: const Color(0xFFf0f4ff),
        ),
        useMaterial3: true,
        textTheme: GoogleFonts.almaraiTextTheme(Theme.of(context).textTheme),
        cardTheme: const CardThemeData(
          color: Colors.white,
          surfaceTintColor: Colors.white,
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          brightness: Brightness.dark,
          seedColor: const Color(0xFF2563eb),
          primary: const Color(0xFF2563eb),
          surface: const Color(0xFF0b1120),
        ),
        useMaterial3: true,
        textTheme: GoogleFonts.almaraiTextTheme(ThemeData.dark().textTheme),
        cardTheme: const CardThemeData(
          color: Color(0xFF131e35),
          surfaceTintColor: Color(0xFF131e35),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}