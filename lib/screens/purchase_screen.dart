import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/product.dart';
import '../models/movement.dart';

class PurchaseScreen extends StatefulWidget {
  final Product? product;
  const PurchaseScreen({super.key, this.product});

  @override
  State<PurchaseScreen> createState() => _PurchaseScreenState();
}

enum _Step { category, product, form }

class _PurchaseScreenState extends State<PurchaseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _qtyCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _supplierCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  final _newNameCtrl = TextEditingController();
  final _newCategoryCtrl = TextEditingController();
  final _db = DatabaseHelper();
  bool _saving = false;
  bool _addingNew = false;
  List<String> _suppliers = [];

  _Step _step = _Step.category;
  List<String> _categories = [];
  List<Product> _products = [];
  Product? _selected;
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      _selected = widget.product;
      _step = _Step.form;
    }
    _load();
  }

  Future<void> _load() async {
    final results = await Future.wait([_db.getCategories(), _db.getProducts(), _db.getAllSuppliers()]);
    setState(() {
      _categories = results[0] as List<String>;
      _products = results[1] as List<Product>;
      _suppliers = results[2] as List<String>;
    });
  }

  List<Product> get _filteredProducts {
    if (_selectedCategory == null) return [];
    return _products.where((p) => p.category == _selectedCategory).toList();
  }

  void _selectCategory(String cat) {
    setState(() { _selectedCategory = cat; _step = _Step.product; });
  }

  void _selectProduct(Product p) {
    setState(() { _selected = p; _step = _Step.form; });
  }

  void _backToCategories() {
    setState(() { _selectedCategory = null; _step = _Step.category; _addingNew = false; });
  }

  void _backToProducts() {
    setState(() { _selected = null; _step = _Step.product; _addingNew = false; });
  }

  Future<void> _saveNewProductAndPurchase() async {
    if (_newNameCtrl.text.trim().isEmpty) return;
    final cat = _newCategoryCtrl.text.trim().isEmpty ? (_selectedCategory ?? 'Общее') : _newCategoryCtrl.text.trim();
    final product = Product(name: _newNameCtrl.text.trim(), category: cat, quantity: 0, price: 0);
    final id = await _db.insertProduct(product);
    _selected = product.copyWith(id: id);
    _addNewCategoryToFilter(cat);
    setState(() => _addingNew = false);
  }

  void _showSupplierPicker() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Column(mainAxisSize: MainAxisSize.min, children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text('Выберите поставщика', style: Theme.of(context).textTheme.titleMedium),
        ),
        if (_suppliers.isEmpty)
          const Padding(padding: EdgeInsets.all(16), child: Text('Нет сохранённых поставщиков'))
        else
          ..._suppliers.map((s) => ListTile(
            leading: const Icon(Icons.business),
            title: Text(s),
            onTap: () { _supplierCtrl.text = s; Navigator.pop(ctx); },
          )),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.add_circle_outline),
          title: const Text('Новый поставщик'),
          onTap: () {
            Navigator.pop(ctx);
            _showNewSupplierDialog();
          },
        ),
        const SizedBox(height: 8),
      ]),
    );
  }

  void _showNewSupplierDialog() {
    showDialog<String>(
      context: context,
      builder: (_) => const _SupplierDialog(),
    ).then((name) {
      if (name != null && name.isNotEmpty) {
        _supplierCtrl.text = name;
        if (!_suppliers.contains(name)) _suppliers.add(name);
      }
    });
  }

  void _addNewCategoryToFilter(String cat) {
    if (!_categories.contains(cat)) _categories.add(cat);
  }

  @override
  void dispose() {
    _qtyCtrl.dispose(); _priceCtrl.dispose(); _supplierCtrl.dispose();
    _noteCtrl.dispose(); _newNameCtrl.dispose(); _newCategoryCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selected == null) return;
    setState(() => _saving = true);
    try {
      await _db.addMovement(Movement(
        productId: _selected!.id!,
        type: 'purchase',
        quantity: int.parse(_qtyCtrl.text),
        unitPrice: double.tryParse(_priceCtrl.text.replaceAll(',', '.')) ?? 0,
        counterparty: _supplierCtrl.text.trim().isEmpty ? null : _supplierCtrl.text.trim(),
        note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
      ));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Закупка оформлена: +${_qtyCtrl.text} шт.'), backgroundColor: Colors.green.shade600),
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
    return Scaffold(
      appBar: AppBar(title: Text(_appBarTitle)),
      body: _buildBody(),
    );
  }

  String get _appBarTitle {
    switch (_step) {
      case _Step.category: return 'Закупка — категория';
      case _Step.product: return 'Закупка — товар';
      case _Step.form: return _selected != null ? 'Закупка: ${_selected!.name}' : 'Закупка товара';
    }
  }

  Widget _buildBody() {
    switch (_step) {
      case _Step.category: return _buildCategoryStep();
      case _Step.product: return _buildProductStep();
      case _Step.form: return _buildFormStep();
    }
  }

  Widget _buildCategoryStep() {
    final theme = Theme.of(context);
    return _categories.isEmpty
      ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.folder_open, size: 64, color: theme.colorScheme.outline),
          const SizedBox(height: 16),
          Text('Нет категорий. Сначала добавьте товар.', style: TextStyle(color: theme.colorScheme.outline)),
        ]))
      : ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text('Выберите категорию', style: theme.textTheme.titleMedium),
            ),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: _categories.map((cat) {
                final count = _products.where((p) => p.category == cat).length;
                return SizedBox(
                  width: (MediaQuery.of(context).size.width - 40) / 2,
                  child: Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => _selectCategory(cat),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(children: [
                          Icon(Icons.folder, size: 36, color: theme.colorScheme.primary),
                          const SizedBox(height: 8),
                          Text(cat, style: const TextStyle(fontWeight: FontWeight.w600), textAlign: TextAlign.center),
                          Text('$count товаров', style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
                        ]),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        );
  }

  Widget _buildProductStep() {
    final theme = Theme.of(context);
    final filtered = _filteredProducts;
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: Row(children: [
          Text('Категория: $_selectedCategory', style: theme.textTheme.titleSmall),
          const Spacer(),
          TextButton(onPressed: _backToCategories, child: const Text('Изменить')),
        ]),
      ),
      if (_addingNew)
        Padding(
          padding: const EdgeInsets.all(16),
          child: Card(
            color: Colors.green.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(children: [
                Text('Новый товар', style: theme.textTheme.titleSmall),
                const SizedBox(height: 12),
                TextField(
                  controller: _newNameCtrl,
                  decoration: const InputDecoration(labelText: 'Название *', border: OutlineInputBorder(), isDense: true),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _newCategoryCtrl,
                  decoration: InputDecoration(labelText: 'Категория', border: const OutlineInputBorder(), isDense: true,
                    hintText: _selectedCategory ?? 'Общее'),
                ),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: OutlinedButton(onPressed: () => setState(() => _addingNew = false), child: const Text('Отмена'))),
                  const SizedBox(width: 12),
                  Expanded(child: FilledButton(onPressed: () async {
                    await _saveNewProductAndPurchase();
                    // reload products and find the new one
                    await _load();
                    final newProduct = _products.firstWhere(
                      (p) => p.name == _newNameCtrl.text.trim() && p.category == (_newCategoryCtrl.text.trim().isEmpty ? (_selectedCategory ?? 'Общее') : _newCategoryCtrl.text.trim()),
                      orElse: () => _products.first,
                    );
                    _selectProduct(newProduct);
                  }, child: const Text('Добавить'))),
                ]),
              ]),
            ),
          ),
        )
      else
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: FilledButton.tonalIcon(
            onPressed: () {
              _newNameCtrl.clear();
              _newCategoryCtrl.clear();
              setState(() => _addingNew = true);
            },
            icon: const Icon(Icons.add), label: const Text('Добавить новый товар'),
          ),
        ),
      Expanded(
        child: filtered.isEmpty
          ? Center(child: Text('Нет товаров в этой категории', style: TextStyle(color: theme.colorScheme.outline)))
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: filtered.length,
              itemBuilder: (ctx, i) {
                final p = filtered[i];
                return Card(
                  margin: const EdgeInsets.only(bottom: 4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: p.quantity > 0 ? Colors.green.shade100 : Colors.grey.shade100,
                      child: Icon(Icons.inventory_2, color: p.quantity > 0 ? Colors.green.shade700 : Colors.grey, size: 20),
                    ),
                    title: Text(p.name),
                    subtitle: Text('Остаток: ${p.quantity} шт.', style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _selectProduct(p),
                  ),
                );
              },
            ),
      ),
    ]);
  }

  Widget _buildFormStep() {
    final theme = Theme.of(context);
    return Form(
      key: _formKey,
      child: ListView(padding: const EdgeInsets.all(16), children: [
        Card(
          color: Colors.green.shade50,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              Icon(Icons.check_circle, color: Colors.green.shade700),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(_selected!.name, style: theme.textTheme.titleMedium),
                Text('${_selected!.category} | Остаток: ${_selected!.quantity} шт.', style: TextStyle(color: Colors.green.shade800, fontSize: 13)),
              ])),
              TextButton.icon(onPressed: _backToProducts, icon: const Icon(Icons.swap_horiz, size: 18), label: const Text('Изменить')),
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
            controller: _supplierCtrl,
            decoration: const InputDecoration(labelText: 'Поставщик', border: OutlineInputBorder(), prefixIcon: Icon(Icons.business), hintText: 'Название компании'),
          )),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.list),
            tooltip: 'Выбрать из списка',
            onPressed: _showSupplierPicker,
          ),
        ]),
        const SizedBox(height: 12),
        TextFormField(controller: _noteCtrl, decoration: const InputDecoration(labelText: 'Примечание', border: OutlineInputBorder(), prefixIcon: Icon(Icons.notes)), maxLines: 2),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: _saving ? null : _save,
          style: FilledButton.styleFrom(backgroundColor: Colors.green.shade600, padding: const EdgeInsets.symmetric(vertical: 14)),
          icon: _saving
            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Icon(Icons.add_shopping_cart),
          label: const Text('Оформить закупку', style: TextStyle(fontSize: 16)),
        ),
      ]),
    );
  }
}

class _SupplierDialog extends StatefulWidget {
  const _SupplierDialog();
  @override
  State<_SupplierDialog> createState() => _SupplierDialogState();
}

class _SupplierDialogState extends State<_SupplierDialog> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Новый поставщик'),
      content: TextField(
        controller: _ctrl,
        autofocus: true,
        decoration: const InputDecoration(labelText: 'Название', border: OutlineInputBorder()),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
        FilledButton(onPressed: () => Navigator.pop(context, _ctrl.text.trim()), child: const Text('Добавить')),
      ],
    );
  }
}
