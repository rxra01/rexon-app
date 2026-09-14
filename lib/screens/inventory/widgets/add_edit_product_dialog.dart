import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants.dart';
import '../../../core/theme.dart';
import '../../../data/models/product.dart';
import '../../../providers/retail_provider.dart';

class AddEditProductDialog extends StatefulWidget {
  final Product? productToEdit;

  const AddEditProductDialog({super.key, this.productToEdit});

  static Future<void> show(BuildContext context, {Product? productToEdit}) {
    return showDialog(
      context: context,
      builder: (ctx) => AddEditProductDialog(productToEdit: productToEdit),
    );
  }

  @override
  State<AddEditProductDialog> createState() => _AddEditProductDialogState();
}

class _AddEditProductDialogState extends State<AddEditProductDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _skuController;
  late final TextEditingController _barcodeController;
  late final TextEditingController _purchasePriceController;
  late final TextEditingController _sellingPriceController;
  late final TextEditingController _stockController;
  late final TextEditingController _minStockController;

  late String _selectedCategory;
  late String _selectedUnit;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final p = widget.productToEdit;
    _nameController = TextEditingController(text: p?.name ?? '');
    _skuController = TextEditingController(text: p?.sku ?? '');
    _barcodeController = TextEditingController(text: p?.barcode ?? '');
    _purchasePriceController = TextEditingController(
      text: p != null ? p.purchasePrice.toStringAsFixed(0) : '',
    );
    _sellingPriceController = TextEditingController(
      text: p != null ? p.sellingPrice.toStringAsFixed(0) : '',
    );
    _stockController = TextEditingController(
      text: p != null ? p.currentStock.toString() : '10',
    );
    _minStockController = TextEditingController(
      text: p != null ? p.minStockLevel.toString() : '5',
    );

    _selectedCategory = p?.category ?? 'Electronics';
    if (!AppConstants.defaultCategories.contains(_selectedCategory) || _selectedCategory == 'All') {
      _selectedCategory = 'Electronics';
    }
    _selectedUnit = p?.unit ?? 'Piece';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _skuController.dispose();
    _barcodeController.dispose();
    _purchasePriceController.dispose();
    _sellingPriceController.dispose();
    _stockController.dispose();
    _minStockController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final retail = context.read<RetailProvider>();

    final cost = double.tryParse(_purchasePriceController.text.trim()) ?? 0.0;
    final sell = double.tryParse(_sellingPriceController.text.trim()) ?? 0.0;
    final stock = int.tryParse(_stockController.text.trim()) ?? 0;
    final minStock = int.tryParse(_minStockController.text.trim()) ?? 5;

    final isEdit = widget.productToEdit != null;

    try {
      if (isEdit) {
        final updated = widget.productToEdit!.copyWith(
          name: _nameController.text.trim(),
          sku: _skuController.text.trim().isNotEmpty
              ? _skuController.text.trim()
              : widget.productToEdit!.sku,
          barcode: _barcodeController.text.trim().isEmpty ? null : _barcodeController.text.trim(),
          category: _selectedCategory,
          unit: _selectedUnit,
          purchasePrice: cost,
          sellingPrice: sell,
          minStockLevel: minStock,
        );
        await retail.updateProduct(updated);
      } else {
        final newProd = Product(
          id: const Uuid().v4(),
          businessId: retail.businessId ?? '',
          name: _nameController.text.trim(),
          sku: _skuController.text.trim(),
          barcode: _barcodeController.text.trim().isEmpty ? null : _barcodeController.text.trim(),
          category: _selectedCategory,
          unit: _selectedUnit,
          purchasePrice: cost,
          sellingPrice: sell,
          currentStock: stock,
          minStockLevel: minStock,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await retail.addProduct(newProd);
      }

      if (!mounted) return;
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEdit ? 'Product updated successfully.' : 'Product added to catalogue.'),
          backgroundColor: AppTheme.tertiaryEmerald,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Save error: $e'), backgroundColor: AppTheme.crimsonError),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.productToEdit != null;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        isEdit ? 'Edit Product' : 'Add New Product',
        style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w700),
      ),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Name
                Text('Product Name *', style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(hintText: 'e.g. Wireless Mouse M185'),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 14),

                // Category & Unit Row
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Category', style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          DropdownButtonFormField<String>(
                            value: _selectedCategory,
                            isExpanded: true,
                            items: AppConstants.defaultCategories
                                .where((c) => c != 'All')
                                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                                .toList(),
                            onChanged: (v) => setState(() => _selectedCategory = v ?? 'Electronics'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Unit', style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          DropdownButtonFormField<String>(
                            value: _selectedUnit,
                            isExpanded: true,
                            items: AppConstants.units
                                .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                                .toList(),
                            onChanged: (v) => setState(() => _selectedUnit = v ?? 'Piece'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // SKU & Barcode
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('SKU (Optional)', style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          TextFormField(
                            controller: _skuController,
                            decoration: const InputDecoration(hintText: 'Auto-generated if blank'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Barcode (Optional)', style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          TextFormField(
                            controller: _barcodeController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(hintText: 'e.g. 890123...'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Purchase & Selling Price Row
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Cost / Purchase Price (₹) *', style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          TextFormField(
                            controller: _purchasePriceController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(hintText: '0.00'),
                            validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Selling Price (₹) *', style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          TextFormField(
                            controller: _sellingPriceController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(hintText: '0.00'),
                            validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Opening Stock & Min Stock Level
                Row(
                  children: [
                    if (!isEdit) ...[
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Opening Stock *', style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            TextFormField(
                              controller: _stockController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(hintText: '10'),
                              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Low Stock Alert Level *', style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          TextFormField(
                            controller: _minStockController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(hintText: '5'),
                            validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: Text('Cancel', style: GoogleFonts.manrope(color: AppTheme.textMuted)),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _handleSave,
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.secondaryBlue, foregroundColor: Colors.white),
          child: _isSaving
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Text(isEdit ? 'Save Changes' : 'Add Product'),
        ),
      ],
    );
  }
}
