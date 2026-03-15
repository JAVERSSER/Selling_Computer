import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';
import '../../models/order.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final userId = context.read<AuthProvider>().user?.id;
    if (userId != null) {
      await context.read<OrderProvider>().fetchOrders(userId: userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final op = context.watch<OrderProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Orders'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: op.loading
          ? const Center(child: CircularProgressIndicator())
          : op.orders.isEmpty
              ? Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.receipt_long_outlined,
                      size: 80, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('No orders yet',
                      style: TextStyle(fontSize: 18, color: Colors.grey)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Start Shopping')),
                ]))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: op.orders.length,
                    itemBuilder: (ctx, i) =>
                        _OrderCard(order: op.orders[i]),
                  ),
                ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Order order;
  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.07),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          ),
          child: Row(children: [
            Expanded(
              child: Text('Order #${order.id}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 15)),
            ),
            _statusBadge(order.status),
          ]),
        ),

        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Status progress tracker
            _StatusTracker(currentStatus: order.status),
            const SizedBox(height: 16),

            // Items
            const Text('Items',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 8),
            ...order.items.map((item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                            child: Text('${item.productName}  ×${item.quantity}',
                                style: const TextStyle(fontSize: 13))),
                        Text('\$${item.subtotal.toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.w600)),
                      ]),
                )),

            const Divider(height: 20),

            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Total',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Text('\$${order.totalAmount.toStringAsFixed(2)}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.indigo)),
            ]),

            const SizedBox(height: 8),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.location_on_outlined,
                  size: 15, color: Colors.grey),
              const SizedBox(width: 4),
              Expanded(
                  child: Text(order.shippingAddress,
                      style:
                          const TextStyle(color: Colors.grey, fontSize: 13))),
            ]),
            const SizedBox(height: 4),
            Row(children: [
              const Icon(Icons.access_time, size: 13, color: Colors.grey),
              const SizedBox(width: 4),
              Text(_fmt(order.createdAt),
                  style:
                      const TextStyle(color: Colors.grey, fontSize: 12)),
            ]),
          ]),
        ),
      ]),
    );
  }

  Widget _statusBadge(String status) {
    final color = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12)),
      child: Text(status.toUpperCase(),
          style: TextStyle(
              color: color, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }

  Color _statusColor(String s) => switch (s) {
        'pending'   => Colors.orange,
        'preparing' => Colors.blue,
        'shipping'  => Colors.purple,
        'delivered' => Colors.green,
        _           => Colors.grey,
      };

  String _fmt(String raw) {
    try {
      return DateFormat('MMM d, yyyy – h:mm a').format(DateTime.parse(raw));
    } catch (_) {
      return raw;
    }
  }
}

class _StatusTracker extends StatelessWidget {
  final String currentStatus;
  const _StatusTracker({required this.currentStatus});

  static const _steps = [
    ('pending',   'Pending',   Icons.hourglass_empty),
    ('preparing', 'Preparing', Icons.build_outlined),
    ('shipping',  'Shipping',  Icons.local_shipping_outlined),
    ('delivered', 'Delivered', Icons.check_circle_outline),
  ];

  @override
  Widget build(BuildContext context) {
    final currentIdx = _steps.indexWhere((s) => s.$1 == currentStatus);
    return Row(
      children: List.generate(_steps.length * 2 - 1, (i) {
        if (i.isOdd) {
          final done = (i ~/ 2) < currentIdx;
          return Expanded(
            child: Container(
                height: 2,
                color: done ? Colors.indigo : Colors.grey[300]),
          );
        }
        final idx   = i ~/ 2;
        final step  = _steps[idx];
        final done  = idx <= currentIdx;
        final color = done ? Colors.indigo : Colors.grey[400]!;
        return Column(mainAxisSize: MainAxisSize.min, children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: done
                ? Colors.indigo.withValues(alpha: 0.15)
                : Colors.grey[200],
            child: Icon(step.$3, size: 16, color: color),
          ),
          const SizedBox(height: 4),
          Text(step.$2,
              style: TextStyle(
                  fontSize: 9,
                  color: color,
                  fontWeight: FontWeight.w600)),
        ]);
      }),
    );
  }
}