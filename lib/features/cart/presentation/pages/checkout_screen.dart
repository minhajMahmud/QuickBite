import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/theme/app_theme.dart';
import '../../../../presentation/providers/app_providers.dart';
import '../../../../presentation/widgets/curved_panel_bottom_nav.dart';
import '../../../authentication/presentation/providers/auth_provider.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  bool _showPaymentOptions = false;
  int _selectedMethod = 0;
  final TextEditingController _promoController = TextEditingController();
  double _discountAmount = 0;
  String? _appliedPromoCode;
  String? _promoFeedback;

  final List<_PaymentMethod> _paymentMethods = const [
    _PaymentMethod(label: 'Cash on delivery', suffix: ''),
    _PaymentMethod(label: 'GCash', suffix: '****** 1234'),
    _PaymentMethod(label: 'Paymaya', suffix: '****** 1234'),
    _PaymentMethod(label: 'Paypal', suffix: '****** 1234'),
    _PaymentMethod(label: 'MasterCard', suffix: '****** 1234'),
    _PaymentMethod(label: 'Visa', suffix: '****** 1234'),
  ];

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
          feedback = 'BITE20 needs a minimum subtotal of ₱25.';
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

  Future<void> _showReceiptDialog({
    required BuildContext context,
    required List cartItems,
    required double subtotal,
    required double deliveryFee,
    required double discount,
    required double total,
    required String paymentMethod,
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
                      '• ${item.quantity} x ${item.food.name} (₱${item.subtotal.toStringAsFixed(2)})',
                    ),
                  ),
                ),
                const Divider(height: 16),
                Text('Payment: $paymentMethod'),
                Text('Subtotal: ₱${subtotal.toStringAsFixed(2)}'),
                Text('Delivery: ₱${deliveryFee.toStringAsFixed(2)}'),
                Text('Discount: -₱${discount.toStringAsFixed(2)}'),
                const SizedBox(height: 6),
                Text(
                  'Total Paid: ₱${total.toStringAsFixed(2)}',
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
              child: Row(
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
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Location',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Barangay 10 - Cabugao,\nLegaspi, Albay',
                          style: TextStyle(color: AppColors.muted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _sectionCard(
              context,
              title: 'Payment Method',
              child: Column(
                children: [
                  InkWell(
                    onTap: () {
                      setState(
                          () => _showPaymentOptions = !_showPaymentOptions);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          const Icon(Icons.account_balance_wallet_outlined,
                              color: Color(0xFFFF0B72)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _paymentMethods[_selectedMethod].label,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                          Icon(_showPaymentOptions
                              ? Icons.keyboard_arrow_up
                              : Icons.keyboard_arrow_down),
                        ],
                      ),
                    ),
                  ),
                  AnimatedCrossFade(
                    duration: const Duration(milliseconds: 180),
                    crossFadeState: _showPaymentOptions
                        ? CrossFadeState.showSecond
                        : CrossFadeState.showFirst,
                    firstChild: const SizedBox.shrink(),
                    secondChild: Container(
                      margin: const EdgeInsets.only(top: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: theme.dividerColor.withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        children:
                            List.generate(_paymentMethods.length, (index) {
                          final method = _paymentMethods[index];
                          final selected = index == _selectedMethod;
                          return Column(
                            children: [
                              ListTile(
                                onTap: () {
                                  setState(() {
                                    _selectedMethod = index;
                                    _showPaymentOptions = false;
                                  });
                                },
                                leading: CircleAvatar(
                                  backgroundColor: selected
                                      ? const Color(0xFFFF0B72)
                                          .withOpacity(0.12)
                                      : theme.dividerColor.withOpacity(0.12),
                                  child: Text(
                                    method.label[0],
                                    style: TextStyle(
                                      color: selected
                                          ? const Color(0xFFFF0B72)
                                          : theme.textTheme.bodyMedium?.color,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                title: Text(method.label),
                                subtitle: method.suffix.isEmpty
                                    ? null
                                    : Text(method.suffix),
                                trailing: selected
                                    ? const Icon(Icons.check_circle,
                                        color: Color(0xFFFF0B72))
                                    : null,
                              ),
                              if (index != _paymentMethods.length - 1)
                                Divider(
                                  height: 1,
                                  color: theme.dividerColor.withOpacity(0.2),
                                ),
                            ],
                          );
                        }),
                      ),
                    ),
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
                                      '₱ ${(item.food.price * item.quantity).toStringAsFixed(0)}',
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
                      'Shipping cost', '₱${deliveryFee.toStringAsFixed(0)}'),
                  const SizedBox(height: 8),
                  _summaryRow('Sub Total', '₱${totalPrice.toStringAsFixed(0)}'),
                  const SizedBox(height: 8),
                  _summaryRow(
                    'Total',
                    '₱${grandTotal.toStringAsFixed(0)}',
                    emphasize: true,
                  ),
                  if (_discountAmount > 0) ...[
                    const SizedBox(height: 8),
                    _summaryRow(
                      _appliedPromoCode == null
                          ? 'Promo Discount'
                          : 'Promo ($_appliedPromoCode)',
                      '-₱${_discountAmount.toStringAsFixed(0)}',
                    ),
                    const SizedBox(height: 8),
                    _summaryRow(
                      'Payable',
                      '₱${discountedTotal.toStringAsFixed(0)}',
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
                onPressed: cartItems.isEmpty
                    ? null
                    : () async {
                        final trackingOrder = ref
                            .read(ongoingOrdersProvider.notifier)
                            .createOrderFromCart(
                              cartItems: cartItems,
                              total: discountedTotal,
                            );

                        await _showReceiptDialog(
                          context: context,
                          cartItems: cartItems,
                          subtotal: totalPrice,
                          deliveryFee: deliveryFee,
                          discount: _discountAmount,
                          total: discountedTotal,
                          paymentMethod: _paymentMethods[_selectedMethod].label,
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Order placed with ${_paymentMethods[_selectedMethod].label}! 🎉',
                            ),
                          ),
                        );
                        ref.read(cartProvider.notifier).clearCart();
                        context
                            .go('/order-tracking?orderId=${trackingOrder.id}');
                      },
                child: const Text('Place Order'),
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

class _PaymentMethod {
  final String label;
  final String suffix;

  const _PaymentMethod({required this.label, required this.suffix});
}
