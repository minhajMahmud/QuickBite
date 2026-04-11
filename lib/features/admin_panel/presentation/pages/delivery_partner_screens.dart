import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../presentation/providers/app_providers.dart';
import '../../../authentication/presentation/providers/auth_provider.dart';

import '../providers/delivery_panel_provider.dart';

final ValueNotifier<bool> _deliverySidebarCollapsed =
    ValueNotifier<bool>(false);

void _showActionSnackBar(
  BuildContext context,
  String message, {
  bool isError = false,
}) {
  final messenger = ScaffoldMessenger.of(context);
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor:
            isError ? const Color(0xFFB42318) : const Color(0xFF111827),
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
}

ButtonStyle _primaryActionStyle({required Color color}) {
  return ButtonStyle(
    backgroundColor: MaterialStateProperty.resolveWith<Color>(
      (states) {
        if (states.contains(MaterialState.disabled))
          return color.withOpacity(0.55);
        if (states.contains(MaterialState.pressed))
          return color.withOpacity(0.85);
        if (states.contains(MaterialState.hovered))
          return color.withOpacity(0.92);
        return color;
      },
    ),
    foregroundColor: MaterialStateProperty.all(Colors.white),
    elevation: MaterialStateProperty.resolveWith<double>(
      (states) => states.contains(MaterialState.hovered) ? 2 : 0,
    ),
    shape: MaterialStateProperty.all(
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    animationDuration: const Duration(milliseconds: 160),
  );
}

ButtonStyle _secondaryActionStyle(BuildContext context) {
  final theme = Theme.of(context);
  return ButtonStyle(
    foregroundColor: MaterialStateProperty.resolveWith<Color>(
      (states) => states.contains(MaterialState.disabled)
          ? Colors.grey
          : theme.textTheme.bodyMedium?.color ?? Colors.black87,
    ),
    side: MaterialStateProperty.resolveWith<BorderSide>(
      (states) => BorderSide(
        color: states.contains(MaterialState.hovered)
            ? theme.colorScheme.primary.withOpacity(0.5)
            : theme.dividerColor.withOpacity(0.35),
      ),
    ),
    shape: MaterialStateProperty.all(
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    animationDuration: const Duration(milliseconds: 160),
  );
}

/// Admin Delivery Report Screen
class DeliveryDashboardScreen extends ConsumerWidget {
  const DeliveryDashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(deliveryPanelProvider);
    final weeklyData = ref.watch(weeklyEarningsDataProvider);
    final pendingDeliveries = state.incomingRequests
        .map(
          (request) => ActiveDelivery(
            id: request.id,
            restaurantName: request.restaurantName,
            customerName: request.customerName,
            customerAddress: request.customerAddress,
            estimatedEarning: request.deliveryFee,
            pickupLocation: request.restaurantName,
            dropLocation: request.customerAddress,
            status: request.status,
            createdAt: request.createdAt,
          ),
        )
        .toList();

    return DeliveryPanelScaffold(
      currentRoute: '/delivery-partner',
      title: 'Delivery Partner Dashboard',
      subtitle: 'Live operations, earnings, and delivery requests',
      bottomButton: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton.icon(
          onPressed: () {
            context.push('/delivery-partner/incoming-order');
          },
          icon: const Icon(Icons.local_shipping),
          label: const Text('Take New Delivery'),
          style: _primaryActionStyle(color: const Color(0xFF0F9D58)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PanelCard(
            child: _DashboardHero(
              name: state.profile.name,
              activeDeliveries: state.activeDeliveries.length,
              incomingRequests: state.incomingRequests.length,
              weeklyEarnings: state.weeklyEarnings,
              onTakeDelivery: () {
                context.push('/delivery-partner/incoming-order');
              },
            ),
          ),
          const SizedBox(height: 24),
          _EarningsSummaryGrid(
            weeklyEarnings: state.weeklyEarnings,
            totalDeliveries: state.totalDeliveriesToday,
            avgPerDelivery: state.totalDeliveriesToday == 0
                ? 0
                : state.weeklyEarnings / state.totalDeliveriesToday,
            rating: state.profile.rating,
          ),
          const SizedBox(height: 24),
          _KPIGrid(
            totalEarningsToday: state.totalEarningsToday,
            totalDeliveries: state.totalDeliveriesToday,
            rating: state.profile.rating,
            ordersCompleted: state.profile.totalDeliveries,
          ),
          const SizedBox(height: 24),
          _PanelCard(
            title: 'Weekly Delivery Report',
            child: _WeeklyEarningsBreakdown(data: weeklyData),
          ),
          const SizedBox(height: 24),
          _PanelCard(
            title: 'Detailed Delivery Report',
            child: _EarningsDetailsList(earnings: state.earnings),
          ),
          const SizedBox(height: 24),
          _WeeklyEarningsChart(),
          if (pendingDeliveries.isNotEmpty) ...[
            const SizedBox(height: 24),
            _PanelCard(
              title: 'Incoming Delivery Requests',
              child: _PendingDeliveriesList(
                deliveries: pendingDeliveries,
                onConfirmOrder: (deliveryId) {
                  ref
                      .read(deliveryPanelProvider.notifier)
                      .acceptIncomingRequest(deliveryId);
                  _showActionSnackBar(context, 'Delivery accepted.');
                },
                onCancelOrder: (deliveryId) {
                  ref
                      .read(deliveryPanelProvider.notifier)
                      .rejectIncomingRequest(deliveryId);
                  _showActionSnackBar(context, 'Delivery declined.',
                      isError: true);
                },
              ),
            ),
          ],
          if (state.activeDeliveries.isNotEmpty) ...[
            const SizedBox(height: 24),
            _PanelCard(
              title: 'Active Deliveries',
              child: _PendingDeliveriesList(
                deliveries: state.activeDeliveries,
                onConfirmOrder: (deliveryId) {
                  ref
                      .read(deliveryPanelProvider.notifier)
                      .confirmDelivery(deliveryId);
                  _showActionSnackBar(context, 'Delivery confirmed.');
                },
                onCancelOrder: (deliveryId) {
                  ref
                      .read(deliveryPanelProvider.notifier)
                      .cancelDelivery(deliveryId);
                  _showActionSnackBar(context, 'Delivery cancelled.',
                      isError: true);
                },
              ),
            ),
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
      currentRoute: '/delivery-partner/earnings',
      title: 'Earnings',
      subtitle: state.profile.name,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PanelCard(
            child: _SectionIntroCard(
              icon: Icons.trending_up,
              title: 'Earnings Overview',
              description:
                  'Track your daily momentum, delivery yield, and weekly trends at a glance.',
              accentColor: const Color(0xFFFF7A00),
            ),
          ),
          const SizedBox(height: 24),
          _EarningsSummaryGrid(
            weeklyEarnings: state.weeklyEarnings,
            totalDeliveries: state.totalDeliveriesToday,
            avgPerDelivery: state.weeklyEarnings / 7,
            rating: state.profile.rating,
          ),
          const SizedBox(height: 24),
          _PanelCard(
            title: 'Weekly Earnings Breakdown',
            child: _WeeklyEarningsBreakdown(data: weeklyData),
          ),
          const SizedBox(height: 24),
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
      currentRoute: '/delivery-partner/settings',
      title: 'Settings',
      subtitle: state.profile.name,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _PanelCard(
              child: _SectionIntroCard(
                icon: Icons.tune,
                title: 'Partner Preferences',
                description:
                    'Control profile, delivery availability, and alerts from one clean settings center.',
                accentColor: const Color(0xFF0F9D58),
              ),
            ),
            const SizedBox(height: 24),
            _PanelCard(
              title: 'Profile Information',
              child: _ProfileSettingsForm(
                profile: state.profile,
                onSave: (newProfile) {
                  ref
                      .read(deliveryPanelProvider.notifier)
                      .updateProfile(newProfile);
                  _showActionSnackBar(context, 'Profile updated successfully');
                },
              ),
            ),
            const SizedBox(height: 24),
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

/// Orders Screen - Shows all pending orders
class DeliveryOrdersScreen extends ConsumerWidget {
  const DeliveryOrdersScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(deliveryPanelProvider);

    return DeliveryPanelScaffold(
      currentRoute: '/delivery-partner/orders',
      title: 'Pending Orders',
      subtitle: 'Active delivery orders',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PanelCard(
            child: _SectionIntroCard(
              icon: Icons.assignment_turned_in_outlined,
              title: 'Orders Command Center',
              description:
                  'Review active jobs, monitor status movement, and act quickly on order events.',
              accentColor: const Color(0xFF2563EB),
            ),
          ),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 760;
              final stats = [
                _OrderStatCard(
                  icon: Icons.local_shipping,
                  value: state.activeDeliveries.length.toString(),
                  label: 'Total Orders',
                  color: const Color(0xFF2563EB),
                ),
                _OrderStatCard(
                  icon: Icons.hourglass_bottom,
                  value: state.activeDeliveries
                      .where((d) => d.status == 'pending')
                      .length
                      .toString(),
                  label: 'Pending',
                  color: const Color(0xFFF59E0B),
                ),
                _OrderStatCard(
                  icon: Icons.check_circle,
                  value: state.activeDeliveries
                      .where((d) => d.status == 'confirmed')
                      .length
                      .toString(),
                  label: 'Confirmed',
                  color: const Color(0xFF10B981),
                ),
              ];

              if (isNarrow) {
                return Column(
                  children: [
                    for (final card in stats) ...[
                      card,
                      const SizedBox(height: 12),
                    ],
                  ],
                );
              }

              return Row(
                children: [
                  for (var i = 0; i < stats.length; i++) ...[
                    Expanded(child: stats[i]),
                    if (i < stats.length - 1) const SizedBox(width: 12),
                  ],
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          _PanelCard(
            title: 'All Active Orders',
            child: state.activeDeliveries.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          Icon(
                            Icons.inbox_outlined,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No active orders',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Start taking deliveries to see them here',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.grey,
                                    ),
                          ),
                        ],
                      ),
                    ),
                  )
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Order ID')),
                        DataColumn(label: Text('Restaurant')),
                        DataColumn(label: Text('Customer')),
                        DataColumn(label: Text('Status')),
                        DataColumn(label: Text('Earning')),
                        DataColumn(label: Text('Actions')),
                      ],
                      rows: state.activeDeliveries.map((delivery) {
                        final isConfirmed = delivery.status == 'confirmed';
                        final isPending = delivery.status == 'pending';

                        return DataRow(
                          cells: [
                            DataCell(Text(
                              delivery.id,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600),
                            )),
                            DataCell(Text(delivery.restaurantName)),
                            DataCell(Text(delivery.customerName)),
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: isConfirmed
                                      ? Colors.green.withOpacity(0.1)
                                      : isPending
                                          ? Colors.orange.withOpacity(0.1)
                                          : Colors.blue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  delivery.status.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: isConfirmed
                                        ? Colors.green
                                        : isPending
                                            ? Colors.orange
                                            : Colors.blue,
                                  ),
                                ),
                              ),
                            ),
                            DataCell(Text(
                                '\$${delivery.estimatedEarning.toStringAsFixed(2)}')),
                            DataCell(
                              PopupMenuButton<String>(
                                tooltip: 'Actions',
                                onSelected: (value) {
                                  if (value == 'confirm' && isPending) {
                                    ref
                                        .read(deliveryPanelProvider.notifier)
                                        .confirmDelivery(delivery.id);
                                    _showActionSnackBar(
                                        context, 'Order confirmed');
                                  } else if (value == 'cancel') {
                                    ref
                                        .read(deliveryPanelProvider.notifier)
                                        .cancelDelivery(delivery.id);
                                    _showActionSnackBar(
                                        context, 'Order cancelled',
                                        isError: true);
                                  }
                                },
                                itemBuilder: (context) => [
                                  if (isPending)
                                    const PopupMenuItem(
                                      value: 'confirm',
                                      child: Row(
                                        children: [
                                          Icon(Icons.check, size: 18),
                                          SizedBox(width: 8),
                                          Text('Confirm'),
                                        ],
                                      ),
                                    ),
                                  const PopupMenuItem(
                                    value: 'cancel',
                                    child: Row(
                                      children: [
                                        Icon(Icons.close,
                                            size: 18, color: Colors.red),
                                        SizedBox(width: 8),
                                        Text('Cancel',
                                            style:
                                                TextStyle(color: Colors.red)),
                                      ],
                                    ),
                                  ),
                                ],
                                child: const Icon(Icons.more_vert),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
          ),
        ],
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
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFFF7A00).withOpacity(0.18),
                  const Color(0xFFFF7A00).withOpacity(0.06),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: const Color(0xFFFF7A00), size: 26),
          ),
          const SizedBox(height: 14),
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
  final VoidCallback onConfirmOrder;
  final VoidCallback onCancelOrder;
  final Function(String) onStatusChange;

  const _ActiveDeliveryCard({
    required this.delivery,
    required this.onConfirmOrder,
    required this.onCancelOrder,
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
                        onPressed: onConfirmOrder,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                        ),
                        child: const Text(
                          'Confirm Order',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: onCancelOrder,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                        ),
                        child: const Text(
                          'Cancel Order',
                          style: TextStyle(color: Colors.white),
                        ),
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
                      onPressed: onConfirmOrder,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                      child: const Text(
                        'Confirm',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onCancelOrder,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(color: Colors.white),
                      ),
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
  final void Function(String deliveryId) onConfirmOrder;
  final void Function(String deliveryId) onCancelOrder;

  const _PendingDeliveriesList({
    required this.deliveries,
    required this.onConfirmOrder,
    required this.onCancelOrder,
  });

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
                        const SizedBox(height: 6),
                        PopupMenuButton<String>(
                          tooltip: 'Order actions',
                          onSelected: (value) {
                            if (value == 'confirm') {
                              onConfirmOrder(delivery.id);
                            } else if (value == 'cancel') {
                              onCancelOrder(delivery.id);
                            }
                          },
                          itemBuilder: (context) => const [
                            PopupMenuItem(
                              value: 'confirm',
                              child: Text('Confirm Order'),
                            ),
                            PopupMenuItem(
                              value: 'cancel',
                              child: Text('Cancel Order'),
                            ),
                          ],
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Colors.grey.withOpacity(0.35),
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.more_vert, size: 16),
                                SizedBox(width: 4),
                                Text('Menu'),
                              ],
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
      case 'confirmed':
        return Colors.green;
      case 'in_transit':
        return Colors.orange;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.redAccent;
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
    final theme = Theme.of(context);

    final decoration = InputDecoration(
      filled: true,
      fillColor: theme.colorScheme.surface.withOpacity(0.75),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: theme.dividerColor.withOpacity(0.25)),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: nameController,
          decoration: decoration.copyWith(
            labelText: 'Full Name',
            hintText: 'Enter your full name',
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: emailController,
          decoration: decoration.copyWith(
            labelText: 'Email',
            hintText: 'Enter your email',
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: phoneController,
          decoration: decoration.copyWith(
            labelText: 'Phone',
            hintText: 'Enter your phone number',
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: vehicleController,
          decoration: decoration.copyWith(
            labelText: 'Vehicle Type',
            hintText: 'e.g., Motorcycle, Car',
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: licensePlateController,
          decoration: decoration.copyWith(
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

class _SectionIntroCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color accentColor;

  const _SectionIntroCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: accentColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: accentColor),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                description,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _OrderStatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _OrderStatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
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
  final Widget? bottomButton;

  const DeliveryPanelScaffold({
    Key? key,
    required this.currentRoute,
    required this.title,
    required this.subtitle,
    required this.child,
    this.action,
    this.bottomButton,
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
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          sliver: SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1280),
                child: child,
              ),
            ),
          ),
        ),
      ],
    );

    if (isMobile) {
      return Scaffold(
        appBar: AppBar(
          title: Text(title),
          backgroundColor: theme.scaffoldBackgroundColor,
          elevation: 0,
          centerTitle: false,
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
        bottomNavigationBar: bottomButton != null
            ? Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: theme.dividerColor,
                      width: 1,
                    ),
                  ),
                ),
                child: bottomButton,
              )
            : null,
      );
    }

    return Scaffold(
      body: Row(
        children: [
          DeliveryPanelSidebar(currentRoute: currentRoute),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.surface,
                    theme.colorScheme.surface.withOpacity(0.96),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: content,
            ),
          ),
        ],
      ),
      bottomNavigationBar: bottomButton != null
          ? Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: theme.dividerColor,
                    width: 1,
                  ),
                ),
              ),
              child: bottomButton,
            )
          : null,
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
                        'DELIVERY PARTNER',
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
                route: '/delivery-partner',
                currentRoute: currentRoute,
                collapsed: collapsed,
              ),
              _buildNavItem(
                context: context,
                icon: Icons.list_alt_outlined,
                label: 'Orders',
                route: '/delivery-partner/orders',
                currentRoute: currentRoute,
                collapsed: collapsed,
              ),
              _buildNavItem(
                context: context,
                icon: Icons.trending_up,
                label: 'Earnings',
                route: '/delivery-partner/earnings',
                currentRoute: currentRoute,
                collapsed: collapsed,
              ),
              _buildNavItem(
                context: context,
                icon: Icons.settings_outlined,
                label: 'Settings',
                route: '/delivery-partner/settings',
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
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: ElevatedButton(
                  onPressed: () {
                    ref.read(authProvider.notifier).logout();
                    if (compact && Navigator.of(context).canPop()) {
                      Navigator.of(context).pop();
                    }
                    context.go('/login');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.withOpacity(0.12),
                    minimumSize: const Size(double.infinity, 48),
                    elevation: 0,
                  ),
                  child: collapsed
                      ? const Icon(Icons.logout, color: Colors.redAccent)
                      : const Text(
                          'Logout',
                          style: TextStyle(
                            color: Colors.redAccent,
                            fontWeight: FontWeight.w600,
                          ),
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
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.dividerColor.withOpacity(0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          if (action != null) ...[
            const SizedBox(height: 12),
            action!,
          ],
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

    final body = Padding(
      padding: const EdgeInsets.all(20),
      child: child,
    );

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.dividerColor.withOpacity(0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: title == null
          ? body
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
                  child: Text(
                    title!,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Divider(
                  height: 1,
                  color: theme.dividerColor.withOpacity(0.08),
                ),
                body,
              ],
            ),
    );
  }
}

/// Incoming Order Screen - Shows live requests with Accept/Decline options
class IncomingOrderScreen extends ConsumerWidget {
  const IncomingOrderScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final state = ref.watch(deliveryPanelProvider);
    final request =
        state.incomingRequests.isNotEmpty ? state.incomingRequests.first : null;

    if (request == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Incoming Request'),
          leading: BackButton(onPressed: () => context.pop()),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.inbox_outlined, size: 56, color: Colors.grey),
                const SizedBox(height: 12),
                Text(
                  'No delivery requests right now.',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  'When an order is assigned to you, it will appear here.',
                  style:
                      theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    final etaText = request.estimatedDeliveryTime == null
        ? '—'
        : request.estimatedDeliveryTime!.toLocal().toString().split('.').first;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(onPressed: () => context.pop()),
        actions: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: CircleAvatar(
              radius: 24,
              backgroundColor: Colors.blue,
              child: Text(
                'DP',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: NetworkImage(
              'https://images.unsplash.com/photo-1524661135-423995f22d0b?auto=format&fit=crop&w=1200&q=80',
            ),
            fit: BoxFit.cover,
          ),
        ),
        child: Stack(
          children: [
            Container(color: Colors.black.withOpacity(0.32)),
            SafeArea(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                        Icons.notifications_active,
                                        color: Colors.blue),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'INCOMING DELIVERY REQUEST',
                                          style: theme.textTheme.labelSmall
                                              ?.copyWith(
                                            color: Colors.grey,
                                            letterSpacing: 1,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          request.restaurantName,
                                          style: theme.textTheme.headlineSmall
                                              ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          'Customer: ${request.customerName}',
                                          style: theme.textTheme.bodyMedium
                                              ?.copyWith(
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        'PAY',
                                        style: theme.textTheme.labelSmall
                                            ?.copyWith(
                                          color: Colors.grey,
                                          letterSpacing: 1,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '\$${request.deliveryFee.toStringAsFixed(2)}',
                                        style: theme.textTheme.headlineSmall
                                            ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blue,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildInfoCard(
                                      context,
                                      Icons.straighten,
                                      '\$${request.totalAmount.toStringAsFixed(2)}',
                                      'ORDER TOTAL',
                                      theme,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildInfoCard(
                                      context,
                                      Icons.schedule,
                                      etaText,
                                      'EST. READY',
                                      theme,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(Icons.storefront,
                                        color: Colors.blue),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'PICKUP LOCATION',
                                          style: theme.textTheme.labelSmall
                                              ?.copyWith(
                                            color: Colors.grey,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          request.restaurantName,
                                          style: theme.textTheme.bodyLarge
                                              ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          request.customerAddress,
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(Icons.location_on,
                                        color: Colors.green),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'CUSTOMER',
                                          style: theme.textTheme.labelSmall
                                              ?.copyWith(
                                            color: Colors.grey,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          request.customerName,
                                          style: theme.textTheme.bodyLarge
                                              ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          request.customerPhone,
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              if (request.customerEmail.isNotEmpty &&
                                  request.customerEmail != '-')
                                Text(
                                  'Customer email: ${request.customerEmail}',
                                  style: theme.textTheme.bodySmall
                                      ?.copyWith(color: Colors.grey),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton.icon(
                          onPressed: state.isLoading
                              ? null
                              : () async {
                                  await ref
                                      .read(deliveryPanelProvider.notifier)
                                      .acceptIncomingRequest(request.id);
                                  if (!context.mounted) return;
                                  if (ref.read(deliveryPanelProvider).error ==
                                      null) {
                                    _showActionSnackBar(
                                        context, 'Delivery accepted.');
                                    context.push(
                                        '/delivery-partner/order-accepted');
                                  }
                                },
                          icon: const Icon(Icons.check_circle_outline),
                          label: const Text('Accept Delivery'),
                          style: _primaryActionStyle(color: Colors.blue),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: OutlinedButton.icon(
                          onPressed: state.isLoading
                              ? null
                              : () async {
                                  await ref
                                      .read(deliveryPanelProvider.notifier)
                                      .rejectIncomingRequest(request.id);
                                  if (!context.mounted) return;
                                  _showActionSnackBar(
                                      context, 'Delivery declined.',
                                      isError: true);
                                  context.pop();
                                },
                          style: _secondaryActionStyle(context),
                          icon: const Icon(Icons.close, color: Colors.grey),
                          label: const Text(
                            'DECLINE ORDER',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildInfoCard(BuildContext context, IconData icon,
      String value, String label, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.blue, size: 28),
          const SizedBox(height: 8),
          Text(value,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(label,
              style: theme.textTheme.labelSmall?.copyWith(color: Colors.grey)),
        ],
      ),
    );
  }
}

class _DashboardHero extends StatelessWidget {
  final String name;
  final int activeDeliveries;
  final int incomingRequests;
  final double weeklyEarnings;
  final VoidCallback onTakeDelivery;

  const _DashboardHero({
    required this.name,
    required this.activeDeliveries,
    required this.incomingRequests,
    required this.weeklyEarnings,
    required this.onTakeDelivery,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF111827)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 700;

          final stats = Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _HeroStatChip(
                label: 'Active deliveries',
                value: '$activeDeliveries',
                icon: Icons.delivery_dining_outlined,
              ),
              _HeroStatChip(
                label: 'Incoming requests',
                value: '$incomingRequests',
                icon: Icons.notifications_active_outlined,
              ),
              _HeroStatChip(
                label: 'Weekly earnings',
                value: '\$${weeklyEarnings.toStringAsFixed(2)}',
                icon: Icons.account_balance_wallet_outlined,
              ),
            ],
          );

          final cta = SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: onTakeDelivery,
              icon: const Icon(Icons.local_shipping_outlined),
              label: const Text('Review requests'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F9D58),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          );

          if (isNarrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back, $name',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Everything you need to manage today’s deliveries in one place.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 20),
                stats,
                const SizedBox(height: 20),
                cta,
              ],
            );
          }

          return Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back, $name',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Everything you need to manage today’s deliveries in one place.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 20),
                    stats,
                  ],
                ),
              ),
              const SizedBox(width: 16),
              cta,
            ],
          );
        },
      ),
    );
  }
}

class _HeroStatChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _HeroStatChip({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white70, size: 18),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Decline Order Screen
class DeclineOrderScreen extends StatefulWidget {
  const DeclineOrderScreen({Key? key}) : super(key: key);

  @override
  State<DeclineOrderScreen> createState() => _DeclineOrderScreenState();
}

class _DeclineOrderScreenState extends State<DeclineOrderScreen> {
  String? _selectedReason;
  final _otherReasonController = TextEditingController();

  final List<Map<String, dynamic>> _declineReasons = [
    {'id': 'too_far', 'icon': Icons.location_on, 'label': 'Too far'},
    {'id': 'closed', 'icon': Icons.storefront, 'label': 'Store is closed'},
    {'id': 'low_pay', 'icon': Icons.monetization_on, 'label': 'Low pay'},
    {'id': 'emergency', 'icon': Icons.emergency, 'label': 'Emergency'},
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(onPressed: () => context.pop()),
        title: Text(
          'Velocity Delivery',
          style:
              theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: CircleAvatar(
              radius: 20,
              backgroundColor: Colors.blue,
              child: Text(
                'DP',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.warning,
                          color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ACTION REQUIRED',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Declining Order #8829',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.red.shade800,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Please provide a reason for rejecting this delivery.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.red.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'SELECT REASON',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12),
              Column(
                children: _declineReasons.map((reason) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedReason = reason['id'] as String;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _selectedReason == reason['id']
                              ? Colors.blue.withOpacity(0.1)
                              : Colors.grey.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _selectedReason == reason['id']
                                ? Colors.blue
                                : Colors.grey.withOpacity(0.2),
                            width: _selectedReason == reason['id'] ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(reason['icon'] as IconData,
                                  color: Colors.blue),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              reason['label'] as String,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Spacer(),
                            Radio<String>(
                              value: reason['id'] as String,
                              groupValue: _selectedReason,
                              onChanged: (value) {
                                setState(() {
                                  _selectedReason = value;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              Text(
                'OTHER REASON',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _otherReasonController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Please specify your reason here...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.withOpacity(0.2)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.withOpacity(0.2)),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    context.pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Confirm Rejection',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton(
                  onPressed: () {
                    context.pop();
                  },
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: BorderSide(color: Colors.grey.withOpacity(0.3)),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _otherReasonController.dispose();
    super.dispose();
  }
}

/// Order Accepted Screen
class OrderAcceptedScreen extends StatelessWidget {
  const OrderAcceptedScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: NetworkImage(
              'https://images.unsplash.com/photo-1524661135-423995f22d0b?auto=format&fit=crop&w=1200&q=80',
            ),
            fit: BoxFit.cover,
          ),
        ),
        child: Stack(
          children: [
            Container(color: Colors.black.withOpacity(0.4)),
            SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Velocity Delivery',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.blue,
                          child: Text(
                            'DP',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 64,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Order Accepted!',
                        style: theme.textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "Great news! You've successfully\nsecured this delivery.",
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: Colors.grey[300],
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              _showActionSnackBar(
                                  context, 'Navigation started');
                            },
                            icon: const Icon(Icons.navigation),
                            label: const Text('Start Navigation'),
                            style: _primaryActionStyle(color: Colors.blue),
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              _showActionSnackBar(
                                  context, 'Viewing pickup details');
                            },
                            icon: const Icon(Icons.info_outline),
                            label: const Text('View Pickup Details'),
                            style: _secondaryActionStyle(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning,
                              color: Colors.red, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Safety first: Please ensure you are parked safely.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.red,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
