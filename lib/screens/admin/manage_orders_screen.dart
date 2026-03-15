import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/order_provider.dart';
import '../../models/order.dart';

class ManageOrdersScreen extends StatefulWidget {
  const ManageOrdersScreen({super.key});

  @override
  State<ManageOrdersScreen> createState() => _ManageOrdersScreenState();
}

class _ManageOrdersScreenState extends State<ManageOrdersScreen> {
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrderProvider>().fetchOrders();
    });
  }

  static const _filters = ['all', 'pending', 'preparing', 'shipping', 'delivered'];

  @override
  Widget build(BuildContext context) {
    final op = context.watch<OrderProvider>();
    final orders = _filter == 'all'
        ? op.orders
        : op.orders.where((o) => o.status == _filter).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Orders'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => op.fetchOrders(),
          ),
        ],
      ),
      body: Column(children: [
        // Filter tabs
        SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            children: _filters.map((f) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(f == 'all' ? 'All' : f.toUpperCase(),
                    style: const TextStyle(fontSize: 12)),
                selected: _filter == f,
                onSelected: (_) => setState(() => _filter = f),
              ),
            )).toList(),
          ),
        ),
        // Orders list
        Expanded(
          child: op.loading
              ? const Center(child: CircularProgressIndicator())
              : orders.isEmpty
                  ? Center(
                      child: Text(
                          _filter == 'all' ? 'No orders yet' : 'No $_filter orders',
                          style: const TextStyle(color: Colors.grey, fontSize: 16)))
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: orders.length,
                      itemBuilder: (ctx, i) =>
                          _OrderCard(order: orders[i], op: op),
                    ),
        ),
      ]),
    );
  }
}

class _OrderCard extends StatefulWidget {
  final Order order;
  final OrderProvider op;
  const _OrderCard({required this.order, required this.op});

  @override
  State<_OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<_OrderCard> {
  bool _updating = false;

  // Next status in the flow
  static const _flow = ['pending', 'preparing', 'shipping', 'delivered'];

  String? get _nextStatus {
    final idx = _flow.indexOf(widget.order.status);
    if (idx == -1 || idx == _flow.length - 1) return null;
    return _flow[idx + 1];
  }

  String _nextLabel(String next) => switch (next) {
        'preparing' => 'Confirm & Prepare',
        'shipping'  => 'Confirm & Ship',
        'delivered' => 'Confirm Delivered',
        _           => 'Confirm',
      };

  Color _nextColor(String next) => switch (next) {
        'preparing' => Colors.blue,
        'shipping'  => Colors.purple,
        'delivered' => Colors.green,
        _           => Colors.orange,
      };

  Future<void> _confirm(String next) async {
    setState(() => _updating = true);
    await widget.op.updateOrderStatus(widget.order.id, next);
    if (mounted) setState(() => _updating = false);
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final next  = _nextStatus;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        title: Row(children: [
          Expanded(
            child: Text('Order #${order.id}  •  ${order.customerName ?? 'Customer'}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          ),
          _statusBadge(order.status),
        ]),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(
              '\$${order.totalAmount.toStringAsFixed(2)}  •  ${_fmt(order.createdAt)}',
              style: const TextStyle(fontSize: 12)),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Divider(),

              // Order items
              ...order.items.map((item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                              child: Text('${item.productName}  x${item.quantity}',
                                  style: const TextStyle(fontSize: 13))),
                          Text('\$${item.subtotal.toStringAsFixed(2)}',
                              style: const TextStyle(fontWeight: FontWeight.w600)),
                        ]),
                  )),

              const Divider(),

              // Total
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('Total',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Text('\$${order.totalAmount.toStringAsFixed(2)}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15)),
              ]),
              const SizedBox(height: 6),

              // Shipping address
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Icon(Icons.location_on_outlined, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(
                    child: Text(order.shippingAddress,
                        style: const TextStyle(color: Colors.grey, fontSize: 13))),
              ]),

              const SizedBox(height: 16),

              // Status progress
              _StatusProgress(currentStatus: order.status),

              const SizedBox(height: 16),

              // Confirm button (next step)
              if (next != null)
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _nextColor(next),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: _updating
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.check_circle_outline, size: 20),
                    label: Text(_nextLabel(next),
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14)),
                    onPressed: _updating ? null : () => _confirm(next),
                  ),
                )
              else
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle, color: Colors.green, size: 20),
                        SizedBox(width: 8),
                        Text('Order Completed',
                            style: TextStyle(
                                color: Colors.green, fontWeight: FontWeight.bold)),
                      ]),
                ),
            ]),
          ),
        ],
      ),
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
      return DateFormat('MMM d, yyyy').format(DateTime.parse(raw));
    } catch (_) {
      return raw;
    }
  }
}

class _StatusProgress extends StatelessWidget {
  final String currentStatus;
  const _StatusProgress({required this.currentStatus});

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
          // Connector line
          final stepIdx = i ~/ 2;
          final done    = stepIdx < currentIdx;
          return Expanded(
            child: Container(
              height: 2,
              color: done ? Colors.indigo : Colors.grey[300],
            ),
          );
        }
        final stepIdx = i ~/ 2;
        final step    = _steps[stepIdx];
        final isDone  = stepIdx <= currentIdx;
        final color   = isDone ? Colors.indigo : Colors.grey[400]!;
        return Column(mainAxisSize: MainAxisSize.min, children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: isDone
                ? Colors.indigo.withValues(alpha: 0.15)
                : Colors.grey[200],
            child: Icon(step.$3, size: 16, color: color),
          ),
          const SizedBox(height: 4),
          Text(step.$2,
              style: TextStyle(
                  fontSize: 9, color: color, fontWeight: FontWeight.w600)),
        ]);
      }),
    );
  }
}
