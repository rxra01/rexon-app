import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../data/models/business.dart';
import '../../providers/auth_provider.dart';
import '../../providers/retail_provider.dart';

class BusinessSetupScreen extends StatefulWidget {
  const BusinessSetupScreen({super.key});

  @override
  State<BusinessSetupScreen> createState() => _BusinessSetupScreenState();
}

class _BusinessSetupScreenState extends State<BusinessSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController(text: 'My Retail Store');
  final _ownerNameController = TextEditingController(text: 'Store Owner');
  final _phoneController = TextEditingController(text: '+91 98765 43210');
  final _emailController = TextEditingController();
  final _addressController = TextEditingController(text: 'Main Market, City Center');
  final _gstinController = TextEditingController();
  final String _businessType = 'retailer';

  @override
  void dispose() {
    _nameController.dispose();
    _ownerNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _gstinController.dispose();
    super.dispose();
  }

  Future<void> _handleCompleteSetup() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final business = Business(
      id: auth.currentBusinessId ?? 'biz_${DateTime.now().millisecondsSinceEpoch}',
      ownerUid: auth.currentUserId ?? 'owner_user',
      name: _nameController.text.trim(),
      type: _businessType,
      ownerName: _ownerNameController.text.trim(),
      phone: _phoneController.text.trim(),
      email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
      address: _addressController.text.trim(),
      gstin: _gstinController.text.trim().isEmpty ? null : _gstinController.text.trim().toUpperCase(),
      currency: '₹',
      createdAt: DateTime.now(),
    );

    await auth.completeBusinessSetup(business);
    if (!mounted) return;
    context.read<RetailProvider>().loadAll(business.id);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isDesktop = MediaQuery.of(context).size.width >= 800;

    return Scaffold(
      backgroundColor: AppTheme.canvasBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Setup Your Retail Shop',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppTheme.textDark,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppTheme.crimsonError),
            tooltip: 'Sign Out',
            onPressed: () => auth.logout(),
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Container(
            constraints: BoxConstraints(maxWidth: isDesktop ? 600 : double.infinity),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header snippet
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.primarySlate,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.store_rounded,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Step 1 of 1: Shop Information',
                              style: GoogleFonts.manrope(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.tertiaryEmerald,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Tell us about your business',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'This will appear on your customer invoices & receipts',
                              style: GoogleFonts.manrope(
                                fontSize: 12,
                                color: const Color(0xFF94A3B8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Form card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.borderSlate),
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Store Name
                        Text(
                          'Business / Store Name *',
                          style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            hintText: 'e.g. Apex Electronics & Mobile',
                            prefixIcon: Icon(Icons.storefront_rounded, size: 20, color: AppTheme.textMuted),
                          ),
                          validator: (v) => v == null || v.trim().isEmpty ? 'Store name is required' : null,
                        ),
                        const SizedBox(height: 16),

                        // Owner Name & Phone row
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Owner Name *',
                                    style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 6),
                                  TextFormField(
                                    controller: _ownerNameController,
                                    decoration: const InputDecoration(
                                      hintText: 'e.g. Rahul Sharma',
                                      prefixIcon: Icon(Icons.person_rounded, size: 20, color: AppTheme.textMuted),
                                    ),
                                    validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Contact Phone *',
                                    style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 6),
                                  TextFormField(
                                    controller: _phoneController,
                                    decoration: const InputDecoration(
                                      hintText: '+91 98765 ...',
                                      prefixIcon: Icon(Icons.call_rounded, size: 20, color: AppTheme.textMuted),
                                    ),
                                    validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Email & GSTIN row
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Email (Optional)',
                                    style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 6),
                                  TextFormField(
                                    controller: _emailController,
                                    keyboardType: TextInputType.emailAddress,
                                    decoration: const InputDecoration(
                                      hintText: 'owner@shop.com',
                                      prefixIcon: Icon(Icons.email_outlined, size: 20, color: AppTheme.textMuted),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'GSTIN (Optional)',
                                    style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 6),
                                  TextFormField(
                                    controller: _gstinController,
                                    textCapitalization: TextCapitalization.characters,
                                    decoration: const InputDecoration(
                                      hintText: '15-digit GSTIN',
                                      prefixIcon: Icon(Icons.receipt_long_rounded, size: 20, color: AppTheme.textMuted),
                                    ),
                                    validator: (v) {
                                      if (v == null || v.trim().isEmpty) return null;
                                      final val = v.trim();
                                      if (val.length != 15) {
                                        return 'GSTIN must be 15 chars';
                                      }
                                      return null;
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Address
                        Text(
                          'Shop Street Address *',
                          style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _addressController,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            hintText: 'Shop No., Market, Street, City, State, PIN',
                            prefixIcon: Icon(Icons.location_on_outlined, size: 20, color: AppTheme.textMuted),
                          ),
                          validator: (v) => v == null || v.trim().isEmpty ? 'Address is required' : null,
                        ),
                        const SizedBox(height: 24),

                        // Complete Setup CTA
                        ElevatedButton(
                          onPressed: auth.isLoading ? null : _handleCompleteSetup,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.secondaryBlue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: auth.isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Save & Open Dashboard',
                                      style: GoogleFonts.manrope(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Icon(Icons.check_circle_rounded, size: 18),
                                  ],
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
