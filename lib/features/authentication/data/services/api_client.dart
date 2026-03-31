import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/auth_model.dart';

class ApiClient {
  // Use 'localhost' for web, configure for mobile
  static const String _baseUrl = 'http://localhost:3000/api/v1';

  static final ApiClient _instance = ApiClient._internal();

  factory ApiClient() {
    return _instance;
  }

  ApiClient._internal();

  /// Register/Signup user
  Future<Map<String, dynamic>> signup(SignupRequest request) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/auth/register'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'name': request.fullName,
              'email': request.email.trim().toLowerCase(),
              'phone': request.phone.trim(),
              'password': request.password,
              'role': request.role.value,
            }),
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () => throw Exception('Request timeout'),
          );

      print('Signup Response: ${response.statusCode}');
      print('Signup Body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data;
      } else {
        final error = jsonDecode(response.body) as Map<String, dynamic>;
        throw Exception(error['message'] ?? 'Signup failed');
      }
    } catch (e) {
      print('Signup Error: $e');
      rethrow;
    }
  }

  /// Login user
  Future<Map<String, dynamic>> login(LoginRequest request) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/auth/login'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'email': request.email.trim().toLowerCase(),
              'password': request.password,
            }),
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () => throw Exception('Request timeout'),
          );

      print('Login Response: ${response.statusCode}');
      print('Login Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data;
      } else {
        final error = jsonDecode(response.body) as Map<String, dynamic>;
        throw Exception(error['message'] ?? 'Login failed');
      }
    } catch (e) {
      print('Login Error: $e');
      rethrow;
    }
  }

  /// Verify email
  Future<Map<String, dynamic>> verifyEmail(String email, String token) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/auth/verify-email'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'email': email.trim().toLowerCase(),
              'token': token,
            }),
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () => throw Exception('Request timeout'),
          );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data;
      } else {
        throw Exception('Email verification failed');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Request password reset
  Future<Map<String, dynamic>> requestPasswordReset(String email) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/auth/forgot-password'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'email': email.trim().toLowerCase(),
            }),
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () => throw Exception('Request timeout'),
          );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data;
      } else {
        throw Exception('Password reset request failed');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Reset password
  Future<Map<String, dynamic>> resetPassword(
    String email,
    String token,
    String newPassword,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/auth/reset-password'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'email': email.trim().toLowerCase(),
              'token': token,
              'newPassword': newPassword,
            }),
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () => throw Exception('Request timeout'),
          );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data;
      } else {
        throw Exception('Password reset failed');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Update authenticated user profile
  Future<Map<String, dynamic>> updateProfile({
    required String token,
    required Map<String, dynamic> payload,
  }) async {
    try {
      final response = await http
          .patch(
            Uri.parse('$_baseUrl/users/me'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode(payload),
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () => throw Exception('Request timeout'),
          );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }

      final error = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(error['message'] ?? 'Profile update failed');
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getMyAddresses({
    required String token,
  }) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/users/me/addresses'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    ).timeout(
      const Duration(seconds: 30),
      onTimeout: () => throw Exception('Request timeout'),
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(error['message'] ?? 'Failed to fetch addresses');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final raw = data['addresses'];
    if (raw is! List) return [];
    return raw
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  Future<Map<String, dynamic>> createMyAddress({
    required String token,
    required Map<String, dynamic> payload,
  }) async {
    final response = await http
        .post(
          Uri.parse('$_baseUrl/users/me/addresses'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode(payload),
        )
        .timeout(
          const Duration(seconds: 30),
          onTimeout: () => throw Exception('Request timeout'),
        );

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 201 || response.statusCode == 200) {
      return data;
    }

    throw Exception(data['message'] ?? 'Failed to create address');
  }

  Future<Map<String, dynamic>> updateMyAddress({
    required String token,
    required String addressId,
    required Map<String, dynamic> payload,
  }) async {
    final response = await http
        .patch(
          Uri.parse('$_baseUrl/users/me/addresses/$addressId'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode(payload),
        )
        .timeout(
          const Duration(seconds: 30),
          onTimeout: () => throw Exception('Request timeout'),
        );

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 200) {
      return data;
    }

    throw Exception(data['message'] ?? 'Failed to update address');
  }

  Future<void> deleteMyAddress({
    required String token,
    required String addressId,
  }) async {
    final response = await http.delete(
      Uri.parse('$_baseUrl/users/me/addresses/$addressId'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    ).timeout(
      const Duration(seconds: 30),
      onTimeout: () => throw Exception('Request timeout'),
    );

    if (response.statusCode != 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(data['message'] ?? 'Failed to delete address');
    }
  }

  Future<void> setDefaultMyAddress({
    required String token,
    required String addressId,
  }) async {
    final response = await http.patch(
      Uri.parse('$_baseUrl/users/me/addresses/$addressId/default'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    ).timeout(
      const Duration(seconds: 30),
      onTimeout: () => throw Exception('Request timeout'),
    );

    if (response.statusCode != 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(data['message'] ?? 'Failed to set default address');
    }
  }

  Future<List<Map<String, dynamic>>> getMyFavorites({
    required String token,
  }) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/users/me/favorites'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    ).timeout(
      const Duration(seconds: 30),
      onTimeout: () => throw Exception('Request timeout'),
    );

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200) {
      throw Exception(data['message'] ?? 'Failed to fetch favorites');
    }

    final raw = data['favorites'];
    if (raw is! List) return [];
    return raw
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  Future<List<Map<String, dynamic>>> getMyNotifications({
    required String token,
  }) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/users/me/notifications'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    ).timeout(
      const Duration(seconds: 30),
      onTimeout: () => throw Exception('Request timeout'),
    );

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200) {
      throw Exception(data['message'] ?? 'Failed to fetch notifications');
    }

    final raw = data['notifications'];
    if (raw is! List) return [];
    return raw
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  Future<void> markAllNotificationsRead({
    required String token,
  }) async {
    final response = await http.patch(
      Uri.parse('$_baseUrl/users/me/notifications/read-all'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    ).timeout(
      const Duration(seconds: 30),
      onTimeout: () => throw Exception('Request timeout'),
    );

    if (response.statusCode != 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(data['message'] ?? 'Failed to mark notifications read');
    }
  }

  Future<List<Map<String, dynamic>>> getMyOrders({
    required String token,
  }) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/orders'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    ).timeout(
      const Duration(seconds: 30),
      onTimeout: () => throw Exception('Request timeout'),
    );

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200) {
      throw Exception(data['message'] ?? 'Failed to fetch orders');
    }

    final raw = data['orders'];
    if (raw is! List) return [];
    return raw
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  Future<List<Map<String, dynamic>>> getAdminUsers({
    required String token,
  }) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/users'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    ).timeout(
      const Duration(seconds: 30),
      onTimeout: () => throw Exception('Request timeout'),
    );

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200) {
      throw Exception(data['message'] ?? 'Failed to fetch users');
    }

    final raw = data['users'];
    if (raw is! List) return [];
    return raw
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  Future<List<Map<String, dynamic>>> getPendingApprovalUsers({
    required String token,
  }) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/users/pending-approvals'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    ).timeout(
      const Duration(seconds: 30),
      onTimeout: () => throw Exception('Request timeout'),
    );

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200) {
      throw Exception(data['message'] ?? 'Failed to fetch pending approvals');
    }

    final raw = data['users'];
    if (raw is! List) return [];
    return raw
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  Future<Map<String, dynamic>> setUserApprovalStatus({
    required String token,
    required String userId,
    required bool approved,
  }) async {
    final response = await http
        .patch(
          Uri.parse('$_baseUrl/users/$userId/approval'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({'approved': approved}),
        )
        .timeout(
          const Duration(seconds: 30),
          onTimeout: () => throw Exception('Request timeout'),
        );

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200) {
      throw Exception(data['message'] ?? 'Failed to update approval status');
    }

    return data;
  }
}
