import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/product.dart';
import '../models/movement.dart';
import '../models/app_settings.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'warehouse.db');
    return await openDatabase(
      path,
      version: 3,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        category TEXT DEFAULT 'Общее',
        quantity INTEGER DEFAULT 0,
        price REAL DEFAULT 0.0,
        description TEXT,
        barcode TEXT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE movements (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        productId INTEGER NOT NULL,
        type TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        counterparty TEXT,
        unitPrice REAL DEFAULT 0.0,
        date TEXT NOT NULL,
        note TEXT,
        FOREIGN KEY (productId) REFERENCES products (id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE movements ADD COLUMN counterparty TEXT');
      await db.execute('ALTER TABLE movements ADD COLUMN unitPrice REAL DEFAULT 0.0');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS settings (
          key TEXT PRIMARY KEY,
          value TEXT NOT NULL
        )
      ''');
    }
    if (oldVersion < 3) {
      try { await db.execute('ALTER TABLE products ADD COLUMN barcode TEXT'); } catch (_) {}
    }
  }

  Future<int> insertProduct(Product product) async {
    final db = await database;
    return await db.insert('products', product.toMap());
  }

  Future<int> updateProduct(Product product) async {
    final db = await database;
    return await db.update(
      'products',
      product.toMap(),
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  Future<int> deleteProduct(int id) async {
    final db = await database;
    await db.delete('movements', where: 'productId = ?', whereArgs: [id]);
    return await db.delete('products', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Product>> getProducts({String? search, String? category}) async {
    final db = await database;
    final where = <String>[];
    final args = <dynamic>[];
    if (search != null && search.isNotEmpty) {
      where.add('(name LIKE ? OR category LIKE ? OR barcode LIKE ?)');
      args.addAll(['%$search%', '%$search%', '%$search%']);
    }
    if (category != null && category.isNotEmpty) {
      where.add('category = ?');
      args.add(category);
    }
    final maps = await db.query(
      'products',
      where: where.isEmpty ? null : where.join(' AND '),
      whereArgs: args.isEmpty ? null : args,
      orderBy: 'name ASC',
    );
    return maps.map((m) => Product.fromMap(m)).toList();
  }

  Future<Product?> getProductByBarcode(String barcode) async {
    final db = await database;
    final maps = await db.query('products', where: 'barcode = ?', whereArgs: [barcode.trim()], limit: 1);
    if (maps.isEmpty) return null;
    return Product.fromMap(maps.first);
  }

  Future<List<String>> getCategories() async {
    final db = await database;
    final productCats = await db.rawQuery(
      'SELECT DISTINCT category FROM products ORDER BY category ASC',
    );
    final fromProducts = productCats.map((r) => r['category'] as String).toSet();
    final fromSaved = await getSavedCategories();
    final all = {...fromProducts, ...fromSaved};
    return all.toList()..sort();
  }

  Future<List<String>> getSavedCategories() async {
    final db = await database;
    final maps = await db.query('settings', where: 'key = ?', whereArgs: ['saved_categories']);
    if (maps.isEmpty) return [];
    final raw = maps.first['value'] as String;
    if (raw.isEmpty) return [];
    return raw.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
  }

  Future<void> saveCategory(String category) async {
    final current = await getSavedCategories();
    if (current.contains(category)) return;
    current.add(category);
    final db = await database;
    await db.insert('settings', {'key': 'saved_categories', 'value': current.join(',')},
      conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteSavedCategory(String category) async {
    final db = await database;
    final current = await getSavedCategories();
    if (current.contains(category)) {
      current.remove(category);
      await db.insert('settings', {'key': 'saved_categories', 'value': current.join(',')},
        conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await db.update(
      'products',
      {'category': 'Общее'},
      where: 'category = ?',
      whereArgs: [category],
    );
  }

  Future<List<String>> getAllSuppliers() async {
    final db = await database;
    final result = await db.rawQuery(
      "SELECT DISTINCT counterparty FROM movements WHERE type = 'purchase' AND counterparty IS NOT NULL AND counterparty != '' ORDER BY counterparty ASC",
    );
    return result.map((r) => r['counterparty'] as String).toList();
  }

  Future<List<String>> getAllBuyers() async {
    final db = await database;
    final result = await db.rawQuery(
      "SELECT DISTINCT counterparty FROM movements WHERE type = 'sale' AND counterparty IS NOT NULL AND counterparty != '' ORDER BY counterparty ASC",
    );
    return result.map((r) => r['counterparty'] as String).toList();
  }

  Future<Product?> getProduct(int id) async {
    final db = await database;
    final maps = await db.query('products', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Product.fromMap(maps.first);
  }

  Future<void> addMovement(Movement movement) async {
    final db = await database;
    final product = await getProduct(movement.productId);
    if (product == null) throw Exception('Товар не найден');

    if (movement.type == 'sale' && product.quantity < movement.quantity) {
      throw Exception('Недостаточно товара на складе');
    }

    final delta = movement.type == 'purchase' ? movement.quantity : -movement.quantity;
    final updated = product.copyWith(
      quantity: product.quantity + delta,
      updatedAt: DateTime.now().toIso8601String(),
    );

    await db.transaction((txn) async {
      await txn.update('products', updated.toMap(), where: 'id = ?', whereArgs: [product.id]);
      await txn.insert('movements', movement.toMap());
    });
  }

  Future<List<Movement>> getMovements(int productId) async {
    final db = await database;
    final maps = await db.query(
      'movements',
      where: 'productId = ?',
      whereArgs: [productId],
      orderBy: 'date DESC',
    );
    return maps.map((m) => Movement.fromMap(m)).toList();
  }

  Future<List<Map<String, dynamic>>> getAllMovementsWithProduct({int? limit}) async {
    final db = await database;
    final maps = await db.rawQuery('''
      SELECT m.*, p.name as productName
      FROM movements m
      LEFT JOIN products p ON m.productId = p.id
      ORDER BY m.date DESC
      ${limit != null ? 'LIMIT $limit' : ''}
    ''');
    return maps;
  }

  Future<List<Map<String, dynamic>>> getCounterpartyMovements(String name, String type) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT m.*, p.name as productName
      FROM movements m
      LEFT JOIN products p ON m.productId = p.id
      WHERE m.counterparty = ? AND m.type = ?
      ORDER BY m.date DESC
    ''', [name, type]);
  }

  Future<Map<String, dynamic>> getStats() async {
    final db = await database;
    final productCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM products'),
    ) ?? 0;
    final totalStock = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COALESCE(SUM(quantity), 0) FROM products'),
    ) ?? 0;
    final totalValue = (await db.rawQuery(
      'SELECT COALESCE(SUM(quantity * price), 0) FROM products',
    )).first.values.first;
    final lowStock = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM products WHERE quantity > 0 AND quantity <= 5'),
    ) ?? 0;
    final outOfStock = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM products WHERE quantity = 0'),
    ) ?? 0;
    final purchaseTotal = (await db.rawQuery(
      "SELECT COALESCE(SUM(quantity * unitPrice), 0) FROM movements WHERE type = 'purchase'",
    )).first.values.first;
    final saleTotal = (await db.rawQuery(
      "SELECT COALESCE(SUM(quantity * unitPrice), 0) FROM movements WHERE type = 'sale'",
    )).first.values.first;

    return {
      'productCount': productCount,
      'totalStock': totalStock,
      'totalValue': totalValue,
      'lowStock': lowStock,
      'outOfStock': outOfStock,
      'purchaseTotal': purchaseTotal,
      'saleTotal': saleTotal,
    };
  }

  Future<List<Map<String, dynamic>>> getCategoryStats() async {
    final db = await database;
    return await db.rawQuery('''
      SELECT category,
             COUNT(*) as productCount,
             COALESCE(SUM(quantity), 0) as totalQuantity,
             COALESCE(SUM(quantity * price), 0) as totalValue
      FROM products
      GROUP BY category
      ORDER BY totalValue DESC
    ''');
  }

  Future<AppSettings> getSettings() async {
    Database? db;
    try { db = await database; } catch (e) { return AppSettings(); }
    final maps = await db.query('settings');
    final map = <String, String>{};
    for (final row in maps) {
      map[row['key'] as String] = row['value'] as String;
    }
    return AppSettings.fromMap(map);
  }

  Future<void> saveSettings(AppSettings settings) async {
    final db = await database;
    final batch = db.batch();
    for (final entry in settings.toMap().entries) {
      batch.insert(
        'settings',
        {'key': entry.key, 'value': entry.value},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<Map<String, dynamic>>> getAllProducts() async {
    final db = await database;
    return db.query('products', orderBy: 'name ASC');
  }
}
