class Category {
  final int id;
  final String name;

  Category({required this.id, required this.name});

  factory Category.fromJson(Map<String, dynamic> json) => Category(
        id: int.parse(json['id'].toString()),
        name: json['name'],
      );

  Map<String, dynamic> toJson() => {'id': id, 'name': name};
}
