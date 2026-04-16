import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../presentation/providers/app_providers.dart';
import '../../../../presentation/widgets/status_badge.dart';
import '../../../../presentation/widgets/curved_panel_bottom_nav.dart';
import '../../../authentication/presentation/providers/auth_provider.dart';
import '../../../authentication/data/services/api_client.dart';
import '../widgets/user_dashboard_sidebar.dart';
import '../dialogs/add_address_dialog.dart';

/// User Order History Screen
class UserOrderHistoryScreen extends ConsumerStatefulWidget {
  const UserOrderHistoryScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<UserOrderHistoryScreen> createState() =>
      _UserOrderHistoryScreenState();
}

class _UserOrderHistoryScreenState
    extends ConsumerState<UserOrderHistoryScreen> {
  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = false;

  Future<void> _loadOrders() async {
    final token = ref.read(authProvider).token;
    if (token == null || token.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final rows = await ApiClient().getMyOrders(token: token);
      if (!mounted) return;
      setState(() {
        _orders = rows;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatOrderDate(String? isoDate) {
    final parsed = DateTime.tryParse(isoDate ?? '');
    if (parsed == null) return 'Unknown date';
    final local = parsed.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${local.year}-${two(local.month)}-${two(local.day)} ${two(local.hour)}:${two(local.minute)}';
  }

  List<String> _itemsFromOrder(Map<String, dynamic> order) {
    final raw = order['items'];
    if (raw is! List) return const [];
    return raw.map((item) {
      if (item is Map) {
        final name = item['name']?.toString();
        if (name != null && name.isNotEmpty) return name;
      }
      return item.toString();
    }).toList();
  }

  Map<String, dynamic> _deliveryPartnerFromOrder(Map<String, dynamic> order) {
    final raw = order['deliveryPartner'];
    if (raw is Map<String, dynamic>) return Map<String, dynamic>.from(raw);
    if (raw is Map) {
      return raw.map((key, value) => MapEntry('$key', value));
    }
    return <String, dynamic>{};
  }

  Map<String, dynamic> _deliveryRequestFromOrder(Map<String, dynamic> order) {
    final raw = order['deliveryRequest'];
    if (raw is Map<String, dynamic>) return Map<String, dynamic>.from(raw);
    if (raw is Map) {
      return raw.map((key, value) => MapEntry('$key', value));
    }
    return <String, dynamic>{};
  }

  bool _hasAssignedPartner(Map<String, dynamic> order) {
    final partner = _deliveryPartnerFromOrder(order);
    final id = partner['id']?.toString() ?? '';
    final name = partner['name']?.toString() ?? '';
    return id.isNotEmpty || name.isNotEmpty;
  }

  void _openChatForOrder(
    BuildContext context,
    Map<String, dynamic> order,
  ) {
    final authState = ref.read(authProvider);
    final currentUser = authState.user;

    if (currentUser == null || currentUser.id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to open chat.')),
      );
      return;
    }

    final orderId = (order['id'] ?? '').toString();
    if (orderId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order ID is missing.')),
      );
      return;
    }

    final partner = _deliveryPartnerFromOrder(order);
    final partnerName = (partner['name']?.toString().trim().isNotEmpty ?? false)
        ? partner['name'].toString()
        : 'Delivery Partner';
    final partnerAvatar =
        (partner['avatar']?.toString().trim().isNotEmpty ?? false)
            ? partner['avatar'].toString()
            : null;

    context.push(
      '/delivery-chat/${Uri.encodeComponent(orderId)}',
      extra: {
        'orderId': orderId,
        'currentUserId': currentUser.id,
        'currentUserName': currentUser.name,
        'riderName': partnerName,
        'riderAvatar': partnerAvatar,
        'isCustomer': true,
      },
    );
  }

  Future<void> _showOrderDetailsDialog(
    BuildContext context,
    Map<String, dynamic> order,
  ) async {
    final orderId = (order['id'] ?? '').toString();
    final status = (order['status'] ?? 'pending').toString();
    final paymentStatus =
        (order['paymentStatus'] ?? order['payment_status'] ?? 'pending')
            .toString();
    final restaurantName =
        (order['restaurantName'] ?? order['restaurant_name'] ?? 'Restaurant')
            .toString();
    final orderDate = _formatOrderDate(order['createdAt']?.toString());
    final totalAmount = ((order['totalAmount'] ?? 0) as num).toDouble();
    final itemNames = _itemsFromOrder(order);
    final partner = _deliveryPartnerFromOrder(order);
    final request = _deliveryRequestFromOrder(order);
    final hasPartner = _hasAssignedPartner(order);
    final requestStatus = (request['status'] ?? '').toString();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Order Details'),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      'Order: #${orderId.length >= 6 ? orderId.substring(0, 6) : orderId}'),
                  const SizedBox(height: 6),
                  Text('Restaurant: $restaurantName'),
                  Text('Date: $orderDate'),
                  Text('Total: \$${totalAmount.toStringAsFixed(2)}'),
                  const SizedBox(height: 8),
                  Text('Order status: ${status.toUpperCase()}'),
                  Text('Payment status: ${paymentStatus.toUpperCase()}'),
                  if (requestStatus.isNotEmpty)
                    Text('Delivery request: ${requestStatus.toUpperCase()}'),
                  if (hasPartner) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Assigned delivery partner: ${partner['name']?.toString() ?? 'Delivery Partner'}',
                    ),
                    if ((partner['phone']?.toString() ?? '').isNotEmpty)
                      Text('Phone: ${partner['phone']}'),
                  ],
                  if (itemNames.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    const Text(
                      'Items',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    ...itemNames.map((item) => Text('• $item')),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            if (hasPartner)
              TextButton.icon(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  _openChatForOrder(context, order);
                },
                icon: const Icon(Icons.chat_bubble_outline, size: 18),
                label: const Text('Chat with Delivery Partner'),
              ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadOrders();
    });
  }

  Future<void> _showRatingDialog(BuildContext context, String restaurant) {
    double rating = 4;
    final feedbackController = TextEditingController();

    return showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Rate $restaurant'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Rating: ${rating.toStringAsFixed(1)} / 5'),
                  Slider(
                    value: rating,
                    min: 1,
                    max: 5,
                    divisions: 8,
                    label: rating.toStringAsFixed(1),
                    onChanged: (value) {
                      setDialogState(() => rating = value);
                    },
                  ),
                  TextField(
                    controller: feedbackController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'Share your feedback...',
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Thanks! Your ${rating.toStringAsFixed(1)}★ review was submitted.',
                        ),
                      ),
                    );
                  },
                  child: const Text('Submit'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final orders = _orders;
    final ongoingOrders = ref.watch(ongoingOrdersProvider);
    final isCompact = MediaQuery.of(context).size.width < 900;

    return Scaffold(
      drawer: isCompact
          ? const Drawer(
              child: SafeArea(
                child: UserDashboardSidebar(
                  currentRoute: '/dashboard/orders',
                  compact: true,
                ),
              ),
            )
          : null,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Order History'),
            Text(
              '${orders.length} orders',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
        elevation: 0,
        automaticallyImplyLeading: isCompact,
        actions: _buildAppBarActions(isCompact),
      ),
      body: SafeArea(
        child: Row(
          children: [
            if (!isCompact)
              const UserDashboardSidebar(currentRoute: '/dashboard/orders'),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        if (ongoingOrders.isNotEmpty) ...[
                          Text(
                            'Ongoing Orders',
                            style: theme.textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          ...ongoingOrders.map(
                            (ongoing) => Card(
                              color: const Color(0xFFFFF7ED),
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                title: Text(
                                  '#${ongoing.id.substring(ongoing.id.length - 6)} • ${ongoing.restaurantName}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Text(
                                  '${ongoing.items.join(', ')}\nETA: ${ongoing.etaMinutes} min',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                trailing: ElevatedButton(
                                  onPressed: () => context.go(
                                    '/order-tracking?orderId=${ongoing.id}',
                                  ),
                                  child: const Text('Track'),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Past Orders',
                            style: theme.textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                        ],
                        ...orders.map((order) {
                          final orderId = (order['id'] ?? '').toString();
                          final status =
                              (order['status'] ?? 'pending').toString();
                          final restaurantName =
                              (order['restaurantName'] ?? 'Restaurant')
                                  .toString();
                          final totalAmount =
                              ((order['totalAmount'] ?? 0) as num).toDouble();
                          final orderDate =
                              _formatOrderDate(order['createdAt']?.toString());
                          final itemNames = _itemsFromOrder(order);

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  LayoutBuilder(
                                    builder: (context, constraints) {
                                      final narrow = constraints.maxWidth < 360;
                                      final idText = Text(
                                        '#${orderId.length >= 6 ? orderId.substring(0, 6) : orderId}',
                                        style: theme.textTheme.titleSmall
                                            ?.copyWith(
                                                fontWeight: FontWeight.bold),
                                      );
                                      final badge = StatusBadge(status: status);

                                      if (narrow) {
                                        return Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            idText,
                                            const SizedBox(height: 6),
                                            badge,
                                          ],
                                        );
                                      }

                                      return Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [idText, badge],
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    restaurantName,
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    itemNames.isEmpty
                                        ? 'No line items available'
                                        : itemNames.join(', '),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.bodySmall
                                        ?.copyWith(color: theme.hintColor),
                                  ),
                                  const SizedBox(height: 12),
                                  LayoutBuilder(
                                    builder: (context, constraints) {
                                      final narrow = constraints.maxWidth < 320;
                                      final date = Text(
                                        orderDate,
                                        style: theme.textTheme.bodySmall,
                                      );
                                      final total = Text(
                                        '\$${totalAmount.toStringAsFixed(2)}',
                                        style: theme.textTheme.titleSmall
                                            ?.copyWith(
                                                fontWeight: FontWeight.bold),
                                      );

                                      if (narrow) {
                                        return Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            date,
                                            const SizedBox(height: 6),
                                            total
                                          ],
                                        );
                                      }

                                      return Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [date, total],
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 10),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 6,
                                    children: [
                                      OutlinedButton.icon(
                                        onPressed: () =>
                                            _showOrderDetailsDialog(
                                          context,
                                          order,
                                        ),
                                        icon: const Icon(
                                          Icons.visibility_outlined,
                                          size: 18,
                                        ),
                                        label: const Text('Order Details'),
                                      ),
                                      OutlinedButton.icon(
                                        onPressed: () => _showRatingDialog(
                                            context, restaurantName),
                                        icon: const Icon(Icons.star_border,
                                            size: 18),
                                        label: const Text('Rate & Review'),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ],
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar:
          _userPanelBottomNav(context, currentRoute: '/dashboard/orders'),
    );
  }
}

/// User Favorites Screen
class UserFavoritesScreen extends ConsumerStatefulWidget {
  const UserFavoritesScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<UserFavoritesScreen> createState() =>
      _UserFavoritesScreenState();
}

class _UserFavoritesScreenState extends ConsumerState<UserFavoritesScreen> {
  List<Map<String, dynamic>> _favorites = [];
  bool _isLoading = false;

  Future<void> _loadFavorites() async {
    final token = ref.read(authProvider).token;
    if (token == null || token.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final rows = await ApiClient().getMyFavorites(token: token);
      if (!mounted) return;
      setState(() {
        _favorites = rows;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFavorites();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final restaurants = _favorites;
    final isCompact = MediaQuery.of(context).size.width < 900;

    return Scaffold(
      drawer: isCompact
          ? const Drawer(
              child: SafeArea(
                child: UserDashboardSidebar(
                  currentRoute: '/dashboard/favorites',
                  compact: true,
                ),
              ),
            )
          : null,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('My Favorites'),
            Text(
              '${restaurants.length} restaurants',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
        elevation: 0,
        automaticallyImplyLeading: isCompact,
        actions: _buildAppBarActions(isCompact),
      ),
      body: SafeArea(
        child: Row(
          children: [
            if (!isCompact)
              const UserDashboardSidebar(currentRoute: '/dashboard/favorites'),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        final width = constraints.maxWidth;
                        final crossAxisCount = width > 900
                            ? 3
                            : width > 620
                                ? 2
                                : 1;

                        return GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossAxisCount,
                            childAspectRatio: crossAxisCount == 1 ? 1.3 : 0.9,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                          ),
                          itemCount: restaurants.length,
                          itemBuilder: (context, index) {
                            final restaurant = restaurants[index];
                            final restaurantData = (restaurant['restaurant']
                                    is Map<String, dynamic>)
                                ? restaurant['restaurant']
                                    as Map<String, dynamic>
                                : <String, dynamic>{};
                            final name =
                                (restaurantData['name'] ?? 'Restaurant')
                                    .toString();
                            final cuisine =
                                (restaurantData['cuisine'] ?? '').toString();
                            final rating = restaurantData['rating'] ?? 0;
                            final image = restaurantData['image']?.toString();
                            return Card(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ClipRRect(
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(12),
                                    ),
                                    child: image == null || image.isEmpty
                                        ? Container(
                                            height:
                                                crossAxisCount == 1 ? 160 : 120,
                                            color: Colors.grey[300],
                                            child: Center(
                                              child: Icon(
                                                Icons.restaurant,
                                                size: 40,
                                                color: theme.primaryColor,
                                              ),
                                            ),
                                          )
                                        : Image.network(
                                            image,
                                            height:
                                                crossAxisCount == 1 ? 160 : 120,
                                            width: double.infinity,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) =>
                                                Container(
                                              height: crossAxisCount == 1
                                                  ? 160
                                                  : 120,
                                              color: Colors.grey[300],
                                              child: Center(
                                                child: Icon(
                                                  Icons.restaurant,
                                                  size: 40,
                                                  color: theme.primaryColor,
                                                ),
                                              ),
                                            ),
                                          ),
                                  ),
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            name,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: theme.textTheme.titleSmall
                                                ?.copyWith(
                                                    fontWeight:
                                                        FontWeight.bold),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            cuisine,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: theme.textTheme.bodySmall,
                                          ),
                                          const Spacer(),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Row(
                                                children: [
                                                  const Icon(
                                                    Icons.star,
                                                    size: 14,
                                                    color: Colors.amber,
                                                  ),
                                                  const SizedBox(width: 2),
                                                  Text(
                                                    '$rating',
                                                    style: theme
                                                        .textTheme.bodySmall,
                                                  ),
                                                ],
                                              ),
                                              const Icon(
                                                Icons.favorite,
                                                size: 16,
                                                color: Colors.red,
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar:
          _userPanelBottomNav(context, currentRoute: '/dashboard/favorites'),
    );
  }
}

/// User Addresses Screen
class UserAddressesScreen extends ConsumerStatefulWidget {
  const UserAddressesScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<UserAddressesScreen> createState() =>
      _UserAddressesScreenState();
}

class _UserAddressesScreenState extends ConsumerState<UserAddressesScreen> {
  late List<Address> addresses;
  bool _isLoading = false;

  String _composeCityStateZip(String city, String state, String? postalCode) {
    final cityPart = city.trim();
    final stateZip = [state.trim(), (postalCode ?? '').trim()]
        .where((v) => v.isNotEmpty)
        .join(' ');
    if (cityPart.isEmpty) return stateZip;
    if (stateZip.isEmpty) return cityPart;
    return '$cityPart, $stateZip';
  }

  ({String city, String state, String postalCode}) _splitCityStateZip(
      String value) {
    final parts = value.split(',').map((e) => e.trim()).toList();
    final city = parts.isNotEmpty ? parts.first : '';
    final stateZip = parts.length > 1 ? parts[1] : '';
    final pieces =
        stateZip.split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
    final state = pieces.isNotEmpty ? pieces.first : '';
    final postalCode = pieces.length > 1 ? pieces.sublist(1).join(' ') : '';
    return (city: city, state: state, postalCode: postalCode);
  }

  Address _fromApiAddress(Map<String, dynamic> json) {
    final city = (json['city'] ?? '').toString();
    final state = (json['state'] ?? '').toString();
    final postal = json['postalCode']?.toString();

    return Address(
      id: (json['id'] ?? '').toString(),
      label: (json['label'] ?? 'Address').toString(),
      address: (json['streetAddress'] ?? '').toString(),
      cityStateZip: _composeCityStateZip(city, state, postal),
      isDefault: json['isDefault'] == true,
    );
  }

  Future<void> _loadAddresses() async {
    final token = ref.read(authProvider).token;
    if (token == null || token.isEmpty) {
      return;
    }

    setState(() => _isLoading = true);
    try {
      final api = ApiClient();
      final rows = await api.getMyAddresses(token: token);
      if (!mounted) return;
      setState(() {
        addresses = rows.map(_fromApiAddress).toList();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    addresses = [];
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAddresses();
    });
  }

  void _showAddAddressDialog({Address? address}) {
    showDialog(
      context: context,
      builder: (context) => AddAddressDialog(
        initialAddress: address,
        onSave: (newAddress) async {
          final token = ref.read(authProvider).token;
          if (token == null || token.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Please login again.')),
            );
            return;
          }

          final cityState = _splitCityStateZip(newAddress.cityStateZip);

          try {
            final api = ApiClient();
            if (address != null) {
              await api.updateMyAddress(
                token: token,
                addressId: address.id,
                payload: {
                  'label': newAddress.label,
                  'streetAddress': newAddress.address,
                  'city': cityState.city,
                  'state': cityState.state,
                  'postalCode': cityState.postalCode,
                  'isDefault': newAddress.isDefault,
                },
              );
            } else {
              await api.createMyAddress(
                token: token,
                payload: {
                  'label': newAddress.label,
                  'streetAddress': newAddress.address,
                  'city': cityState.city,
                  'state': cityState.state,
                  'postalCode': cityState.postalCode,
                  'isDefault': newAddress.isDefault,
                },
              );
            }

            await _loadAddresses();
          } catch (e) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(e.toString().replaceAll('Exception: ', ''))),
            );
          }
        },
      ),
    );
  }

  void _deleteAddress(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Address'),
        content: const Text('Are you sure you want to delete this address?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final token = ref.read(authProvider).token;
              Navigator.pop(context);
              if (token == null || token.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please login again.')),
                );
                return;
              }

              try {
                await ApiClient().deleteMyAddress(token: token, addressId: id);
                await _loadAddresses();
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Address deleted')),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content:
                          Text(e.toString().replaceAll('Exception: ', ''))),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _setAsDefault(String id) async {
    final token = ref.read(authProvider).token;
    if (token == null || token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login again.')),
      );
      return;
    }

    try {
      await ApiClient().setDefaultMyAddress(token: token, addressId: id);
      await _loadAddresses();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCompact = MediaQuery.of(context).size.width < 900;

    return Scaffold(
      drawer: isCompact
          ? const Drawer(
              child: SafeArea(
                child: UserDashboardSidebar(
                  currentRoute: '/dashboard/addresses',
                  compact: true,
                ),
              ),
            )
          : null,
      appBar: AppBar(
        title: const Text('Saved Addresses'),
        elevation: 0,
        automaticallyImplyLeading: isCompact,
        actions: _buildAppBarActions(isCompact),
      ),
      body: SafeArea(
        child: Row(
          children: [
            if (!isCompact)
              const UserDashboardSidebar(currentRoute: '/dashboard/addresses'),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: addresses.length,
                      itemBuilder: (context, index) {
                        final addr = addresses[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                LayoutBuilder(
                                  builder: (context, constraints) {
                                    final narrow = constraints.maxWidth < 360;

                                    final labelRow = Row(
                                      children: [
                                        Icon(
                                          Icons.location_on,
                                          color: theme.primaryColor,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          addr.label,
                                          style: theme.textTheme.titleSmall
                                              ?.copyWith(
                                                  fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    );

                                    final badge = addr.isDefault
                                        ? Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: theme.primaryColor
                                                  .withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              'Default',
                                              style: TextStyle(
                                                color: theme.primaryColor,
                                                fontSize: 12,
                                              ),
                                            ),
                                          )
                                        : const SizedBox.shrink();

                                    if (narrow) {
                                      return Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          labelRow,
                                          if (addr.isDefault) ...[
                                            const SizedBox(height: 6),
                                            badge,
                                          ],
                                        ],
                                      );
                                    }

                                    return Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [labelRow, badge],
                                    );
                                  },
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  addr.address,
                                  style: theme.textTheme.bodySmall,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  addr.cityStateZip,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Wrap(
                                  alignment: WrapAlignment.end,
                                  spacing: 8,
                                  runSpacing: 6,
                                  children: [
                                    if (!addr.isDefault)
                                      TextButton(
                                        onPressed: () => _setAsDefault(addr.id),
                                        child: const Text('Set Default'),
                                      ),
                                    TextButton(
                                      onPressed: () =>
                                          _showAddAddressDialog(address: addr),
                                      child: const Text('Edit'),
                                    ),
                                    TextButton(
                                      onPressed: () => _deleteAddress(addr.id),
                                      child: const Text('Delete'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddAddressDialog(),
        heroTag: 'user-addresses-fab',
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar:
          _userPanelBottomNav(context, currentRoute: '/dashboard/addresses'),
    );
  }
}

Widget _userPanelBottomNav(BuildContext context,
    {required String currentRoute}) {
  return CurvedPanelBottomNav(
    items: [
      CurvedNavItemData(
        icon: Icons.home_outlined,
        selectedIcon: Icons.home,
        label: 'Home',
        isSelected: currentRoute == '/dashboard',
        onTap: () => context.go('/dashboard'),
      ),
      CurvedNavItemData(
        icon: Icons.travel_explore_outlined,
        selectedIcon: Icons.travel_explore,
        label: 'Browse',
        isSelected: currentRoute == '/browse',
        onTap: () => context.go('/browse'),
      ),
      CurvedNavItemData(
        icon: Icons.receipt_long_outlined,
        selectedIcon: Icons.receipt_long,
        label: 'Orders',
        isSelected: currentRoute == '/dashboard/orders',
        onTap: () => context.go('/dashboard/orders'),
      ),
      CurvedNavItemData(
        icon: Icons.notifications_outlined,
        selectedIcon: Icons.notifications,
        label: 'Alerts',
        isSelected: currentRoute == '/dashboard/notifications',
        onTap: () => context.go('/dashboard/notifications'),
      ),
      CurvedNavItemData(
        icon: Icons.settings_outlined,
        selectedIcon: Icons.settings,
        label: 'Settings',
        isSelected: currentRoute == '/dashboard/settings',
        onTap: () => context.go('/dashboard/settings'),
      ),
    ],
  );
}

List<Widget> _buildAppBarActions(bool compact) {
  if (compact) {
    return [
      IconButton(
        icon: const Icon(Icons.search),
        onPressed: () {},
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        iconSize: 20,
      ),
      IconButton(
        icon: const Icon(Icons.notifications_outlined),
        onPressed: () {},
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        iconSize: 20,
      ),
      IconButton(
        icon: const Icon(Icons.person),
        onPressed: () {},
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        iconSize: 20,
      ),
      const SizedBox(width: 8),
    ];
  }

  return [
    IconButton(
      icon: const Icon(Icons.search),
      onPressed: () {},
    ),
    const SizedBox(width: 8),
    IconButton(
      icon: const Icon(Icons.notifications_outlined),
      onPressed: () {},
    ),
    const SizedBox(width: 8),
    const CircleAvatar(
      backgroundColor: Color(0xFFFF6B35),
      child: Icon(Icons.person, color: Colors.white),
    ),
    const SizedBox(width: 16),
  ];
}
