import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../presentation/providers/app_providers.dart';

import '../providers/delivery_panel_provider.dart';

final ValueNotifier<bool> _deliverySidebarCollapsed =
    ValueNotifier<bool>(false);

/// Admin Delivery Report Screen
class DeliveryDashboardScreen extends ConsumerWidget {
  const DeliveryDashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(deliveryPanelProvider);
    final weeklyData = ref.watch(weeklyEarningsDataProvider);

    return DeliveryPanelScaffold(
      currentRoute: '/admin/deliveries',
      title: 'Admin Delivery Report',
      subtitle: 'Weekly and detailed delivery analytics',
      child: Column(
        children: [
          // Report Summary Cards
          _EarningsSummaryGrid(
            weeklyEarnings: state.weeklyEarnings,
            totalDeliveries: state.totalDeliveriesToday,
            avgPerDelivery: state.totalDeliveriesToday == 0
                ? 0
                : state.weeklyEarnings / state.totalDeliveriesToday,
            rating: state.profile.rating,
          ),
          const SizedBox(height: 24),

          // KPI Snapshot
          _KPIGrid(
            totalEarningsToday: state.totalEarningsToday,
            totalDeliveries: state.totalDeliveriesToday,
            rating: state.profile.rating,
            ordersCompleted: state.profile.totalDeliveries,
          ),
          const SizedBox(height: 24),

          // Weekly Report Breakdown
          _PanelCard(
            title: 'Weekly Delivery Report',
            child: _WeeklyEarningsBreakdown(data: weeklyData),
          ),
          const SizedBox(height: 24),

          // Detailed Report Table
          _PanelCard(
            title: 'Detailed Delivery Report',
            child: _EarningsDetailsList(earnings: state.earnings),
          ),
          const SizedBox(height: 24),

          // Visual Trend Chart
          _WeeklyEarningsChart(),

          if (state.activeDeliveries.isNotEmpty) ...[
            const SizedBox(height: 24),
            _PanelCard(
              title: 'Live Delivery Snapshot',
              child: _ActiveDeliveryCard(
                delivery: state.activeDeliveries.first,
                onStatusChange: (newStatus) {
                  ref.read(deliveryPanelProvider.notifier).updateDeliveryStatus(
                      state.activeDeliveries.first.id, newStatus);
                },
              ),
            ),
            const SizedBox(height: 24),
            _PendingDeliveriesList(deliveries: state.activeDeliveries),
          ],
        ],
      ),
    );
  }
}

/// Earnings Screen
class DeliveryEarningsScreen extends ConsumerWidget {
  const DeliveryEarningsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(deliveryPanelProvider);
    final weeklyData = ref.watch(weeklyEarningsDataProvider);

    return DeliveryPanelScaffold(
      currentRoute: '/admin/deliveries',
      title: 'Earnings',
      subtitle: state.profile.name,
      child: Column(
        children: [
          // Earnings Summary Cards
          _EarningsSummaryGrid(
            weeklyEarnings: state.weeklyEarnings,
            totalDeliveries: state.totalDeliveriesToday,
            avgPerDelivery: state.weeklyEarnings / 7,
            rating: state.profile.rating,
          ),
          const SizedBox(height: 24),

          // Weekly Earnings Breakdown
          _PanelCard(
            title: 'Weekly Earnings Breakdown',
            child: _WeeklyEarningsBreakdown(data: weeklyData),
          ),
          const SizedBox(height: 24),

          // Earnings Details Table
          _PanelCard(
            title: 'Recent Deliveries',
            child: _EarningsDetailsList(earnings: state.earnings),
          ),
        ],
      ),
    );
  }
}

/// Settings Screen
class DeliverySettingsScreen extends ConsumerWidget {
  const DeliverySettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(deliveryPanelProvider);
    return DeliveryPanelScaffold(
      currentRoute: '/admin/deliveries',
      title: 'Settings',
      subtitle: state.profile.name,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Section
            _PanelCard(
              title: 'Profile Information',
              child: _ProfileSettingsForm(
                profile: state.profile,
                onSave: (newProfile) {
                  ref
                      .read(deliveryPanelProvider.notifier)
                      .updateProfile(newProfile);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Profile updated successfully')),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),

            // Delivery Preferences
            _PanelCard(
              title: 'Delivery Preferences',
              child: Column(
                children: [
                  ListTile(
                    title: const Text('Auto-accept orders'),
                    subtitle: const Text('Automatically accept new orders'),
                    trailing: Switch(
                      value: state.autoAcceptOrders,
                      onChanged: (_) {
                        ref
                            .read(deliveryPanelProvider.notifier)
                            .toggleAutoAccept();
                      },
                    ),
                  ),
                  const Divider(),
                  ListTile(
                    title: const Text('Go Online'),
                    subtitle:
                        const Text('Make yourself available for deliveries'),
                    trailing: Switch(
                      value: state.profile.isActive,
                      onChanged: (_) {
                        ref.read(deliveryPanelProvider.notifier).updateProfile(
                              state.profile.copyWith(
                                isActive: !state.profile.isActive,
                              ),
                            );
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Notifications
            _PanelCard(
              title: 'Notifications',
              child: Column(
                children: [
                  ListTile(
                    title: const Text('Enable Notifications'),
                    subtitle:
                        const Text('Receive push notifications for new orders'),
                    trailing: Switch(
                      value: state.notificationsEnabled,
                      onChanged: (_) {
                        ref
                            .read(deliveryPanelProvider.notifier)
                            .toggleNotifications();
                      },
                    ),
                  ),
                  const Divider(),
                  ListTile(
                    title: const Text('SMS Alerts'),
                    subtitle: const Text('Get SMS updates on delivery status'),
                    trailing: Switch(
                      value: true,
                      onChanged: (_) {},
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============= Components =============

class _KPIGrid extends StatelessWidget {
  final double totalEarningsToday;
  final int totalDeliveries;
  final double rating;
  final int ordersCompleted;

  const _KPIGrid({
    required this.totalEarningsToday,
    required this.totalDeliveries,
    required this.rating,
    required this.ordersCompleted,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final crossAxisCount = width < 700 ? 2 : 4;

        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: width < 480 ? 1.1 : 1.25,
          children: [
            _StatCard(
              icon: Icons.attach_money,
              value: '\$${totalEarningsToday.toStringAsFixed(2)}',
              label: 'Today\'s Earnings',
            ),
            _StatCard(
              icon: Icons.local_shipping,
              value: '$totalDeliveries',
              label: 'Deliveries Today',
            ),
            _StatCard(
              icon: Icons.star,
              value: '$rating',
              label: 'Rating',
            ),
            _StatCard(
              icon: Icons.check_circle,
              value: '$ordersCompleted',
              label: 'Total Deliveries',
            ),
          ],
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _PanelCard(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: const Color(0xFFFF7A00), size: 28),
          const SizedBox(height: 12),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.textTheme.titleMedium?.color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ActiveDeliveryCard extends StatelessWidget {
  final ActiveDelivery delivery;
  final Function(String) onStatusChange;

  const _ActiveDeliveryCard({
    required this.delivery,
    required this.onStatusChange,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _PanelCard(
      title: 'Active Delivery',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Map placeholder
          Container(
            height: 250,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.map, size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 8),
                  Text(
                    'Live Map View',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Delivery details
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 520;

              final details = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'From: ${delivery.restaurantName}',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'To: ${delivery.customerName}',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              );

              final meta = Column(
                crossAxisAlignment: isNarrow
                    ? CrossAxisAlignment.start
                    : CrossAxisAlignment.end,
                children: [
                  Text(
                    '\$${delivery.estimatedEarning.toStringAsFixed(2)}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFFF7A00),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (delivery.otp != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF7A00).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'OTP: ${delivery.otp}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFF7A00),
                        ),
                      ),
                    ),
                ],
              );

              if (isNarrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [details, const SizedBox(height: 12), meta],
                );
              }

              return Row(
                children: [
                  Expanded(child: details),
                  const SizedBox(width: 16),
                  meta,
                ],
              );
            },
          ),
          const SizedBox(height: 16),

          // Status buttons
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 520;

              if (isNarrow) {
                return Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {},
                        child: const Text('Call Customer'),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          onStatusChange('delivered');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF7A00),
                        ),
                        child: const Text(
                          'Mark Delivered',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {},
                      child: const Text('Call Customer'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        onStatusChange('delivered');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF7A00),
                      ),
                      child: const Text(
                        'Mark Delivered',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _WeeklyEarningsChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _PanelCard(
      title: 'Weekly Earnings',
      child: SizedBox(
        height: 250,
        child: BarChart(
          BarChartData(
            barGroups: [
              _makeGroupData(0, 65),
              _makeGroupData(1, 78.5),
              _makeGroupData(2, 82),
              _makeGroupData(3, 55.5),
              _makeGroupData(4, 95),
              _makeGroupData(5, 110),
              _makeGroupData(6, 59.75),
            ],
            borderData: FlBorderData(show: false),
            gridData: const FlGridData(show: false),
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    const titles = [
                      'Mon',
                      'Tue',
                      'Wed',
                      'Thu',
                      'Fri',
                      'Sat',
                      'Sun'
                    ];
                    final index = value.toInt();
                    if (index < 0 || index >= titles.length) {
                      return const SizedBox.shrink();
                    }
                    return Text(titles[index]);
                  },
                ),
              ),
              leftTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: true),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
            ),
          ),
        ),
      ),
    );
  }

  BarChartGroupData _makeGroupData(int x, double y) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: const Color(0xFFFF7A00),
          width: 16,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(4),
            topRight: Radius.circular(4),
          ),
        ),
      ],
    );
  }
}

class _PendingDeliveriesList extends StatelessWidget {
  final List<ActiveDelivery> deliveries;

  const _PendingDeliveriesList({required this.deliveries});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return _PanelCard(
      title: 'Pending Deliveries',
      child: deliveries.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Text(
                  'No pending deliveries',
                  style:
                      theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
                ),
              ),
            )
          : ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: deliveries.length,
              separatorBuilder: (_, __) => const Divider(height: 12),
              itemBuilder: (context, index) {
                final delivery = deliveries[index];
                return LayoutBuilder(
                  builder: (context, constraints) {
                    final isNarrow = constraints.maxWidth < 500;
                    final info = Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          delivery.restaurantName,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'To: ${delivery.customerName}',
                          style: theme.textTheme.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    );

                    final meta = Column(
                      crossAxisAlignment: isNarrow
                          ? CrossAxisAlignment.start
                          : CrossAxisAlignment.end,
                      children: [
                        Text(
                          '\$${delivery.estimatedEarning.toStringAsFixed(2)}',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFFF7A00),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor(delivery.status)
                                .withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            delivery.status.replaceAll('_', ' ').toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: _getStatusColor(delivery.status),
                            ),
                          ),
                        ),
                      ],
                    );

                    if (isNarrow) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [info, const SizedBox(height: 8), meta],
                      );
                    }

                    return Row(
                      children: [
                        Expanded(child: info),
                        const SizedBox(width: 12),
                        meta,
                      ],
                    );
                  },
                );
              },
            ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'picked_up':
        return Colors.blue;
      case 'in_transit':
        return Colors.orange;
      case 'delivered':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}

class _EarningsSummaryGrid extends StatelessWidget {
  final double weeklyEarnings;
  final int totalDeliveries;
  final double avgPerDelivery;
  final double rating;

  const _EarningsSummaryGrid({
    required this.weeklyEarnings,
    required this.totalDeliveries,
    required this.avgPerDelivery,
    required this.rating,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final crossAxisCount = width < 700 ? 2 : 4;

        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: width < 480 ? 1.1 : 1.25,
          children: [
            _StatCard(
              icon: Icons.trending_up,
              value: '\$${weeklyEarnings.toStringAsFixed(2)}',
              label: 'Weekly Earnings',
            ),
            _StatCard(
              icon: Icons.local_shipping,
              value: '$totalDeliveries',
              label: 'Total Deliveries',
            ),
            _StatCard(
              icon: Icons.attach_money,
              value: '\$${avgPerDelivery.toStringAsFixed(2)}',
              label: 'Avg Per Delivery',
            ),
            _StatCard(
              icon: Icons.star,
              value: '$rating',
              label: 'Rating',
            ),
          ],
        );
      },
    );
  }
}

class _WeeklyEarningsBreakdown extends StatelessWidget {
  final List<MapEntry<String, double>> data;

  const _WeeklyEarningsBreakdown({required this.data});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 250,
      child: BarChart(
        BarChartData(
          barGroups: List.generate(
            data.length,
            (i) => BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: data[i].value,
                  color: const Color(0xFFFF7A00),
                  width: 16,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(4),
                  ),
                ),
              ],
            ),
          ),
          borderData: FlBorderData(show: false),
          gridData: const FlGridData(show: false),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= data.length) {
                    return const SizedBox.shrink();
                  }
                  return Text(data[index].key);
                },
              ),
            ),
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: true),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
        ),
      ),
    );
  }
}

class _EarningsDetailsList extends StatelessWidget {
  final List<EarningRecord> earnings;

  const _EarningsDetailsList({required this.earnings});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return earnings.isEmpty
        ? Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Text(
                'No earnings data available',
                style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
              ),
            ),
          )
        : ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: earnings.length,
            separatorBuilder: (_, __) => const Divider(height: 12),
            itemBuilder: (context, index) {
              final record = earnings[index];
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Delivery #${record.deliveryId}',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        record.date.toString().split(' ')[0],
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: Colors.grey),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '\$${record.amount.toStringAsFixed(2)}',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFFF7A00),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        record.status.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: record.status == 'completed'
                              ? Colors.green
                              : Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          );
  }
}

class _ProfileSettingsForm extends StatefulWidget {
  final DeliveryPartnerProfile profile;
  final Function(DeliveryPartnerProfile) onSave;

  const _ProfileSettingsForm({
    required this.profile,
    required this.onSave,
  });

  @override
  State<_ProfileSettingsForm> createState() => _ProfileSettingsFormState();
}

class _ProfileSettingsFormState extends State<_ProfileSettingsForm> {
  late TextEditingController nameController;
  late TextEditingController emailController;
  late TextEditingController phoneController;
  late TextEditingController vehicleController;
  late TextEditingController licensePlateController;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.profile.name);
    emailController = TextEditingController(text: widget.profile.email);
    phoneController = TextEditingController(text: widget.profile.phone);
    vehicleController = TextEditingController(text: widget.profile.vehicleType);
    licensePlateController =
        TextEditingController(text: widget.profile.licensePlate);
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    vehicleController.dispose();
    licensePlateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Full Name',
            hintText: 'Enter your full name',
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: emailController,
          decoration: const InputDecoration(
            labelText: 'Email',
            hintText: 'Enter your email',
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: phoneController,
          decoration: const InputDecoration(
            labelText: 'Phone',
            hintText: 'Enter your phone number',
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: vehicleController,
          decoration: const InputDecoration(
            labelText: 'Vehicle Type',
            hintText: 'e.g., Motorcycle, Car',
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: licensePlateController,
          decoration: const InputDecoration(
            labelText: 'License Plate',
            hintText: 'Enter license plate',
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () {
            final newProfile = widget.profile.copyWith(
              name: nameController.text,
              email: emailController.text,
              phone: phoneController.text,
              vehicleType: vehicleController.text,
              licensePlate: licensePlateController.text,
            );
            widget.onSave(newProfile);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF7A00),
            minimumSize: const Size(double.infinity, 48),
          ),
          child: const Text(
            'Save Changes',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }
}

// ============= Shared Components =============

class DeliveryPanelScaffold extends StatelessWidget {
  final String currentRoute;
  final String title;
  final String subtitle;
  final Widget child;
  final Widget? action;

  const DeliveryPanelScaffold({
    Key? key,
    required this.currentRoute,
    required this.title,
    required this.subtitle,
    required this.child,
    this.action,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMobile = MediaQuery.of(context).size.width < 900;

    final content = CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: _TopHeader(
            title: title,
            subtitle: subtitle,
            action: action,
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverToBoxAdapter(child: child),
        ),
      ],
    );

    if (isMobile) {
      return Scaffold(
        appBar: AppBar(
          title: Text(title),
          backgroundColor: theme.scaffoldBackgroundColor,
          elevation: 0,
        ),
        drawer: Drawer(
          child: SafeArea(
            child: DeliveryPanelSidebar(
              currentRoute: currentRoute,
              compact: true,
            ),
          ),
        ),
        body: content,
      );
    }

    return Scaffold(
      body: Row(
        children: [
          DeliveryPanelSidebar(currentRoute: currentRoute),
          Expanded(
            child: Container(
              color: theme.scaffoldBackgroundColor,
              child: content,
            ),
          ),
        ],
      ),
    );
  }
}

class DeliveryPanelSidebar extends ConsumerWidget {
  final String currentRoute;
  final bool compact;

  const DeliveryPanelSidebar({
    Key? key,
    required this.currentRoute,
    this.compact = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final allowCollapse = !compact;

    return ValueListenableBuilder<bool>(
      valueListenable: _deliverySidebarCollapsed,
      builder: (context, collapsedValue, _) {
        if (compact && collapsedValue) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_deliverySidebarCollapsed.value) {
              _deliverySidebarCollapsed.value = false;
            }
          });
        }

        final collapsed = allowCollapse ? collapsedValue : false;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          width: compact ? double.infinity : (collapsed ? 84 : 240),
          decoration: BoxDecoration(
            color: theme.cardColor,
            border: Border(
              right: BorderSide(color: theme.dividerColor.withOpacity(0.15)),
            ),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom:
                        BorderSide(color: theme.dividerColor.withOpacity(0.15)),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: collapsed
                      ? MainAxisAlignment.center
                      : MainAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF8A00),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Center(
                        child: Text(
                          'Q',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                      ),
                    ),
                    if (!collapsed) ...[
                      const SizedBox(width: 10),
                      Text(
                        'QuickBite',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (!collapsed)
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 18, 14, 10),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF8A00).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        'ADMIN DELIVERY',
                        style: TextStyle(
                          color: Color(0xFFFF7A00),
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ),
              _buildNavItem(
                context: context,
                icon: Icons.dashboard_outlined,
                label: 'Delivery Report',
                route: '/admin/deliveries',
                currentRoute: currentRoute,
                collapsed: collapsed,
              ),
              _buildNavItem(
                context: context,
                icon: Icons.trending_up,
                label: 'Earnings',
                route: '/admin/deliveries/earnings',
                currentRoute: currentRoute,
                collapsed: collapsed,
              ),
              _buildNavItem(
                context: context,
                icon: Icons.settings_outlined,
                label: 'Settings',
                route: '/admin/deliveries/settings',
                currentRoute: currentRoute,
                collapsed: collapsed,
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: ElevatedButton(
                  onPressed: () {
                    ref.read(themeModeProvider.notifier).toggle();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.cardColor,
                    side: BorderSide(
                      color: theme.dividerColor.withOpacity(0.35),
                    ),
                    minimumSize: const Size(double.infinity, 44),
                  ),
                  child: collapsed
                      ? Icon(
                          isDark
                              ? Icons.light_mode_outlined
                              : Icons.dark_mode_outlined,
                          color: theme.textTheme.bodyMedium?.color,
                        )
                      : Text(
                          isDark ? 'Light Mode' : 'Dark Mode',
                          style: TextStyle(
                              color: theme.textTheme.bodyMedium?.color),
                        ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton(
                  onPressed: () {
                    if (compact && Navigator.of(context).canPop()) {
                      Navigator.of(context).pop();
                    }
                    context.go('/');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[300],
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  child: collapsed
                      ? Icon(Icons.home_outlined,
                          color: theme.textTheme.bodyMedium?.color)
                      : Text(
                          'Back Home',
                          style: TextStyle(
                              color: theme.textTheme.bodyMedium?.color),
                        ),
                ),
              ),
              if (allowCollapse)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Tooltip(
                    message: collapsed ? 'Expand' : 'Collapse',
                    child: IconButton(
                      onPressed: () {
                        _deliverySidebarCollapsed.value =
                            !_deliverySidebarCollapsed.value;
                      },
                      icon: Icon(
                        collapsed ? Icons.chevron_right : Icons.chevron_left,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String route,
    required String currentRoute,
    required bool collapsed,
  }) {
    final isActive = currentRoute == route;

    final navItem = Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isActive
            ? const Color(0xFFFF7A00).withOpacity(0.12)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isActive ? const Color(0xFFFF7A00) : Colors.grey,
        ),
        title: collapsed
            ? null
            : Text(
                label,
                style: TextStyle(
                  color: isActive ? const Color(0xFFFF7A00) : Colors.grey,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                ),
              ),
        horizontalTitleGap: collapsed ? 0 : 12,
        minLeadingWidth: 24,
        onTap: () => context.go(route),
      ),
    );

    if (!collapsed) return navItem;
    return Tooltip(message: label, child: navItem);
  }
}

class _TopHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget? action;

  const _TopHeader({
    required this.title,
    required this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: theme.dividerColor.withOpacity(0.15)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          if (action != null) action!,
        ],
      ),
    );
  }
}

class _PanelCard extends StatelessWidget {
  final String? title;
  final Widget child;

  const _PanelCard({
    this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.dividerColor.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title!,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          if (title != null)
            Divider(
              height: 1,
              color: theme.dividerColor.withOpacity(0.1),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ],
      ),
    );
  }
}
