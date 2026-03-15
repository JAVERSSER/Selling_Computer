import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/product_provider.dart';
import '../../models/product.dart';
import '../../widgets/product_image.dart';
import 'add_edit_product_screen.dart';

class ManageProductsScreen extends StatefulWidget {
  const ManageProductsScreen({super.key});

  @override
  State<ManageProductsScreen> createState() => _ManageProductsScreenState();
}

class _ManageProductsScreenState extends State<ManageProductsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final pp = context.read<ProductProvider>();
      pp.fetchProducts();
      pp.fetchCategories();
    });
  }

  @override
  Widget build(BuildContext context) {
    final pp = context.watch<ProductProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Products'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF1A237E),
                elevation: 0,
              ),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Product'),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const AddEditProductScreen()),
              ).then((_) => pp.fetchProducts()),
            ),
          ),
        ],
      ),
      body: pp.loading
          ? const Center(child: CircularProgressIndicator())
          : pp.products.isEmpty
              ? _emptyState(context, pp)
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: pp.products.length,
                  itemBuilder: (ctx, i) =>
                      _ProductCard(product: pp.products[i], pp: pp),
                ),
    );
  }

  Widget _emptyState(BuildContext context, ProductProvider pp) => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.inventory_2_outlined,
                size: 44, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          const Text('No products yet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Add your first product to start selling',
              style: TextStyle(color: Colors.grey[600])),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const AddEditProductScreen()),
            ).then((_) => pp.fetchProducts()),
            icon: const Icon(Icons.add),
            label: const Text('Add First Product'),
          ),
        ]),
      );
}

class _ProductCard extends StatelessWidget {
  final Product product;
  final ProductProvider pp;
  const _ProductCard({required this.product, required this.pp});

  @override
  Widget build(BuildContext context) {
    final outOfStock = product.stock == 0;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(children: [
          // Image
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 70,
              height: 70,
              child: ProductImage(
                image: product.image,
                categoryName: product.categoryName,
                fit: BoxFit.cover,
                iconSize: 28,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Info
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(
                      child: Text(product.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ),
                    if (product.categoryName != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A237E).withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(product.categoryName!,
                            style: const TextStyle(
                                color: Color(0xFF1A237E),
                                fontSize: 10,
                                fontWeight: FontWeight.w600)),
                      ),
                  ]),
                  const SizedBox(height: 4),
                  Text('\$${product.price.toStringAsFixed(2)}',
                      style: const TextStyle(
                          color: Color(0xFF1A237E),
                          fontWeight: FontWeight.bold,
                          fontSize: 15)),
                  const SizedBox(height: 4),
                  Row(children: [
                    Icon(Icons.circle,
                        size: 8,
                        color: outOfStock
                            ? Colors.red
                            : product.stock < 5
                                ? Colors.orange
                                : Colors.green),
                    const SizedBox(width: 4),
                    Text(
                      outOfStock
                          ? 'Out of stock'
                          : 'Stock: ${product.stock}',
                      style: TextStyle(
                          fontSize: 12,
                          color: outOfStock
                              ? Colors.red
                              : product.stock < 5
                                  ? Colors.orange
                                  : Colors.grey[600]),
                    ),
                  ]),
                ]),
          ),

          // Actions
          Column(mainAxisSize: MainAxisSize.min, children: [
            _actionBtn(
              icon: Icons.edit_outlined,
              color: Colors.blue,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) =>
                        AddEditProductScreen(product: product)),
              ).then((_) => pp.fetchProducts()),
            ),
            const SizedBox(height: 6),
            _actionBtn(
              icon: Icons.delete_outline,
              color: Colors.red,
              onTap: () => _confirmDelete(context),
            ),
          ]),
        ]),
      ),
    );
  }

  Widget _actionBtn(
          {required IconData icon,
          required Color color,
          required VoidCallback onTap}) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
      );

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Row(children: [
          Icon(Icons.warning_amber_rounded, color: Colors.red),
          SizedBox(width: 8),
          Text('Delete Product'),
        ]),
        content: RichText(
          text: TextSpan(
            style: const TextStyle(color: Colors.black87, fontSize: 14),
            children: [
              const TextSpan(text: 'Are you sure you want to delete '),
              TextSpan(
                  text: '"${product.name}"',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const TextSpan(text: '? This cannot be undone.'),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(context);
              pp.deleteProduct(product.id);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
