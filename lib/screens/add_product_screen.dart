import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/product.dart';

class AddProductScreen extends StatefulWidget {
  final Product? product;
  const AddProductScreen({super.key, this.product});
  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _barcodeCtrl = TextEditingController();
  final _db = DatabaseHelper();
  bool _saving = false;
  String _category = 'Общее';
  List<String> _categories = ['Общее'];
  String _newCategory = '';

  @override
  void initState() {
    super.initState();
    _load();
    if (widget.product != null) {
      _nameCtrl.text = widget.product!.name;
      _category = widget.product!.category;
      _qtyCtrl.text = widget.product!.quantity.toString();
      _priceCtrl.text = widget.product!.price.toString();
      _descCtrl.text = widget.product!.description ?? '';
      _barcodeCtrl.text = widget.product!.barcode ?? '';
    }
  }

  Future<void> _load() async {
    final cats = await _db.getCategories();
    if (!cats.contains('Общее')) cats.insert(0, 'Общее');
    setState(() => _categories = cats);
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _qtyCtrl.dispose(); _priceCtrl.dispose(); _descCtrl.dispose(); _barcodeCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_newCategory.isNotEmpty) {
      await _db.saveCategory(_newCategory);
      _category = _newCategory;
    }
    setState(() => _saving = true);
    final product = Product(
      id: widget.product?.id,
      name: _nameCtrl.text.trim(),
      category: _category,
      quantity: int.tryParse(_qtyCtrl.text) ?? 0,
      price: double.tryParse(_priceCtrl.text.replaceAll(',', '.')) ?? 0.0,
      description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      barcode: _barcodeCtrl.text.trim().isEmpty ? null : _barcodeCtrl.text.trim(),
    );
    if (widget.product != null) { await _db.updateProduct(product); }
    else { await _db.insertProduct(product); }
    setState(() => _saving = false);
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.product != null;
    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Редактировать товар' : 'Добавить товар')),
      body: Form(
        key: _formKey,
        child: ListView(padding: const EdgeInsets.all(16), children: [
          TextFormField(
            controller: _nameCtrl,
            decoration: const InputDecoration(labelText: 'Название *', border: OutlineInputBorder()),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Введите название' : null,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _categories.contains(_category) ? _category : 'Общее',
            decoration: const InputDecoration(labelText: 'Категория', border: OutlineInputBorder()),
            items: [
              ..._categories.map((c) => DropdownMenuItem(value: c, child: Text(c))),
              const DropdownMenuItem(value: '__new__', child: Text('+ Новая категория')),
            ],
            onChanged: (v) {
              if (v == '__new__') {
                showDialog(context: context, builder: (ctx) => AlertDialog(
                  title: const Text('Новая категория'),
                  content: TextField(onChanged: (v) => _newCategory = v, decoration: const InputDecoration(labelText: 'Название', border: OutlineInputBorder())),
                  actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Добавить'))],
                )).then((_) { _load(); });
              } else {
                setState(() => _category = v!);
              }
            },
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: TextFormField(
              controller: _qtyCtrl,
              decoration: const InputDecoration(labelText: 'Количество', border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
              validator: (v) { if (v != null && v.isNotEmpty && int.tryParse(v) == null) return 'Число'; return null; },
            )),
            const SizedBox(width: 12),
            Expanded(child: TextFormField(
              controller: _priceCtrl,
              decoration: const InputDecoration(labelText: 'Цена (руб)', border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
            )),
          ]),
          const SizedBox(height: 12),
          TextFormField(controller: _descCtrl, decoration: const InputDecoration(labelText: 'Описание', border: OutlineInputBorder()), maxLines: 3),
          const SizedBox(height: 12),
          TextFormField(
            controller: _barcodeCtrl,
            decoration: InputDecoration(
              labelText: 'Штрих-код',
              border: OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () {
                  _barcodeCtrl.text = DateTime.now().millisecondsSinceEpoch.toString().substring(5);
                },
              ),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.save),
            label: Text(isEdit ? 'Сохранить' : 'Добавить'),
          ),
        ]),
      ),
    );
  }
}
