/// Enum for user roles in the application
enum UserRole {
  customer('customer'),
  restaurant('restaurant'),
  deliveryPartner('delivery_partner'),
  admin('admin'),
  guest('guest');

  final String value;
  const UserRole(this.value);

  /// Convert string to UserRole
  static UserRole fromString(String value) {
    try {
      return UserRole.values.firstWhere(
        (role) => role.value == value,
        orElse: () => UserRole.guest,
      );
    } catch (e) {
      return UserRole.guest;
    }
  }

  /// Check if role is valid
  bool get isValid => this != UserRole.guest;

  /// Display name for UI
  String get displayName {
    switch (this) {
      case UserRole.customer:
        return 'Customer';
      case UserRole.restaurant:
        return 'Restaurant';
      case UserRole.deliveryPartner:
        return 'Delivery Partner';
      case UserRole.admin:
        return 'Admin';
      case UserRole.guest:
        return 'Guest';
    }
  }

  /// Icon for role
  String get icon {
    switch (this) {
      case UserRole.customer:
        return '🛒';
      case UserRole.restaurant:
        return '🍽️';
      case UserRole.deliveryPartner:
        return '🚗';
      case UserRole.admin:
        return '⚙️';
      case UserRole.guest:
        return '👤';
    }
  }
}
