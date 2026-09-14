import 'dart:async';
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
  final _phoneController = TextEditingController(text: '9876500001');
  final _identifierController = TextEditingController(text: '+91 98765 00001');
  final _passwordController = TextEditingController(text: '123456');

  int _authMethodTab = 0; // 0 = Mobile OTP, 1 = PIN / Password
  String _selectedRole = 'owner';
  bool _obscurePassword = true;
  bool _rememberDevice = true;

  @override
  void dispose() {
    _phoneController.dispose();
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Handle Tab 0: Mobile OTP Flow
  void _handleOtpRequest() {
    final rawDigits = _phoneController.text.replaceAll(RegExp(r'\D'), '');
    if (rawDigits.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid 10-digit mobile number'),
          backgroundColor: AppTheme.crimsonError,
        ),
      );
      return;
    }

    final formattedPhone = '+91${rawDigits.length >= 10 ? rawDigits.substring(rawDigits.length - 10) : rawDigits}';
    _showOtpDialog(formattedPhone);
  }

  // Handle Tab 1: Direct PIN / Password Login
  Future<void> _handlePasswordLogin() async {
    if (!_formKey.currentState!.validate()) return;
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

  // Full-featured, responsive OTP verification dialog
  void _showOtpDialog(String phone) {
    final otpController = TextEditingController();
    bool isVerifying = false;
    String otpStatus = 'sending'; // 'sending' | 'sent' | 'fallback'
    String statusMessage = 'Dispatching SMS verification code via Firebase...';
    String? errorMessage;
    int countdown = 30;
    Timer? timer;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setModalState) {
          // Trigger SMS send and countdown when dialog is first displayed
          void startOtpFlow() {
            setModalState(() {
              otpStatus = 'sending';
              statusMessage = 'Dispatching SMS verification code via Firebase...';
              errorMessage = null;
              countdown = 30;
            });

            timer?.cancel();
            timer = Timer.periodic(const Duration(seconds: 1), (t) {
              if (countdown > 0) {
                setModalState(() => countdown--);
              } else {
                t.cancel();
              }
            });

            if (FirebaseService().isInitialized) {
              FirebaseService().sendPhoneOtp(
                phoneNumber: phone,
                onCodeSent: (verificationId) {
                  setModalState(() {
                    otpStatus = 'sent';
                    statusMessage = 'Verification code dispatched to $phone.';
                  });
                },
                onVerificationFailed: (e) {
                  setModalState(() {
                    otpStatus = 'fallback';
                    statusMessage = 'SMS gateway note: ${e.message ?? e.code}.\nFor quick access, enter test code: 123456 or store PIN.';
                  });
                },
                onAutoVerified: (credential) async {
                  try {
                    final user = (await FirebaseService().auth.signInWithCredential(credential)).user;
                    if (user != null && mounted) {
                      final auth = context.read<AuthProvider>();
                      final ok = await auth.loginWithFirebaseUser(
                        uid: user.uid,
                        phoneNumber: user.phoneNumber ?? phone,
                        role: _selectedRole,
                      );
                      if (ok && mounted && ctx.mounted) {
                        timer?.cancel();
                        Navigator.of(ctx).pop();
                        if (auth.currentBusinessId != null && mounted) {
                          context.read<RetailProvider>().loadAll(auth.currentBusinessId!);
                        }
                      }
                    }
                  } catch (e) {
                    debugPrint('[Login] Auto-verify note: $e');
                  }
                },
              );
            } else {
              // Firebase running in offline/local mock mode
              setModalState(() {
                otpStatus = 'fallback';
                statusMessage = 'Offline / Sandbox Mode.\nEnter test OTP: 123456 to continue.';
              });
            }
          }

          // Trigger on first modal frame
          if (otpStatus == 'sending' && timer == null) {
            WidgetsBinding.instance.addPostFrameCallback((_) => startOtpFlow());
          }

          Future<void> submitVerification(String code) async {
            if (code.length != 6) {
              setModalState(() => errorMessage = 'Please enter a 6-digit code');
              return;
            }

            setModalState(() {
              isVerifying = true;
              errorMessage = null;
            });

            bool loggedIn = false;

            // 1. Try Firebase verification if active
            if (FirebaseService().verificationId != null || FirebaseService().webConfirmationResult != null) {
              try {
                final credential = await FirebaseService().verifyOtp(code);
                final user = credential.user;
                if (user != null && mounted) {
                  final auth = context.read<AuthProvider>();
                  final ok = await auth.loginWithFirebaseUser(
                    uid: user.uid,
                    phoneNumber: user.phoneNumber ?? phone,
                    role: _selectedRole,
                  );
                  if (ok) loggedIn = true;
                }
              } catch (e) {
                debugPrint('[Login] Firebase verifyOtp threw: $e');
              }
            }

            // 2. Resilient fallback for demo/sandbox code '123456' or store PIN
            if (!loggedIn && mounted) {
              final auth = context.read<AuthProvider>();
              final ok = await auth.login(
                identifier: phone,
                passwordOrOtp: code,
                role: _selectedRole,
              );
              if (ok) loggedIn = true;
            }

            if (loggedIn && mounted && ctx.mounted) {
              timer?.cancel();
              Navigator.of(ctx).pop();
              final auth = context.read<AuthProvider>();
              if (auth.currentBusinessId != null && mounted) {
                context.read<RetailProvider>().loadAll(auth.currentBusinessId!);
              }
            } else if (mounted) {
              setModalState(() {
                isVerifying = false;
                errorMessage = 'Invalid code. Use the SMS code or default PIN: 123456';
              });
            }
          }

          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 420),
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Dialog Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.secondaryBlue.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.sms_rounded, color: AppTheme.secondaryBlue, size: 20),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Verify Phone Number',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textDark,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 20),
                        onPressed: () {
                          timer?.cancel();
                          Navigator.of(ctx).pop();
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Phone summary with edit link
                  Row(
                    children: [
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: GoogleFonts.manrope(fontSize: 13, color: AppTheme.textMuted),
                            children: [
                              const TextSpan(text: 'Code sent to '),
                              TextSpan(
                                text: phone,
                                style: const TextStyle(fontWeight: FontWeight.w700, color: AppTheme.textDark),
                              ),
                            ],
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          timer?.cancel();
                          Navigator.of(ctx).pop();
                        },
                        child: Text(
                          'Change',
                          style: GoogleFonts.manrope(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.secondaryBlue,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Status Banner
                  if (otpStatus == 'sending')
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.secondaryBlue),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              statusMessage,
                              style: GoogleFonts.manrope(fontSize: 12, color: AppTheme.textMuted),
                            ),
                          ),
                        ],
                      ),
                    )
                  else if (otpStatus == 'sent')
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.emeraldLight,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.emeraldBorder),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_rounded, color: AppTheme.emeraldText, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              statusMessage,
                              style: GoogleFonts.manrope(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.emeraldText,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.amberLight,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.amberBorder),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.info_outline_rounded, color: AppTheme.amberText, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              statusMessage,
                              style: GoogleFonts.manrope(
                                fontSize: 12,
                                height: 1.3,
                                color: AppTheme.amberText,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 20),

                  // 6-digit OTP input box
                  TextFormField(
                    controller: otpController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    autofocus: true,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.manrope(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 8,
                      color: AppTheme.textDark,
                    ),
                    decoration: InputDecoration(
                      counterText: '',
                      hintText: '123456',
                      hintStyle: GoogleFonts.manrope(
                        fontSize: 26,
                        color: AppTheme.textMuted.withValues(alpha: 0.3),
                        letterSpacing: 8,
                      ),
                    ),
                    onChanged: (val) {
                      if (val.trim().length == 6) {
                        submitVerification(val.trim());
                      }
                    },
                  ),

                  if (errorMessage != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      errorMessage!,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.crimsonError,
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),

                  // Resend countdown or action
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (countdown > 0)
                        Text(
                          'Resend code in ${countdown}s',
                          style: GoogleFonts.manrope(
                            fontSize: 12,
                            color: AppTheme.textMuted,
                          ),
                        )
                      else
                        TextButton.icon(
                          icon: const Icon(Icons.refresh_rounded, size: 16),
                          label: const Text('Resend Code'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppTheme.secondaryBlue,
                            visualDensity: VisualDensity.compact,
                          ),
                          onPressed: () => startOtpFlow(),
                        ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Verify Button
                  ElevatedButton(
                    onPressed: isVerifying ? null : () => submitVerification(otpController.text.trim()),
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
                            style: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w700),
                          ),
                  ),

                  const SizedBox(height: 12),

                  // Alternative: PIN login
                  Center(
                    child: TextButton(
                      onPressed: () {
                        timer?.cancel();
                        Navigator.of(ctx).pop();
                        setState(() => _authMethodTab = 1);
                      },
                      child: Text(
                        'Log in with Store PIN / Password instead',
                        style: GoogleFonts.manrope(
                          fontSize: 12,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
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
                        color: AppTheme.primarySlate.withValues(alpha: 0.15),
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
                const SizedBox(height: 20),

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
                        color: Colors.black.withValues(alpha: 0.02),
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
                        // Method Selector: Mobile OTP vs Password/PIN
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
                                  onTap: () => setState(() => _authMethodTab = 0),
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    decoration: BoxDecoration(
                                      color: _authMethodTab == 0 ? Colors.white : Colors.transparent,
                                      borderRadius: BorderRadius.circular(8),
                                      boxShadow: _authMethodTab == 0
                                          ? [
                                              BoxShadow(
                                                color: Colors.black.withValues(alpha: 0.04),
                                                blurRadius: 4,
                                              )
                                            ]
                                          : null,
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.phone_android_rounded,
                                          size: 16,
                                          color: _authMethodTab == 0 ? AppTheme.secondaryBlue : AppTheme.textMuted,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Mobile OTP',
                                          style: GoogleFonts.manrope(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: _authMethodTab == 0 ? AppTheme.textDark : AppTheme.textMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: InkWell(
                                  onTap: () => setState(() => _authMethodTab = 1),
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    decoration: BoxDecoration(
                                      color: _authMethodTab == 1 ? Colors.white : Colors.transparent,
                                      borderRadius: BorderRadius.circular(8),
                                      boxShadow: _authMethodTab == 1
                                          ? [
                                              BoxShadow(
                                                color: Colors.black.withValues(alpha: 0.04),
                                                blurRadius: 4,
                                              )
                                            ]
                                          : null,
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.lock_outline_rounded,
                                          size: 16,
                                          color: _authMethodTab == 1 ? AppTheme.secondaryBlue : AppTheme.textMuted,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'PIN / Password',
                                          style: GoogleFonts.manrope(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: _authMethodTab == 1 ? AppTheme.textDark : AppTheme.textMuted,
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
                        const SizedBox(height: 16),

                        // Role Selector Toggle
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceContainerLow.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  onTap: () => setState(() => _selectedRole = 'owner'),
                                  borderRadius: BorderRadius.circular(6),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 6),
                                    decoration: BoxDecoration(
                                      color: _selectedRole == 'owner' ? Colors.white : Colors.transparent,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.verified_user_rounded,
                                          size: 14,
                                          color: _selectedRole == 'owner' ? AppTheme.secondaryBlue : AppTheme.textMuted,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Shop Owner',
                                          style: GoogleFonts.manrope(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: _selectedRole == 'owner' ? AppTheme.textDark : AppTheme.textMuted,
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
                                  borderRadius: BorderRadius.circular(6),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 6),
                                    decoration: BoxDecoration(
                                      color: _selectedRole == 'staff' ? Colors.white : Colors.transparent,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.badge_rounded,
                                          size: 14,
                                          color: _selectedRole == 'staff' ? AppTheme.secondaryBlue : AppTheme.textMuted,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Staff Login',
                                          style: GoogleFonts.manrope(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: _selectedRole == 'staff' ? AppTheme.textDark : AppTheme.textMuted,
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
                        const SizedBox(height: 18),

                        // TAB 0: Mobile OTP Inputs
                        if (_authMethodTab == 0) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Mobile Number',
                                style: GoogleFonts.manrope(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textDark,
                                ),
                              ),
                              Flexible(
                                child: InkWell(
                                  onTap: () => _phoneController.text = '9876500001',
                                  child: Text(
                                    'Sample: 98765 00001',
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.manrope(
                                      fontSize: 11,
                                      color: AppTheme.secondaryBlue,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            style: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w600),
                            decoration: InputDecoration(
                              hintText: '98765 43210',
                              prefixIcon: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                                margin: const EdgeInsets.only(right: 8),
                                decoration: const BoxDecoration(
                                  border: Border(right: BorderSide(color: AppTheme.borderSlate)),
                                ),
                                child: Text(
                                  '+91',
                                  style: GoogleFonts.manrope(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.textDark,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.info_outline_rounded, size: 14, color: AppTheme.textMuted),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'A 6-digit verification code will be sent via SMS.',
                                  style: GoogleFonts.manrope(fontSize: 12, color: AppTheme.textMuted),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Get OTP & Sign In Button
                          ElevatedButton(
                            onPressed: auth.isLoading ? null : _handleOtpRequest,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.secondaryBlue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.sms_rounded, size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  'Get OTP & Sign In',
                                  style: GoogleFonts.manrope(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ]

                        // TAB 1: Password / PIN Inputs
                        else ...[
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
                              prefixIcon: Icon(Icons.person_outline_rounded, size: 20, color: AppTheme.textMuted),
                            ),
                            validator: (v) => v == null || v.trim().isEmpty ? 'Please enter mobile or email' : null,
                          ),
                          const SizedBox(height: 16),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Password / Store PIN',
                                style: GoogleFonts.manrope(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textDark,
                                ),
                              ),
                              Flexible(
                                child: Text(
                                  'Demo PIN: 123456',
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.manrope(
                                    fontSize: 11,
                                    color: AppTheme.secondaryBlue,
                                    fontWeight: FontWeight.w600,
                                  ),
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
                          const SizedBox(height: 14),

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
                          const SizedBox(height: 18),

                          ElevatedButton(
                            onPressed: auth.isLoading ? null : _handlePasswordLogin,
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
