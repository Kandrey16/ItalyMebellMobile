class DeliveryMethod {
  final int id;
  final String name;
  final double price;

  DeliveryMethod({required this.id, required this.name, required this.price});

  factory DeliveryMethod.fromJson(Map<String, dynamic> json) {
    return DeliveryMethod(
      id: json['id_order_delivery'],
      name: json['name_order_delivery'],
      price: double.parse(json['price_order_delivery']),
    );
  }
}
