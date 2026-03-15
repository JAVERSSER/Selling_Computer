class CartItem {
  final int id;
  final int productId;
  final String productName;
  final double price;
  final String? image;
  int quantity;

  CartItem({
    required this.id,
    required this.productId,
    required this.productName,
    required this.price,
    required this.quantity,
    this.image,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
        id: int.parse(json['id'].toString()),
        productId: int.parse(json['product_id'].toString()),
        productName: json['product_name'] ?? '',
        price: double.parse(json['price'].toString()),
        quantity: int.parse(json['quantity'].toString()),
        image: json['image'],
      );

  double get subtotal => price * quantity;
}
