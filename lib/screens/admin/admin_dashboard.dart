import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../auth/login_screen.dart';
import 'manage_products_screen.dart';
import 'manage_orders_screen.dart';
import 'manage_users_screen.dart';
import 'manage_categories_screen.dart';
import 'order_payment_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  Map<String, dynamic>? _stats;
  bool _loadingStats = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final res = await ApiService().get('dashboard/stats.php');
      if (res['success'] == true) {
        setState(() { _stats = res['data']; _loadingStats = false; });
      } else {
        setState(() => _loadingStats = false);
      }
    } catch (_) {
      setState(() => _loadingStats = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () { setState(() => _loadingStats = true); _loadStats(); },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await context.read<AuthProvider>().logout();
              if (!context.mounted) return;
              Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const LoginScreen()));
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Welcome
          Text('Welcome, ${user?.name ?? 'Admin'}',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          Text(user?.email ?? '', style: TextStyle(color: Colors.grey[600])),
          const SizedBox(height: 28),

          // Stats
          const Text('Overview',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          _loadingStats
              ? const Center(child: CircularProgressIndicator())
              : _buildStats(),

          const SizedBox(height: 28),

          // Management tiles
          const Text('Management',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          LayoutBuilder(builder: (context, constraints) {
            final cols = constraints.maxWidth > 700 ? 4 : 2;
            return GridView.count(
              crossAxisCount: cols,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _tile(context, 'Products', Icons.computer,
                    Colors.indigo, const ManageProductsScreen()),
                _tile(context, 'Categories', Icons.category_outlined,
                    Colors.teal, const ManageCategoriesScreen()),
                _tile(context, 'Orders', Icons.receipt_long_outlined,
                    Colors.orange, const ManageOrdersScreen()),
                _tile(context, 'Users', Icons.people_outlined,
                    Colors.purple, const ManageUsersScreen()),
              ],
            );
          }),

          // Recent orders
          if (_stats != null && (_stats!['recent_orders'] as List).isNotEmpty) ...[
            const SizedBox(height: 28),
            const Text('Recent Orders',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            _buildRecentOrders(),
          ],
        ]),
      ),
    );
  }

  Widget _buildStats() {
    if (_stats == null) {
      return const Text('Could not load stats', style: TextStyle(color: Colors.grey));
    }
    final items = [
      _StatData('Products', '${_stats!['total_products']}', Icons.computer, Colors.indigo),
      _StatData('Categories', '${_stats!['total_categories']}', Icons.category_outlined, Colors.teal),
      _StatData('Customers', '${_stats!['total_users']}', Icons.people_outlined, Colors.purple),
      _StatData('Total Orders', '${_stats!['total_orders']}', Icons.receipt_long_outlined, Colors.orange),
      _StatData('Revenue', '\$${((_stats!['total_revenue'] as num)).toStringAsFixed(2)}',
          Icons.attach_money, Colors.green),
      _StatData('Pending', '${_stats!['pending_orders']}', Icons.hourglass_empty, Colors.red),
    ];
    return LayoutBuilder(builder: (context, c) {
      final cols = c.maxWidth > 900 ? 6 : c.maxWidth > 600 ? 3 : 2;
      return GridView.count(
        crossAxisCount: cols,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.3,
        children: items.map((s) => _statCard(s)).toList(),
      );
    });
  }

  Widget _statCard(_StatData s) => Card(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(s.icon, color: s.color, size: 24),
            const SizedBox(height: 6),
            Text(s.value,
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold, color: s.color)),
            const SizedBox(height: 2),
            Text(s.label,
                style: const TextStyle(fontSize: 11, color: Colors.grey),
                textAlign: TextAlign.center),
          ]),
        ),
      );

  Widget _buildRecentOrders() {
    final orders = (_stats!['recent_orders'] as List);
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: orders.map((o) {
          final color = switch (o['status']) {
            'pending'   => Colors.orange,
            'preparing' => Colors.blue,
            'shipping'  => Colors.purple,
            'delivered' => Colors.green,
            _           => Colors.grey,
          };
          return ListTile(
            leading: CircleAvatar(
              radius: 18,
              backgroundColor: color.withValues(alpha: 0.15),
              child: Text('#${o['id']}',
                  style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold)),
            ),
            title: Text(o['customer_name'] ?? 'Customer',
                style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text('\$${double.parse(o['total_amount'].toString()).toStringAsFixed(2)}'),
            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10)),
                child: Text(o['status'].toString().toUpperCase(),
                    style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right, color: Colors.grey, size: 18),
            ]),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => OrderPaymentScreen(orderData: Map<String, dynamic>.from(o)),
              ),
            ).then((_) { setState(() => _loadingStats = true); _loadStats(); }),
          );
        }).toList(),
      ),
    );
  }

  Widget _tile(BuildContext context, String label, IconData icon, Color color, Widget screen) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => screen))
            .then((_) { setState(() => _loadingStats = true); _loadStats(); }),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          CircleAvatar(
              radius: 28,
              backgroundColor: color.withValues(alpha: 0.15),
              child: Icon(icon, color: color, size: 28)),
          const SizedBox(height: 12),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
        ]),
      ),
    );
  }
}

class _StatData {
  final String label, value;
  final IconData icon;
  final Color color;
  _StatData(this.label, this.value, this.icon, this.color);
}
