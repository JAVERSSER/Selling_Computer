import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/cart_provider.dart';
import '../../widgets/product_card.dart';
import '../../models/product.dart';
import '../auth/login_screen.dart';
import 'product_detail_screen.dart';
import 'cart_screen.dart';
import 'order_history_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchCtrl  = TextEditingController();
  final _scrollCtrl  = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().fetchProducts();
      context.read<ProductProvider>().fetchCategories();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToProducts() {
    _scrollCtrl.animateTo(
      320,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final pp   = context.watch<ProductProvider>();
    final cart = context.watch<CartProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: _buildAppBar(context, auth, cart),
      body: RefreshIndicator(
        onRefresh: () async {
          await pp.fetchProducts();
          await pp.fetchCategories();
        },
        child: CustomScrollView(
          controller: _scrollCtrl,
          slivers: [
            // Hero banner
            SliverToBoxAdapter(
              child: _HeroBanner(
                userName: auth.user?.name,
                onShopNow: _scrollToProducts,
              ),
            ),

            // Search bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: _SearchBar(
                  controller: _searchCtrl,
                  onChanged: pp.setSearch,
                ),
              ),
            ),

            // Category icons
            SliverToBoxAdapter(child: _CategoryRow(pp: pp)),

            // Section title
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      pp.selectedCategory == null
                          ? 'All Products'
                          : pp.categories
                              .firstWhere(
                                  (c) => c.id == pp.selectedCategory,
                                  orElse: () => pp.categories.first)
                              .name,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text('${pp.products.length} items',
                        style: const TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            ),

            // Product grid
            _ProductGridSliver(pp: pp, auth: auth, cart: cart),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
      BuildContext context, AuthProvider auth, CartProvider cart) {
    return AppBar(
      elevation: 0,
      backgroundColor: const Color(0xFF1A237E),
      foregroundColor: Colors.white,
      title: Row(children: [
        const Icon(Icons.computer, color: Colors.white70, size: 22),
        const SizedBox(width: 8),
        const Text('PC Store',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
      ]),
      actions: [
        // Cart
        Stack(alignment: Alignment.topRight, children: [
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const CartScreen())),
          ),
          if (cart.count > 0)
            Positioned(
              right: 6,
              top: 6,
              child: Container(
                width: 16,
                height: 16,
                decoration: const BoxDecoration(
                    color: Colors.redAccent, shape: BoxShape.circle),
                child: Center(
                  child: Text('${cart.count}',
                      style: const TextStyle(fontSize: 10, color: Colors.white)),
                ),
              ),
            ),
        ]),
        // Orders
        IconButton(
          icon: const Icon(Icons.receipt_long_outlined),
          tooltip: 'My Orders',
          onPressed: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const OrderHistoryScreen())),
        ),
        // Avatar + logout
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: PopupMenuButton(
            child: CircleAvatar(
              radius: 16,
              backgroundColor: Colors.white24,
              child: Text(
                (auth.user?.name ?? 'U')[0].toUpperCase(),
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            itemBuilder: (_) => <PopupMenuEntry>[
              PopupMenuItem(
                enabled: false,
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(auth.user?.name ?? '',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text(auth.user?.email ?? '',
                          style: const TextStyle(
                              fontSize: 12, color: Colors.grey)),
                    ]),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'orders',
                child: const Row(children: [
                  Icon(Icons.receipt_long_outlined, size: 18),
                  SizedBox(width: 8),
                  Text('My Orders'),
                ]),
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(
                        builder: (_) => const OrderHistoryScreen())),
              ),
              PopupMenuItem(
                value: 'logout',
                child: const Row(children: [
                  Icon(Icons.logout, size: 18, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Logout', style: TextStyle(color: Colors.red)),
                ]),
                onTap: () async {
                  await context.read<AuthProvider>().logout();
                  if (!context.mounted) return;
                  Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const LoginScreen()));
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Hero Banner ──────────────────────────────────────────────────────────────

class _HeroBanner extends StatelessWidget {
  final String? userName;
  final VoidCallback? onShopNow;
  const _HeroBanner({this.userName, this.onShopNow});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      height: 160,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xFF1A237E), Color(0xFF283593)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A237E).withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(children: [
        // Background icons
        Positioned(
          right: -20,
          top: -20,
          child: Icon(Icons.computer,
              size: 140, color: Colors.white.withValues(alpha: 0.07)),
        ),
        Positioned(
          right: 60,
          bottom: -10,
          child: Icon(Icons.laptop_mac,
              size: 80, color: Colors.white.withValues(alpha: 0.05)),
        ),
        // Content
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  userName != null ? 'Hello, $userName 👋' : 'Welcome to PC Store',
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Find Your Perfect\nComputer Setup',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      height: 1.3),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: onShopNow,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text('Shop Now →',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
              ]),
        ),
      ]),
    );
  }
}

// ── Search Bar ───────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  const _SearchBar({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: 'Search laptops, desktops, monitors...',
        hintStyle: const TextStyle(fontSize: 13),
        prefixIcon: const Icon(Icons.search, color: Colors.grey),
        suffixIcon: controller.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear, size: 18),
                onPressed: () {
                  controller.clear();
                  onChanged('');
                })
            : null,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 0),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: Color(0xFF1A237E), width: 1.5)),
      ),
    );
  }
}

// ── Category Row ─────────────────────────────────────────────────────────────

class _CategoryRow extends StatelessWidget {
  final ProductProvider pp;
  const _CategoryRow({required this.pp});

  static const _icons = <String, IconData>{
    'laptops':     Icons.laptop_mac,
    'desktops':    Icons.desktop_windows,
    'monitors':    Icons.monitor,
    'components':  Icons.memory,
    'peripherals': Icons.keyboard,
    'storage':     Icons.storage,
    'printers':    Icons.print,
  };

  static const _colors = <String, Color>{
    'laptops':     Color(0xFF3F51B5),
    'desktops':    Color(0xFF2196F3),
    'monitors':    Color(0xFF009688),
    'components':  Color(0xFF9C27B0),
    'peripherals': Color(0xFFFF9800),
    'storage':     Color(0xFF607D8B),
    'printers':    Color(0xFF795548),
  };

  IconData _icon(String name) {
    final key = name.toLowerCase();
    for (final e in _icons.entries) {
      if (key.contains(e.key.replaceAll('s', ''))) return e.value;
    }
    return Icons.devices_other;
  }

  Color _color(String name) {
    final key = name.toLowerCase();
    for (final e in _colors.entries) {
      if (key.contains(e.key.replaceAll('s', ''))) return e.value;
    }
    return const Color(0xFF1A237E);
  }

  @override
  Widget build(BuildContext context) {
    if (pp.categories.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 86,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _CategoryChip(
            icon: Icons.grid_view_rounded,
            label: 'All',
            color: const Color(0xFF1A237E),
            selected: pp.selectedCategory == null,
            onTap: () => pp.setCategory(null),
          ),
          ...pp.categories.map((c) => _CategoryChip(
                icon: _icon(c.name),
                label: c.name,
                color: _color(c.name),
                selected: pp.selectedCategory == c.id,
                onTap: () => pp.setCategory(c.id),
              )),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 68,
        margin: const EdgeInsets.only(right: 10),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: selected ? color : Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: selected
                      ? color.withValues(alpha: 0.35)
                      : Colors.black12,
                  blurRadius: selected ? 8 : 4,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(icon,
                size: 22,
                color: selected ? Colors.white : color),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight:
                  selected ? FontWeight.bold : FontWeight.normal,
              color: selected ? color : Colors.grey[700],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ]),
      ),
    );
  }
}

// ── Product Grid ─────────────────────────────────────────────────────────────

class _ProductGridSliver extends StatelessWidget {
  final ProductProvider pp;
  final AuthProvider auth;
  final CartProvider cart;

  const _ProductGridSliver(
      {required this.pp, required this.auth, required this.cart});

  @override
  Widget build(BuildContext context) {
    if (pp.loading) {
      return const SliverFillRemaining(
          child: Center(child: CircularProgressIndicator()));
    }
    if (pp.error != null) {
      return SliverFillRemaining(
        child: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.wifi_off, size: 56, color: Colors.grey),
            const SizedBox(height: 12),
            Text(pp.error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 12),
            ElevatedButton.icon(
                onPressed: pp.fetchProducts,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry')),
          ]),
        ),
      );
    }
    if (pp.products.isEmpty) {
      return const SliverFillRemaining(
        child: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.search_off, size: 56, color: Colors.grey),
            SizedBox(height: 12),
            Text('No products found', style: TextStyle(color: Colors.grey)),
          ]),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverLayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.crossAxisExtent;
          final cols  = width > 900 ? 4 : width > 600 ? 3 : 2;
          return SliverGrid(
            delegate: SliverChildBuilderDelegate(
              (ctx, i) {
                final product = pp.products[i];
                return ProductCard(
                  product: product,
                  onTap: () => Navigator.push(
                      ctx,
                      MaterialPageRoute(
                          builder: (_) =>
                              ProductDetailScreen(productId: product.id))),
                  onAddToCart: () => _addToCart(ctx, product),
                );
              },
              childCount: pp.products.length,
            ),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: cols,
              childAspectRatio: 0.68,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
          );
        },
      ),
    );
  }

  Future<void> _addToCart(BuildContext context, Product product) async {
    final userId = auth.user?.id;
    if (userId == null) return;
    final ok = await cart.addToCart(userId, product.id, 1);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ok ? '${product.name} added to cart!' : 'Failed to add'),
      duration: const Duration(seconds: 2),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ));
  }
}