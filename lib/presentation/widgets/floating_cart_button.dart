import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Floating Cart Button widget - animated cart button with item count
class FloatingCartButton extends StatelessWidget {
  final int itemCount;
  final VoidCallback onPressed;

  const FloatingCartButton({
    Key? key,
    required this.itemCount,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FloatingActionButton(
      onPressed: onPressed,
      heroTag: 'floating-cart-button',
      backgroundColor: theme.primaryColor,
      child: Stack(
        children: [
          const Icon(Icons.shopping_bag),
          if (itemCount > 0)
            Positioned(
              top: -4,
              right: -4,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(10),
                ),
                constraints: const BoxConstraints(
                  minWidth: 20,
                  minHeight: 20,
                ),
                child: Text(
                  itemCount > 99 ? '99+' : itemCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ).animate().scale(duration: const Duration(milliseconds: 300)),
            ),
        ],
      ),
    );
  }
}
