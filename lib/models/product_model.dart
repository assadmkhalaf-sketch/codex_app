class Product {
  final int? id;
  final String name;
  final int stock;
  final double priceUsd;
  final double priceIqd;
  final int alertThreshold;

  Product({
    this.id,
    required this.name,
    required this.stock,
    required this.priceUsd,
    required this.priceIqd,
    required this.alertThreshold,
  });

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'],
      name: map['name'],
      stock: map['stock'] ?? 0,
      priceUsd: (map['price_usd'] as num).toDouble(),
      priceIqd: (map['price_iqd'] as num).toDouble(),
      alertThreshold: map['alert_threshold'] ?? 5,
    );
  }
}