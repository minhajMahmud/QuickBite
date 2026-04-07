import 'package:flutter/material.dart';
import '../../data/models/models.dart';
import '../../config/theme/app_theme.dart';
import 'adaptive_app_image.dart';

/// Food Item Card Widget
class FoodItemCard extends StatelessWidget {
  final FoodItem foodItem;
  final VoidCallback? onAddToCart;

  const FoodItemCard({Key? key, required this.foodItem, this.onAddToCart})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            // Food Image
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: AdaptiveAppImage(
                source: foodItem.image,
                width: 80,
                height: 80,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 12),
            // Food Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    foodItem.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.lightForeground,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    foodItem.description,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.muted,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '\$${foodItem.price.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryOrange,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Add to Cart Button
            FloatingActionButton.small(
              heroTag: null,
              onPressed: onAddToCart,
              backgroundColor: AppColors.primaryOrange,
              child: const Icon(Icons.add, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
