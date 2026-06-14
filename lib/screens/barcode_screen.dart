import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../database/database_helper.dart';
import '../models/product.dart';
import '../utils/barcode_helper.dart';
import 'product_detail_screen.dart';

class BarcodeScreen extends StatefulWidget {
  const BarcodeScreen({super.key});
  @override
  State<BarcodeScreen> createState() => _BarcodeScreenState();
}

class _BarcodeScreenState extends State<BarcodeScreen> {
  final _db = DatabaseHelper();
  final _searchCtrl = TextEditingController();
  final _scannerController = MobileScannerController();
  List<Product> _products = [];
  List<Product> _filtered = [];
  bool _loading = true;
  String _search = '';
  Rect? _scanRect;

  @override
  void initState() { super.initState(); _load(); _scannerController.addListener(_onScannerReady); }

  @override
  void dispose() { _searchCtrl.dispose(); _scannerController.dispose(); super.dispose(); }

  void _onScannerReady() {
    if (_scannerController.value.isInitialized && _scanRect != null) {
      _scannerController.updateScanWindow(_scanRect);
    }
  }

  Future<void> _load() async {
    final products = await _db.getProducts();
    setState(() { _products = products; _filterProducts(); _loading = false; });
  }

  void _filterProducts() {
    setState(() {
      if (_search.isEmpty) { _filtered = List.from(_products); }
      else { _filtered = _products.where((p) =>
        p.name.toLowerCase().contains(_search.toLowerCase()) ||
        (p.barcode?.contains(_search) ?? false)
      ).toList(); }
    });
  }

  Future<void> _generateFor(Product p) async {
    final bc = DateTime.now().millisecondsSinceEpoch.toString().substring(5);
    final updated = p.copyWith(barcode: bc);
    await _db.updateProduct(updated);
    await _load();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Штрих-код $bc создан для ${p.name}'), backgroundColor: Colors.green));
  }

  Future<void> _clearBarcode(Product p) async {
    final updated = p.copyWith(barcode: null);
    await _db.updateProduct(updated);
    await _load();
  }

  Future<void> _printBarcode(Product p) async {
    await Share.share('Товар: ${p.name}\nШтрих-код: ${p.barcode}', subject: 'Штрих-код ${p.barcode}');
  }

  Future<void> _shareBarcode(Product p) async {
    if (p.barcode == null) return;
    await shareBarcodeImage(p.barcode!, p.name, p.category);
  }

  Future<void> _shareAll() async {
    final withBarcode = _products.where((p) => p.barcode != null && p.barcode!.isNotEmpty).toList();
    if (withBarcode.isEmpty) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Нет товаров со штрих-кодами')));
      return;
    }
    final productsData = withBarcode.map((p) => {'name': p.name, 'barcode': p.barcode, 'category': p.category}).toList();
    await shareAllBarcodes(productsData);
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Штрих-коды'),
          actions: [
            IconButton(
              icon: const Icon(Icons.share),
              tooltip: 'Отправить все',
              onPressed: _shareAll,
            ),
          ],
          bottom: const TabBar(tabs: [Tab(text: 'Поиск и генерация'), Tab(icon: Icon(Icons.camera_alt), text: 'Сканер')]),
        ),
        body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(children: [_buildProductList(), _buildScanner()]),
      ),
    );
  }

  Widget _buildProductList() {
    final theme = Theme.of(context);
    return Column(children: [
      Padding(
        padding: const EdgeInsets.all(12),
        child: TextField(
          controller: _searchCtrl,
          decoration: InputDecoration(
            hintText: 'Поиск товара или штрих-кода...',
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onChanged: (v) { _search = v; _filterProducts(); },
        ),
      ),
      Expanded(
        child: _filtered.isEmpty
          ? Center(child: Text('Нет товаров', style: TextStyle(color: theme.colorScheme.outline)))
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: _filtered.length,
                itemBuilder: (ctx, i) {
                  final p = _filtered[i];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: p.barcode != null ? Colors.green.shade100 : Colors.grey.shade100,
                        child: Icon(Icons.qr_code, color: p.barcode != null ? Colors.green.shade700 : Colors.grey),
                      ),
                      title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(p.barcode != null ? 'ШК: ${p.barcode}' : 'Нет штрих-кода',
                        style: TextStyle(fontSize: 12, color: p.barcode != null ? theme.colorScheme.onSurfaceVariant : theme.colorScheme.outline)),
                      trailing: PopupMenuButton(
                        itemBuilder: (_) => [
                          PopupMenuItem(child: const Text('Сгенерировать'), onTap: () => _generateFor(p)),
                          if (p.barcode != null) ...[
                            PopupMenuItem(child: const Text('Печать'), onTap: () => _printBarcode(p)),
                            PopupMenuItem(child: const Text('Отправить'), onTap: () => _shareBarcode(p)),
                            PopupMenuItem(child: const Text('Очистить'), onTap: () => _clearBarcode(p)),
                          ],
                        ],
                      ),
                      onTap: () => Navigator.push(ctx, MaterialPageRoute(builder: (_) => ProductDetailScreen(product: p))).then((_) => _load()),
                    ),
                  );
                },
              ),
            ),
      ),
    ]);
  }

  bool _scanning = true;
  String? _lastScanned;

  Widget _buildScanner() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        const scanW = 300.0;
        const scanH = 180.0;
        final left = (w - scanW) / 2;
        final top = (h - scanH) / 2 - 40;
        final rect = Rect.fromLTWH(left, top, scanW, scanH);

        if (_scanRect == null) {
          _scanRect = rect;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _scannerController.value.isInitialized) {
              _scannerController.updateScanWindow(rect);
            }
          });
        }

        return Stack(
          children: [
            MobileScanner(
              controller: _scannerController,
              onDetect: (capture) async {
                if (!_scanning) return;
                final bc = capture.barcodes.firstOrNull;
                final raw = bc?.rawValue?.trim();
                if (raw == null || raw.isEmpty || raw == _lastScanned) return;
                _lastScanned = raw;
                _scanning = false;
                final found = await _db.getProductByBarcode(raw);
                if (found != null && context.mounted) {
                  await Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailScreen(product: found)));
                } else if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Товар с кодом $raw не найден'),
                  ));
                }
                _scanning = true;
                _lastScanned = null;
              },
            ),
            _ScanOverlay(scanRect: rect),
          ],
        );
      },
    );
  }
}

class _ScanOverlay extends StatelessWidget {
  final Rect scanRect;
  const _ScanOverlay({required this.scanRect});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _ScannerMaskPainter(cutoutRect: scanRect),
            ),
          ),
        ),
        Positioned(
          left: scanRect.left,
          top: scanRect.top,
          child: SizedBox(
            width: scanRect.width,
            height: scanRect.height,
            child: CustomPaint(painter: _ScanFramePainter()),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          top: scanRect.bottom + 16,
          child: const Text(
            'Наведите камеру на штрих-код',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ),
      ],
    );
  }
}

class _ScannerMaskPainter extends CustomPainter {
  final Rect cutoutRect;
  _ScannerMaskPainter({required this.cutoutRect});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withValues(alpha: 0.5);
    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height)),
        Path()..addRRect(RRect.fromRectAndRadius(cutoutRect, const Radius.circular(12))),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _ScannerMaskPainter old) => old.cutoutRect != cutoutRect;
}

class _ScanFramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    const len = 24.0;
    final corners = [
      (0.0, 0.0, 1.0, 1.0),
      (size.width, 0.0, -1.0, 1.0),
      (0.0, size.height, 1.0, -1.0),
      (size.width, size.height, -1.0, -1.0),
    ];
    for (final (dx, dy, hs, vs) in corners) {
      canvas.drawLine(Offset(dx, dy), Offset(dx + hs * len, dy), paint);
      canvas.drawLine(Offset(dx, dy), Offset(dx, dy + vs * len), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ScanFramePainter old) => false;
}
