import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/product_provider.dart';
import '../../models/category.dart';

class ManageCategoriesScreen extends StatefulWidget {
  const ManageCategoriesScreen({super.key});

  @override
  State<ManageCategoriesScreen> createState() => _ManageCategoriesScreenState();
}

class _ManageCategoriesScreenState extends State<ManageCategoriesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().fetchCategories();
    });
  }

  // ── Category icons map ────────────────────────────────────────────────────
  IconData _icon(String name) {
    final n = name.toLowerCase();
    if (n.contains('laptop'))    return Icons.laptop_mac;
    if (n.contains('desktop'))   return Icons.desktop_windows;
    if (n.contains('monitor'))   return Icons.monitor;
    if (n.contains('component')) return Icons.memory;
    if (n.contains('peripher'))  return Icons.keyboard;
    if (n.contains('storage') || n.contains('ssd') || n.contains('hdd')) {
      return Icons.storage;
    }
    if (n.contains('network'))   return Icons.router_outlined;
    if (n.contains('printer'))   return Icons.print;
    if (n.contains('mouse'))     return Icons.mouse;
    return Icons.category_outlined;
  }

  Color _color(String name) {
    final n = name.toLowerCase();
    if (n.contains('laptop'))    return Colors.indigo;
    if (n.contains('desktop'))   return Colors.blue;
    if (n.contains('monitor'))   return Colors.teal;
    if (n.contains('component')) return Colors.purple;
    if (n.contains('peripher'))  return Colors.orange;
    if (n.contains('storage'))   return Colors.blueGrey;
    if (n.contains('network'))   return Colors.cyan;
    return const Color(0xFF1A237E);
  }

  // ── Add category dialog ───────────────────────────────────────────────────
  void _showAddDialog() {
    final ctrl    = TextEditingController();
    bool  adding  = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          title: const Row(children: [
            Icon(Icons.add_circle_outline,
                color: Color(0xFF1A237E), size: 24),
            SizedBox(width: 8),
            Text('Add Category'),
          ]),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('Enter a name for the new category:',
                style: TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 14),
            TextField(
              controller: ctrl,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                hintText: 'e.g. Gaming Chairs',
                prefixIcon: const Icon(Icons.category_outlined),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                      color: Color(0xFF1A237E), width: 2),
                ),
              ),
              onSubmitted: (_) async {
                final name = ctrl.text.trim();
                if (name.isEmpty) return;
                setS(() => adding = true);
                final ok = await context
                    .read<ProductProvider>()
                    .createCategory(name);
                if (ctx.mounted) Navigator.pop(ctx);
                if (!ok && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Failed — category may already exist'),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                  ));
                }
              },
            ),
          ]),
          actions: [
            TextButton(
              onPressed: adding ? null : () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              icon: adding
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.add, size: 18),
              label: const Text('Add'),
              onPressed: adding
                  ? null
                  : () async {
                      final name = ctrl.text.trim();
                      if (name.isEmpty) return;
                      setS(() => adding = true);
                      final ok = await context
                          .read<ProductProvider>()
                          .createCategory(name);
                      if (ctx.mounted) Navigator.pop(ctx);
                      if (!ok && mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content:
                              Text('Failed — category may already exist'),
                          backgroundColor: Colors.red,
                          behavior: SnackBarBehavior.floating,
                        ));
                      }
                    },
            ),
          ],
        ),
      ),
    );
  }

  // ── Delete confirm ────────────────────────────────────────────────────────
  void _confirmDelete(ProductProvider pp, Category cat) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Row(children: [
          Icon(Icons.warning_amber_rounded, color: Colors.red),
          SizedBox(width: 8),
          Text('Delete Category'),
        ]),
        content: RichText(
          text: TextSpan(
            style: const TextStyle(color: Colors.black87, fontSize: 14),
            children: [
              const TextSpan(text: 'Delete '),
              TextSpan(
                  text: '"${cat.name}"',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const TextSpan(
                  text:
                      '?\n\nProducts in this category will NOT be deleted, but will lose their category.'),
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
              pp.deleteCategory(cat.id);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pp   = context.watch<ProductProvider>();
    final cats = pp.categories;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text('Manage Categories'),
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
              label: const Text('Add Category'),
              onPressed: _showAddDialog,
            ),
          ),
        ],
      ),
      body: cats.isEmpty
          ? _emptyState()
          : Column(children: [
              // Counter bar
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 12),
                color: Colors.white,
                child: Text(
                  '${cats.length} categor${cats.length == 1 ? 'y' : 'ies'}',
                  style: TextStyle(
                      color: Colors.grey[600], fontSize: 13),
                ),
              ),
              // List
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: cats.length,
                  itemBuilder: (ctx, i) {
                    final cat   = cats[i];
                    final color = _color(cat.name);
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        leading: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(_icon(cat.name),
                              color: color, size: 22),
                        ),
                        title: Text(cat.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15)),
                        subtitle: Text('ID: ${cat.id}',
                            style: const TextStyle(
                                fontSize: 11, color: Colors.grey)),
                        trailing: GestureDetector(
                          onTap: () => _confirmDelete(pp, cat),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.delete_outline,
                                color: Colors.red, size: 18),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ]),

      // FAB — quick add
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddDialog,
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Category',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _emptyState() => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.category_outlined,
                size: 44, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          const Text('No categories yet',
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Add your first category to organize products',
              style: TextStyle(color: Colors.grey[600])),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showAddDialog,
            icon: const Icon(Icons.add),
            label: const Text('Add First Category'),
          ),
        ]),
      );
}
