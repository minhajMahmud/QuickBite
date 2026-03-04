import 'package:equatable/equatable.dart';
import 'user_role.dart';

/// Signup Request Model
class SignupRequest extends Equatable {
  final String fullName;
  final String email;
  final String phone;
  final String password;
  final UserRole role;
  final String profilePicture;
  final DateTime? dateOfBirth;
  final String? gender;

  const SignupRequest({
    required this.fullName,
    required this.email,
    required this.phone,
    required this.password,
    required this.role,
    this.profilePicture = '',
    this.dateOfBirth,
    this.gender,
  });

  @override
  List<Object?> get props => [
        fullName,
        email,
        phone,
        password,
        role,
        profilePicture,
        dateOfBirth,
        gender,
      ];

  Map<String, dynamic> toJson() => {
        'fullName': fullName,
        'email': email,
        'phone': phone,
        'password': password,
        'role': role.value,
        'profilePicture': profilePicture,
        'dateOfBirth': dateOfBirth?.toIso8601String(),
        'gender': gender,
      };
}

/// Login Request Model
class LoginRequest extends Equatable {
  final String email;
  final String password;

  const LoginRequest({
    required this.email,
    required this.password,
  });

  @override
  List<Object?> get props => [email, password];

  Map<String, dynamic> toJson() => {
        'email': email,
        'password': password,
      };
}

/// Auth Response Model
class AuthResponse extends Equatable {
  final String userId;
  final String token;
  final String refreshToken;
  final AuthUser user;

  const AuthResponse({
    required this.userId,
    required this.token,
    required this.refreshToken,
    required this.user,
  });

  @override
  List<Object?> get props => [userId, token, refreshToken, user];

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      userId: json['userId'] ?? '',
      token: json['token'] ?? '',
      refreshToken: json['refreshToken'] ?? '',
      user: AuthUser.fromJson(json['user'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'token': token,
        'refreshToken': refreshToken,
        'user': user.toJson(),
      };
}

/// Auth User Model
class AuthUser extends Equatable {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final UserRole role;
  final String avatar;
  final bool emailVerified;
  final DateTime? dateOfBirth;
  final String? gender;
  final String? passwordHash;

  const AuthUser({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    required this.role,
    this.avatar = '',
    this.emailVerified = false,
    this.dateOfBirth,
    this.gender,
    this.passwordHash,
  });

  AuthUser copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    UserRole? role,
    String? avatar,
    bool? emailVerified,
    DateTime? dateOfBirth,
    String? gender,
    String? passwordHash,
    bool clearDateOfBirth = false,
    bool clearGender = false,
    bool clearPasswordHash = false,
  }) {
    return AuthUser(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      avatar: avatar ?? this.avatar,
      emailVerified: emailVerified ?? this.emailVerified,
      dateOfBirth: clearDateOfBirth ? null : (dateOfBirth ?? this.dateOfBirth),
      gender: clearGender ? null : (gender ?? this.gender),
      passwordHash:
          clearPasswordHash ? null : (passwordHash ?? this.passwordHash),
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        email,
        phone,
        role,
        avatar,
        emailVerified,
        dateOfBirth,
        gender,
        passwordHash,
      ];

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      role: UserRole.fromString(json['role'] ?? 'guest'),
      avatar: json['avatar'] ?? '',
      emailVerified: json['emailVerified'] ?? false,
      dateOfBirth: json['dateOfBirth'] != null
          ? DateTime.tryParse(json['dateOfBirth'])
          : null,
      gender: json['gender'],
      passwordHash: json['passwordHash'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'phone': phone,
        'role': role.value,
        'avatar': avatar,
        'emailVerified': emailVerified,
        'dateOfBirth': dateOfBirth?.toIso8601String(),
        'gender': gender,
        'passwordHash': passwordHash,
      };
}

/// Auth State
class AuthState extends Equatable {
  final bool isAuthenticated;
  final bool isLoading;
  final AuthUser? user;
  final String? error;
  final String? successMessage;

  const AuthState({
    this.isAuthenticated = false,
    this.isLoading = false,
    this.user,
    this.error,
    this.successMessage,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    bool? isLoading,
    AuthUser? user,
    String? error,
    String? successMessage,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      user: user ?? this.user,
      error: error,
      successMessage: successMessage,
    );
  }

  @override
  List<Object?> get props =>
      [isAuthenticated, isLoading, user, error, successMessage];
}
