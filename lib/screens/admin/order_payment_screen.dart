import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/order_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/product_image.dart';

class OrderPaymentScreen extends StatefulWidget {
  final Map<String, dynamic> orderData;
  const OrderPaymentScreen({super.key, required this.orderData});

  @override
  State<OrderPaymentScreen> createState() => _OrderPaymentScreenState();
}

class _OrderPaymentScreenState extends State<OrderPaymentScreen> {
  Map<String, dynamic>? _fullOrder;
  bool _loading = true;
  bool _updating = false;
  late String _status;

  static const _flow = ['pending', 'preparing', 'shipping', 'delivered'];

  @override
  void initState() {
    super.initState();
    _status = widget.orderData['status'] ?? 'pending';
    _fetchFullOrder();
  }

  Future<void> _fetchFullOrder() async {
    final id = widget.orderData['id'];
    try {
      final res = await ApiService().get('orders/read_one.php?id=$id');
      if (res['success'] == true) {
        final data = res['data'] as Map<String, dynamic>;
        if (mounted) {
          setState(() {
            _fullOrder = data;
            _status    = data['status'] ?? _status;
            _loading   = false;
          });
        }
      } else {
        // fallback: use basic data with empty items
        if (mounted) {
          setState(() {
            _fullOrder = {...widget.orderData, 'items': []};
            _loading   = false;
          });
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _fullOrder = {...widget.orderData, 'items': []};
          _loading   = false;
        });
      }
    }
  }

  String? get _nextStatus {
    final idx = _flow.indexOf(_status);
    if (idx == -1 || idx == _flow.length - 1) return null;
    return _flow[idx + 1];
  }

  Future<void> _confirm(String next) async {
    setState(() => _updating = true);
    final id = int.parse(widget.orderData['id'].toString());
    await context.read<OrderProvider>().updateOrderStatus(id, next);
    if (mounted) {
      setState(() {
        _status   = next;
        _updating = false;
        if (_fullOrder != null) _fullOrder!['status'] = next;
      });
    }
  }

  Color _statusColor(String s) => switch (s) {
        'pending'   => Colors.orange,
        'preparing' => Colors.blue,
        'shipping'  => Colors.purple,
        'delivered' => Colors.green,
        _           => Colors.grey,
      };

  String _statusLabel(String s) => switch (s) {
        'pending'   => 'Awaiting Payment Confirmation',
        'preparing' => 'Payment Confirmed — Preparing',
        'shipping'  => 'Shipped — Out for Delivery',
        'delivered' => 'Delivered & Payment Complete',
        _           => s,
      };

  String _confirmLabel(String next) => switch (next) {
        'preparing' => 'Confirm Payment & Prepare Order',
        'shipping'  => 'Confirm Shipped',
        'delivered' => 'Confirm Delivered',
        _           => 'Confirm',
      };

  Color _confirmColor(String next) => switch (next) {
        'preparing' => Colors.green,
        'shipping'  => Colors.purple,
        'delivered' => const Color(0xFF1A237E),
        _           => Colors.orange,
      };

  @override
  Widget build(BuildContext context) {
    final orderId = widget.orderData['id'];
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: Text('Order #$orderId — Payment'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(),
    );
  }

  Widget _buildBody() {
    final o     = _fullOrder!;
    final total = double.parse(o['total_amount'].toString());
    final items = (o['items'] as List?) ?? [];
    final next  = _nextStatus;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(children: [

        // ── Status card ──────────────────────────────────────────────
        _card(Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Order Status',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            _badge(_status),
          ]),
          const SizedBox(height: 16),
          _StatusBar(currentStatus: _status),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: _statusColor(_status).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: _statusColor(_status).withValues(alpha: 0.25)),
            ),
            child: Row(children: [
              Icon(_statusIcon(_status),
                  color: _statusColor(_status), size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(_statusLabel(_status),
                    style: TextStyle(
                        color: _statusColor(_status),
                        fontWeight: FontWeight.w600,
                        fontSize: 13)),
              ),
            ]),
          ),
        ])),

        const SizedBox(height: 12),

        // ── Payment summary ──────────────────────────────────────────
        _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Payment Summary',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 14),
          _row(Icons.payment_outlined, 'Method', 'Cash on Delivery'),
          const Divider(height: 20),
          _row(
            _status == 'delivered'
                ? Icons.check_circle
                : Icons.radio_button_unchecked,
            'Payment',
            _status == 'delivered' ? 'PAID' : 'PENDING',
            valueColor:
                _status == 'delivered' ? Colors.green : Colors.orange,
            bold: true,
          ),
          const Divider(height: 20),
          _row(
            Icons.attach_money,
            'Total',
            '\$${total.toStringAsFixed(2)}',
            valueColor: const Color(0xFF1A237E),
            bold: true,
            size: 18,
          ),
        ])),

        const SizedBox(height: 12),

        // ── Customer info ────────────────────────────────────────────
        _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Customer Information',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 14),
          _row(Icons.person_outline, 'Name', o['customer_name'] ?? '-'),
          const Divider(height: 20),
          _row(Icons.email_outlined, 'Email', o['customer_email'] ?? '-'),
          if ((o['customer_phone'] ?? '').toString().isNotEmpty) ...[
            const Divider(height: 20),
            _row(Icons.phone_outlined, 'Phone',
                o['customer_phone'].toString()),
          ],
          const Divider(height: 20),
          _row(Icons.location_on_outlined, 'Address',
              o['shipping_address'] ?? '-'),
          const Divider(height: 20),
          _row(Icons.access_time_outlined, 'Date',
              _fmt(o['created_at'] ?? '')),
        ])),

        const SizedBox(height: 12),

        // ── Order items ──────────────────────────────────────────────
        _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Order Items (${items.length})',
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 12),
          if (items.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('No items found',
                    style: TextStyle(color: Colors.grey)),
              ),
            )
          else
            ...items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        width: 54,
                        height: 54,
                        child: ProductImage(
                            image: item['image'],
                            fit: BoxFit.cover,
                            iconSize: 22),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item['product_name'] ?? '',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 2),
                            Text(
                                'Qty: ${item['quantity']}  •  \$${double.parse(item['price'].toString()).toStringAsFixed(2)} each',
                                style: const TextStyle(
                                    color: Colors.grey, fontSize: 12)),
                          ]),
                    ),
                    Text(
                      '\$${(double.parse(item['price'].toString()) * int.parse(item['quantity'].toString())).toStringAsFixed(2)}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A237E),
                          fontSize: 14),
                    ),
                  ]),
                )),
          const Divider(),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Total',
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 15)),
            Text('\$${total.toStringAsFixed(2)}',
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Color(0xFF1A237E))),
          ]),
        ])),

        const SizedBox(height: 20),

        // ── Confirm button ───────────────────────────────────────────
        if (next != null)
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: _confirmColor(next),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 3,
              ),
              icon: _updating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.check_circle_outline, size: 22),
              label: Text(_confirmLabel(next),
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.bold)),
              onPressed: _updating ? null : () => _confirm(next),
            ),
          )
        else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 24),
                  SizedBox(width: 10),
                  Text('Order Complete — Payment Received',
                      style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                          fontSize: 15)),
                ]),
          ),

        const SizedBox(height: 24),
      ]),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Widget _card(Widget child) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 8,
                offset: const Offset(0, 2)),
          ],
        ),
        child: child,
      );

  Widget _badge(String status) {
    final c = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
          color: c.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20)),
      child: Text(status.toUpperCase(),
          style: TextStyle(
              color: c,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5)),
    );
  }

  Widget _row(IconData icon, String label, String value,
      {Color? valueColor,
      bool bold = false,
      double size = 13}) =>
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 18, color: Colors.grey[500]),
        const SizedBox(width: 10),
        SizedBox(
          width: 80,
          child: Text(label,
              style: TextStyle(color: Colors.grey[600], fontSize: 13)),
        ),
        Expanded(
          child: Text(value,
              style: TextStyle(
                  fontSize: size,
                  fontWeight: bold ? FontWeight.bold : FontWeight.w500,
                  color: valueColor ?? Colors.black87)),
        ),
      ]);

  IconData _statusIcon(String s) => switch (s) {
        'pending'   => Icons.hourglass_empty,
        'preparing' => Icons.build_outlined,
        'shipping'  => Icons.local_shipping_outlined,
        'delivered' => Icons.check_circle_outline,
        _           => Icons.info_outline,
      };

  String _fmt(String raw) {
    try {
      return DateFormat('MMM d, yyyy  h:mm a').format(DateTime.parse(raw));
    } catch (_) {
      return raw;
    }
  }
}

// ── Status progress bar ───────────────────────────────────────────────────────

class _StatusBar extends StatelessWidget {
  final String currentStatus;
  const _StatusBar({required this.currentStatus});

  static const _steps = [
    ('pending',   'Pending',   Icons.hourglass_empty),
    ('preparing', 'Preparing', Icons.build_outlined),
    ('shipping',  'Shipping',  Icons.local_shipping_outlined),
    ('delivered', 'Delivered', Icons.check_circle_outline),
  ];

  @override
  Widget build(BuildContext context) {
    final idx = _steps.indexWhere((s) => s.$1 == currentStatus);
    return Row(
      children: List.generate(_steps.length * 2 - 1, (i) {
        if (i.isOdd) {
          final done = (i ~/ 2) < idx;
          return Expanded(
            child: Container(
                height: 2,
                color: done
                    ? const Color(0xFF1A237E)
                    : Colors.grey[300]),
          );
        }
        final si   = i ~/ 2;
        final done = si <= idx;
        final c    = done ? const Color(0xFF1A237E) : Colors.grey[400]!;
        return Column(mainAxisSize: MainAxisSize.min, children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: done
                ? const Color(0xFF1A237E).withValues(alpha: 0.15)
                : Colors.grey[200],
            child: Icon(_steps[si].$3, size: 15, color: c),
          ),
          const SizedBox(height: 4),
          Text(_steps[si].$2,
              style: TextStyle(
                  fontSize: 9,
                  color: c,
                  fontWeight: FontWeight.w600)),
        ]);
      }),
    );
  }
}
