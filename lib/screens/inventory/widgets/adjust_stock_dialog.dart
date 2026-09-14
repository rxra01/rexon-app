import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/constants.dart';
import '../../../core/theme.dart';
import '../../../data/models/product.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/retail_provider.dart';

class AdjustStockDialog extends StatefulWidget {
  final Product product;

  const AdjustStockDialog({super.key, required this.product});

  static Future<void> show(BuildContext context, Product product) {
    return showDialog(
      context: context,
      builder: (ctx) => AdjustStockDialog(product: product),
    );
  }

  @override
  State<AdjustStockDialog> createState() => _AdjustStockDialogState();
}

class _AdjustStockDialogState extends State<AdjustStockDialog> {
  final _qtyController = TextEditingController(text: '1');
  bool _isAddition = true;
  String _selectedReason = AppConstants.adjustmentReasons.first;
  bool _isProcessing = false;

  @override
  void dispose() {
    _qtyController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final qty = int.tryParse(_qtyController.text.trim()) ?? 0;
    if (qty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid quantity > 0')),
      );
      return;
    }

    final delta = _isAddition ? qty : -qty;

    setState(() => _isProcessing = true);
    final auth = context.read<AuthProvider>();
    final retail = context.read<RetailProvider>();

    try {
      await retail.adjustStock(
        productId: widget.product.id,
        quantityDelta: delta,
        reason: _selectedReason,
        createdBy: auth.currentUserId ?? 'owner',
      );

      if (!mounted) return;
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Stock adjusted for ${widget.product.name}: ${_isAddition ? "+" : ""}$delta ${widget.product.unit}',
          ),
          backgroundColor: AppTheme.tertiaryEmerald,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Adjustment failed: $e'), backgroundColor: AppTheme.crimsonError),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final qty = int.tryParse(_qtyController.text.trim()) ?? 0;
    final finalStock = _isAddition
        ? widget.product.currentStock + qty
        : (widget.product.currentStock - qty).clamp(0, 999999);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.tune_rounded, color: AppTheme.secondaryBlue, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Adjust Stock',
                  style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                Text(
                  widget.product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.manrope(fontSize: 12, color: AppTheme.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Current stock readout
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Current Stock:', style: GoogleFonts.manrope(fontSize: 13, color: AppTheme.textMuted)),
                  Text(
                    '${widget.product.currentStock} ${widget.product.unit}',
                    style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textDark),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Mode Toggle: Add vs Deduct
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _isAddition = true),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _isAddition ? AppTheme.emeraldLight : AppTheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _isAddition ? AppTheme.emeraldBorder : Colors.transparent,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_circle_outline_rounded,
                              size: 16, color: _isAddition ? AppTheme.emeraldText : AppTheme.textMuted),
                          const SizedBox(width: 6),
                          Text(
                            'Add Stock (+)',
                            style: GoogleFonts.manrope(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: _isAddition ? AppTheme.emeraldText : AppTheme.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _isAddition = false),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: !_isAddition ? AppTheme.crimsonLight : AppTheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: !_isAddition ? AppTheme.crimsonBorder : Colors.transparent,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.remove_circle_outline_rounded,
                              size: 16, color: !_isAddition ? AppTheme.crimsonText : AppTheme.textMuted),
                          const SizedBox(width: 6),
                          Text(
                            'Deduct (-)',
                            style: GoogleFonts.manrope(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: !_isAddition ? AppTheme.crimsonText : AppTheme.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Quantity Input
            Text(
              'Quantity to ${_isAddition ? "Add" : "Deduct"} (${widget.product.unit}) *',
              style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _qtyController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                prefixIcon: Icon(
                  _isAddition ? Icons.add_rounded : Icons.remove_rounded,
                  color: _isAddition ? AppTheme.emeraldText : AppTheme.crimsonText,
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),

            // Mandatory Reason Dropdown (Adhering to PRD §6.3: "required for adjustment")
            Text(
              'Mandatory Reason for Audit Trail *',
              style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              value: _selectedReason,
              isExpanded: true,
              decoration: const InputDecoration(),
              items: AppConstants.adjustmentReasons.map((r) {
                return DropdownMenuItem(value: r, child: Text(r, style: GoogleFonts.manrope(fontSize: 13)));
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedReason = val);
              },
            ),
            const SizedBox(height: 16),

            // Projected New Stock
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.borderSlate),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Projected New Stock:', style: GoogleFonts.manrope(fontSize: 12, color: AppTheme.textMuted)),
                  Text(
                    '$finalStock ${widget.product.unit}',
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: finalStock <= widget.product.minStockLevel
                          ? AppTheme.amberWarning
                          : AppTheme.secondaryBlue,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isProcessing ? null : () => Navigator.of(context).pop(),
          child: Text('Cancel', style: GoogleFonts.manrope(color: AppTheme.textMuted)),
        ),
        ElevatedButton(
          onPressed: _isProcessing ? null : _handleSave,
          style: ElevatedButton.styleFrom(
            backgroundColor: _isAddition ? AppTheme.secondaryBlue : AppTheme.crimsonError,
            foregroundColor: Colors.white,
          ),
          child: _isProcessing
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Save Adjustment'),
        ),
      ],
    );
  }
}
