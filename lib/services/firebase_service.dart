import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import '../firebase_options.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  FirebaseAuth? _auth;
  FirebaseFirestore? _firestore;

  FirebaseAuth get auth => _auth ?? FirebaseAuth.instance;
  FirebaseFirestore get firestore => _firestore ?? FirebaseFirestore.instance;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      _auth = FirebaseAuth.instance;
      _firestore = FirebaseFirestore.instance;

      // Enable offline persistence settings where available
      if (!kIsWeb) {
        _firestore!.settings = const Settings(
          persistenceEnabled: true,
          cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
        );
      }

      _isInitialized = true;
      debugPrint('[FirebaseService] Successfully connected to Firebase project rexon-35454.');
      try {
        if (_auth?.currentUser == null) {
          await _auth?.signInAnonymously();
        }
      } catch (e) {
        debugPrint('[FirebaseService] Note: anonymous sign-in skipped: $e');
      }
    } catch (e) {
      debugPrint('[FirebaseService] Note: Firebase init skipped or running offline: $e');
    }
  }

  /// Ensure an active Firebase user session exists (e.g. for Firestore writes)
  Future<void> ensureAuth() async {
    if (!_isInitialized) await initialize();
    try {
      if (auth.currentUser == null) {
        await auth.signInAnonymously();
      }
    } catch (e) {
      debugPrint('[FirebaseService] ensureAuth note: $e');
    }
  }

  // --- PHONE AUTHENTICATION (PRD §6.1) ---
  String? _verificationId;
  int? _resendToken;
  ConfirmationResult? _webConfirmationResult;

  /// Initiate Phone OTP flow for Indian mobile numbers (+91)
  Future<void> sendPhoneOtp({
    required String phoneNumber,
    required Function(String verificationId) onCodeSent,
    required Function(FirebaseAuthException e) onVerificationFailed,
    required Function(PhoneAuthCredential credential) onAutoVerified,
  }) async {
    if (!_isInitialized) await initialize();

    // Format phone number with Indian country code if missing
    var formattedPhone = phoneNumber.trim().replaceAll(' ', '');
    if (!formattedPhone.startsWith('+')) {
      if (formattedPhone.length == 10) {
        formattedPhone = '+91$formattedPhone';
      } else {
        formattedPhone = '+$formattedPhone';
      }
    }

    if (kIsWeb) {
      try {
        _webConfirmationResult = await auth.signInWithPhoneNumber(formattedPhone);
        onCodeSent('web_confirmation');
      } on FirebaseAuthException catch (e) {
        onVerificationFailed(e);
      }
    } else {
      await auth.verifyPhoneNumber(
        phoneNumber: formattedPhone,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) {
          onAutoVerified(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          onVerificationFailed(e);
        },
        codeSent: (String verificationId, int? resendToken) {
          _verificationId = verificationId;
          _resendToken = resendToken;
          onCodeSent(verificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
        forceResendingToken: _resendToken,
      );
    }
  }

  /// Verify 6-digit SMS OTP
  Future<UserCredential> verifyOtp(String smsCode) async {
    if (kIsWeb && _webConfirmationResult != null) {
      return await _webConfirmationResult!.confirm(smsCode.trim());
    }

    if (_verificationId == null) {
      throw Exception('No active verification in progress. Request a new OTP.');
    }

    final credential = PhoneAuthProvider.credential(
      verificationId: _verificationId!,
      smsCode: smsCode.trim(),
    );

    return await auth.signInWithCredential(credential);
  }

  /// Sign out
  Future<void> signOut() async {
    if (_isInitialized) {
      await auth.signOut();
    }
  }
}
