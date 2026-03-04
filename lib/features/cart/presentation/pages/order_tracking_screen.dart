import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../config/theme/app_theme.dart';
import '../../../../presentation/providers/app_providers.dart';
import '../../../../presentation/widgets/curved_panel_bottom_nav.dart';

class OrderTrackingScreen extends ConsumerStatefulWidget {
  final String? orderId;

  const OrderTrackingScreen({Key? key, this.orderId}) : super(key: key);

  @override
  ConsumerState<OrderTrackingScreen> createState() =>
      _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends ConsumerState<OrderTrackingScreen> {
  static const _statuses = [
    'Order Confirmed',
    'Preparing your food',
    'Rider picked up order',
    'On the way',
    'Delivered',
  ];

  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!mounted) return;

      final order = _selectedOrder(ref.read(ongoingOrdersProvider));
      if (order == null) return;

      if (order.status == OngoingOrderStatus.delivered) {
        timer.cancel();
      } else {
        ref.read(ongoingOrdersProvider.notifier).advanceTracking(order.id);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  OngoingOrder? _selectedOrder(List<OngoingOrder> orders) {
    if (orders.isEmpty) return null;
    if (widget.orderId == null || widget.orderId!.isEmpty) {
      return orders.first;
    }
    for (final order in orders) {
      if (order.id == widget.orderId) {
        return order;
      }
    }
    return orders.first;
  }

  int _statusIndexFromState(OngoingOrderStatus status) {
    return switch (status) {
      OngoingOrderStatus.confirmed => 0,
      OngoingOrderStatus.preparing => 1,
      OngoingOrderStatus.pickedUp => 2,
      OngoingOrderStatus.onTheWay => 3,
      OngoingOrderStatus.delivered => 4,
    };
  }

  @override
  Widget build(BuildContext context) {
    final orders = ref.watch(ongoingOrdersProvider);
    final selected = _selectedOrder(orders);

    if (selected == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Live Order Tracking')),
        body: const Center(
          child: Text('No ongoing orders to track yet.'),
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
              onTap: () => context.go('/dashboard'),
            ),
          ],
        ),
      );
    }

    final statusIndex = _statusIndexFromState(selected.status);
    final progress = (statusIndex + 1) / _statuses.length;

    final cameraCenter = LatLng(
      (selected.restaurantLat + selected.customerLat) / 2,
      (selected.restaurantLng + selected.customerLng) / 2,
    );

    final markers = {
      Marker(
        markerId: const MarkerId('restaurant'),
        position: LatLng(selected.restaurantLat, selected.restaurantLng),
        infoWindow: const InfoWindow(title: 'Restaurant'),
      ),
      Marker(
        markerId: const MarkerId('customer'),
        position: LatLng(selected.customerLat, selected.customerLng),
        infoWindow: const InfoWindow(title: 'Your location'),
      ),
      Marker(
        markerId: const MarkerId('rider'),
        position: LatLng(selected.riderLat, selected.riderLng),
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
          LatLng(selected.restaurantLat, selected.restaurantLng),
          LatLng(selected.riderLat, selected.riderLng),
          LatLng(selected.customerLat, selected.customerLng),
        ],
      ),
    };

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
                selected.etaMinutes == 0
                    ? 'Delivered'
                    : 'ETA: ${selected.etaMinutes} min',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _statuses[statusIndex],
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              'Order #${selected.id.substring(selected.id.length - 6)} • ${selected.items.length} items',
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
              _statuses.length,
              (index) => ListTile(
                dense: true,
                leading: Icon(
                  index <= statusIndex
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  color: index <= statusIndex ? Colors.green : AppColors.muted,
                ),
                title: Text(_statuses[index]),
              ),
            ),
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
            onTap: () => context.go('/dashboard'),
          ),
        ],
      ),
    );
  }
}
