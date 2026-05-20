import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../models/product.dart';
import '../models/movement.dart';
import '../utils/currency_helper.dart';
import 'add_product_screen.dart';
import 'purchase_screen.dart';
import 'sale_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;
  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final _db = DatabaseHelper();
  late Product _product;
  List<Movement> _movements = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _product = widget.product;
    _load();
  }

  Future<void> _load() async {
    final results = await Future.wait([_db.getProduct(_product.id!), _db.getMovements(_product.id!)]);
    setState(() {
      if (results[0] != null) _product = results[0] as Product;
      _movements = results[1] as List<Movement>;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fmt = DateFormat('dd.MM.yyyy HH:mm');
    final inStock = _product.quantity > 0;
    final lowStock = _product.quantity > 0 && _product.quantity <= 5;
    final stockColor = inStock ? (lowStock ? Colors.orange : Colors.green) : Colors.red;

    return Scaffold(
      appBar: AppBar(
        title: Text(_product.name),
        actions: [IconButton(icon: const Icon(Icons.edit), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AddProductScreen(product: _product))).then((r) { if (r == true) _load(); }))],
      ),
      body: _loading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(onRefresh: _load, child: ListView(padding: const EdgeInsets.all(16), children: [
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(children: [
                  Container(width: 72, height: 72,
                    decoration: BoxDecoration(color: inStock ? (lowStock ? Colors.orange.shade100 : Colors.green.shade100) : Colors.red.shade100, borderRadius: BorderRadius.circular(20)),
                    child: Icon(Icons.inventory_2, size: 40, color: stockColor)),
                  const SizedBox(height: 16),
                  Text(_product.name, style: theme.textTheme.headlineSmall),
                  const SizedBox(height: 4),
                  Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(color: theme.colorScheme.primaryContainer, borderRadius: BorderRadius.circular(20)),
                    child: Text(_product.category, style: TextStyle(color: theme.colorScheme.onPrimaryContainer))),
                  const Divider(height: 32),
                  _infoRow(Icons.inventory, 'Количество', '${NumberFormat('#,###').format(_product.quantity)} шт.', color: stockColor),
                  _infoRow(Icons.monetization_on, 'Цена', CurrencyUtil.formatPrice(_product.price)),
                  if (_product.description != null && _product.description!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Align(alignment: Alignment.centerLeft, child: Text('Описание', style: theme.textTheme.titleSmall)),
                    const SizedBox(height: 4),
                    Text(_product.description!, style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
                  ],
                  const SizedBox(height: 8),
                  _infoRow(Icons.calendar_today, 'Создан', fmt.format(DateTime.parse(_product.createdAt))),
                  _infoRow(Icons.update, 'Изменён', fmt.format(DateTime.parse(_product.updatedAt))),
                ]),
              ),
            ),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: FilledButton.icon(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PurchaseScreen(product: _product))).then((r) { if (r == true) _load(); }),
                style: FilledButton.styleFrom(backgroundColor: Colors.green.shade600, padding: const EdgeInsets.symmetric(vertical: 14)),
                icon: const Icon(Icons.add_circle), label: const Text('Закупка'),
              )),
              const SizedBox(width: 12),
              Expanded(child: FilledButton.icon(
                onPressed: _product.quantity > 0
                  ? () => Navigator.push(context, MaterialPageRoute(builder: (_) => SaleScreen(product: _product))).then((r) { if (r == true) _load(); }) : null,
                style: FilledButton.styleFrom(backgroundColor: Colors.orange.shade700, padding: const EdgeInsets.symmetric(vertical: 14)),
                icon: const Icon(Icons.remove_circle), label: const Text('Продажа'),
              )),
            ]),
            const SizedBox(height: 24),
            Text('История операций', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            if (_movements.isEmpty)
              Card(child: Padding(padding: const EdgeInsets.all(24), child: Center(child: Text('Нет операций', style: TextStyle(color: theme.colorScheme.outline)))))
            else
              ..._movements.map((m) {
                final date = DateTime.parse(m.date);
                final isPurchase = m.isPurchase;
                return Card(
                  margin: const EdgeInsets.only(bottom: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(children: [
                      Container(width: 40, height: 40,
                        decoration: BoxDecoration(color: isPurchase ? Colors.green.shade100 : Colors.orange.shade100, borderRadius: BorderRadius.circular(10)),
                        child: Icon(isPurchase ? Icons.add_shopping_cart : Icons.sell, color: isPurchase ? Colors.green.shade700 : Colors.orange.shade700, size: 20)),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(m.typeLabel, style: const TextStyle(fontWeight: FontWeight.w600)),
                        Text('${m.quantity} шт. × ${CurrencyUtil.formatPrice(m.unitPrice)} = ${CurrencyUtil.formatTotal(m.quantity, m.unitPrice)}',
                          style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurfaceVariant)),
                        if (m.counterparty != null)
                          Text('${isPurchase ? 'Поставщик' : 'Покупатель'}: ${m.counterparty}',
                            style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
                      ])),
                      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                        Text(fmt.format(date), style: TextStyle(fontSize: 11, color: theme.colorScheme.outline)),
                        if (m.note != null) Text(m.note!, style: TextStyle(fontSize: 11, color: theme.colorScheme.outline)),
                      ]),
                    ]),
                  ),
                );
              }),
            const SizedBox(height: 32),
          ])),
    );
  }

  Widget _infoRow(IconData icon, String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8), Text(label, style: const TextStyle(color: Colors.grey)), const Spacer(),
        if (color != null) Text(value, style: TextStyle(fontWeight: FontWeight.w600, color: color))
        else Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ]),
    );
  }
}
