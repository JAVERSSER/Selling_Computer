import 'dart:convert';
import 'package:flutter/material.dart';

class ProductImage extends StatelessWidget {
  final String? image;
  final String? categoryName;
  final double? width;
  final double? height;
  final BoxFit fit;
  final double iconSize;

  const ProductImage({
    super.key,
    required this.image,
    this.categoryName,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.iconSize = 52,
  });

  @override
  Widget build(BuildContext context) {
    if (image != null && image!.contains(',')) {
      try {
        final bytes = base64Decode(image!.split(',').last.trim());
        return SizedBox(
          width: width,
          height: height,
          child: Image.memory(
            bytes,
            fit: fit,
            width: width,
            height: height,
            errorBuilder: (ctx, err, stack) => _placeholder(),
          ),
        );
      } catch (_) {}
    }
    return _placeholder();
  }

  Widget _placeholder() {
    final info = _categoryInfo(categoryName);
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            info.color.withValues(alpha: 0.12),
            info.color.withValues(alpha: 0.25),
          ],
        ),
      ),
      child: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(info.icon, size: iconSize, color: info.color.withValues(alpha: 0.7)),
          if (iconSize > 36) ...[
            const SizedBox(height: 8),
            Text(
              info.label,
              style: TextStyle(
                fontSize: 11,
                color: info.color.withValues(alpha: 0.8),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ]),
      ),
    );
  }

  static _CategoryInfo _categoryInfo(String? name) {
    final n = (name ?? '').toLowerCase();
    if (n.contains('laptop')) {
      return _CategoryInfo(Icons.laptop_mac, Colors.indigo, 'Laptop');
    }
    if (n.contains('desktop')) {
      return _CategoryInfo(Icons.desktop_windows, Colors.blue, 'Desktop');
    }
    if (n.contains('monitor')) {
      return _CategoryInfo(Icons.monitor, Colors.teal, 'Monitor');
    }
    if (n.contains('component')) {
      return _CategoryInfo(Icons.memory, Colors.purple, 'Component');
    }
    if (n.contains('peripher')) {
      return _CategoryInfo(Icons.keyboard, Colors.orange, 'Peripheral');
    }
    if (n.contains('mouse')) {
      return _CategoryInfo(Icons.mouse, Colors.cyan, 'Mouse');
    }
    if (n.contains('keyboard')) {
      return _CategoryInfo(Icons.keyboard, Colors.green, 'Keyboard');
    }
    if (n.contains('printer')) {
      return _CategoryInfo(Icons.print, Colors.brown, 'Printer');
    }
    if (n.contains('storage') || n.contains('ssd') || n.contains('hdd')) {
      return _CategoryInfo(Icons.storage, Colors.blueGrey, 'Storage');
    }
    return _CategoryInfo(Icons.computer, Colors.indigo, 'Computer');
  }
}

class _CategoryInfo {
  final IconData icon;
  final Color color;
  final String label;
  const _CategoryInfo(this.icon, this.color, this.label);
}