import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/theme.dart';
import '../../../data/models/sale.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/retail_provider.dart';

class VoidInvoiceDialog extends StatefulWidget {
  final Sale sale;

  const VoidInvoiceDialog({super.key, required this.sale});

  static Future<void> show(BuildContext context, Sale sale) {
    return showDialog(
      context: context,
      builder: (ctx) => VoidInvoiceDialog(sale: sale),
    );
  }

  @override
  State<VoidInvoiceDialog> createState() => _VoidInvoiceDialogState();
}

class _VoidInvoiceDialogState extends State<VoidInvoiceDialog> {
  final _reasonController = TextEditingController(text: 'Billing error / cancelled by customer');
  bool _isProcessing = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _handleVoid() async {
    if (_reasonController.text.trim().isEmpty) return;

    setState(() => _isProcessing = true);
    final auth = context.read<AuthProvider>();
    final retail = context.read<RetailProvider>();

    try {
      await retail.voidSale(
        saleId: widget.sale.id,
        voidReason: _reasonController.text.trim(),
        createdBy: auth.currentUserId ?? 'owner',
      );

      if (!mounted) return;
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Invoice #${widget.sale.invoiceNumber} voided. Stock & dues reversed.'),
          backgroundColor: AppTheme.primarySlate,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to void invoice: $e'),
          backgroundColor: AppTheme.crimsonError,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppTheme.crimsonLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.warning_rounded, color: AppTheme.crimsonError, size: 20),
          ),
          const SizedBox(width: 10),
          Text(
            'Void #${widget.sale.invoiceNumber}',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.textDark,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Voiding this invoice will atomically:',
            style: GoogleFonts.manrope(fontSize: 13, color: AppTheme.textSlate),
          ),
          const SizedBox(height: 6),
          _buildBullet('Restore stock quantities for all ${widget.sale.items.length} line items'),
          _buildBullet('Reverse any unpaid customer dues (Khata balance)'),
          _buildBullet('Log an auditable cancellation movement in inventory records'),
          const SizedBox(height: 16),
          Text(
            'Reason for cancellation *',
            style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textDark),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _reasonController,
            decoration: const InputDecoration(
              hintText: 'Enter reason (e.g. Duplicate bill, Item returned)',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isProcessing ? null : () => Navigator.of(context).pop(),
          child: Text('Cancel', style: GoogleFonts.manrope(color: AppTheme.textMuted)),
        ),
        ElevatedButton(
          onPressed: _isProcessing ? null : _handleVoid,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.crimsonError,
            foregroundColor: Colors.white,
          ),
          child: _isProcessing
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Confirm Void'),
        ),
      ],
    );
  }

  Widget _buildBullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(color: AppTheme.crimsonError, fontWeight: FontWeight.bold)),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.manrope(fontSize: 12, color: AppTheme.textMuted),
            ),
          ),
        ],
      ),
    );
  }
}
