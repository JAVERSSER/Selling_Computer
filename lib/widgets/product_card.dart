import 'package:flutter/material.dart';
import '../models/product.dart';
import 'product_image.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;
  final VoidCallback? onAddToCart;

  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
    this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final outOfStock = product.stock == 0;

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 3,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image section
            Expanded(
              flex: 5,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ProductImage(
                    image: product.image,
                    categoryName: product.categoryName,
                    fit: BoxFit.cover,
                  ),
                  // Category badge top-left
                  if (product.categoryName != null)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(_categoryIcon(product.categoryName),
                              size: 10, color: Colors.white),
                          const SizedBox(width: 4),
                          Text(
                            product.categoryName!,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w600),
                          ),
                        ]),
                      ),
                    ),
                  // Out of stock overlay
                  if (outOfStock)
                    Container(
                      color: Colors.black45,
                      child: const Center(
                        child: Text('OUT OF STOCK',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                letterSpacing: 1)),
                      ),
                    ),
                ],
              ),
            ),

            // Info section
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Name
                    Text(
                      product.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 12),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    // Price + cart button
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            '\$${product.price.toStringAsFixed(2)}',
                            style: TextStyle(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        if (onAddToCart != null)
                          _CartButton(
                            onTap: outOfStock ? null : onAddToCart,
                            theme: theme,
                          ),
                      ],
                    ),

                    // Stock indicator
                    _StockBar(stock: product.stock),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _categoryIcon(String? name) {
    final n = (name ?? '').toLowerCase();
    if (n.contains('laptop'))    return Icons.laptop_mac;
    if (n.contains('desktop'))   return Icons.desktop_windows;
    if (n.contains('monitor'))   return Icons.monitor;
    if (n.contains('component')) return Icons.memory;
    if (n.contains('peripher'))  return Icons.keyboard;
    return Icons.computer;
  }
}

class _CartButton extends StatelessWidget {
  final VoidCallback? onTap;
  final ThemeData theme;
  const _CartButton({this.onTap, required this.theme});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: onTap != null
              ? theme.colorScheme.primary
              : Colors.grey[300],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          Icons.add_shopping_cart,
          size: 16,
          color: onTap != null ? Colors.white : Colors.grey[500],
        ),
      ),
    );
  }
}

class _StockBar extends StatelessWidget {
  final int stock;
  const _StockBar({required this.stock});

  @override
  Widget build(BuildContext context) {
    if (stock <= 0) {
      return const Text('Out of stock',
          style: TextStyle(color: Colors.red, fontSize: 11));
    }
    final color = stock > 10
        ? Colors.green
        : stock > 3
            ? Colors.orange
            : Colors.red;
    return Row(children: [
      Icon(Icons.circle, size: 8, color: color),
      const SizedBox(width: 4),
      Text(
        stock > 10 ? 'In Stock' : 'Only $stock left',
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w500),
      ),
    ]);
  }
}