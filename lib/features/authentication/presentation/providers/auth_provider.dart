import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../../data/models/auth_model.dart';
import '../../data/models/user_role.dart';

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
      // Simulate API call
      await Future.delayed(const Duration(seconds: 2));

      // TODO: Replace with actual API call
      // Example: final response = await authRepository.signup(request);

      // Mock successful response
      final normalizedEmail = request.email.trim().toLowerCase();
      final passwordHash = _hashPassword(request.password.trim());
      final mockUser = AuthUser(
        id: 'user_${DateTime.now().millisecondsSinceEpoch}',
        name: request.fullName,
        email: normalizedEmail,
        phone: request.phone,
        role: request.role,
        avatar: request.profilePicture,
        emailVerified: false,
        dateOfBirth: request.dateOfBirth,
        gender: request.gender,
        passwordHash: passwordHash,
      );

      _registeredAccounts[normalizedEmail] = _RegisteredAccount(
        user: mockUser,
        passwordHash: passwordHash,
      );

      _setState(state.copyWith(
        isAuthenticated: true,
        isLoading: false,
        user: mockUser,
        successMessage: 'Account created successfully!',
      ));
    } catch (e) {
      _setState(state.copyWith(
        isLoading: false,
        error: e.toString(),
      ));
    }
  }

  /// Login user
  Future<void> login(LoginRequest request) async {
    _setState(state.copyWith(isLoading: true, error: null));
    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 2));

      // TODO: Replace with actual API call
      // Example: final response = await authRepository.login(request);

      final normalizedEmail = request.email.trim().toLowerCase();
      final normalizedPasswordHash = _hashPassword(request.password.trim());
      final account = _registeredAccounts[normalizedEmail];

      if (account == null || account.passwordHash != normalizedPasswordHash) {
        _setState(state.copyWith(
          isLoading: false,
          isAuthenticated: false,
          user: null,
          error: 'Invalid email or password',
        ));
        return;
      }

      _setState(state.copyWith(
        isAuthenticated: true,
        isLoading: false,
        user: account.user,
        successMessage: 'Logged in successfully!',
      ));
    } catch (e) {
      _setState(state.copyWith(
        isLoading: false,
        error: e.toString(),
      ));
    }
  }

  /// Logout user
  void logout() {
    _setState(const AuthState());
  }

  void updateCustomerProfile({
    required String fullName,
    required String email,
    required String phone,
    required String profilePicture,
    DateTime? dateOfBirth,
    String? gender,
  }) {
    final currentUser = state.user;
    if (currentUser == null) return;

    final oldEmail = currentUser.email.trim().toLowerCase();
    final newEmail = email.trim().toLowerCase();
    final currentAccount = _registeredAccounts[oldEmail];
    if (currentAccount == null) return;

    final updatedUser = currentUser.copyWith(
      name: fullName,
      email: newEmail,
      phone: phone,
      avatar: profilePicture,
      dateOfBirth: dateOfBirth,
      clearDateOfBirth: dateOfBirth == null,
      gender: gender,
      clearGender: (gender == null || gender.isEmpty),
    );

    _registeredAccounts.remove(oldEmail);
    _registeredAccounts[newEmail] = _RegisteredAccount(
      user: updatedUser,
      passwordHash: currentAccount.passwordHash,
    );

    _setState(state.copyWith(
      user: updatedUser,
      successMessage: 'Profile updated successfully!',
      error: null,
    ));
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
