class OrderItem {
  final int id;
  final int productId;
  final String productName;
  final double price;
  final int quantity;
  final String? image;

  OrderItem({
    required this.id,
    required this.productId,
    required this.productName,
    required this.price,
    required this.quantity,
    this.image,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) => OrderItem(
        id: int.parse(json['id'].toString()),
        productId: int.parse(json['product_id'].toString()),
        productName: json['product_name'] ?? '',
        price: double.parse(json['price'].toString()),
        quantity: int.parse(json['quantity'].toString()),
        image: json['image'],
      );

  double get subtotal => price * quantity;
}

class Order {
  final int id;
  final int userId;
  final String? customerName;
  final double totalAmount;
  final String status;
  final String shippingAddress;
  final String createdAt;
  final List<OrderItem> items;

  Order({
    required this.id,
    required this.userId,
    this.customerName,
    required this.totalAmount,
    required this.status,
    required this.shippingAddress,
    required this.createdAt,
    required this.items,
  });

  factory Order.fromJson(Map<String, dynamic> json) => Order(
        id: int.parse(json['id'].toString()),
        userId: int.parse(json['user_id'].toString()),
        customerName: json['customer_name'],
        totalAmount: double.parse(json['total_amount'].toString()),
        status: json['status'] ?? 'pending',
        shippingAddress: json['shipping_address'] ?? '',
        createdAt: json['created_at'] ?? '',
        items: json['items'] != null
            ? (json['items'] as List)
                .map((i) => OrderItem.fromJson(i))
                .toList()
            : [],
      );
}
