class Movement {
  final int? id;
  final int productId;
  final String type; // 'purchase' or 'sale'
  final int quantity;
  final String? counterparty;
  final double unitPrice;
  final String date;
  final String? note;

  Movement({
    this.id,
    required this.productId,
    required this.type,
    required this.quantity,
    this.counterparty,
    this.unitPrice = 0.0,
    String? date,
    this.note,
  }) : date = date ?? DateTime.now().toIso8601String();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'productId': productId,
      'type': type,
      'quantity': quantity,
      'counterparty': counterparty,
      'unitPrice': unitPrice,
      'date': date,
      'note': note,
    };
  }

  factory Movement.fromMap(Map<String, dynamic> map) {
    return Movement(
      id: map['id'] as int?,
      productId: map['productId'] as int,
      type: map['type'] as String,
      quantity: map['quantity'] as int,
      counterparty: map['counterparty'] as String?,
      unitPrice: (map['unitPrice'] as num?)?.toDouble() ?? 0.0,
      date: map['date'] as String?,
      note: map['note'] as String?,
    );
  }

  double get total => quantity * unitPrice;
  bool get isPurchase => type == 'purchase';
  String get typeLabel => isPurchase ? 'Закупка' : 'Продажа';
}
