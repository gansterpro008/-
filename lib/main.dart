import 'package:flutter/material.dart';
import 'database/database_helper.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final db = DatabaseHelper();
  final settings = await db.getSettings();
  final initialTheme = settings.themeMode == 'dark' ? ThemeMode.dark : ThemeMode.light;
  runApp(WarehouseApp(initialTheme: initialTheme));
}

class WarehouseApp extends StatefulWidget {
  final ThemeMode initialTheme;
  const WarehouseApp({super.key, required this.initialTheme});

  @override
  State<WarehouseApp> createState() => _WarehouseAppState();
}

class _WarehouseAppState extends State<WarehouseApp> {
  late ThemeMode _themeMode;

  @override
  void initState() {
    super.initState();
    _themeMode = widget.initialTheme;
  }

  Future<void> refreshTheme() async {
    final db = DatabaseHelper();
    final settings = await db.getSettings();
    if (mounted) {
      setState(() => _themeMode = settings.themeMode == 'dark' ? ThemeMode.dark : ThemeMode.light);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Учёт товаров',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo, brightness: Brightness.light),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo, brightness: Brightness.dark),
        useMaterial3: true,
      ),
      home: HomeScreen(onThemeChanged: refreshTheme),
    );
  }
}
