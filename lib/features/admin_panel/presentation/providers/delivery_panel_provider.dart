import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Delivery Partner Profile Data
class DeliveryPartnerProfile {
  final String id;
  final String name;
  final String email;
  final String phone;
  final double rating;
  final int totalDeliveries;
  final bool isActive;
  final String vehicleType;
  final String licensePlate;

  DeliveryPartnerProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.rating,
    required this.totalDeliveries,
    required this.isActive,
    required this.vehicleType,
    required this.licensePlate,
  });

  DeliveryPartnerProfile copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    double? rating,
    int? totalDeliveries,
    bool? isActive,
    String? vehicleType,
    String? licensePlate,
  }) {
    return DeliveryPartnerProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      rating: rating ?? this.rating,
      totalDeliveries: totalDeliveries ?? this.totalDeliveries,
      isActive: isActive ?? this.isActive,
      vehicleType: vehicleType ?? this.vehicleType,
      licensePlate: licensePlate ?? this.licensePlate,
    );
  }
}

/// Active Delivery
class ActiveDelivery {
  final String id;
  final String restaurantName;
  final String customerName;
  final String customerAddress;
  final double estimatedEarning;
  final String pickupLocation;
  final String dropLocation;
  final String
      status; // 'picked_up', 'confirmed', 'in_transit', 'delivered', 'cancelled'
  final String? otp;
  final DateTime createdAt;

  ActiveDelivery({
    required this.id,
    required this.restaurantName,
    required this.customerName,
    required this.customerAddress,
    required this.estimatedEarning,
    required this.pickupLocation,
    required this.dropLocation,
    required this.status,
    this.otp,
    required this.createdAt,
  });

  ActiveDelivery copyWith({
    String? id,
    String? restaurantName,
    String? customerName,
    String? customerAddress,
    double? estimatedEarning,
    String? pickupLocation,
    String? dropLocation,
    String? status,
    String? otp,
    DateTime? createdAt,
  }) {
    return ActiveDelivery(
      id: id ?? this.id,
      restaurantName: restaurantName ?? this.restaurantName,
      customerName: customerName ?? this.customerName,
      customerAddress: customerAddress ?? this.customerAddress,
      estimatedEarning: estimatedEarning ?? this.estimatedEarning,
      pickupLocation: pickupLocation ?? this.pickupLocation,
      dropLocation: dropLocation ?? this.dropLocation,
      status: status ?? this.status,
      otp: otp ?? this.otp,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// Earning Record
class EarningRecord {
  final String id;
  final String deliveryId;
  final double amount;
  final DateTime date;
  final String status; // 'completed', 'pending'

  EarningRecord({
    required this.id,
    required this.deliveryId,
    required this.amount,
    required this.date,
    required this.status,
  });
}

/// Delivery Panel State
class DeliveryPanelState {
  final DeliveryPartnerProfile profile;
  final List<ActiveDelivery> activeDeliveries;
  final List<EarningRecord> earnings;
  final double totalEarningsToday;
  final double weeklyEarnings;
  final int totalDeliveriesToday;
  final bool notificationsEnabled;
  final bool autoAcceptOrders;
  final bool isLoading;
  final String? error;

  const DeliveryPanelState({
    required this.profile,
    required this.activeDeliveries,
    required this.earnings,
    required this.totalEarningsToday,
    required this.weeklyEarnings,
    required this.totalDeliveriesToday,
    required this.notificationsEnabled,
    required this.autoAcceptOrders,
    required this.isLoading,
    this.error,
  });

  DeliveryPanelState.initial()
      : this(
          profile: DeliveryPartnerProfile(
            id: 'dp_001',
            name: 'Alex Johnson',
            email: 'alex@quickbite.com',
            phone: '(555) 123-4567',
            rating: 4.9,
            totalDeliveries: 342,
            isActive: true,
            vehicleType: 'Motorcycle',
            licensePlate: 'XY-123-ZA',
          ),
          activeDeliveries: const [],
          earnings: const [],
          totalEarningsToday: 78.50,
          weeklyEarnings: 445.75,
          totalDeliveriesToday: 6,
          notificationsEnabled: true,
          autoAcceptOrders: false,
          isLoading: false,
          error: null,
        );

  DeliveryPanelState copyWith({
    DeliveryPartnerProfile? profile,
    List<ActiveDelivery>? activeDeliveries,
    List<EarningRecord>? earnings,
    double? totalEarningsToday,
    double? weeklyEarnings,
    int? totalDeliveriesToday,
    bool? notificationsEnabled,
    bool? autoAcceptOrders,
    bool? isLoading,
    String? error,
  }) {
    return DeliveryPanelState(
      profile: profile ?? this.profile,
      activeDeliveries: activeDeliveries ?? this.activeDeliveries,
      earnings: earnings ?? this.earnings,
      totalEarningsToday: totalEarningsToday ?? this.totalEarningsToday,
      weeklyEarnings: weeklyEarnings ?? this.weeklyEarnings,
      totalDeliveriesToday: totalDeliveriesToday ?? this.totalDeliveriesToday,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      autoAcceptOrders: autoAcceptOrders ?? this.autoAcceptOrders,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Delivery Panel Notifier
class DeliveryPanelNotifier extends StateNotifier<DeliveryPanelState> {
  DeliveryPanelNotifier() : super(DeliveryPanelState.initial());

  /// Load active deliveries
  Future<void> loadActiveDeliveries() async {
    state = state.copyWith(isLoading: true);
    try {
      await Future.delayed(const Duration(milliseconds: 800));

      final mockDeliveries = [
        ActiveDelivery(
          id: 'dlv_001',
          restaurantName: 'The Burger Place',
          customerName: 'Sarah Chen',
          customerAddress: '123 Main St, Apt 4B',
          estimatedEarning: 12.50,
          pickupLocation: 'The Burger Place - Downtown',
          dropLocation: '123 Main St, Apt 4B',
          status: 'picked_up',
          otp: '3847',
          createdAt: DateTime.now().subtract(const Duration(minutes: 18)),
        ),
        ActiveDelivery(
          id: 'dlv_002',
          restaurantName: 'Pizza Paradise',
          customerName: 'John Smith',
          customerAddress: '456 Oak Ave',
          estimatedEarning: 15.00,
          pickupLocation: 'Pizza Paradise - Central',
          dropLocation: '456 Oak Ave',
          status: 'in_transit',
          otp: null,
          createdAt: DateTime.now().subtract(const Duration(minutes: 35)),
        ),
      ];

      state = state.copyWith(
        activeDeliveries: mockDeliveries,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Update delivery status
  void updateDeliveryStatus(String deliveryId, String newStatus) {
    final updated = state.activeDeliveries.map((d) {
      if (d.id == deliveryId) {
        return d.copyWith(status: newStatus);
      }
      return d;
    }).toList();

    state = state.copyWith(activeDeliveries: updated);
  }

  /// Confirm order for delivery
  void confirmDelivery(String deliveryId) {
    final updated = state.activeDeliveries.map((d) {
      if (d.id == deliveryId) {
        return d.copyWith(status: 'confirmed');
      }
      return d;
    }).toList();

    state = state.copyWith(activeDeliveries: updated);
  }

  /// Cancel order for delivery
  void cancelDelivery(String deliveryId) {
    final updated = state.activeDeliveries.map((d) {
      if (d.id == deliveryId) {
        return d.copyWith(status: 'cancelled');
      }
      return d;
    }).toList();

    state = state.copyWith(activeDeliveries: updated);
  }

  /// Update profile
  Future<void> updateProfile(DeliveryPartnerProfile newProfile) async {
    state = state.copyWith(isLoading: true);
    try {
      await Future.delayed(const Duration(seconds: 1));
      state = state.copyWith(
        profile: newProfile,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Toggle notifications
  void toggleNotifications() {
    state = state.copyWith(
      notificationsEnabled: !state.notificationsEnabled,
    );
  }

  /// Toggle auto-accept orders
  void toggleAutoAccept() {
    state = state.copyWith(
      autoAcceptOrders: !state.autoAcceptOrders,
    );
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Delivery Panel Provider
final deliveryPanelProvider =
    StateNotifierProvider<DeliveryPanelNotifier, DeliveryPanelState>((ref) {
  return DeliveryPanelNotifier();
});

/// Weekly Earnings Data Provider
final weeklyEarningsDataProvider =
    Provider<List<MapEntry<String, double>>>((ref) {
  return [
    MapEntry('Mon', 65.0),
    MapEntry('Tue', 78.5),
    MapEntry('Wed', 82.0),
    MapEntry('Thu', 55.5),
    MapEntry('Fri', 95.0),
    MapEntry('Sat', 110.0),
    MapEntry('Sun', 59.75),
  ];
});
