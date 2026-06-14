import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:share_plus/share_plus.dart';
import '../database/database_helper.dart';

class ExportService {
  static Future<void> exportToExcel() async {
    final db = DatabaseHelper();
    final excel = Excel.createExcel();

    await _addProductsSheet(excel, db);
    await _addCategoriesSheet(excel, db);
    await _addSuppliersSheet(excel, db);
    await _addBuyersSheet(excel, db);

    final fileBytes = excel.encode();
    if (fileBytes == null) return;

    final dir = await getDownloadsDirectory();
    final file = File('${dir?.path ?? '.'}/monetka_export.xlsx');
    await file.writeAsBytes(fileBytes);

    await Share.shareXFiles([XFile(file.path)], text: 'Экспорт СкладСкой');
  }

  static Future<void> _addProductsSheet(Excel excel, DatabaseHelper db) async {
    final products = await db.getAllProducts();
    final sheet = excel['Товары'];
    sheet.appendRow([
      TextCellValue('ID'), TextCellValue('Наименование'), TextCellValue('Категория'),
      TextCellValue('Количество'), TextCellValue('Цена (руб)'), TextCellValue('Штрих-код'), TextCellValue('Описание'),
    ]);
    for (final p in products) {
      sheet.appendRow([
        TextCellValue('${p['id']}'), TextCellValue('${p['name']}'), TextCellValue('${p['category']}'),
        TextCellValue('${p['quantity']}'), TextCellValue('${p['price']} руб'),
        TextCellValue('${p['barcode'] ?? ''}'), TextCellValue('${p['description'] ?? ''}'),
      ]);
    }
  }

  static Future<void> _addCategoriesSheet(Excel excel, DatabaseHelper db) async {
    final stats = await db.getCategoryStats();
    final sheet = excel['Категории'];
    sheet.appendRow([TextCellValue('Категория'), TextCellValue('Кол-во товаров'), TextCellValue('Общее количество'), TextCellValue('Сумма')]);
    for (final s in stats) {
      sheet.appendRow([
        TextCellValue('${s['category']}'), TextCellValue('${s['productCount']}'),
        TextCellValue('${s['totalQuantity']}'), TextCellValue('${s['totalValue']} руб'),
      ]);
    }
  }

  static Future<void> _addSuppliersSheet(Excel excel, DatabaseHelper db) async {
    final suppliers = await db.getAllSuppliers();
    final all = await db.getAllMovementsWithProduct();
    final sheet = excel['Поставщики'];
    sheet.appendRow([TextCellValue('Поставщик'), TextCellValue('Кол-во операций'), TextCellValue('Сумма')]);
    for (final s in suppliers) {
      final ops = all.where((m) => m['counterparty'] == s && m['type'] == 'purchase').toList();
      final total = ops.fold(0.0, (sum, m) => sum + (m['quantity'] as int) * ((m['unitPrice'] as num?)?.toDouble() ?? 0));
      sheet.appendRow([TextCellValue(s), TextCellValue('${ops.length}'), TextCellValue('$total')]);
    }
  }

  static Future<void> _addBuyersSheet(Excel excel, DatabaseHelper db) async {
    final buyers = await db.getAllBuyers();
    final all = await db.getAllMovementsWithProduct();
    final sheet = excel['Покупатели'];
    sheet.appendRow([TextCellValue('Покупатель'), TextCellValue('Кол-во операций'), TextCellValue('Сумма')]);
    for (final b in buyers) {
      final ops = all.where((m) => m['counterparty'] == b && m['type'] == 'sale').toList();
      final total = ops.fold(0.0, (sum, m) => sum + (m['quantity'] as int) * ((m['unitPrice'] as num?)?.toDouble() ?? 0));
      sheet.appendRow([TextCellValue(b), TextCellValue('${ops.length}'), TextCellValue('$total')]);
    }
  }
}
