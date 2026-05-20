import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/product.dart';
import '../utils/currency_helper.dart';
import 'add_product_screen.dart';
import 'product_detail_screen.dart';
import 'purchase_screen.dart';
import 'sale_screen.dart';
import 'counterparties_screen.dart';
import 'dashboard_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback onThemeChanged;
  const HomeScreen({super.key, required this.onThemeChanged});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentTab = 0;
  late final _pages = [
    const _ProductsTab(),
    const CounterpartiesScreen(),
    const DashboardScreen(),
    ProfileScreen(onThemeChanged: widget.onThemeChanged),
  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentTab, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentTab,
        onDestinationSelected: (i) => setState(() => _currentTab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.inventory_2_outlined), selectedIcon: Icon(Icons.inventory_2), label: 'Товары'),
          NavigationDestination(icon: Icon(Icons.people_outline), selectedIcon: Icon(Icons.people), label: 'Контрагенты'),
          NavigationDestination(icon: Icon(Icons.bar_chart_outlined), selectedIcon: Icon(Icons.bar_chart), label: 'Статистика'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Профиль'),
        ],
      ),
    );
  }
}

class _ProductsTab extends StatefulWidget {
  const _ProductsTab();
  @override
  State<_ProductsTab> createState() => _ProductsTabState();
}

class _ProductsTabState extends State<_ProductsTab> with AutomaticKeepAliveClientMixin {
  final _db = DatabaseHelper();
  List<Product> _products = [];
  List<String> _categories = [];
  String? _selectedCategory;
  final _searchController = TextEditingController();
  bool _isLoading = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final results = await Future.wait([_db.getProducts(), _db.getCategories()]);
    setState(() {
      _products = results[0] as List<Product>;
      _categories = results[1] as List<String>;
      _isLoading = false;
    });
  }

  List<Product> get _filtered {
    var list = _products;
    if (_selectedCategory != null) list = list.where((p) => p.category == _selectedCategory).toList();
    final q = _searchController.text.trim().toLowerCase();
    if (q.isNotEmpty) list = list.where((p) => p.name.toLowerCase().contains(q)).toList();
    return list;
  }

  List<String> get _matchingCategories {
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) return [];
    return _categories.where((c) => c.toLowerCase().contains(q)).toList();
  }

  bool get _isSearchingCategory {
    final q = _searchController.text.trim().toLowerCase();
    return q.isNotEmpty && _matchingCategories.isNotEmpty;
  }

  @override
  void dispose() { _searchController.dispose(); super.dispose(); }

  Future<void> _deleteProduct(Product product) async {
    final confirm = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Удалить товар'),
      content: Text('Удалить "${product.name}"? Все движения также будут удалены.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Отмена')),
        TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Удалить', style: TextStyle(color: Colors.red))),
      ],
    ));
    if (confirm == true) { await _db.deleteProduct(product.id!); _load(); }
  }

  Future<void> _openPurchase() async {
    final r = await Navigator.push(context, MaterialPageRoute(builder: (_) => const PurchaseScreen()));
    if (r == true) _load();
  }

  Future<void> _addCategory() async {
    final name = await showDialog<String>(context: context, builder: (_) => const _AddCategoryDialog());
    if (name != null && name.isNotEmpty) {
      await _db.saveCategory(name);
      _load();
    }
  }

  Future<void> _deleteCategory(String category) async {
    final confirm = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Удалить категорию'),
      content: Text('Удалить категорию "$category"? Все товары этой категории будут перемещены в "Общее".'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Отмена')),
        TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Удалить', style: TextStyle(color: Colors.red))),
      ],
    ));
    if (confirm == true) {
      await _db.deleteSavedCategory(category);
      if (_selectedCategory == category) _selectedCategory = null;
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final filtered = _filtered;

    return Scaffold(
      appBar: AppBar(title: const Text('Склад'), centerTitle: true),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Поиск по названию или категории',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(icon: const Icon(Icons.clear), onPressed: () { _searchController.clear(); _load(); }) : null,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              filled: true, fillColor: theme.colorScheme.surfaceContainerHighest,
              contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),
        if (_categories.isNotEmpty)
          SizedBox(
            height: 44,
            child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), children: [
              _CategoryChip(label: 'Все', selected: _selectedCategory == null, onTap: () => setState(() => _selectedCategory = null)),
              ..._categories.map((c) => _CategoryChip(label: c, selected: _selectedCategory == c,
                onTap: () => setState(() => _selectedCategory == c ? _selectedCategory = null : _selectedCategory = c),
                onLongPress: () => _deleteCategory(c))),
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: ActionChip(
                  avatar: const Icon(Icons.add, size: 18),
                  label: const Text('Категория'),
                  onPressed: _addCategory,
                ),
              ),
            ]),
          ),
        Expanded(
          child: _isLoading ? const Center(child: CircularProgressIndicator())
            : _isSearchingCategory ? _buildCategorySearchResults(theme)
            : filtered.isEmpty ? _emptyState(theme)
            : RefreshIndicator(onRefresh: _load, child: ListView.builder(
                padding: const EdgeInsets.only(bottom: 80),
                itemCount: filtered.length,
                itemBuilder: (ctx, i) {
                  final canSell = filtered[i].quantity > 0;
                  return _ProductCard(
                    product: filtered[i],
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailScreen(product: filtered[i]))).then((_) => _load()),
                    onEdit: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AddProductScreen(product: filtered[i]))).then((_) => _load()),
                    onDelete: () => _deleteProduct(filtered[i]),
                    onPurchase: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PurchaseScreen(product: filtered[i]))).then((_) => _load()),
                    onSale: canSell ? () => Navigator.push(context, MaterialPageRoute(builder: (_) => SaleScreen(product: filtered[i]))).then((_) => _load()) : null,
                  );
                },
              )),
        ),
      ]),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            heroTag: 'fab_purchase',
            onPressed: _openPurchase,
            tooltip: 'Закупка',
            backgroundColor: Colors.green.shade600,
            foregroundColor: Colors.white,
            child: const Icon(Icons.add_shopping_cart),
          ),
          const SizedBox(height: 8),
          FloatingActionButton.small(
            heroTag: 'fab_product',
            onPressed: () async { final r = await Navigator.push(context, MaterialPageRoute(builder: (_) => const AddProductScreen())); if (r == true) _load(); },
            tooltip: 'Добавить товар',
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }

  Widget _emptyState(ThemeData theme) {
    final q = _searchController.text.trim();
    return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.inventory_2_outlined, size: 80, color: theme.colorScheme.outline),
      const SizedBox(height: 16),
      Text(q.isNotEmpty ? 'Ничего не найдено' : 'Товаров пока нет', style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.outline)),
      if (q.isEmpty) ...[const SizedBox(height: 8), Text('Нажмите "+ Товар" чтобы добавить', style: TextStyle(color: theme.colorScheme.outline))],
    ]));
  }

  Widget _buildCategorySearchResults(ThemeData theme) {
    final cats = _matchingCategories;
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: cats.length,
      itemBuilder: (ctx, i) {
        final catName = cats[i];
        final count = _products.where((p) => p.category == catName).length;
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () {
              _searchController.clear();
              setState(() => _selectedCategory = catName);
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(children: [
                Container(width: 48, height: 48,
                  decoration: BoxDecoration(color: theme.colorScheme.primaryContainer, borderRadius: BorderRadius.circular(12)),
                  child: Icon(Icons.folder, color: theme.colorScheme.onPrimaryContainer)),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(catName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                  Text('$count товаров', style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
                ])),
                const Icon(Icons.chevron_right),
              ]),
            ),
          ),
        );
      },
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label; final bool selected; final VoidCallback onTap; final VoidCallback? onLongPress;
  const _CategoryChip({required this.label, required this.selected, required this.onTap, this.onLongPress});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chip = FilterChip(
      label: Text(label), selected: selected, onSelected: (_) => onTap(), showCheckmark: false,
      backgroundColor: theme.colorScheme.surfaceContainerHighest, selectedColor: theme.colorScheme.primaryContainer,
    );
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: onLongPress != null ? GestureDetector(onLongPress: onLongPress, behavior: HitTestBehavior.translucent, child: chip) : chip,
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap, onEdit, onDelete, onPurchase;
  final VoidCallback? onSale;

  const _ProductCard({
    required this.product, required this.onTap, required this.onEdit, required this.onDelete,
    required this.onPurchase, required this.onSale,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final inStock = product.quantity > 0;
    final lowStock = product.quantity > 0 && product.quantity <= 5;
    final stockColor = inStock ? (lowStock ? Colors.orange.shade700 : Colors.green.shade700) : Colors.red.shade700;
    final stockBg = inStock ? (lowStock ? Colors.orange.shade100 : Colors.green.shade100) : Colors.red.shade100;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      elevation: 1, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        borderRadius: BorderRadius.circular(14), onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(children: [
            Container(width: 48, height: 48, decoration: BoxDecoration(color: stockBg, borderRadius: BorderRadius.circular(12)),
              child: Icon(Icons.inventory_2, color: stockColor)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(product.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
              const SizedBox(height: 2),
              Text(product.category, style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('${product.quantity} шт.', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: stockColor)),
              Text(CurrencyUtil.formatPrice(product.price), style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
            ]),
            const SizedBox(width: 4),
            PopupMenuButton<String>(onSelected: (v) {
              if (v == 'edit') { onEdit(); } else if (v == 'delete') { onDelete(); }
              else if (v == 'purchase') { onPurchase(); } else if (v == 'sale' && onSale != null) { onSale!(); }
            }, itemBuilder: (_) => [
              const PopupMenuItem(value: 'purchase', child: ListTile(leading: Icon(Icons.add_circle, color: Colors.green), title: Text('Закупка'), dense: true)),
              if (onSale != null) const PopupMenuItem(value: 'sale', child: ListTile(leading: Icon(Icons.remove_circle, color: Colors.orange), title: Text('Продажа'), dense: true)),
              const PopupMenuItem(value: 'edit', child: ListTile(leading: Icon(Icons.edit), title: Text('Изменить'), dense: true)),
              const PopupMenuItem(value: 'delete', child: ListTile(leading: Icon(Icons.delete, color: Colors.red), title: Text('Удалить'), dense: true)),
            ]),
          ]),
        ),
      ),
    );
  }
}

class _AddCategoryDialog extends StatefulWidget {
  const _AddCategoryDialog();
  @override
  State<_AddCategoryDialog> createState() => _AddCategoryDialogState();
}

class _AddCategoryDialogState extends State<_AddCategoryDialog> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Новая категория'),
      content: TextField(
        controller: _ctrl,
        autofocus: true,
        decoration: const InputDecoration(labelText: 'Название категории', border: OutlineInputBorder()),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
        FilledButton(onPressed: () => Navigator.pop(context, _ctrl.text.trim()), child: const Text('Добавить')),
      ],
    );
  }
}
