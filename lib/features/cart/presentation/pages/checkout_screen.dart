import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/theme/app_theme.dart';
import '../../../../presentation/providers/app_providers.dart';
import '../../../../presentation/widgets/curved_panel_bottom_nav.dart';
import '../../../authentication/data/services/api_client.dart';
import '../../../authentication/presentation/providers/auth_provider.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final TextEditingController _promoController = TextEditingController();
  double _discountAmount = 0;
  String? _appliedPromoCode;
  String? _promoFeedback;
  bool _isPlacingOrder = false;
  String _deliveryLocationLabel = 'Home';
  String _deliveryAddress = 'Barangay 10 - Cabugao, Legaspi, Albay';
  double? _deliveryLatitude = 13.1391;
  double? _deliveryLongitude = 123.7438;

  @override
  void dispose() {
    _promoController.dispose();
    super.dispose();
  }

  void _applyPromo(double subtotal, double deliveryFee) {
    final code = _promoController.text.trim().toUpperCase();
    if (code.isEmpty) {
      setState(() {
        _discountAmount = 0;
        _appliedPromoCode = null;
        _promoFeedback = 'Enter a promo code first.';
      });
      return;
    }

    double discount = 0;
    String feedback;

    switch (code) {
      case 'SAVE10':
        discount = subtotal * 0.10;
        feedback = 'SAVE10 applied: 10% off subtotal.';
        break;
      case 'BITE20':
        if (subtotal >= 25) {
          discount = subtotal * 0.20;
          feedback = 'BITE20 applied: 20% off subtotal.';
        } else {
          feedback = 'BITE20 needs a minimum subtotal of ৳25.';
        }
        break;
      case 'FREEDEL':
        discount = deliveryFee;
        feedback = 'FREEDEL applied: delivery fee removed.';
        break;
      default:
        feedback = 'Invalid code. Try SAVE10, BITE20, or FREEDEL.';
    }

    setState(() {
      _discountAmount = discount;
      _appliedPromoCode = discount > 0 ? code : null;
      _promoFeedback = feedback;
    });
  }

  Future<void> _showEditAddressDialog() async {
    final locationController =
        TextEditingController(text: _deliveryLocationLabel);
    final addressController = TextEditingController(text: _deliveryAddress);
    final latitudeController = TextEditingController(
      text: _deliveryLatitude?.toStringAsFixed(6) ?? '',
    );
    final longitudeController = TextEditingController(
      text: _deliveryLongitude?.toStringAsFixed(6) ?? '',
    );

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit delivery address'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: locationController,
                  decoration: const InputDecoration(
                    labelText: 'Location label',
                    hintText: 'Home / Office',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: addressController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Full address',
                    hintText: 'Street, area, city',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: latitudeController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Latitude (optional)',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: longitudeController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Longitude (optional)',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final nextLocation = locationController.text.trim();
                final nextAddress = addressController.text.trim();
                final lat = double.tryParse(latitudeController.text.trim());
                final lng = double.tryParse(longitudeController.text.trim());

                setState(() {
                  _deliveryLocationLabel =
                      nextLocation.isEmpty ? 'Location' : nextLocation;
                  _deliveryAddress =
                      nextAddress.isEmpty ? _deliveryAddress : nextAddress;
                  _deliveryLatitude = lat;
                  _deliveryLongitude = lng;
                });

                Navigator.of(context).pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    locationController.dispose();
    addressController.dispose();
    latitudeController.dispose();
    longitudeController.dispose();
  }

  Future<void> _showReceiptDialog({
    required BuildContext context,
    required List cartItems,
    required double subtotal,
    required double deliveryFee,
    required double discount,
    required double total,
    required String orderId,
    required String locationLabel,
    required String address,
    required double? latitude,
    required double? longitude,
  }) {
    return showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Order Receipt'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                ...cartItems.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      '• ${item.quantity} x ${item.food.name} (৳${item.subtotal.toStringAsFixed(2)})',
                    ),
                  ),
                ),
                const Divider(height: 16),
                Text('Order ID: $orderId'),
                const Text('Payment: Pending restaurant acceptance'),
                Text('Delivery To: $locationLabel'),
                Text('Address: $address'),
                if (latitude != null && longitude != null)
                  Text(
                    'Coordinates: ${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}',
                  ),
                Text('Subtotal: ৳${subtotal.toStringAsFixed(2)}'),
                Text('Delivery: ৳${deliveryFee.toStringAsFixed(2)}'),
                Text('Discount: -৳${discount.toStringAsFixed(2)}'),
                const SizedBox(height: 6),
                Text(
                  'Total Paid: ৳${total.toStringAsFixed(2)} BDT',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cartItems = ref.watch(cartProvider);
    final totalPrice = ref.watch(cartTotalPriceProvider);
    final deliveryFee = ref.watch(deliveryFeeProvider);
    final grandTotal = ref.watch(cartGrandTotalProvider);
    final isGuest = !ref.watch(authProvider).isAuthenticated;
    final theme = Theme.of(context);
    final discountedTotal =
        (grandTotal - _discountAmount).clamp(0, double.infinity).toDouble();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Check Out'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 20),
          children: [
            _sectionCard(
              context,
              title: 'Address',
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 118,
                        height: 86,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: theme.brightness == Brightness.dark
                              ? Colors.white.withOpacity(0.05)
                              : const Color(0xFFF1F3F8),
                        ),
                        child: Stack(
                          children: [
                            const Center(
                              child: Icon(Icons.map_outlined,
                                  size: 34, color: AppColors.muted),
                            ),
                            Positioned(
                              right: 8,
                              bottom: 8,
                              child: Container(
                                width: 10,
                                height: 10,
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _deliveryLocationLabel,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _deliveryAddress,
                              style: const TextStyle(color: AppColors.muted),
                            ),
                            if (_deliveryLatitude != null &&
                                _deliveryLongitude != null) ...[
                              const SizedBox(height: 6),
                              Text(
                                'Lat: ${_deliveryLatitude!.toStringAsFixed(6)}, Lng: ${_deliveryLongitude!.toStringAsFixed(6)}',
                                style: const TextStyle(
                                  color: AppColors.muted,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: OutlinedButton.icon(
                      onPressed: _showEditAddressDialog,
                      icon: const Icon(Icons.edit_location_alt_outlined),
                      label: const Text('Edit Address & Location'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _sectionCard(
              context,
              title: 'Payment',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF0B72).withOpacity(0.10),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.account_balance_wallet_outlined,
                          color: Color(0xFFFF0B72),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Restaurant will first accept/reject your order.\nYou can choose Card or Cash on Delivery after acceptance.',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'All prices are shown in BDT (৳).',
                    style: TextStyle(color: AppColors.muted),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _sectionCard(
              context,
              title: 'In your Cart:',
              child: cartItems.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: Text('No items in cart yet.'),
                    )
                  : Column(
                      children: cartItems.map((item) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(999),
                                child: Image.network(
                                  item.food.image,
                                  width: 44,
                                  height: 44,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    width: 44,
                                    height: 44,
                                    color: AppColors.secondaryLight,
                                    child: const Icon(Icons.fastfood),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${item.quantity}-pc. ${item.food.name}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '৳ ${(item.food.price * item.quantity).toStringAsFixed(0)}',
                                      style: const TextStyle(
                                        color: Color(0xFFFF0B72),
                                        fontSize: 24,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
            ),
            const SizedBox(height: 12),
            _sectionCard(
              context,
              title: 'Add Voucher or Promo Code',
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _promoController,
                          decoration: const InputDecoration(
                            hintText: 'Enter code (SAVE10/BITE20/FREEDEL)',
                            prefixIcon: Icon(Icons.discount_outlined),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () => _applyPromo(totalPrice, deliveryFee),
                        child: const Text('Apply'),
                      ),
                    ],
                  ),
                  if (_promoFeedback != null) ...[
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _promoFeedback!,
                        style: TextStyle(
                          color:
                              _discountAmount > 0 ? Colors.green : Colors.red,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: theme.dividerColor.withOpacity(0.25),
                ),
              ),
              child: Column(
                children: [
                  _summaryRow(
                      'Shipping cost', '৳${deliveryFee.toStringAsFixed(0)}'),
                  const SizedBox(height: 8),
                  _summaryRow('Sub Total', '৳${totalPrice.toStringAsFixed(0)}'),
                  const SizedBox(height: 8),
                  _summaryRow(
                    'Total',
                    '৳${grandTotal.toStringAsFixed(0)}',
                    emphasize: true,
                  ),
                  if (_discountAmount > 0) ...[
                    const SizedBox(height: 8),
                    _summaryRow(
                      _appliedPromoCode == null
                          ? 'Promo Discount'
                          : 'Promo ($_appliedPromoCode)',
                      '-৳${_discountAmount.toStringAsFixed(0)}',
                    ),
                    const SizedBox(height: 8),
                    _summaryRow(
                      'Payable',
                      '৳${discountedTotal.toStringAsFixed(0)} BDT',
                      emphasize: true,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: cartItems.isEmpty || _isPlacingOrder
                    ? null
                    : () async {
                        if (isGuest) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please log in to place an order.'),
                            ),
                          );
                          context.push('/login');
                          return;
                        }

                        final token = ref.read(authProvider).token;
                        if (token == null || token.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Authentication expired. Please log in again.',
                              ),
                            ),
                          );
                          context.push('/login');
                          return;
                        }

                        final restaurantIds = cartItems
                            .map((item) => item.food.restaurantId)
                            .toSet();

                        if (restaurantIds.length != 1) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Please keep items from one restaurant per order.',
                              ),
                            ),
                          );
                          return;
                        }

                        final restaurantId = restaurantIds.first;
                        final orderItems = cartItems
                            .map<Map<String, dynamic>>(
                              (item) => {
                                'foodItemId': item.food.id,
                                'quantity': item.quantity,
                                'unitPrice': item.food.price,
                                'itemTotal': item.subtotal,
                              },
                            )
                            .toList();

                        setState(() => _isPlacingOrder = true);
                        try {
                          final createdOrder = await ApiClient().createOrder(
                            token: token,
                            restaurantId: restaurantId,
                            items: orderItems,
                            totalAmount: discountedTotal,
                          );

                          if (!mounted) return;
                          final orderId = createdOrder['id']?.toString() ?? '';

                          await _showReceiptDialog(
                            context: context,
                            cartItems: cartItems,
                            subtotal: totalPrice,
                            deliveryFee: deliveryFee,
                            discount: _discountAmount,
                            total: discountedTotal,
                            orderId: orderId,
                            locationLabel: _deliveryLocationLabel,
                            address: _deliveryAddress,
                            latitude: _deliveryLatitude,
                            longitude: _deliveryLongitude,
                          );

                          if (!mounted) return;

                          ref.read(cartProvider.notifier).clearCart();

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Order sent to restaurant. Waiting for acceptance.',
                              ),
                            ),
                          );

                          if (orderId.isNotEmpty) {
                            context.go('/order-tracking?orderId=$orderId');
                          } else {
                            context.go('/dashboard/orders');
                          }
                        } catch (e) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(e.toString())),
                          );
                        } finally {
                          if (mounted) {
                            setState(() => _isPlacingOrder = false);
                          }
                        }
                      },
                child: _isPlacingOrder
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        isGuest
                            ? 'Sign in to Place Order'
                            : 'Place Order in BDT',
                      ),
              ),
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
            icon: Icons.shopping_cart_outlined,
            selectedIcon: Icons.shopping_cart,
            label: 'Cart',
            isSelected: true,
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

  Widget _sectionCard(
    BuildContext context, {
    required String title,
    required Widget child,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 2, bottom: 8),
            child: Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, {bool emphasize = false}) {
    final style = TextStyle(
      fontWeight: emphasize ? FontWeight.w700 : FontWeight.w500,
      fontSize: emphasize ? 15 : 13,
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: style.copyWith(color: AppColors.muted)),
        Text(value, style: style),
      ],
    );
  }
}
