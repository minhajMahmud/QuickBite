import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/dashboard_providers.dart';
import '../widgets/dashboard_overview_widget.dart';
import '../widgets/dashboard_stats_widget.dart';

class RestaurantDashboardPage extends ConsumerStatefulWidget {
  final String? restaurantId;

  const RestaurantDashboardPage({Key? key, this.restaurantId})
      : super(key: key);

  @override
  ConsumerState<RestaurantDashboardPage> createState() =>
      _RestaurantDashboardPageState();
}

class _RestaurantDashboardPageState
    extends ConsumerState<RestaurantDashboardPage> {
  @override
  void initState() {
    super.initState();
    // Set the restaurant ID if provided
    if (widget.restaurantId != null) {
      Future.microtask(() {
        ref.read(selectedRestaurantIdProvider.notifier).state =
            widget.restaurantId;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final overviewAsync = ref.watch(dashboardOverviewProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Restaurant Dashboard'),
        elevation: 0,
      ),
      body: overviewAsync.when(
        data: (overview) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Restaurant Info
              DashboardOverviewWidget(restaurant: overview.restaurant),
              const SizedBox(height: 24),

              // Stats Cards
              DashboardStatsWidget(metrics: overview.metrics),
              const SizedBox(height: 24),

              // Operating Hours
              _buildOperatingHours(overview),
            ],
          ),
        ),
        loading: () => const Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: CircularProgressIndicator(),
          ),
        ),
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Error loading dashboard',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(err.toString()),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.refresh(dashboardOverviewProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => ref.refresh(dashboardOverviewProvider),
        child: const Icon(Icons.refresh),
      ),
    );
  }

  Widget _buildOperatingHours(overview) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Operating Hours',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            ...overview.operatingHours.map((hours) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(hours.dayOfWeek),
                    hours.isClosed
                        ? const Text('Closed',
                            style: TextStyle(color: Colors.red))
                        : Text('${hours.openingTime} - ${hours.closingTime}'),
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
