import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../config/theme/app_theme.dart';
import '../../../../presentation/widgets/curved_panel_bottom_nav.dart';
import '../../../authentication/data/services/api_client.dart';
import '../../../authentication/presentation/providers/auth_provider.dart';

class OrderTrackingScreen extends ConsumerStatefulWidget {
  final String? orderId;

  const OrderTrackingScreen({Key? key, this.orderId}) : super(key: key);

  @override
  ConsumerState<OrderTrackingScreen> createState() =>
      _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends ConsumerState<OrderTrackingScreen> {
  static const _timelineStatuses = [
    'Pending confirmation',
    'Accepted by restaurant',
    'Preparing your food',
    'Ready for pickup',
    'On the way',
    'Delivered',
  ];

  static const _paymentMethods = [
    ('Cash on Delivery', 'cash', 'Pay the rider when order arrives'),
    ('Card', 'credit_card', 'Pay now securely with card'),
  ];

  Timer? _timer;
  StreamSubscription<Map<String, dynamic>>? _eventsSubscription;
  bool _isLoading = true;
  bool _isSubmittingPayment = false;
  bool _isStreamConnected = false;
  String? _error;
  Map<String, dynamic>? _order;
  int _selectedPaymentMethod = 0;

  @override
  void initState() {
    super.initState();
    _fetchOrder(showLoader: true);
    _connectLiveUpdates();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _fetchOrder());
  }

  @override
  void dispose() {
    _eventsSubscription?.cancel();
    _timer?.cancel();
    super.dispose();
  }

  void _connectLiveUpdates() {
    final orderId = widget.orderId;
    final token = ref.read(authProvider).token;

    if (orderId == null || orderId.isEmpty || token == null || token.isEmpty) {
      return;
    }

    _eventsSubscription?.cancel();
    if (mounted) {
      setState(() {
        _isStreamConnected = false;
      });
    }
    _eventsSubscription =
        ApiClient().streamMyOrderEvents(token: token, orderId: orderId).listen(
      (event) {
        if (!mounted) return;
        setState(() {
          _order = event;
          _error = null;
          _isLoading = false;
          _isStreamConnected = true;
        });

        final status = (event['status'] ?? event['order_status'] ?? 'pending')
            .toString()
            .toLowerCase();

        if (status == 'delivered' || status == 'cancelled') {
          _timer?.cancel();
        }
      },
      onError: (_) {
        if (!mounted) return;
        setState(() {
          _isStreamConnected = false;
        });
      },
      cancelOnError: false,
    );
  }

  Future<void> _fetchOrder({bool showLoader = false}) async {
    if (widget.orderId == null || widget.orderId!.isEmpty) {
      setState(() {
        _error = 'Missing order id. Please open this screen from checkout.';
        _isLoading = false;
      });
      return;
    }

    final token = ref.read(authProvider).token;
    if (token == null || token.isEmpty) {
      setState(() {
        _error = 'Please log in to track this order.';
        _isLoading = false;
      });
      return;
    }

    if (showLoader && mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final row = await ApiClient().getMyOrderById(
        token: token,
        orderId: widget.orderId!,
      );

      if (!mounted) return;
      setState(() {
        _order = row;
        _error = null;
        _isLoading = false;
      });

      final status = (row['status'] ?? row['order_status'] ?? 'pending')
          .toString()
          .toLowerCase();
      if (status == 'delivered' || status == 'cancelled') {
        _timer?.cancel();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
        _isStreamConnected = false;
      });
    }
  }

  int _statusIndexFromBackend(String status) {
    return switch (status) {
      'pending' => 0,
      'confirmed' => 1,
      'preparing' => 2,
      'ready' => 3,
      'on_the_way' => 4,
      'delivered' => 5,
      'cancelled' => 0,
      _ => 0,
    };
  }

  String _statusHeadline(String status) {
    return switch (status) {
      'pending' => 'Waiting for restaurant response',
      'confirmed' => 'Order accepted ✅',
      'preparing' => 'Restaurant is preparing your order',
      'ready' => 'Order is ready and assigned for delivery',
      'on_the_way' => 'Your order is on the way 🚚',
      'delivered' => 'Delivered 🎉',
      'cancelled' => 'Order rejected/cancelled',
      _ => 'Order update in progress',
    };
  }

  Future<void> _submitPayment() async {
    final token = ref.read(authProvider).token;
    final orderId = _order?['id']?.toString();
    if (token == null || token.isEmpty || orderId == null || orderId.isEmpty) {
      return;
    }

    setState(() => _isSubmittingPayment = true);
    try {
      await ApiClient().updateMyOrderPayment(
        token: token,
        orderId: orderId,
        paymentMethod: _paymentMethods[_selectedPaymentMethod].$2,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _selectedPaymentMethod == 0
                ? 'Cash on Delivery selected successfully.'
                : 'Card payment confirmed successfully.',
          ),
        ),
      );

      await _fetchOrder();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmittingPayment = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isGuest = !ref.watch(authProvider).isAuthenticated;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Live Order Tracking')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Live Order Tracking')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => _fetchOrder(showLoader: true),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: CurvedPanelBottomNav(
          items: [
            CurvedNavItemData(
              icon: Icons.home_outlined,
              selectedIcon: Icons.home,
              label: 'Home',
              isSelected: false,
              onTap: () => context.go('/'),
            ),
            CurvedNavItemData(
              icon: Icons.search_outlined,
              selectedIcon: Icons.search,
              label: 'Browse',
              isSelected: false,
              onTap: () => context.go('/browse'),
            ),
            CurvedNavItemData(
              icon: Icons.shopping_cart_outlined,
              selectedIcon: Icons.shopping_cart,
              label: 'Cart',
              isSelected: false,
              onTap: () => context.go('/cart'),
            ),
            CurvedNavItemData(
              icon: Icons.person_outline,
              selectedIcon: Icons.person,
              label: 'Account',
              isSelected: false,
              onTap: () =>
                  isGuest ? context.push('/login') : context.go('/dashboard'),
            ),
          ],
        ),
      );
    }

    final selected = _order!;
    final orderId = selected['id']?.toString() ?? '—';
    final status = (selected['status'] ?? selected['order_status'] ?? 'pending')
        .toString();
    final paymentStatus =
        (selected['paymentStatus'] ?? selected['payment_status'] ?? 'pending')
            .toString();
    final paymentMethod =
        (selected['paymentMethod'] ?? selected['payment_method'] ?? 'cash')
            .toString();

    final statusIndex = _statusIndexFromBackend(status);
    final progress = (statusIndex + 1) / _timelineStatuses.length;

    final cameraCenter = LatLng(
      (23.7806 + 23.7678) / 2,
      (90.4070 + 90.4250) / 2,
    );

    final statusStep =
        (statusIndex / (_timelineStatuses.length - 1)).clamp(0, 1).toDouble();
    const restaurantLat = 23.7806;
    const restaurantLng = 90.4070;
    const customerLat = 23.7678;
    const customerLng = 90.4250;
    final riderLat = restaurantLat + (customerLat - restaurantLat) * statusStep;
    final riderLng = restaurantLng + (customerLng - restaurantLng) * statusStep;

    final markers = {
      Marker(
        markerId: const MarkerId('restaurant'),
        position: const LatLng(restaurantLat, restaurantLng),
        infoWindow: const InfoWindow(title: 'Restaurant'),
      ),
      Marker(
        markerId: const MarkerId('customer'),
        position: const LatLng(customerLat, customerLng),
        infoWindow: const InfoWindow(title: 'Your location'),
      ),
      Marker(
        markerId: const MarkerId('rider'),
        position: LatLng(riderLat, riderLng),
        infoWindow: const InfoWindow(title: 'Delivery rider'),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueAzure,
        ),
      ),
    };

    final polylines = {
      Polyline(
        polylineId: const PolylineId('route_to_customer'),
        color: AppColors.primaryOrange,
        width: 5,
        points: [
          const LatLng(restaurantLat, restaurantLng),
          LatLng(riderLat, riderLng),
          const LatLng(customerLat, customerLng),
        ],
      ),
    };

    final itemsRaw = selected['items'];
    final itemLines = <String>[];
    if (itemsRaw is List) {
      for (final item in itemsRaw) {
        if (item is Map) {
          final name = item['name']?.toString() ?? 'Item';
          final qty = int.tryParse(item['quantity']?.toString() ?? '1') ?? 1;
          itemLines.add('$qty x $name');
        }
      }
    }

    final canShowPayment = status == 'confirmed' && paymentStatus == 'pending';
    final isRejected = status == 'cancelled';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Order Tracking'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                height: 220,
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: cameraCenter,
                    zoom: 13.5,
                  ),
                  markers: markers,
                  polylines: polylines,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Text(
                status == 'delivered'
                    ? 'Delivered'
                    : (isRejected ? 'Order cancelled' : 'ETA: 20-35 min'),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _statusHeadline(status),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _isStreamConnected
                        ? Colors.green.withValues(alpha: 0.12)
                        : Colors.grey.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: _isStreamConnected
                          ? Colors.green.withValues(alpha: 0.45)
                          : Colors.grey.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.circle,
                        size: 8,
                        color: _isStreamConnected ? Colors.green : Colors.grey,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _isStreamConnected ? 'Live' : 'Fallback',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          color: _isStreamConnected
                              ? Colors.green.shade800
                              : Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Order #${orderId.length >= 6 ? orderId.substring(orderId.length - 6) : orderId} • ${itemLines.length} items',
              style: const TextStyle(color: AppColors.muted),
            ),
            const SizedBox(height: 6),
            Text(
              'Payment: $paymentMethod • Status: $paymentStatus',
              style: const TextStyle(color: AppColors.muted),
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              borderRadius: BorderRadius.circular(999),
            ),
            const SizedBox(height: 16),
            ...List.generate(
              _timelineStatuses.length,
              (index) => ListTile(
                dense: true,
                leading: Icon(
                  index <= statusIndex
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  color: index <= statusIndex ? Colors.green : AppColors.muted,
                ),
                title: Text(_timelineStatuses[index]),
              ),
            ),
            if (itemLines.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text(
                'Order items',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              ...itemLines.map((line) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text('• $line'),
                  )),
            ],
            if (canShowPayment) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Choose payment method',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 10),
                    ...List.generate(_paymentMethods.length, (index) {
                      final method = _paymentMethods[index];
                      return RadioListTile<int>(
                        value: index,
                        groupValue: _selectedPaymentMethod,
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text(method.$1),
                        subtitle: Text(method.$3),
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() => _selectedPaymentMethod = value);
                        },
                      );
                    }),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSubmittingPayment ? null : _submitPayment,
                        child: _isSubmittingPayment
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Confirm Payment Method'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () => context.go('/dashboard/orders'),
              icon: const Icon(Icons.receipt_long),
              label: const Text('View my orders'),
            ),
          ],
        ),
      ),
      bottomNavigationBar: CurvedPanelBottomNav(
        items: [
          CurvedNavItemData(
            icon: Icons.home_outlined,
            selectedIcon: Icons.home,
            label: 'Home',
            isSelected: false,
            onTap: () => context.go('/'),
          ),
          CurvedNavItemData(
            icon: Icons.search_outlined,
            selectedIcon: Icons.search,
            label: 'Browse',
            isSelected: false,
            onTap: () => context.go('/browse'),
          ),
          CurvedNavItemData(
            icon: Icons.receipt_long_outlined,
            selectedIcon: Icons.receipt_long,
            label: 'Orders',
            isSelected: true,
            onTap: () => context.go('/dashboard/orders'),
          ),
          CurvedNavItemData(
            icon: Icons.person_outline,
            selectedIcon: Icons.person,
            label: 'Account',
            isSelected: false,
            onTap: () =>
                isGuest ? context.push('/login') : context.go('/dashboard'),
          ),
        ],
      ),
    );
  }
}
