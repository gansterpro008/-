import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/app_settings.dart';
import '../utils/export_service.dart';
import 'calculator_screen.dart';
import 'barcode_screen.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  final VoidCallback onThemeChanged;
  const ProfileScreen({super.key, required this.onThemeChanged});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _db = DatabaseHelper();
  AppSettings _settings = AppSettings();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final settings = await _db.getSettings();
    setState(() { _settings = settings; _loading = false; });
  }

  Future<void> _editOrg() async {
    final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => _OrgEditScreen(settings: _settings)));
    if (result != null) {
      _settings = result;
      await _db.saveSettings(_settings);
      setState(() {});
    }
  }

  Future<void> _editUser() async {
    final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => _UserEditScreen(settings: _settings)));
    if (result != null) {
      _settings = result;
      await _db.saveSettings(_settings);
      setState(() {});
    }
  }

  Future<void> _openSettings() async {
    final result = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
    if (result == true) { _load(); widget.onThemeChanged(); }
  }

  Future<void> _exportData() async {
    try {
      await ExportService.exportToExcel();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Excel-файл сохранён и отправлен'),
        backgroundColor: Colors.green,
      ));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка экспорта: $e'), backgroundColor: Colors.red));
    }
  }

  void _openCalculator() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const CalculatorScreen()));
  }

  void _openBarcode() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const BarcodeScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Профиль'), centerTitle: true, actions: [
        IconButton(icon: const Icon(Icons.settings), onPressed: _openSettings, tooltip: 'Настройки'),
      ]),
      body: _loading
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(children: [
                    Container(width: 80, height: 80, decoration: BoxDecoration(color: theme.colorScheme.primaryContainer, borderRadius: BorderRadius.circular(24)),
                      child: Icon(Icons.business, size: 44, color: theme.colorScheme.onPrimaryContainer)),
                    const SizedBox(height: 12),
                    Text(_settings.orgName, style: theme.textTheme.titleLarge),
                    if (_settings.orgAddress.isNotEmpty) Text(_settings.orgAddress, style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
                    const SizedBox(height: 16),
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      if (_settings.orgPhone.isNotEmpty) ...[Icon(Icons.phone, size: 16, color: theme.colorScheme.onSurfaceVariant), const SizedBox(width: 4), Text(_settings.orgPhone, style: TextStyle(color: theme.colorScheme.onSurfaceVariant)), const SizedBox(width: 16)],
                      if (_settings.orgEmail.isNotEmpty) ...[Icon(Icons.email, size: 16, color: theme.colorScheme.onSurfaceVariant), const SizedBox(width: 4), Text(_settings.orgEmail, style: TextStyle(color: theme.colorScheme.onSurfaceVariant))],
                    ]),
                    if (_settings.orgTaxId.isNotEmpty) const SizedBox(height: 4),
                    if (_settings.orgTaxId.isNotEmpty) Text('БИН/ИНН: ${_settings.orgTaxId}', style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 13)),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(onPressed: _editOrg, icon: const Icon(Icons.edit), label: const Text('Редактировать организацию')),
                  ]),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(children: [
                    Container(width: 72, height: 72, decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(24)),
                      child: Icon(Icons.person, size: 40, color: Colors.blue.shade700)),
                    const SizedBox(height: 12),
                    Text(_settings.userName, style: theme.textTheme.titleLarge),
                    Container(margin: const EdgeInsets.only(top: 4), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(20)),
                      child: Text(_settings.userRole, style: TextStyle(color: Colors.blue.shade700))),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(onPressed: _editUser, icon: const Icon(Icons.edit), label: const Text('Редактировать профиль')),
                  ]),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  leading: const Icon(Icons.settings),
                  title: const Text('Настройки приложения'),
                  subtitle: const Text('Тема, валюта, язык'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _openSettings,
                ),
              ),
              const SizedBox(height: 12),
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  leading: const Icon(Icons.file_download),
                  title: const Text('Экспорт в Excel'),
                  subtitle: const Text('Выгрузить товары в XLSX'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _exportData,
                ),
              ),
              const SizedBox(height: 12),
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  leading: const Icon(Icons.calculate),
                  title: const Text('Калькулятор'),
                  subtitle: const Text('Подсчёт суммы, количества'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _openCalculator,
                ),
              ),
              const SizedBox(height: 12),
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  leading: const Icon(Icons.qr_code),
                  title: const Text('Штрих-коды'),
                  subtitle: const Text('Генератор и сканер'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _openBarcode,
                ),
              ),
              const SizedBox(height: 24),
              Center(child: Text('Учёт товаров v2.0', style: TextStyle(color: theme.colorScheme.outline, fontSize: 12))),
            ],
          ),
    );
  }
}

class _OrgEditScreen extends StatefulWidget {
  final AppSettings settings;
  const _OrgEditScreen({required this.settings});
  @override
  State<_OrgEditScreen> createState() => _OrgEditScreenState();
}

class _OrgEditScreenState extends State<_OrgEditScreen> {
  late final _nameCtrl = TextEditingController(text: widget.settings.orgName);
  late final _addressCtrl = TextEditingController(text: widget.settings.orgAddress);
  late final _phoneCtrl = TextEditingController(text: widget.settings.orgPhone);
  late final _emailCtrl = TextEditingController(text: widget.settings.orgEmail);
  late final _taxIdCtrl = TextEditingController(text: widget.settings.orgTaxId);

  @override
  void dispose() {
    _nameCtrl.dispose(); _addressCtrl.dispose(); _phoneCtrl.dispose(); _emailCtrl.dispose(); _taxIdCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Организация')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        TextFormField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Название организации', border: OutlineInputBorder(), prefixIcon: Icon(Icons.business))),
        const SizedBox(height: 12),
        TextFormField(controller: _addressCtrl, decoration: const InputDecoration(labelText: 'Адрес', border: OutlineInputBorder(), prefixIcon: Icon(Icons.location_on))),
        const SizedBox(height: 12),
        TextFormField(controller: _phoneCtrl, decoration: const InputDecoration(labelText: 'Телефон', border: OutlineInputBorder(), prefixIcon: Icon(Icons.phone)), keyboardType: TextInputType.phone),
        const SizedBox(height: 12),
        TextFormField(controller: _emailCtrl, decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder(), prefixIcon: Icon(Icons.email)), keyboardType: TextInputType.emailAddress),
        const SizedBox(height: 12),
        TextFormField(controller: _taxIdCtrl, decoration: const InputDecoration(labelText: 'БИН/ИНН', border: OutlineInputBorder(), prefixIcon: Icon(Icons.numbers))),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: () => Navigator.pop(context, AppSettings(
            orgName: _nameCtrl.text, orgAddress: _addressCtrl.text, orgPhone: _phoneCtrl.text,
            orgEmail: _emailCtrl.text, orgTaxId: _taxIdCtrl.text,
            userName: widget.settings.userName, userRole: widget.settings.userRole,
            themeMode: widget.settings.themeMode, language: widget.settings.language,
          )),
          icon: const Icon(Icons.save), label: const Text('Сохранить')),
      ]),
    );
  }
}

class _UserEditScreen extends StatefulWidget {
  final AppSettings settings;
  const _UserEditScreen({required this.settings});
  @override
  State<_UserEditScreen> createState() => _UserEditScreenState();
}

class _UserEditScreenState extends State<_UserEditScreen> {
  late final _nameCtrl = TextEditingController(text: widget.settings.userName);
  late final _roleCtrl = TextEditingController(text: widget.settings.userRole);
  @override
  void dispose() { _nameCtrl.dispose(); _roleCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Пользователь')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        TextFormField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Имя', border: OutlineInputBorder(), prefixIcon: Icon(Icons.person))),
        const SizedBox(height: 12),
        TextFormField(controller: _roleCtrl, decoration: const InputDecoration(labelText: 'Должность', border: OutlineInputBorder(), prefixIcon: Icon(Icons.badge))),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: () => Navigator.pop(context, AppSettings(
            orgName: widget.settings.orgName, orgAddress: widget.settings.orgAddress,
            orgPhone: widget.settings.orgPhone, orgEmail: widget.settings.orgEmail,
            orgTaxId: widget.settings.orgTaxId, userName: _nameCtrl.text, userRole: _roleCtrl.text,
            themeMode: widget.settings.themeMode, language: widget.settings.language,
          )),
          icon: const Icon(Icons.save), label: const Text('Сохранить')),
      ]),
    );
  }
}
