import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/product.dart';
import '../models/movement.dart';

class SaleScreen extends StatefulWidget {
  final Product product;
  const SaleScreen({super.key, required this.product});

  @override
  State<SaleScreen> createState() => _SaleScreenState();
}

class _SaleScreenState extends State<SaleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _qtyCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _buyerCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  final _db = DatabaseHelper();
  bool _saving = false;
  List<String> _buyers = [];

  @override
  void initState() {
    super.initState();
    _priceCtrl.text = widget.product.price.toString();
    _db.getAllBuyers().then((b) { if (mounted) setState(() => _buyers = b); });
  }

  @override
  void dispose() {
    _qtyCtrl.dispose(); _priceCtrl.dispose(); _buyerCtrl.dispose(); _noteCtrl.dispose();
    super.dispose();
  }

  void _showBuyerPicker() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Column(mainAxisSize: MainAxisSize.min, children: [
        Padding(padding: const EdgeInsets.all(16), child: Text('Выберите покупателя', style: Theme.of(context).textTheme.titleMedium)),
        if (_buyers.isEmpty)
          const Padding(padding: EdgeInsets.all(16), child: Text('Нет сохранённых покупателей'))
        else
          ..._buyers.map((s) => ListTile(
            leading: const Icon(Icons.person),
            title: Text(s),
            onTap: () { _buyerCtrl.text = s; Navigator.pop(ctx); },
          )),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.add_circle_outline),
          title: const Text('Новый покупатель'),
          onTap: () { Navigator.pop(ctx); _showNewBuyerDialog(); },
        ),
        const SizedBox(height: 8),
      ]),
    );
  }

  void _showNewBuyerDialog() {
    showDialog<String>(context: context, builder: (_) => const _BuyerDialog()).then((name) {
      if (name != null && name.isNotEmpty) {
        _buyerCtrl.text = name;
        if (!_buyers.contains(name)) _buyers.add(name);
      }
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await _db.addMovement(Movement(
        productId: widget.product.id!,
        type: 'sale',
        quantity: int.parse(_qtyCtrl.text),
        unitPrice: double.tryParse(_priceCtrl.text.replaceAll(',', '.')) ?? 0,
        counterparty: _buyerCtrl.text.trim().isEmpty ? null : _buyerCtrl.text.trim(),
        note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
      ));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Продажа оформлена: -${_qtyCtrl.text} шт.'), backgroundColor: Colors.orange.shade700),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка: $e'), backgroundColor: Colors.red));
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Продажа товара')),
      body: Form(
        key: _formKey,
        child: ListView(padding: const EdgeInsets.all(16), children: [
          Card(
            color: Colors.orange.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(children: [
                Icon(Icons.shopping_cart, color: Colors.orange.shade800),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(widget.product.name, style: theme.textTheme.titleMedium),
                  Text('Доступно: ${widget.product.quantity} шт.', style: TextStyle(color: Colors.orange.shade800)),
                ])),
              ]),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _qtyCtrl,
            decoration: const InputDecoration(labelText: 'Количество *', border: OutlineInputBorder(), suffixText: 'шт.', prefixIcon: Icon(Icons.numbers)),
            keyboardType: TextInputType.number,
            validator: (v) {
              if (v == null || v.isEmpty) return 'Введите количество';
              final n = int.tryParse(v); if (n == null || n <= 0) return 'Введите положительное число';
              if (n > widget.product.quantity) return 'Недостаточно товара (доступно: ${widget.product.quantity})';
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _priceCtrl,
            decoration: const InputDecoration(labelText: 'Цена за единицу (₽)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.monetization_on_outlined)),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: TextFormField(
              controller: _buyerCtrl,
              decoration: const InputDecoration(labelText: 'Покупатель', border: OutlineInputBorder(), prefixIcon: Icon(Icons.person), hintText: 'Имя или название компании'),
            )),
            const SizedBox(width: 8),
            IconButton(icon: const Icon(Icons.list), tooltip: 'Выбрать из списка', onPressed: _showBuyerPicker),
          ]),
          const SizedBox(height: 12),
          TextFormField(controller: _noteCtrl, decoration: const InputDecoration(labelText: 'Примечание', border: OutlineInputBorder(), prefixIcon: Icon(Icons.notes)), maxLines: 2),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _saving ? null : _save,
            style: FilledButton.styleFrom(backgroundColor: Colors.orange.shade700, padding: const EdgeInsets.symmetric(vertical: 14)),
            icon: _saving
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.sell),
            label: const Text('Оформить продажу', style: TextStyle(fontSize: 16)),
          ),
        ]),
      ),
    );
  }
}

class _BuyerDialog extends StatefulWidget {
  const _BuyerDialog();
  @override
  State<_BuyerDialog> createState() => _BuyerDialogState();
}

class _BuyerDialogState extends State<_BuyerDialog> {
  final _ctrl = TextEditingController();
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Новый покупатель'),
      content: TextField(controller: _ctrl, autofocus: true, decoration: const InputDecoration(labelText: 'Имя / Название', border: OutlineInputBorder())),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
        FilledButton(onPressed: () => Navigator.pop(context, _ctrl.text.trim()), child: const Text('Добавить')),
      ],
    );
  }
}
