import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/models/business.dart';
import '../data/repositories/demo_data.dart';
import '../data/repositories/retail_repository.dart';
import '../services/firebase_service.dart';

enum AuthStatus { unauthenticated, authenticated }

class AuthProvider extends ChangeNotifier {
  final RetailRepository _repository;

  AuthProvider(this._repository) {
    _loadSession();
  }

  AuthStatus _status = AuthStatus.unauthenticated;
  String? _currentUserId;
  String? _currentBusinessId;
  String _currentRole = 'owner'; // "owner" | "staff"
  Business? _currentBusiness;
  bool _isLoading = false;

  AuthStatus get status => _status;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  String? get currentUserId => _currentUserId;
  String? get currentBusinessId => _currentBusinessId;
  String get currentRole => _currentRole;
  bool get isOwner => _currentRole == 'owner';
  Business? get currentBusiness => _currentBusiness;
  bool get hasBusinessSetup => _currentBusiness != null;
  bool get isLoading => _isLoading;

  Future<void> _loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    final uid = prefs.getString('rexon_session_uid');
    final bizId = prefs.getString('rexon_session_biz_id');
    final role = prefs.getString('rexon_session_role') ?? 'owner';

    if (uid != null && bizId != null) {
      _currentUserId = uid;
      _currentBusinessId = bizId;
      _currentRole = role;
      _currentBusiness = await _repository.getBusiness(bizId);
      _status = AuthStatus.authenticated;
      notifyListeners();
    }
  }

  // Quick Demo / Explore Sandbox Store
  Future<void> loginDemoStore() async {
    _isLoading = true;
    notifyListeners();

    _currentUserId = DemoData.demoOwnerUid;
    _currentBusinessId = DemoData.demoBusinessId;
    _currentRole = 'owner';

    // Seed demo data if not present
    _currentBusiness = await _repository.getBusiness(_currentBusinessId!);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('rexon_session_uid', _currentUserId!);
    await prefs.setString('rexon_session_biz_id', _currentBusinessId!);
    await prefs.setString('rexon_session_role', _currentRole);

    _status = AuthStatus.authenticated;
    _isLoading = false;
    notifyListeners();
  }

  // Phone OTP or Email Login
  Future<bool> login({
    required String identifier, // Phone or email
    required String passwordOrOtp,
    String role = 'owner',
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      await Future.delayed(const Duration(milliseconds: 600)); // Simulate auth handshake

      // Derive consistent UID from identifier
      final cleanId = identifier.trim().replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_').toLowerCase();
      final uid = 'usr_$cleanId';
      final bizId = 'biz_$cleanId';

      _currentUserId = uid;
      _currentBusinessId = bizId;
      _currentRole = role;

      // Check if business profile exists
      _currentBusiness = await _repository.getBusiness(bizId);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('rexon_session_uid', uid);
      await prefs.setString('rexon_session_biz_id', bizId);
      await prefs.setString('rexon_session_role', role);

      _status = AuthStatus.authenticated;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Real Firebase Auth Integration (PRD §6.1)
  Future<bool> loginWithFirebaseUser({
    required String uid,
    required String? phoneNumber,
    String role = 'owner',
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final bizId = 'biz_$uid';
      _currentUserId = uid;
      _currentBusinessId = bizId;
      _currentRole = role;

      _currentBusiness = await _repository.getBusiness(bizId);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('rexon_session_uid', uid);
      await prefs.setString('rexon_session_biz_id', bizId);
      await prefs.setString('rexon_session_role', role);

      _status = AuthStatus.authenticated;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Save new business profile from setup wizard
  Future<void> completeBusinessSetup(Business business) async {
    _isLoading = true;
    notifyListeners();

    await _repository.saveBusiness(business);
    _currentBusiness = business;
    _currentBusinessId = business.id;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('rexon_session_biz_id', business.id);

    _isLoading = false;
    notifyListeners();
  }

  Future<void> updateBusiness(Business updated) async {
    await _repository.saveBusiness(updated);
    _currentBusiness = updated;
    notifyListeners();
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('rexon_session_uid');
    await prefs.remove('rexon_session_biz_id');
    await prefs.remove('rexon_session_role');

    try {
      await FirebaseService().signOut();
    } catch (_) {}

    _status = AuthStatus.unauthenticated;
    _currentUserId = null;
    _currentBusinessId = null;
    _currentBusiness = null;
    notifyListeners();
  }
}
