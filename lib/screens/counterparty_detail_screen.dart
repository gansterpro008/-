import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../utils/currency_helper.dart';

class CounterpartyDetailScreen extends StatefulWidget {
  final String name;
  final bool isSupplier;
  const CounterpartyDetailScreen({super.key, required this.name, required this.isSupplier});

  @override
  State<CounterpartyDetailScreen> createState() => _CounterpartyDetailScreenState();
}

class _CounterpartyDetailScreenState extends State<CounterpartyDetailScreen> {
  final _db = DatabaseHelper();
  List<Map<String, dynamic>> _movements = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final movements = await _db.getCounterpartyMovements(widget.name, widget.isSupplier ? 'purchase' : 'sale');
    setState(() { _movements = movements; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final numFmt = NumberFormat('#,###');
    final dateFmt = DateFormat('dd.MM.yyyy HH:mm');

    final totalQty = _movements.fold<int>(0, (s, m) => s + (m['quantity'] as int));
    final totalSum = _movements.fold<double>(0, (s, m) => s + (m['quantity'] as int) * ((m['unitPrice'] as num?)?.toDouble() ?? 0));

    return Scaffold(
      appBar: AppBar(title: Text(widget.name)),
      body: _loading ? const Center(child: CircularProgressIndicator())
        : Column(children: [
            Card(
              margin: const EdgeInsets.all(12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(children: [
                  CircleAvatar(backgroundColor: widget.isSupplier ? Colors.green.shade100 : Colors.blue.shade100,
                    child: Icon(widget.isSupplier ? Icons.business : Icons.person, color: widget.isSupplier ? Colors.green.shade700 : Colors.blue.shade700)),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(widget.name, style: theme.textTheme.titleMedium),
                    Text(widget.isSupplier ? 'Поставщик' : 'Покупатель', style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
                  ])),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text('${numFmt.format(totalQty)} шт.', style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(CurrencyUtil.formatPrice(totalSum), style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
                  ]),
                ]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(children: [Text('История операций (${_movements.length})', style: theme.textTheme.titleSmall)]),
            ),
            Expanded(
              child: _movements.isEmpty
                ? Center(child: Text('Нет операций', style: TextStyle(color: theme.colorScheme.outline)))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    itemCount: _movements.length,
                    itemBuilder: (ctx, i) {
                      final m = _movements[i];
                      final qty = m['quantity'] as int;
                      final price = (m['unitPrice'] as num?)?.toDouble() ?? 0;
                      final date = DateTime.parse(m['date'] as String);
                      final productName = m['productName'] as String? ?? 'Удалён';
                      return Card(
                        margin: const EdgeInsets.only(bottom: 6),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(children: [
                            Container(width: 40, height: 40,
                              decoration: BoxDecoration(color: (widget.isSupplier ? Colors.green : Colors.blue).shade100, borderRadius: BorderRadius.circular(10)),
                              child: Icon(widget.isSupplier ? Icons.add_shopping_cart : Icons.sell,
                                color: (widget.isSupplier ? Colors.green : Colors.blue).shade700, size: 20)),
                            const SizedBox(width: 12),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(productName, style: const TextStyle(fontWeight: FontWeight.w600)),
                              Text('$qty шт. × ${CurrencyUtil.formatPrice(price)} = ${CurrencyUtil.formatPrice(qty * price)}',
                                style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurfaceVariant)),
                            ])),
                            Text(dateFmt.format(date), style: TextStyle(fontSize: 11, color: theme.colorScheme.outline)),
                          ]),
                        ),
                      );
                    },
                  ),
            ),
          ]),
    );
  }
}
