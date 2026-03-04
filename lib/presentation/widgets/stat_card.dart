import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Stat Card widget - displays KPI with optional trend
class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final double? change;
  final IconData icon;
  final int index;

  const StatCard({
    Key? key,
    required this.title,
    required this.value,
    this.change,
    required this.icon,
    this.index = 0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isPositive = change == null || change! > 0;
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 170;
        final padding = compact ? 14.0 : 20.0;
        final iconBox = compact ? 38.0 : 44.0;
        final iconSize = compact ? 19.0 : 22.0;
        final valueSize = compact ? 28.0 : 32.0;
        final titleSize = compact ? 13.0 : 16.0;

        return Container(
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: theme.dividerColor.withOpacity(0.2),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 12,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: iconBox,
                      height: iconBox,
                      decoration: BoxDecoration(
                        color: theme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        icon,
                        color: theme.primaryColor,
                        size: iconSize,
                      ),
                    ),
                    if (change != null)
                      Flexible(
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: compact ? 6 : 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isPositive
                                ? Colors.green.withOpacity(0.1)
                                : Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isPositive
                                    ? Icons.trending_up
                                    : Icons.trending_down,
                                color: isPositive ? Colors.green : Colors.red,
                                size: compact ? 11 : 12,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${change!.abs().toStringAsFixed(0)}%',
                                style: TextStyle(
                                  color: isPositive ? Colors.green : Colors.red,
                                  fontSize: compact ? 10 : 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
                SizedBox(height: compact ? 10 : 14),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: valueSize,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: titleSize,
                    color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ).animate().then().shimmer(
          duration: const Duration(milliseconds: 800),
          delay: Duration(milliseconds: index * 80),
        );
  }
}
