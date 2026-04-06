import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../../data/models/auth_model.dart';
import '../../data/models/user_role.dart';
import '../../data/services/api_client.dart';

final ValueNotifier<AuthState> authRouterStateNotifier =
    ValueNotifier<AuthState>(const AuthState());

class _DemoAccount {
  final UserRole role;
  final String name;

  const _DemoAccount({
    required this.role,
    required this.name,
  });
}

class _RegisteredAccount {
  final AuthUser user;
  final String passwordHash;

  const _RegisteredAccount({required this.user, required this.passwordHash});
}

const Map<String, _DemoAccount> _demoAccounts = {
  'admin@gmail.com': _DemoAccount(role: UserRole.admin, name: 'Admin User'),
  'customer@gmail.com':
      _DemoAccount(role: UserRole.customer, name: 'Customer User'),
  // Support both spellings for convenience.
  'resturant@gmail.com':
      _DemoAccount(role: UserRole.restaurant, name: 'Restaurant User'),
  'restaurant@gmail.com':
      _DemoAccount(role: UserRole.restaurant, name: 'Restaurant User'),
  'delivery@gmail.com':
      _DemoAccount(role: UserRole.deliveryPartner, name: 'Delivery User'),
};

/// Auth State Notifier
class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState()) {
    for (final entry in _demoAccounts.entries) {
      final email = entry.key.toLowerCase();
      final demo = entry.value;
      final user = AuthUser(
        id: 'demo_$email',
        name: demo.name,
        email: email,
        role: demo.role,
        emailVerified: true,
      );
      _registeredAccounts[email] = _RegisteredAccount(
        user: user,
        passwordHash: _hashPassword('1'),
      );
    }
    authRouterStateNotifier.value = state;
  }

  final Map<String, _RegisteredAccount> _registeredAccounts = {};

  void _setState(AuthState newState) {
    state = newState;
    authRouterStateNotifier.value = newState;
  }

  String _hashPassword(String rawPassword) {
    return sha256.convert(utf8.encode(rawPassword)).toString();
  }

  /// Sign up user
  Future<void> signup(SignupRequest request) async {
    _setState(state.copyWith(isLoading: true, error: null));
    try {
      final apiClient = ApiClient();
      final response = await apiClient.signup(request);

      // Parse the response
      final authResponse = AuthResponse.fromJson(response);

      _setState(state.copyWith(
        isAuthenticated: false, // Email needs verification
        isLoading: false,
        token: authResponse.token,
        user: authResponse.user,
        successMessage: (response['message']?.toString().isNotEmpty ?? false)
            ? '${response['message']} (saved to PostgreSQL)'
            : 'Account created successfully and saved to PostgreSQL. Please verify your email.',
      ));
    } catch (e) {
      print('Signup error: $e');
      _setState(state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      ));
    }
  }

  /// Login user
  Future<void> login(LoginRequest request) async {
    _setState(state.copyWith(isLoading: true, error: null));
    try {
      final apiClient = ApiClient();
      final response = await apiClient.login(request);

      // Parse the response
      final authResponse = AuthResponse.fromJson(response);

      _setState(state.copyWith(
        isAuthenticated: true,
        isLoading: false,
        token: authResponse.token,
        user: authResponse.user,
        successMessage: 'Logged in successfully (backend verified).',
      ));
    } catch (e) {
      print('Login error: $e');
      _setState(state.copyWith(
        isLoading: false,
        isAuthenticated: false,
        user: null,
        error: e.toString().replaceAll('Exception: ', ''),
      ));
    }
  }

  /// Request password reset email
  Future<void> requestPasswordReset(String email) async {
    _setState(state.copyWith(
      isLoading: true,
      error: null,
      successMessage: null,
    ));
    try {
      final apiClient = ApiClient();
      final response = await apiClient.requestPasswordReset(email);

      _setState(state.copyWith(
        isLoading: false,
        successMessage: (response['message']?.toString().isNotEmpty ?? false)
            ? response['message'].toString()
            : 'If that email exists, we will send a password reset link.',
        error: null,
      ));
    } catch (e) {
      _setState(state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      ));
    }
  }

  /// Verify email with 6-digit code
  Future<String> verifyEmail(String email, String code) async {
    _setState(state.copyWith(error: null, successMessage: null));
    try {
      final apiClient = ApiClient();
      final response = await apiClient.verifyEmail(email, code);
      final message = (response['message']?.toString().isNotEmpty ?? false)
          ? response['message'].toString()
          : 'Email verified successfully!';

      _setState(state.copyWith(
        isAuthenticated: true,
        user: state.user?.copyWith(emailVerified: true),
        successMessage: message,
        error: null,
      ));
      return message;
    } catch (e) {
      final errorMessage = e.toString().replaceAll('Exception: ', '');
      _setState(state.copyWith(error: errorMessage));
      rethrow;
    }
  }

  /// Resend email verification code
  Future<String> resendVerificationEmail(String email) async {
    _setState(state.copyWith(error: null, successMessage: null));
    try {
      final apiClient = ApiClient();
      final response = await apiClient.resendVerificationEmail(email);
      final message = (response['message']?.toString().isNotEmpty ?? false)
          ? response['message'].toString()
          : 'Verification code sent successfully.';

      _setState(state.copyWith(
        successMessage: message,
        error: null,
      ));
      return message;
    } catch (e) {
      final errorMessage = e.toString().replaceAll('Exception: ', '');
      _setState(state.copyWith(error: errorMessage));
      rethrow;
    }
  }

  /// Reset password with email + token
  Future<void> resetPassword({
    required String email,
    required String token,
    required String newPassword,
  }) async {
    _setState(state.copyWith(
      isLoading: true,
      error: null,
      successMessage: null,
    ));
    try {
      final apiClient = ApiClient();
      final response = await apiClient.resetPassword(email, token, newPassword);

      _setState(state.copyWith(
        isLoading: false,
        successMessage: (response['message']?.toString().isNotEmpty ?? false)
            ? response['message'].toString()
            : 'Password reset successfully. Please sign in again.',
        error: null,
      ));
    } catch (e) {
      _setState(state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      ));
    }
  }

  /// Logout user
  void logout() {
    _setState(const AuthState());
  }

  Future<void> updateCustomerProfile({
    required String fullName,
    required String email,
    required String phone,
    required String profilePicture,
    DateTime? dateOfBirth,
    String? gender,
  }) async {
    final currentUser = state.user;
    final token = state.token;
    if (currentUser == null || token == null || token.isEmpty) {
      _setState(state.copyWith(error: 'User not authenticated.'));
      return;
    }

    _setState(state.copyWith(isLoading: true, error: null));

    final newEmail = email.trim().toLowerCase();

    try {
      final apiClient = ApiClient();
      final response = await apiClient.updateProfile(
        token: token,
        payload: {
          'name': fullName.trim(),
          'email': newEmail,
          'phone': phone.trim(),
          'avatar': profilePicture.trim(),
          'dateOfBirth': dateOfBirth?.toIso8601String(),
          'gender': (gender == null || gender.isEmpty) ? null : gender,
        },
      );

      final backendUser = response['user'] is Map<String, dynamic>
          ? AuthUser.fromJson(response['user'] as Map<String, dynamic>)
          : currentUser;

      final updatedUser = backendUser.copyWith(
        role: currentUser.role,
        dateOfBirth: dateOfBirth,
        clearDateOfBirth: dateOfBirth == null,
        gender: gender,
        clearGender: (gender == null || gender.isEmpty),
      );

      _setState(state.copyWith(
        isLoading: false,
        user: updatedUser,
        successMessage: response['message']?.toString().isNotEmpty == true
            ? response['message'].toString()
            : 'Profile updated successfully!',
        error: null,
      ));
    } catch (e) {
      _setState(state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      ));
    }
  }

  bool changePassword({
    required String currentPassword,
    required String newPassword,
  }) {
    final currentUser = state.user;
    if (currentUser == null) {
      _setState(state.copyWith(error: 'User not authenticated.'));
      return false;
    }

    final email = currentUser.email.trim().toLowerCase();
    final account = _registeredAccounts[email];
    if (account == null) {
      _setState(state.copyWith(error: 'Account not found.'));
      return false;
    }

    final currentPasswordHash = _hashPassword(currentPassword.trim());
    if (currentPasswordHash != account.passwordHash) {
      _setState(state.copyWith(error: 'Current password is incorrect.'));
      return false;
    }

    final newPasswordHash = _hashPassword(newPassword.trim());
    final updatedUser = currentUser.copyWith(passwordHash: newPasswordHash);
    _registeredAccounts[email] = _RegisteredAccount(
      user: updatedUser,
      passwordHash: newPasswordHash,
    );

    _setState(state.copyWith(
      user: updatedUser,
      successMessage: 'Password changed successfully!',
      error: null,
    ));
    return true;
  }

  /// Clear messages
  void clearMessages() {
    _setState(state.copyWith(error: null, successMessage: null));
  }
}

/// Auth State Provider
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
