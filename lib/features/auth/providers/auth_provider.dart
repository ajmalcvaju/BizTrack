import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/firebase_service.dart';
import '../models/user_model.dart';

final authStateChangesProvider = StreamProvider<User?>((ref) {
  try {
    return FirebaseAuth.instance.authStateChanges();
  } catch (_) {
    return Stream.value(null);
  }
});

class AuthState {
  final User? user;
  final UserModel? userProfile;
  final bool isLoading;
  final String? errorMessage;
  final bool isDemoUser;

  const AuthState({
    this.user,
    this.userProfile,
    this.isLoading = false,
    this.errorMessage,
    this.isDemoUser = false,
  });

  // Always authenticated in personal single-user mode
  bool get isAuthenticated => true;

  AuthState copyWith({
    User? user,
    UserModel? userProfile,
    bool? isLoading,
    String? errorMessage,
    bool? isDemoUser,
    bool clearError = false,
  }) {
    return AuthState(
      user: user ?? this.user,
      userProfile: userProfile ?? this.userProfile,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isDemoUser: isDemoUser ?? this.isDemoUser,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final FirebaseService _service = FirebaseService();

  static const _keyDisplayName = 'bizpilot_owner_name';
  static const _keyBusinessName = 'bizpilot_owner_business';
  static const _keyPhone = 'bizpilot_owner_phone';
  static const _keyEmail = 'bizpilot_owner_email';

  static final UserModel defaultOwner = UserModel(
    uid: 'owner',
    email: 'owner@bizpilot.app',
    displayName: 'Business Owner',
    businessName: 'My Business',
    phone: '',
    createdAt: DateTime(2026, 1, 1),
  );

  AuthNotifier() : super(AuthState(userProfile: defaultOwner)) {
    _init();
  }

  Future<void> _init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedName = prefs.getString(_keyDisplayName);
      final savedBusiness = prefs.getString(_keyBusinessName);
      final savedPhone = prefs.getString(_keyPhone);
      final savedEmail = prefs.getString(_keyEmail);

      UserModel current = defaultOwner;
      if (savedName != null ||
          savedBusiness != null ||
          savedPhone != null ||
          savedEmail != null) {
        current = UserModel(
          uid: 'owner',
          email: savedEmail ?? defaultOwner.email,
          displayName: savedName ?? defaultOwner.displayName,
          businessName: savedBusiness ?? defaultOwner.businessName,
          phone: savedPhone ?? defaultOwner.phone,
          createdAt: defaultOwner.createdAt,
        );
      }

      state = state.copyWith(userProfile: current, isLoading: false);

      // Also try syncing with Firestore if connected
      final remote = await _service.getUserProfile('owner');
      if (remote != null) {
        state = state.copyWith(userProfile: remote);
      }
    } catch (_) {}
  }

  Future<void> updateProfile({
    required String displayName,
    required String businessName,
    required String phone,
    String? email,
  }) async {
    final current = state.userProfile ?? defaultOwner;
    final updated = current.copyWith(
      displayName: displayName.trim(),
      businessName: businessName.trim(),
      phone: phone.trim(),
      email: email?.trim() ?? current.email,
    );

    state = state.copyWith(userProfile: updated);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyDisplayName, updated.displayName);
      await prefs.setString(_keyBusinessName, updated.businessName);
      await prefs.setString(_keyPhone, updated.phone);
      await prefs.setString(_keyEmail, updated.email);
    } catch (_) {}

    try {
      await _service.saveUserProfile(updated);
    } catch (_) {}
  }

  Future<bool> signIn(String email, String password) async => true;

  Future<bool> register({
    required String email,
    required String password,
    required String displayName,
    required String businessName,
    required String phone,
  }) async {
    await updateProfile(
      displayName: displayName,
      businessName: businessName,
      phone: phone,
      email: email,
    );
    return true;
  }

  void loginAsDemo({
    String email = 'owner@bizpilot.in',
    String displayName = 'Rajesh Kumar',
    String businessName = 'Apex Tech Solutions',
    String phone = '+91 98765 43210',
  }) {
    updateProfile(
      displayName: displayName,
      businessName: businessName,
      phone: phone,
      email: email,
    );
  }

  Future<bool> sendPasswordReset(String email) async => true;

  Future<void> signOut() async {}
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
