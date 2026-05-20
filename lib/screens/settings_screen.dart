import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/app_settings.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _db = DatabaseHelper();
  late AppSettings _settings;
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final s = await _db.getSettings();
    setState(() { _settings = s; _loading = false; });
  }

  Future<void> _save() async {
    await _db.saveSettings(_settings);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Настройки сохранены')));
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Настройки')),
      body: _loading ? const Center(child: CircularProgressIndicator())
        : ListView(padding: const EdgeInsets.all(16), children: [
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Тема оформления', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'light', icon: Icon(Icons.light_mode), label: Text('Светлая')),
                      ButtonSegment(value: 'dark', icon: Icon(Icons.dark_mode), label: Text('Тёмная')),
                    ],
                    selected: {_settings.themeMode},
                    onSelectionChanged: (v) => setState(() => _settings.themeMode = v.first),
                  ),
                ]),
              ),
            ),
            const SizedBox(height: 8),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Язык / Language', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'ru', icon: Icon(Icons.language), label: Text('Русский')),
                      ButtonSegment(value: 'en', icon: Icon(Icons.language), label: Text('English')),
                    ],
                    selected: {_settings.language},
                    onSelectionChanged: (v) => setState(() => _settings.language = v.first),
                  ),
                ]),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(onPressed: _save, icon: const Icon(Icons.save), label: const Text('Сохранить настройки')),
          ]),
    );
  }
}
