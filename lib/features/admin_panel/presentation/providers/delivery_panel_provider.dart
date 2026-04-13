import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../authentication/data/models/auth_model.dart';
import '../../../authentication/data/services/api_client.dart';
import '../../../authentication/presentation/providers/auth_provider.dart';

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
  final String? orderId;
  final String restaurantName;
  final String customerName;
  final String? customerPhone;
  final String customerAddress;
  final double estimatedEarning;
  final String pickupLocation;
  final String dropLocation;
  final double? pickupLatitude;
  final double? pickupLongitude;
  final double? dropLatitude;
  final double? dropLongitude;
  final List<String> orderItems;
  final String
      status; // 'picked_up', 'confirmed', 'in_transit', 'delivered', 'cancelled'
  final String? otp;
  final DateTime createdAt;

  ActiveDelivery({
    required this.id,
    this.orderId,
    required this.restaurantName,
    required this.customerName,
    this.customerPhone,
    required this.customerAddress,
    required this.estimatedEarning,
    required this.pickupLocation,
    required this.dropLocation,
    this.pickupLatitude,
    this.pickupLongitude,
    this.dropLatitude,
    this.dropLongitude,
    this.orderItems = const [],
    required this.status,
    this.otp,
    required this.createdAt,
  });

  ActiveDelivery copyWith({
    String? id,
    String? orderId,
    String? restaurantName,
    String? customerName,
    String? customerPhone,
    String? customerAddress,
    double? estimatedEarning,
    String? pickupLocation,
    String? dropLocation,
    double? pickupLatitude,
    double? pickupLongitude,
    double? dropLatitude,
    double? dropLongitude,
    List<String>? orderItems,
    String? status,
    String? otp,
    DateTime? createdAt,
  }) {
    return ActiveDelivery(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      restaurantName: restaurantName ?? this.restaurantName,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      customerAddress: customerAddress ?? this.customerAddress,
      estimatedEarning: estimatedEarning ?? this.estimatedEarning,
      pickupLocation: pickupLocation ?? this.pickupLocation,
      dropLocation: dropLocation ?? this.dropLocation,
      pickupLatitude: pickupLatitude ?? this.pickupLatitude,
      pickupLongitude: pickupLongitude ?? this.pickupLongitude,
      dropLatitude: dropLatitude ?? this.dropLatitude,
      dropLongitude: dropLongitude ?? this.dropLongitude,
      orderItems: orderItems ?? this.orderItems,
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

class IncomingDeliveryRequest {
  final String id;
  final String orderId;
  final String status;
  final String restaurantName;
  final String customerName;
  final String customerPhone;
  final String customerEmail;
  final String customerAddress;
  final double totalAmount;
  final double deliveryFee;
  final DateTime? estimatedDeliveryTime;
  final DateTime createdAt;

  const IncomingDeliveryRequest({
    required this.id,
    required this.orderId,
    required this.status,
    required this.restaurantName,
    required this.customerName,
    required this.customerPhone,
    required this.customerEmail,
    required this.customerAddress,
    required this.totalAmount,
    required this.deliveryFee,
    required this.estimatedDeliveryTime,
    required this.createdAt,
  });
}

/// Delivery Panel State
class DeliveryPanelState {
  final DeliveryPartnerProfile profile;
  final List<ActiveDelivery> activeDeliveries;
  final List<IncomingDeliveryRequest> incomingRequests;
  final List<EarningRecord> earnings;
  final List<MapEntry<String, double>> weeklyEarningsBreakdown;
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
    required this.incomingRequests,
    required this.earnings,
    required this.weeklyEarningsBreakdown,
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
            id: '',
            name: 'Delivery Partner',
            email: '-',
            phone: '-',
            rating: 0,
            totalDeliveries: 0,
            isActive: false,
            vehicleType: '-',
            licensePlate: '-',
          ),
          activeDeliveries: const [],
          incomingRequests: const [],
          earnings: const [],
          weeklyEarningsBreakdown: const [
            MapEntry('Mon', 0),
            MapEntry('Tue', 0),
            MapEntry('Wed', 0),
            MapEntry('Thu', 0),
            MapEntry('Fri', 0),
            MapEntry('Sat', 0),
            MapEntry('Sun', 0),
          ],
          totalEarningsToday: 0,
          weeklyEarnings: 0,
          totalDeliveriesToday: 0,
          notificationsEnabled: false,
          autoAcceptOrders: false,
          isLoading: false,
          error: null,
        );

  DeliveryPanelState copyWith({
    DeliveryPartnerProfile? profile,
    List<ActiveDelivery>? activeDeliveries,
    List<IncomingDeliveryRequest>? incomingRequests,
    List<EarningRecord>? earnings,
    List<MapEntry<String, double>>? weeklyEarningsBreakdown,
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
      incomingRequests: incomingRequests ?? this.incomingRequests,
      earnings: earnings ?? this.earnings,
      weeklyEarningsBreakdown:
          weeklyEarningsBreakdown ?? this.weeklyEarningsBreakdown,
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
  final ApiClient _apiClient;
  String? _currentToken;

  DeliveryPanelNotifier({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient(),
        super(DeliveryPanelState.initial());

  double _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  double? _asNullableDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  int _asInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  DateTime? _parseDate(dynamic value) {
    if (value is DateTime) return value;
    return DateTime.tryParse(value?.toString() ?? '');
  }

  String _customerLabel(Map<String, dynamic> order) {
    final rawUserId = order['userId']?.toString() ?? '';
    if (rawUserId.isEmpty) return 'Customer';
    final shortId =
        rawUserId.length > 6 ? rawUserId.substring(0, 6) : rawUserId;
    return 'Customer $shortId';
  }

  DeliveryPartnerProfile _profileFromJson(
    Map<String, dynamic> data, {
    AuthUser? fallbackUser,
  }) {
    return DeliveryPartnerProfile(
      id: data['id']?.toString() ?? fallbackUser?.id ?? state.profile.id,
      name:
          data['name']?.toString() ?? fallbackUser?.name ?? state.profile.name,
      email: data['email']?.toString() ??
          fallbackUser?.email ??
          state.profile.email,
      phone: data['phone']?.toString() ??
          fallbackUser?.phone ??
          state.profile.phone,
      rating: _asDouble(data['rating'] ?? state.profile.rating),
      totalDeliveries: _asInt(
        data['totalDeliveries'] ??
            data['total_orders'] ??
            state.profile.totalDeliveries,
      ),
      isActive: data['is_active'] == true || data['status'] == 'active',
      vehicleType:
          data['vehicle_type']?.toString() ?? state.profile.vehicleType,
      licensePlate:
          data['vehicle_number']?.toString() ?? state.profile.licensePlate,
    );
  }

  List<ActiveDelivery> _buildActiveDeliveries(
      List<Map<String, dynamic>> orders) {
    return orders
        .where((order) {
          final status = order['status']?.toString().toLowerCase() ?? '';
          return status != 'delivered' && status != 'cancelled';
        })
        .map((order) {
          final nestedOrder = order['order'] is Map<String, dynamic>
              ? Map<String, dynamic>.from(order['order'] as Map)
              : <String, dynamic>{};
            final nestedItems = nestedOrder['items'] is List
              ? List<Map<String, dynamic>>.from(
                (nestedOrder['items'] as List)
                  .whereType<Map>()
                  .map((e) => Map<String, dynamic>.from(e)),
              )
              : <Map<String, dynamic>>[];

            final orderItems = nestedItems
              .map((item) {
              final name = item['name']?.toString() ?? 'Item';
              final qty = _asInt(item['quantity'] ?? 1);
              return '$qty x $name';
              })
              .where((line) => line.trim().isNotEmpty)
              .toList();

          final status = order['status']?.toString() ?? 'confirmed';
          return ActiveDelivery(
            id: order['id']?.toString() ?? '',
            orderId: nestedOrder['id']?.toString(),
            restaurantName: order['restaurantName']?.toString() ??
                nestedOrder['restaurantName']?.toString() ??
                'Restaurant',
            customerName: order['customerName']?.toString() ??
                nestedOrder['customerName']?.toString() ??
                _customerLabel(order),
            customerPhone: order['customerPhone']?.toString() ??
              nestedOrder['customerPhone']?.toString(),
            customerAddress: order['customerAddress']?.toString() ??
                nestedOrder['customerAddress']?.toString() ??
                'N/A',
            estimatedEarning: _asDouble(order['estimatedEarning'] ??
                order['deliveryFee'] ??
                nestedOrder['deliveryFee'] ??
                nestedOrder['totalAmount'] ??
                order['totalAmount'] ??
                order['total_amount']),
            pickupLocation: order['pickupLocation']?.toString() ??
                nestedOrder['pickupLocation']?.toString() ??
                order['restaurantName']?.toString() ??
                nestedOrder['restaurantName']?.toString() ??
                'Pickup location',
            dropLocation: order['dropLocation']?.toString() ??
                nestedOrder['dropLocation']?.toString() ??
                order['customerAddress']?.toString() ??
                nestedOrder['customerAddress']?.toString() ??
                'Drop-off location',
            pickupLatitude: _asNullableDouble(nestedOrder['restaurantLatitude']),
            pickupLongitude: _asNullableDouble(
              nestedOrder['restaurantLongitude'],
            ),
            dropLatitude: _asNullableDouble(nestedOrder['customerLatitude']),
            dropLongitude: _asNullableDouble(nestedOrder['customerLongitude']),
            orderItems: orderItems,
            status: status,
            otp: order['otp']?.toString(),
            createdAt: _parseDate(order['createdAt'] ??
                    order['created_at'] ??
                    nestedOrder['createdAt'] ??
                    nestedOrder['created_at']) ??
                DateTime.now(),
          );
        })
        .where((delivery) => delivery.id.isNotEmpty)
        .toList();
  }

  List<IncomingDeliveryRequest> _buildIncomingRequests(
      List<Map<String, dynamic>> requests) {
    return requests
        .map((request) {
          final order = request['order'] is Map<String, dynamic>
              ? Map<String, dynamic>.from(request['order'] as Map)
              : <String, dynamic>{};

          return IncomingDeliveryRequest(
            id: request['id']?.toString() ?? '',
            orderId:
                request['orderId']?.toString() ?? order['id']?.toString() ?? '',
            status: request['status']?.toString() ?? 'pending',
            restaurantName: order['restaurantName']?.toString() ?? 'Restaurant',
            customerName: order['customerName']?.toString() ?? 'Customer',
            customerPhone: order['customerPhone']?.toString() ?? '-',
            customerEmail: order['customerEmail']?.toString() ?? '-',
            customerAddress: order['customerAddress']?.toString() ?? '-',
            totalAmount: _asDouble(order['totalAmount']),
            deliveryFee: _asDouble(order['deliveryFee']),
            estimatedDeliveryTime: _parseDate(order['estimatedDeliveryTime']),
            createdAt: _parseDate(request['createdAt']) ?? DateTime.now(),
          );
        })
        .where((request) => request.id.isNotEmpty)
        .toList();
  }

  List<MapEntry<String, double>> _buildWeeklyBreakdown(
    List<EarningRecord> earnings,
  ) {
    const weekdayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final totals = <String, double>{
      for (final label in weekdayLabels) label: 0
    };

    for (final record in earnings) {
      final label = weekdayLabels[record.date.weekday - 1];
      totals[label] = (totals[label] ?? 0) + record.amount;
    }

    return weekdayLabels
        .map((label) => MapEntry(label, totals[label] ?? 0))
        .toList();
  }

  Future<void> loadFromBackend({
    required String token,
    AuthUser? fallbackUser,
  }) async {
    _currentToken = token;
    state = state.copyWith(isLoading: true, error: null);

    try {
      final dashboardResponse =
          await _apiClient.getMyDeliveryDashboard(token: token);
      final data = dashboardResponse['data'] is Map<String, dynamic>
          ? Map<String, dynamic>.from(dashboardResponse['data'] as Map)
          : <String, dynamic>{};

      final profileData = data['profile'] is Map<String, dynamic>
          ? Map<String, dynamic>.from(data['profile'] as Map)
          : <String, dynamic>{};

      final summaryData = data['summary'] is Map<String, dynamic>
          ? Map<String, dynamic>.from(data['summary'] as Map)
          : <String, dynamic>{};

      final metricsData = data['metrics'] is Map<String, dynamic>
          ? Map<String, dynamic>.from(data['metrics'] as Map)
          : <String, dynamic>{};

      final activeDeliveriesRaw = data['activeDeliveries'];
      final activeOrders = activeDeliveriesRaw is List
          ? activeDeliveriesRaw
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList()
          : <Map<String, dynamic>>[];

      final incomingRaw = data['incomingRequests'];
      final incomingRequests = incomingRaw is List
          ? incomingRaw
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList()
          : <Map<String, dynamic>>[];

      final earningsRaw = data['earnings'];
      final earnings = earningsRaw is List
          ? earningsRaw
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .map(
                (item) => EarningRecord(
                  id: item['id']?.toString() ?? '',
                  deliveryId: item['deliveryId']?.toString() ??
                      item['id']?.toString() ??
                      '',
                  amount: _asDouble(item['amount']),
                  date: _parseDate(item['date']) ?? DateTime.now(),
                  status: item['status']?.toString() ?? 'completed',
                ),
              )
              .where((record) => record.id.isNotEmpty)
              .toList()
          : <EarningRecord>[];

      final weeklyRaw = data['weeklyEarningsBreakdown'];
      final weeklyBreakdown = weeklyRaw is List
          ? weeklyRaw
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .map((item) => MapEntry(
                    item['day']?.toString() ?? '',
                    _asDouble(item['amount']),
                  ))
              .where((entry) => entry.key.isNotEmpty)
              .toList()
          : _buildWeeklyBreakdown(earnings);

      state = state.copyWith(
        profile: _profileFromJson(profileData, fallbackUser: fallbackUser),
        activeDeliveries: _buildActiveDeliveries(activeOrders),
        incomingRequests: _buildIncomingRequests(incomingRequests),
        earnings: earnings,
        weeklyEarningsBreakdown: weeklyBreakdown,
        totalEarningsToday: _asDouble(metricsData['totalEarningsToday'] ?? 0),
        weeklyEarnings: _asDouble(metricsData['weeklyEarnings'] ?? 0),
        totalDeliveriesToday: _asInt(metricsData['totalDeliveriesToday'] ?? 0),
        isLoading: false,
        error: summaryData['totalDeliveries'] == null &&
                activeOrders.isEmpty &&
                earnings.isEmpty
            ? 'No delivery dashboard data returned by the backend.'
            : null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

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

  Future<void> acceptIncomingRequest(String requestId) async {
    final token = _currentToken;
    if (token == null || token.isEmpty) {
      state = state.copyWith(error: 'Authentication required');
      return;
    }

    try {
      await _apiClient.acceptDeliveryRequest(
          token: token, requestId: requestId);
      await loadFromBackend(token: token);
    } catch (e) {
      state = state.copyWith(
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<void> rejectIncomingRequest(String requestId, {String? reason}) async {
    final token = _currentToken;
    if (token == null || token.isEmpty) {
      state = state.copyWith(error: 'Authentication required');
      return;
    }

    try {
      await _apiClient.rejectDeliveryRequest(
        token: token,
        requestId: requestId,
        reason: reason,
      );
      await loadFromBackend(token: token);
    } catch (e) {
      state = state.copyWith(
        error: e.toString().replaceAll('Exception: ', ''),
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
      final token = _currentToken;
      final payload = <String, dynamic>{
        'name': newProfile.name,
        'email': newProfile.email,
        'phone': newProfile.phone,
      }..removeWhere(
          (_, value) => value == null || value.toString().trim().isEmpty);

      if (token != null && token.isNotEmpty && payload.isNotEmpty) {
        // The current backend only exposes the authenticated user's profile
        // fields, so we update the shared user record and keep delivery-only
        // attributes such as vehicle type local for now.
        final response = await _apiClient.updateProfile(
          token: token,
          payload: payload,
        );

        final updatedUser = response['user'] is Map<String, dynamic>
            ? Map<String, dynamic>.from(response['user'] as Map)
            : <String, dynamic>{};

        state = state.copyWith(
          profile: newProfile.copyWith(
            name: updatedUser['name']?.toString() ?? newProfile.name,
            email: updatedUser['email']?.toString() ?? newProfile.email,
            phone: updatedUser['phone']?.toString() ?? newProfile.phone,
          ),
          isLoading: false,
        );
        return;
      }

      state = state.copyWith(profile: newProfile, isLoading: false);
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
  final notifier = DeliveryPanelNotifier(apiClient: ApiClient());

  void refreshFromAuth(AuthState authState) {
    final token = authState.token;
    if (token == null || token.isEmpty) return;
    unawaited(
      notifier.loadFromBackend(
        token: token,
        fallbackUser: authState.user,
      ),
    );
  }

  ref.listen<AuthState>(authProvider, (_, next) {
    refreshFromAuth(next);
  });

  refreshFromAuth(ref.read(authProvider));

  return notifier;
});

/// Weekly Earnings Data Provider
final weeklyEarningsDataProvider =
    Provider<List<MapEntry<String, double>>>((ref) {
  return ref.watch(
    deliveryPanelProvider.select((state) => state.weeklyEarningsBreakdown),
  );
});
