import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/product.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/product_provider.dart';
import '../../widgets/product_image.dart';
import 'cart_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final int productId;
  const ProductDetailScreen({super.key, required this.productId});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  Product? _product;
  bool _loading = true;
  int _qty = 1;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p =
        await context.read<ProductProvider>().getProduct(widget.productId);
    if (mounted) setState(() { _product = p; _loading = false; });
  }

  Future<void> _addToCart() async {
    final auth = context.read<AuthProvider>();
    if (auth.user == null) return;
    final ok = await context
        .read<CartProvider>()
        .addToCart(auth.user!.id, widget.productId, _qty);
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Added to cart!'),
        action: SnackBarAction(
          label: 'View Cart',
          onPressed: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const CartScreen())),
        ),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_product == null) {
      return Scaffold(
          appBar: AppBar(),
          body: const Center(child: Text('Product not found')));
    }
    final p = _product!;
    return Scaffold(
      appBar: AppBar(title: Text(p.name)),
      body: LayoutBuilder(builder: (context, constraints) {
        final isWide = constraints.maxWidth > 700;
        final content = [_imageSection(p), _infoSection(p)];
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: isWide
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children:
                      content.map((w) => Expanded(child: w)).toList())
              : Column(children: content),
        );
      }),
    );
  }

  Widget _imageSection(Product p) => Padding(
        padding: const EdgeInsets.all(12),
        child: AspectRatio(
          aspectRatio: 1,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: ProductImage(image: p.image, fit: BoxFit.cover),
          ),
        ),
      );

  Widget _infoSection(Product p) => Padding(
        padding: const EdgeInsets.all(12),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (p.categoryName != null)
            Chip(
                label: Text(p.categoryName!),
                visualDensity: VisualDensity.compact),
          const SizedBox(height: 8),
          Text(p.name,
              style: const TextStyle(
                  fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('\$${p.price.toStringAsFixed(2)}',
              style: TextStyle(
                  fontSize: 26,
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Text(p.description,
              style: const TextStyle(fontSize: 15, height: 1.5)),
          const SizedBox(height: 16),
          Text('Stock: ${p.stock}',
              style: TextStyle(
                  color: p.stock > 0 ? Colors.green : Colors.red,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 20),
          Row(children: [
            IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              onPressed: _qty > 1 ? () => setState(() => _qty--) : null,
            ),
            Text('$_qty',
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold)),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed:
                  _qty < p.stock ? () => setState(() => _qty++) : null,
            ),
          ]),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.add_shopping_cart),
              label: const Text('Add to Cart',
                  style: TextStyle(fontSize: 16)),
              onPressed: p.stock > 0 ? _addToCart : null,
              style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8))),
            ),
          ),
        ]),
      );
}
