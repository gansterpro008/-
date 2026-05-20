import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../utils/currency_helper.dart';
import 'counterparty_detail_screen.dart';

class CounterpartiesScreen extends StatefulWidget {
  const CounterpartiesScreen({super.key});
  @override
  State<CounterpartiesScreen> createState() => _CounterpartiesScreenState();
}

class _CounterpartiesScreenState extends State<CounterpartiesScreen> with AutomaticKeepAliveClientMixin {
  final _db = DatabaseHelper();
  List<Map<String, dynamic>> _suppliers = [];
  List<Map<String, dynamic>> _buyers = [];
  bool _loading = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final all = await _db.getAllMovementsWithProduct();
    final suppliers = <String, Map<String, dynamic>>{};
    final buyers = <String, Map<String, dynamic>>{};

    for (final m in all) {
      final type = m['type'] as String;
      final cp = m['counterparty'] as String?;
      if (cp == null || cp.trim().isEmpty) continue;

      final map = type == 'purchase' ? suppliers : buyers;
      final existing = map[cp];
      if (existing == null) {
        map[cp] = {'name': cp, 'count': 1, 'totalQty': m['quantity'] as int,
          'totalSum': (m['quantity'] as int) * ((m['unitPrice'] as num?)?.toDouble() ?? 0), 'lastDate': m['date'] as String};
      } else {
        existing['count'] = (existing['count'] as int) + 1;
        existing['totalQty'] = (existing['totalQty'] as int) + (m['quantity'] as int);
        existing['totalSum'] = (existing['totalSum'] as num) + (m['quantity'] as int) * ((m['unitPrice'] as num?)?.toDouble() ?? 0);
        if (DateTime.parse(m['date'] as String).isAfter(DateTime.parse(existing['lastDate'] as String))) {
          existing['lastDate'] = m['date'];
        }
      }
    }

    setState(() {
      _suppliers = suppliers.values.toList()..sort((a, b) => (b['totalSum'] as num).compareTo(a['totalSum'] as num));
      _buyers = buyers.values.toList()..sort((a, b) => (b['totalSum'] as num).compareTo(a['totalSum'] as num));
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final numFmt = NumberFormat('#,###');

    return Scaffold(
      appBar: AppBar(title: const Text('Контрагенты'), centerTitle: true),
      body: _loading ? const Center(child: CircularProgressIndicator())
        : DefaultTabController(length: 2, child: Column(children: [
            TabBar(tabs: [Tab(text: 'Поставщики (${_suppliers.length})'), Tab(text: 'Покупатели (${_buyers.length})')]),
            Expanded(child: TabBarView(children: [
              _listView(_suppliers, true, theme, numFmt),
              _listView(_buyers, false, theme, numFmt),
            ])),
          ])),
    );
  }

  Widget _listView(List<Map<String, dynamic>> items, bool isSupplier, ThemeData theme, NumberFormat numFmt) {
    if (items.isEmpty) {
      return Center(child: Text(isSupplier ? 'Нет поставщиков' : 'Нет покупателей', style: TextStyle(color: theme.colorScheme.outline)));
    }
    final dateFmt = DateFormat('dd.MM.yyyy');
    return RefreshIndicator(onRefresh: _load, child: ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: items.length,
      itemBuilder: (ctx, i) {
        final item = items[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isSupplier ? Colors.green.shade100 : Colors.blue.shade100,
              child: Icon(isSupplier ? Icons.business : Icons.person, color: isSupplier ? Colors.green.shade700 : Colors.blue.shade700),
            ),
            title: Text(item['name'] as String, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(
              '${item['count']} операций | ${numFmt.format(item['totalQty'])} шт. | ${CurrencyUtil.formatPrice((item['totalSum'] as num).toDouble())}',
              style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
            ),
            trailing: Text(dateFmt.format(DateTime.parse(item['lastDate'] as String)), style: TextStyle(fontSize: 11, color: theme.colorScheme.outline)),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CounterpartyDetailScreen(name: item['name'] as String, isSupplier: isSupplier))).then((_) => _load()),
          ),
        );
      },
    ));
  }
}
