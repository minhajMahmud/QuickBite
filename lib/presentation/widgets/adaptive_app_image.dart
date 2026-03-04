import 'package:flutter/material.dart';

import '../../config/theme/app_theme.dart';

/// A resilient image widget that supports both network and local assets.
///
/// - Handles loading and error states
/// - Uses responsive sizing from parent constraints
/// - Avoids layout exceptions by requiring finite width/height from parent
class AdaptiveAppImage extends StatelessWidget {
  final String source;
  final BoxFit fit;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final Widget? placeholder;
  final Widget? error;

  const AdaptiveAppImage({
    super.key,
    required this.source,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.borderRadius,
    this.placeholder,
    this.error,
  });

  bool get _isNetwork =>
      source.startsWith('http://') || source.startsWith('https://');

  @override
  Widget build(BuildContext context) {
    final fallbackPlaceholder = Container(
      color: AppColors.secondaryLight,
      alignment: Alignment.center,
      child: const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );

    final fallbackError = Container(
      color: AppColors.secondaryLight,
      alignment: Alignment.center,
      child: const Icon(
        Icons.broken_image_outlined,
        color: AppColors.muted,
      ),
    );

    final image = _isNetwork
        ? Image.network(
            source,
            width: width,
            height: height,
            fit: fit,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return placeholder ?? fallbackPlaceholder;
            },
            errorBuilder: (context, _, __) => error ?? fallbackError,
          )
        : Image.asset(
            source,
            width: width,
            height: height,
            fit: fit,
            errorBuilder: (context, _, __) => error ?? fallbackError,
          );

    if (borderRadius == null) return image;

    return ClipRRect(
      borderRadius: borderRadius!,
      child: image,
    );
  }
}
