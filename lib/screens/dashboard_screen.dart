import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../utils/currency_helper.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _db = DatabaseHelper();
  Map<String, dynamic> _stats = {};
  List<Map<String, dynamic>> _recentMovements = [];
  List<Map<String, dynamic>> _categoryStats = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final results = await Future.wait([
      _db.getStats(),
      _db.getAllMovementsWithProduct(limit: 20),
      _db.getCategoryStats(),
    ]);
    setState(() {
      _stats = results[0] as Map<String, dynamic>;
      _recentMovements = results[1] as List<Map<String, dynamic>>;
      _categoryStats = results[2] as List<Map<String, dynamic>>;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fmt = DateFormat('dd.MM.yy HH:mm');
    final numFmt = NumberFormat('#,###');

    return Scaffold(
      appBar: AppBar(title: const Text('Статистика'), centerTitle: true),
      body: _loading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(onRefresh: _load, child: ListView(padding: const EdgeInsets.all(12), children: [
            Row(children: [
              _StatCard(icon: Icons.inventory_2, label: 'Товаров', value: '${_stats['productCount']}', color: Colors.blue, flex: 1),
              const SizedBox(width: 8),
              _StatCard(icon: Icons.category, label: 'Общий остаток', value: numFmt.format(_stats['totalStock']), color: Colors.green, flex: 1),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              _StatCard(icon: Icons.monetization_on, label: 'Общая стоимость',
                value: CurrencyUtil.formatPrice((_stats['totalValue'] as num).toDouble()), color: Colors.indigo, flex: 1),
              const SizedBox(width: 8),
              _StatCard(icon: Icons.warning_amber, label: 'Мало (≤5)', value: '${_stats['lowStock']}', color: Colors.orange, flex: 1),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              _StatCard(icon: Icons.add_shopping_cart, label: 'Закупок на сумму',
                value: CurrencyUtil.formatPrice((_stats['purchaseTotal'] as num).toDouble()), color: Colors.green.shade600, flex: 1),
              const SizedBox(width: 8),
              _StatCard(icon: Icons.sell, label: 'Продаж на сумму',
                value: CurrencyUtil.formatPrice((_stats['saleTotal'] as num).toDouble()), color: Colors.orange.shade700, flex: 1),
            ]),
            if ((_stats['outOfStock'] as int) > 0)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Card(color: Colors.red.shade50, child: ListTile(
                  leading: Icon(Icons.error_outline, color: Colors.red.shade700),
                  title: Text('${_stats['outOfStock']} товаров нет в наличии'),
                  subtitle: const Text('Требуется пополнение'),
                )),
              ),
            if (_categoryStats.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text('По категориям', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              ..._categoryStats.map((c) => Card(
                margin: const EdgeInsets.only(bottom: 4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(children: [
                    Container(width: 40, height: 40,
                      decoration: BoxDecoration(color: theme.colorScheme.primaryContainer, borderRadius: BorderRadius.circular(10)),
                      child: Icon(Icons.folder, color: theme.colorScheme.onPrimaryContainer, size: 20)),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(c['category'] as String, style: const TextStyle(fontWeight: FontWeight.w600)),
                      Text('${c['productCount']} товаров | ${numFmt.format(c['totalQuantity'])} шт.',
                        style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
                    ])),
                    Text(CurrencyUtil.formatPrice((c['totalValue'] as num).toDouble()),
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  ]),
                ),
              )),
            ],
            const SizedBox(height: 16),
            Text('Последние операции', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            if (_recentMovements.isEmpty)
              Card(child: Padding(padding: const EdgeInsets.all(24), child: Center(child: Text('Нет операций', style: TextStyle(color: theme.colorScheme.outline)))))
            else
              ..._recentMovements.map((item) {
                final type = item['type'] as String;
                final isPurchase = type == 'purchase';
                final qty = item['quantity'] as int;
                final date = DateTime.parse(item['date'] as String);
                final counterparty = item['counterparty'] as String?;
                final productName = item['productName'] as String? ?? 'Удалён';
                final unitPrice = (item['unitPrice'] as num?)?.toDouble() ?? 0;
                return Card(
                  margin: const EdgeInsets.only(bottom: 4),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isPurchase ? Colors.green.shade100 : Colors.orange.shade100,
                      child: Icon(isPurchase ? Icons.add_shopping_cart : Icons.sell,
                        color: isPurchase ? Colors.green.shade700 : Colors.orange.shade700, size: 20),
                    ),
                    title: Text(productName),
                    subtitle: Text(
                      '${isPurchase ? 'Закупка' : 'Продажа'} | $qty шт. | ${CurrencyUtil.formatPrice(qty * unitPrice)}${counterparty != null ? ' | $counterparty' : ''}',
                      style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                    ),
                    trailing: Text(fmt.format(date), style: TextStyle(fontSize: 11, color: theme.colorScheme.outline)),
                    dense: true,
                  ),
                );
              }),
            const SizedBox(height: 32),
          ])),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon; final String label; final String value; final Color color; final int flex;
  const _StatCard({required this.icon, required this.label, required this.value, required this.color, required this.flex});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(width: 36, height: 36, decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 20)),
            const SizedBox(height: 10),
            Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
            Text(label, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ]),
        ),
      ),
    );
  }
}
