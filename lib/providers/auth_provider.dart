// providers/auth_provider.dart
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/firebase_service.dart';
import '../utils/constants.dart';

class AuthProvider extends ChangeNotifier {
  // ==========================================
  // DEPENDENCIES
  // ==========================================
  final FirebaseService _service = FirebaseService();

  // ==========================================
  // STATE VARIABLES
  // ==========================================
  UserModel? _user;
  bool _isLoading = false;
  bool _isLoggedIn = false;
  String? _errorMessage;
  String? _startupError;
  late final Future<void> _initialization;

  // ==========================================
  // GETTERS
  // ==========================================
  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _isLoggedIn;
  String? get errorMessage => _errorMessage;
  String? get startupError => _startupError;
  Future<void> get initialization => _initialization;
  String get userName => _user?.name ?? 'User';
  String get userEmail => _user?.email ?? '';
  String get userInitials => _user?.initials ?? '?';

  // ==========================================
  // CONSTRUCTOR
  // ==========================================
  AuthProvider() {
    // App එක start වුනාම, user කෙනෙක් already logged in ද කියලා check කරන්න
    _initialization = _checkCurrentUser();
  }

  // ==========================================
  // CHECK CURRENT USER (App Start වුනාම)
  // ==========================================
  Future<void> _checkCurrentUser() async {
    _isLoading = true;
    _startupError = null;
    notifyListeners();

    try {
      if (_service.isLoggedIn) {
        _user = await _service.getCurrentUserData();
        _isLoggedIn = _user != null;
      } else {
        _isLoggedIn = false;
        _user = null;
      }
    } catch (e) {
      _isLoggedIn = false;
      _user = null;
      _startupError = FirebaseService.friendlyError(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> retrySessionRestore() async {
    _startupError = null;
    await _checkCurrentUser();
  }

  // ==========================================
  // CLEAR ERROR
  // ==========================================
  void clearError() {
    _errorMessage = null;
    _startupError = null;
    notifyListeners();
  }

  // ==========================================
  // REGISTER
  // ==========================================
  Future<bool> register({
    required String name,
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      UserModel? newUser = await _service.registerUser(
        name: name,
        email: email,
        password: password,
      );

      if (newUser != null) {
        _user = newUser;
        _isLoggedIn = true;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = AppConstants.msgRegisterFailed;
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = FirebaseService.friendlyError(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ==========================================
  // LOGIN
  // ==========================================
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      UserModel? loggedUser = await _service.loginUser(
        email: email,
        password: password,
      );

      if (loggedUser != null) {
        _user = loggedUser;
        _isLoggedIn = true;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = AppConstants.msgLoginFailed;
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = FirebaseService.friendlyError(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ==========================================
  // LOGOUT
  // ==========================================
  Future<bool> logout() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _service.logoutUser();

      _user = null;
      _isLoggedIn = false;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = FirebaseService.friendlyError(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ==========================================
  // FORGOT PASSWORD
  // ==========================================
  Future<bool> forgotPassword(String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _service.resetPassword(email);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = FirebaseService.friendlyError(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ==========================================
  // REFRESH USER DATA (Profile update වුනාම)
  // ==========================================
  Future<void> refreshUser() async {
    try {
      _user = await _service.getCurrentUserData();
      notifyListeners();
    } catch (e) {
      _errorMessage = FirebaseService.friendlyError(e);
      notifyListeners();
    }
  }

  // ==========================================
  // UPDATE USER PROFILE
  // ==========================================
  Future<bool> updateProfile({
    String? name,
    String? phone,
    String? photoUrl,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _service.updateUserProfile(
        name: name,
        phone: phone,
        photoUrl: photoUrl,
      );

      if (_user != null) {
        _user = _user!.copyWith(
          name: name,
          phone: phone,
          photoUrl: photoUrl,
        );
      }

      _isLoading = false;
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = FirebaseService.friendlyError(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
