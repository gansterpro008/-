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
  final _categoryCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _db = DatabaseHelper();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      _nameCtrl.text = widget.product!.name;
      _categoryCtrl.text = widget.product!.category;
      _qtyCtrl.text = widget.product!.quantity.toString();
      _priceCtrl.text = widget.product!.price.toString();
      _descCtrl.text = widget.product!.description ?? '';
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _categoryCtrl.dispose();
    _qtyCtrl.dispose(); _priceCtrl.dispose(); _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final product = Product(
      id: widget.product?.id,
      name: _nameCtrl.text.trim(),
      category: _categoryCtrl.text.trim().isEmpty ? 'Общее' : _categoryCtrl.text.trim(),
      quantity: int.tryParse(_qtyCtrl.text) ?? 0,
      price: double.tryParse(_priceCtrl.text.replaceAll(',', '.')) ?? 0.0,
      description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
    );

    if (widget.product != null) {
      await _db.updateProduct(product);
    } else {
      await _db.insertProduct(product);
    }

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
          TextFormField(controller: _categoryCtrl, decoration: const InputDecoration(labelText: 'Категория', border: OutlineInputBorder(), hintText: 'Общее')),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: TextFormField(
              controller: _qtyCtrl,
              decoration: const InputDecoration(labelText: 'Количество', border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
              validator: (v) {
                if (v != null && v.isNotEmpty && int.tryParse(v) == null) return 'Число';
                return null;
              },
            )),
            const SizedBox(width: 12),
            Expanded(child: TextFormField(
              controller: _priceCtrl,
              decoration: const InputDecoration(labelText: 'Цена (₽)', border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
            )),
          ]),
          const SizedBox(height: 12),
          TextFormField(controller: _descCtrl, decoration: const InputDecoration(labelText: 'Описание', border: OutlineInputBorder()), maxLines: 3),
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
