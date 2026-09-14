import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/retail_provider.dart';
import '../../services/firebase_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController(text: '+91 98765 00001');
  final _passwordController = TextEditingController(text: '123456');
  String _selectedRole = 'owner';
  bool _obscurePassword = true;
  bool _rememberDevice = true;

  @override
  void dispose() {
    _identifierController.disposeWidget();
    _passwordController.disposeWidget();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final identifier = _identifierController.text.trim();
    final isPhone = identifier.startsWith('+') || RegExp(r'^\d{10}$').hasMatch(identifier.replaceAll(' ', ''));

    if (isPhone && FirebaseService().isInitialized) {
      try {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sending SMS verification code via Firebase...'), duration: Duration(seconds: 2)),
        );
        await FirebaseService().sendPhoneOtp(
          phoneNumber: identifier,
          onCodeSent: (verificationId) {
            _showOtpDialog(identifier);
          },
          onVerificationFailed: (e) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('SMS OTP failed: ${e.message ?? e.code}. Falling back to PIN login.'),
                backgroundColor: AppTheme.crimsonError,
              ),
            );
            _performDirectLogin();
          },
          onAutoVerified: (credential) async {
            final user = (await FirebaseService().auth.signInWithCredential(credential)).user;
            if (user != null && mounted) {
              final auth = context.read<AuthProvider>();
              final ok = await auth.loginWithFirebaseUser(
                uid: user.uid,
                phoneNumber: user.phoneNumber ?? identifier,
                role: _selectedRole,
              );
              if (ok && auth.currentBusinessId != null && mounted) {
                context.read<RetailProvider>().loadAll(auth.currentBusinessId!);
              }
            }
          },
        );
        return;
      } catch (e) {
        debugPrint('Phone auth exception: $e');
      }
    }

    await _performDirectLogin();
  }

  Future<void> _performDirectLogin() async {
    final auth = context.read<AuthProvider>();
    final success = await auth.login(
      identifier: _identifierController.text.trim(),
      passwordOrOtp: _passwordController.text.trim(),
      role: _selectedRole,
    );

    if (!mounted) return;

    if (success && auth.currentBusinessId != null) {
      context.read<RetailProvider>().loadAll(auth.currentBusinessId!);
    } else if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Login failed. Please check credentials.'),
          backgroundColor: AppTheme.crimsonError,
        ),
      );
    }
  }

  void _showOtpDialog(String phone) {
    final otpController = TextEditingController();
    bool isVerifying = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setModalState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Verify Phone Number',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textDark,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Enter the 6-digit verification code sent via SMS to $phone',
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    color: AppTheme.textMuted,
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: otpController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.manrope(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 8,
                  ),
                  decoration: InputDecoration(
                    counterText: '',
                    hintText: '123456',
                    hintStyle: GoogleFonts.manrope(
                      fontSize: 24,
                      color: AppTheme.textMuted.withValues(alpha: 0.4),
                      letterSpacing: 8,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: isVerifying
                      ? null
                      : () async {
                          final code = otpController.text.trim();
                          if (code.length != 6) {
                            ScaffoldMessenger.of(dialogCtx).showSnackBar(
                              const SnackBar(content: Text('Please enter a 6-digit code')),
                            );
                            return;
                          }

                          setModalState(() => isVerifying = true);
                          try {
                            final credential = await FirebaseService().verifyOtp(code);
                            final user = credential.user;
                            if (user != null) {
                              if (!ctx.mounted) return;
                              Navigator.of(ctx).pop();

                              if (!mounted) return;
                              final auth = context.read<AuthProvider>();
                              final ok = await auth.loginWithFirebaseUser(
                                uid: user.uid,
                                phoneNumber: user.phoneNumber ?? phone,
                                role: _selectedRole,
                              );
                              if (ok && auth.currentBusinessId != null && mounted) {
                                context.read<RetailProvider>().loadAll(auth.currentBusinessId!);
                              }
                            }
                          } catch (e) {
                            setModalState(() => isVerifying = false);
                            if (!dialogCtx.mounted) return;
                            ScaffoldMessenger.of(dialogCtx).showSnackBar(
                              SnackBar(
                                content: Text('Verification failed: $e'),
                                backgroundColor: AppTheme.crimsonError,
                              ),
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.secondaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: isVerifying
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          'Verify & Access Store',
                          style: GoogleFonts.manrope(fontWeight: FontWeight.w700),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleDemoLogin() async {
    final auth = context.read<AuthProvider>();
    await auth.loginDemoStore();
    if (!mounted) return;
    if (auth.currentBusinessId != null) {
      context.read<RetailProvider>().loadAll(auth.currentBusinessId!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isDesktop = MediaQuery.of(context).size.width >= 800;

    return Scaffold(
      backgroundColor: AppTheme.canvasBackground,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            constraints: BoxConstraints(maxWidth: isDesktop ? 480 : double.infinity),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Brand Header
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppTheme.primarySlate,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primarySlate.withOpacity(0.15),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.storefront_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppTheme.tertiaryEmerald,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Rexon Retail V0.1',
                        style: GoogleFonts.manrope(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Rexon',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textDark,
                    letterSpacing: -0.02,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Smart Inventory & Fast Invoicing for Retailers',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    color: AppTheme.textMuted,
                  ),
                ),
                const SizedBox(height: 24),

                // Interactive Demo Sandbox Quick Access Card
                InkWell(
                  onTap: auth.isLoading ? null : _handleDemoLogin,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.emeraldLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.emeraldBorder),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.auto_awesome_rounded,
                            color: AppTheme.emeraldText,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Explore Sample Store',
                                style: GoogleFonts.manrope(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.emeraldText,
                                ),
                              ),
                              Text(
                                'Instant Sandbox • Preloaded with Stock & Bills',
                                style: GoogleFonts.manrope(
                                  fontSize: 12,
                                  color: AppTheme.textSlate,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          color: AppTheme.emeraldText,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Main Login Card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppTheme.cardSurface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.borderSlate),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Role Selector Toggle
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  onTap: () => setState(() => _selectedRole = 'owner'),
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    decoration: BoxDecoration(
                                      color: _selectedRole == 'owner'
                                          ? Colors.white
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(8),
                                      boxShadow: _selectedRole == 'owner'
                                          ? [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(0.04),
                                                blurRadius: 4,
                                              )
                                            ]
                                          : null,
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.verified_user_rounded,
                                          size: 16,
                                          color: _selectedRole == 'owner'
                                              ? AppTheme.secondaryBlue
                                              : AppTheme.textMuted,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Shop Owner',
                                          style: GoogleFonts.manrope(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: _selectedRole == 'owner'
                                                ? AppTheme.textDark
                                                : AppTheme.textMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: InkWell(
                                  onTap: () => setState(() => _selectedRole = 'staff'),
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    decoration: BoxDecoration(
                                      color: _selectedRole == 'staff'
                                          ? Colors.white
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(8),
                                      boxShadow: _selectedRole == 'staff'
                                          ? [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(0.04),
                                                blurRadius: 4,
                                              )
                                            ]
                                          : null,
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.badge_rounded,
                                          size: 16,
                                          color: _selectedRole == 'staff'
                                              ? AppTheme.secondaryBlue
                                              : AppTheme.textMuted,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Staff Login',
                                          style: GoogleFonts.manrope(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: _selectedRole == 'staff'
                                                ? AppTheme.textDark
                                                : AppTheme.textMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Mobile or Email Input
                        Text(
                          'Mobile Number or Email',
                          style: GoogleFonts.manrope(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textDark,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _identifierController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            hintText: '+91 98765 00001 or owner@shop.com',
                            prefixIcon: Icon(Icons.phone_android_rounded, size: 20, color: AppTheme.textMuted),
                          ),
                          validator: (v) => v == null || v.trim().isEmpty ? 'Please enter mobile or email' : null,
                        ),
                        const SizedBox(height: 16),

                        // Password or OTP PIN
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Password / OTP PIN',
                              style: GoogleFonts.manrope(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textDark,
                              ),
                            ),
                            Text(
                              'Demo PIN: 123456',
                              style: GoogleFonts.manrope(
                                fontSize: 11,
                                color: AppTheme.secondaryBlue,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            hintText: 'Enter 6-digit PIN or password',
                            prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20, color: AppTheme.textMuted),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                size: 20,
                                color: AppTheme.textMuted,
                              ),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                          ),
                          validator: (v) => v == null || v.trim().isEmpty ? 'Please enter PIN or password' : null,
                        ),
                        const SizedBox(height: 16),

                        // Trust device checkbox
                        Row(
                          children: [
                            Checkbox(
                              value: _rememberDevice,
                              activeColor: AppTheme.secondaryBlue,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                              onChanged: (v) => setState(() => _rememberDevice = v ?? true),
                            ),
                            Expanded(
                              child: Text(
                                'Remember this device for 30 days',
                                style: GoogleFonts.manrope(
                                  fontSize: 13,
                                  color: AppTheme.textMuted,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Submit Button
                        ElevatedButton(
                          onPressed: auth.isLoading ? null : _handleLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.secondaryBlue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: auth.isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Sign In to Dashboard',
                                      style: GoogleFonts.manrope(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Icon(Icons.arrow_forward_rounded, size: 18),
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

extension on TextEditingController {
  void disposeWidget() {
    dispose();
  }
}
