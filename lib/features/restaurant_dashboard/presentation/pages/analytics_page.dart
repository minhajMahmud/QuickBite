import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../data/models/models.dart';
import '../providers/dashboard_providers.dart';

class AnalyticsPage extends ConsumerStatefulWidget {
  final String? restaurantId;

  const AnalyticsPage({Key? key, this.restaurantId}) : super(key: key);

  @override
  ConsumerState<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends ConsumerState<AnalyticsPage> {
  int selectedDays = 30;

  @override
  void initState() {
    super.initState();
    if (widget.restaurantId != null) {
      Future.microtask(() {
        ref.read(selectedRestaurantIdProvider.notifier).state =
            widget.restaurantId;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final analyticsAsync = ref.watch(analyticsProvider(selectedDays));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date range selector
            Wrap(
              spacing: 8,
              children: [7, 30, 90, 365]
                  .map((days) => FilterChip(
                        label: Text(
                          days == 7
                              ? '1 Week'
                              : days == 30
                                  ? '1 Month'
                                  : days == 90
                                      ? '3 Months'
                                      : 'Year',
                        ),
                        selected: selectedDays == days,
                        onSelected: (selected) {
                          setState(() => selectedDays = days);
                        },
                      ))
                  .toList(),
            ),
            const SizedBox(height: 24),
            // Sales chart
            analyticsAsync.when(
              data: (analytics) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sales Overview',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  _SalesChart(dailySales: analytics.dailySales),
                  const SizedBox(height: 32),
                  // Top selling items
                  Text(
                    'Top Selling Items',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  ...analytics.topItems
                      .map((item) => _TopItemCard(item: item))
                      .toList(),
                ],
              ),
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (err, stack) => Center(
                child: Text('Error: $err'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SalesChart extends StatelessWidget {
  final List<DailySales> dailySales;

  const _SalesChart({required this.dailySales});

  @override
  Widget build(BuildContext context) {
    if (dailySales.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Center(
            child: Text(
              'No sales data available',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ),
      );
    }

    final spots = dailySales
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.revenue.toDouble()))
        .toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LineChart(
          LineChartData(
            gridData: const FlGridData(show: false),
            titlesData: const FlTitlesData(show: false),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                color: const Color(0xFF6C5CE7),
                barWidth: 4,
                dotData: const FlDotData(show: false),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopItemCard extends StatelessWidget {
  final TopSellingItem item;

  const _TopItemCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final currencyFormatter =
        NumberFormat.currency(symbol: '\$', decimalDigits: 2);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${item.totalQuantity} sold',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  currencyFormatter.format(item.totalSales),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF00B894),
                      ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00B894).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '#${item.id.substring(0, 6)}',
                    style: TextStyle(
                      fontSize: 10,
                      color: const Color(0xFF00B894),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
