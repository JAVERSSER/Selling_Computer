import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import '../../models/product.dart';
import '../../providers/product_provider.dart';

class AddEditProductScreen extends StatefulWidget {
  final Product? product;
  const AddEditProductScreen({super.key, this.product});

  @override
  State<AddEditProductScreen> createState() => _AddEditProductScreenState();
}

class _AddEditProductScreenState extends State<AddEditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _stockCtrl = TextEditingController();
  int? _categoryId;
  Uint8List? _imageBytes;
  String? _imageName;
  bool _saving = false;

  bool get _isEdit => widget.product != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      final p = widget.product!;
      _nameCtrl.text  = p.name;
      _descCtrl.text  = p.description;
      _priceCtrl.text = p.price.toString();
      _stockCtrl.text = p.stock.toString();
      _categoryId     = p.categoryId;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _stockCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final file =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (file != null) {
      final bytes = await file.readAsBytes();
      setState(() {
        _imageBytes = bytes;
        _imageName  = file.name;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_categoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a category')));
      return;
    }
    setState(() => _saving = true);
    final pp = context.read<ProductProvider>();
    final fields = {
      'name':        _nameCtrl.text.trim(),
      'description': _descCtrl.text.trim(),
      'price':       _priceCtrl.text.trim(),
      'stock':       _stockCtrl.text.trim(),
      'category_id': _categoryId.toString(),
    };
    bool ok;
    if (_isEdit) {
      ok = await pp.updateProduct(
        id:         widget.product!.id,
        fields:     fields,
        imageBytes: _imageBytes,
        imageName:  _imageName,
      );
    } else {
      ok = await pp.createProduct(
        fields:     fields,
        imageBytes: _imageBytes,
        imageName:  _imageName,
      );
    }
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_isEdit ? 'Product updated!' : 'Product created!')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save product. Check connection.')));
    }
  }

  // Show picked image or existing base64 image
  Widget _buildImagePicker() {
    Widget imageWidget;

    if (_imageBytes != null) {
      // Newly picked image
      imageWidget = Image.memory(_imageBytes!, fit: BoxFit.cover);
    } else if (_isEdit &&
        widget.product!.image != null &&
        widget.product!.image!.startsWith('data:')) {
      // Existing base64 image from database
      try {
        final base64Str = widget.product!.image!.split(',').last;
        final bytes     = base64Decode(base64Str);
        imageWidget     = Image.memory(bytes, fit: BoxFit.cover);
      } catch (_) {
        imageWidget = _imagePlaceholder();
      }
    } else {
      imageWidget = _imagePlaceholder();
    }

    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
          color: Colors.grey[50],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            fit: StackFit.expand,
            children: [
              imageWidget,
              Positioned(
                bottom: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.camera_alt, color: Colors.white, size: 16),
                    SizedBox(width: 4),
                    Text('Change Image',
                        style: TextStyle(color: Colors.white, fontSize: 12)),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _imagePlaceholder() => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.add_photo_alternate_outlined, size: 52, color: Colors.grey),
          SizedBox(height: 8),
          Text('Tap to select image', style: TextStyle(color: Colors.grey)),
        ],
      );

  @override
  Widget build(BuildContext context) {
    final cats = context.watch<ProductProvider>().categories;
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Edit Product' : 'Add Product')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Form(
              key: _formKey,
              child: Column(children: [
                _buildImagePicker(),
                const SizedBox(height: 20),
                _field(_nameCtrl, 'Product Name',
                    validator: (v) => v!.isEmpty ? 'Required' : null),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _descCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                      labelText: 'Description', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 14),
                Row(children: [
                  Expanded(
                      child: _field(_priceCtrl, 'Price (\$)',
                          type: TextInputType.number,
                          validator: (v) =>
                              double.tryParse(v!) == null ? 'Invalid price' : null)),
                  const SizedBox(width: 12),
                  Expanded(
                      child: _field(_stockCtrl, 'Stock',
                          type: TextInputType.number,
                          validator: (v) =>
                              int.tryParse(v!) == null ? 'Invalid stock' : null)),
                ]),
                const SizedBox(height: 14),
                DropdownButtonFormField<int>(
                  initialValue: _categoryId,
                  decoration: const InputDecoration(
                      labelText: 'Category', border: OutlineInputBorder()),
                  items: cats
                      .map((c) =>
                          DropdownMenuItem(value: c.id, child: Text(c.name)))
                      .toList(),
                  onChanged: (v) => setState(() => _categoryId = v),
                  validator: (v) => v == null ? 'Select a category' : null,
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : Text(_isEdit ? 'Update Product' : 'Add Product',
                            style: const TextStyle(fontSize: 16)),
                  ),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label,
          {TextInputType type = TextInputType.text,
          String? Function(String?)? validator}) =>
      TextFormField(
        controller: ctrl,
        keyboardType: type,
        decoration: InputDecoration(
            labelText: label, border: const OutlineInputBorder()),
        validator: validator,
      );
}
