class Product {
  final int id;
  final String name;
  final String description;
  final double price;
  final int stock;
  final int categoryId;
  final String? categoryName;
  final String? image; // base64 data URI: "data:image/png;base64,..."

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.stock,
    required this.categoryId,
    this.categoryName,
    this.image,
  });

  factory Product.fromJson(Map<String, dynamic> json) => Product(
        id: int.parse(json['id'].toString()),
        name: json['name'] ?? '',
        description: json['description'] ?? '',
        price: double.parse(json['price'].toString()),
        stock: int.parse(json['stock'].toString()),
        categoryId: int.parse((json['category_id'] ?? 0).toString()),
        categoryName: json['category_name'],
        image: json['image'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'price': price,
        'stock': stock,
        'category_id': categoryId,
        'image': image,
      };
}
