import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/models.dart';

class DashboardStatsWidget extends StatelessWidget {
  final DashboardMetrics metrics;

  const DashboardStatsWidget({Key? key, required this.metrics})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currencyFormatter =
        NumberFormat.currency(symbol: '\$', decimalDigits: 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Performance Metrics',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        // Stats grid
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          children: [
            _StatCard(
              title: 'Total Orders',
              value: metrics.totalOrders.toString(),
              icon: Icons.shopping_cart,
              color: const Color(0xFF6C5CE7),
            ),
            _StatCard(
              title: 'Gross Sales',
              value: currencyFormatter.format(metrics.grossSales),
              icon: Icons.trending_up,
              color: const Color(0xFF00B894),
            ),
            _StatCard(
              title: 'Pending Orders',
              value: metrics.pendingOrders.toString(),
              icon: Icons.pending_actions,
              color: const Color(0xFFFD79A8),
              highlighted: metrics.pendingOrders > 0,
            ),
            _StatCard(
              title: 'Delivered Orders',
              value: metrics.deliveredOrders.toString(),
              icon: Icons.check_circle,
              color: const Color(0xFF6C5CE7),
            ),
            _StatCard(
              title: 'Avg Order Value',
              value: currencyFormatter.format(metrics.averageOrderValue),
              icon: Icons.show_chart,
              color: const Color(0xFFFF7675),
            ),
            _StatCard(
              title: 'Cancelled Orders',
              value: metrics.cancelledOrders.toString(),
              icon: Icons.cancel_outlined,
              color: const Color(0xFFDFE6E9),
              valueColor: Colors.red,
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Order status breakdown
        _OrderStatusBreakdown(metrics: metrics),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final bool highlighted;
  final Color? valueColor;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.highlighted = false,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: highlighted ? 8 : 2,
      color: highlighted ? color.withOpacity(0.1) : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall,
              maxLines: 2,
            ),
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: valueColor ?? Colors.black,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderStatusBreakdown extends StatelessWidget {
  final DashboardMetrics metrics;

  const _OrderStatusBreakdown({required this.metrics});

  @override
  Widget build(BuildContext context) {
    final statuses = [
      ('Preparing', metrics.preparingOrders, const Color(0xFFFDAB2F)),
      ('Ready', metrics.readyOrders, const Color(0xFF74B9FF)),
      ('On the Way', metrics.onTheWayOrders, const Color(0xFF0984E3)),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Active Orders',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            ...statuses.map((status) {
              final isMobile = MediaQuery.of(context).size.width < 600;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: isMobile
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: status.$3,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(status.$1),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${status.$2} orders',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: status.$3,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(status.$1),
                            ],
                          ),
                          Text('${status.$2} orders'),
                        ],
                      ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}
