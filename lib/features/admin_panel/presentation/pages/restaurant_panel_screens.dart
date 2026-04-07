import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import '../../../../presentation/providers/app_providers.dart';
import '../../../../presentation/widgets/curved_panel_bottom_nav.dart';
import '../../../authentication/presentation/providers/auth_provider.dart';

import '../providers/restaurant_panel_provider.dart';
import 'customer_order_details_screen.dart';

final ValueNotifier<bool> _restaurantSidebarCollapsed =
    ValueNotifier<bool>(false);

class RestaurantOverviewScreen extends ConsumerWidget {
  const RestaurantOverviewScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final backendSync = ref.watch(restaurantPanelSyncProvider);
    final state = ref.watch(restaurantPanelProvider);
    final orders = state.orders;
    final revenue = ref.watch(restaurantPanelRevenueProvider);

    final todayOrders = orders.where((o) => o.status != 'rejected').length;
    final newOrders = orders.where((o) => o.status == 'new').toList();
    final activeOrders = orders
        .where((o) => o.status != 'rejected' && o.status != 'picked_up')
        .toList();

    return RestaurantPanelScaffold(
      currentRoute: '/admin/restaurant-panel',
      title: 'Restaurant Dashboard',
      subtitle: state.profile.name,
      child: Column(
        children: [
          if (backendSync.isLoading) ...[
            const LinearProgressIndicator(minHeight: 3),
            const SizedBox(height: 12),
          ],
          if (backendSync.hasError) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF4E5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Backend sync unavailable right now. Showing fallback panel data.',
                style: TextStyle(fontSize: 12, color: Color(0xFF8A4B00)),
              ),
            ),
            const SizedBox(height: 12),
          ],
          _StatsGrid(
            mobileCrossAxisCount: 2,
            cards: [
              _MetricData(
                icon: Icons.receipt_long_outlined,
                value: '$todayOrders',
                label: "Today's Orders",
              ),
              _MetricData(
                icon: Icons.attach_money,
                value: '\$${revenue.toStringAsFixed(2)}',
                label: "Today's Revenue",
              ),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 980;

              final weeklySalesCard = _PanelCard(
                title: 'Weekly Sales',
                child: SizedBox(
                  height: 220,
                  child: _WeeklySalesChart(
                    values: const [980, 1120, 890, 1340, 1670, 1920, 1540],
                  ),
                ),
              );

              final newOrdersCard = _PanelCard(
                title: 'New Orders (${newOrders.length})',
                child: Column(
                  children: newOrders.isEmpty
                      ? [const _EmptyText('No new orders right now. 🎉')]
                      : newOrders
                          .map(
                            (order) => _CompactOrderCard(
                              order: order,
                              onAccept: () => ref
                                  .read(restaurantPanelProvider.notifier)
                                  .updateOrderStatus(order.id, 'accepted'),
                              onReject: () => ref
                                  .read(restaurantPanelProvider.notifier)
                                  .updateOrderStatus(order.id, 'rejected'),
                            ),
                          )
                          .toList(),
                ),
              );

              if (isNarrow) {
                return Column(
                  children: [
                    weeklySalesCard,
                    const SizedBox(height: 16),
                    newOrdersCard,
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: weeklySalesCard),
                  const SizedBox(width: 16),
                  Expanded(child: newOrdersCard),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          _PanelCard(
            title: 'Active Orders',
            child: Column(
              children: activeOrders
                  .map((order) => _ActiveOrderRow(order: order))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class RestaurantMenuScreen extends ConsumerStatefulWidget {
  const RestaurantMenuScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<RestaurantMenuScreen> createState() =>
      _RestaurantMenuScreenState();
}

class _RestaurantMenuScreenState extends ConsumerState<RestaurantMenuScreen> {
  String _search = '';
  String _selectedCategory = 'All';

  @override
  Widget build(BuildContext context) {
    final backendSync = ref.watch(restaurantPanelSyncProvider);
    final state = ref.watch(restaurantPanelProvider);
    final categories = ref.watch(restaurantPanelCategoriesProvider);

    final filteredItems = state.menuItems.where((item) {
      final matchesSearch = _search.trim().isEmpty ||
          item.name.toLowerCase().contains(_search.toLowerCase()) ||
          item.description.toLowerCase().contains(_search.toLowerCase());
      final matchesCategory =
          _selectedCategory == 'All' || item.category == _selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();

    return RestaurantPanelScaffold(
      currentRoute: '/admin/restaurant-panel/menu',
      title: 'Menu Management',
      subtitle: 'Manage your food items',
      action: ElevatedButton.icon(
        onPressed: () =>
            _showMenuItemDialog(context, categories: state.categories),
        icon: const Icon(Icons.add),
        label: const Text('Add Item'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFF7A00),
          foregroundColor: Colors.white,
          minimumSize: const Size(130, 52),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (backendSync.isLoading) ...[
            const LinearProgressIndicator(minHeight: 3),
            const SizedBox(height: 12),
          ],
          TextField(
            onChanged: (value) => setState(() => _search = value),
            decoration: const InputDecoration(
              hintText: 'Search menu items...',
              prefixIcon: Icon(Icons.search),
            ),
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: categories
                  .map(
                    (category) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(category),
                        selected: _selectedCategory == category,
                        onSelected: (_) =>
                            setState(() => _selectedCategory = category),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final crossAxisCount = width > 1400
                  ? 4
                  : width > 1000
                      ? 3
                      : width > 680
                          ? 2
                          : 1;

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredItems.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.05,
                ),
                itemBuilder: (context, index) {
                  final item = filteredItems[index];
                  return _MenuItemCard(
                    item: item,
                    onEdit: () => _showMenuItemDialog(
                      context,
                      categories: state.categories,
                      existingItem: item,
                    ),
                    onDelete: () {
                      _handleDeleteMenuItem(context, item.id);
                    },
                    onToggleVisibility: () {
                      _handleToggleMenuAvailability(context, item.id);
                    },
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _showMenuItemDialog(
    BuildContext context, {
    required List<RestaurantMenuCategory> categories,
    RestaurantMenuItem? existingItem,
  }) async {
    final parentContext = context;
    final nameController =
        TextEditingController(text: existingItem?.name ?? '');
    final descriptionController =
        TextEditingController(text: existingItem?.description ?? '');
    final priceController =
        TextEditingController(text: existingItem?.price.toString() ?? '');
    final imageController =
        TextEditingController(text: existingItem?.imageUrl ?? '');

    final fallbackCategories = [
      const RestaurantMenuCategory(id: 'cat-2', name: 'Burgers'),
      const RestaurantMenuCategory(id: 'cat-6', name: 'Beverages'),
    ];
    final categoryOptions =
        categories.isEmpty ? fallbackCategories : categories;

    RestaurantMenuCategory selectedCategory = categoryOptions.firstWhere(
      (item) => item.name == existingItem?.category,
      orElse: () => categoryOptions.first,
    );

    bool popular = existingItem?.popular ?? false;
    bool available = existingItem?.isAvailable ?? true;
    bool isSaving = false;
    bool isPickingImage = false;
    Uint8List? selectedImageBytes;
    String? selectedImageMimeType;

    final formKey = GlobalKey<FormState>();
    final imagePicker = ImagePicker();

    final result = await showDialog<bool>(
      context: parentContext,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setModalState) {
          return AlertDialog(
            title:
                Text(existingItem == null ? 'Add Menu Item' : 'Edit Menu Item'),
            content: SizedBox(
              width: 520,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(dialogContext).size.height * 0.72,
                ),
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Theme.of(context)
                                  .dividerColor
                                  .withOpacity(0.25),
                            ),
                          ),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: selectedImageBytes != null
                                    ? Image.memory(
                                        selectedImageBytes!,
                                        width: 72,
                                        height: 72,
                                        fit: BoxFit.cover,
                                      )
                                    : (imageController.text.trim().isNotEmpty
                                        ? Image.network(
                                            imageController.text.trim(),
                                            width: 72,
                                            height: 72,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) =>
                                                Container(
                                              width: 72,
                                              height: 72,
                                              color: Colors.grey.shade200,
                                              child: const Icon(Icons.fastfood),
                                            ),
                                          )
                                        : Container(
                                            width: 72,
                                            height: 72,
                                            color: Colors.grey.shade200,
                                            child: const Icon(Icons.fastfood),
                                          )),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Food Image',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall
                                          ?.copyWith(
                                              fontWeight: FontWeight.w600),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      selectedImageBytes != null
                                          ? 'Selected from device'
                                          : 'Upload from gallery or paste an image URL',
                                      style:
                                          Theme.of(context).textTheme.bodySmall,
                                    ),
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: [
                                        ElevatedButton.icon(
                                          onPressed: isPickingImage
                                              ? null
                                              : () async {
                                                  setModalState(() {
                                                    isPickingImage = true;
                                                  });
                                                  try {
                                                    final picked =
                                                        await imagePicker
                                                            .pickImage(
                                                      source:
                                                          ImageSource.gallery,
                                                      imageQuality: 85,
                                                      maxWidth: 1400,
                                                    );

                                                    if (picked != null) {
                                                      final bytes = await picked
                                                          .readAsBytes();
                                                      if (!dialogContext
                                                          .mounted) {
                                                        return;
                                                      }
                                                      setModalState(() {
                                                        selectedImageBytes =
                                                            bytes;
                                                        selectedImageMimeType =
                                                            picked.mimeType ??
                                                                'image/jpeg';
                                                      });

                                                      if (bytes.lengthInBytes >
                                                          2 * 1024 * 1024) {
                                                        ScaffoldMessenger.of(
                                                                dialogContext)
                                                            .showSnackBar(
                                                          const SnackBar(
                                                            content: Text(
                                                              'Large image selected — it will be compressed before upload.',
                                                            ),
                                                          ),
                                                        );
                                                      }
                                                    }
                                                  } finally {
                                                    if (dialogContext.mounted) {
                                                      setModalState(() {
                                                        isPickingImage = false;
                                                      });
                                                    }
                                                  }
                                                },
                                          icon: isPickingImage
                                              ? const SizedBox(
                                                  width: 14,
                                                  height: 14,
                                                  child:
                                                      CircularProgressIndicator(
                                                          strokeWidth: 2),
                                                )
                                              : const Icon(Icons.upload_file),
                                          label: const Text('Upload'),
                                        ),
                                        OutlinedButton(
                                          onPressed: () {
                                            setModalState(() {
                                              selectedImageBytes = null;
                                              selectedImageMimeType = null;
                                            });
                                          },
                                          child: const Text('Use URL only'),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: nameController,
                          decoration:
                              const InputDecoration(labelText: 'Item name'),
                          validator: (value) =>
                              (value == null || value.trim().isEmpty)
                                  ? 'Required'
                                  : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: descriptionController,
                          maxLines: 2,
                          decoration:
                              const InputDecoration(labelText: 'Description'),
                          validator: (value) =>
                              (value == null || value.trim().isEmpty)
                                  ? 'Required'
                                  : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: priceController,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          decoration: const InputDecoration(labelText: 'Price'),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Required';
                            }
                            final parsed = double.tryParse(value.trim());
                            if (parsed == null || parsed <= 0) {
                              return 'Enter a valid price';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: imageController,
                          decoration: const InputDecoration(
                            labelText: 'Image URL (optional)',
                          ),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: selectedCategory.id,
                          items: categoryOptions
                              .map(
                                (item) => DropdownMenuItem(
                                  value: item.id,
                                  child: Text(item.name),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              final nextCategory = categoryOptions.firstWhere(
                                (item) => item.id == value,
                                orElse: () => categoryOptions.first,
                              );
                              setModalState(
                                  () => selectedCategory = nextCategory);
                            }
                          },
                          decoration:
                              const InputDecoration(labelText: 'Category'),
                        ),
                        const SizedBox(height: 8),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          value: popular,
                          title: const Text('Popular item'),
                          onChanged: (value) =>
                              setModalState(() => popular = value),
                        ),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          value: available,
                          title: const Text('Available'),
                          onChanged: (value) =>
                              setModalState(() => available = value),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed:
                    isSaving ? null : () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: isSaving
                    ? null
                    : () async {
                        if (formKey.currentState?.validate() ?? false) {
                          if (selectedImageBytes == null &&
                              imageController.text.trim().isEmpty) {
                            ScaffoldMessenger.of(dialogContext).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'Please upload an image or provide an image URL.'),
                              ),
                            );
                            return;
                          }

                          setModalState(() => isSaving = true);

                          final parsedPrice =
                              double.parse(priceController.text.trim());
                          final notifier =
                              ref.read(restaurantPanelProvider.notifier);

                          if (existingItem == null) {
                            final created =
                                await notifier.createMenuItemInBackend(
                              name: nameController.text.trim(),
                              description: descriptionController.text.trim(),
                              categoryId: selectedCategory.id,
                              category: selectedCategory.name,
                              price: parsedPrice,
                              imageUrl: imageController.text.trim(),
                              imageBytes: selectedImageBytes,
                              imageMimeType: selectedImageMimeType,
                              popular: popular,
                              available: available,
                            );

                            if (!created) {
                              if (!parentContext.mounted) return;

                              final message = notifier.lastBackendError ??
                                  (notifier.isBackendAvailable
                                      ? 'Could not save item to backend. Please try again.'
                                      : 'Backend save is unavailable. Please login and ensure backend is running.');

                              ScaffoldMessenger.of(parentContext).showSnackBar(
                                SnackBar(content: Text(message)),
                              );
                              setModalState(() => isSaving = false);
                              return;
                            }
                          } else {
                            final updated =
                                await notifier.updateMenuItemInBackend(
                              foodItemId: existingItem.id,
                              name: nameController.text.trim(),
                              description: descriptionController.text.trim(),
                              categoryId: selectedCategory.id,
                              price: parsedPrice,
                              imageUrl: imageController.text.trim(),
                              imageBytes: selectedImageBytes,
                              imageMimeType: selectedImageMimeType,
                              popular: popular,
                              available: available,
                            );

                            if (!updated) {
                              if (!parentContext.mounted) return;

                              final message = notifier.lastBackendError ??
                                  (notifier.isBackendAvailable
                                      ? 'Could not update item in backend. Please try again.'
                                      : 'Backend save is unavailable. Please login and ensure backend is running.');

                              ScaffoldMessenger.of(parentContext).showSnackBar(
                                SnackBar(content: Text(message)),
                              );
                              setModalState(() => isSaving = false);
                              return;
                            }
                          }

                          if (!dialogContext.mounted) return;
                          Navigator.pop(dialogContext, true);
                        }
                      },
                child: Text(isSaving ? 'Saving...' : 'Save'),
              ),
            ],
          );
        },
      ),
    );

    if (result == true) {
      if (!parentContext.mounted) return;
      ScaffoldMessenger.of(parentContext).showSnackBar(
        SnackBar(
          content: Text(
              existingItem == null ? 'Menu item added' : 'Menu item updated'),
        ),
      );
    }
  }

  Future<void> _handleToggleMenuAvailability(
      BuildContext context, String itemId) async {
    final notifier = ref.read(restaurantPanelProvider.notifier);
    final success = await notifier.toggleMenuAvailabilityInBackend(
      foodItemId: itemId,
    );

    if (!context.mounted) return;

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            notifier.lastBackendError ??
                'Could not update availability right now.',
          ),
        ),
      );
    }
  }

  Future<void> _handleDeleteMenuItem(
      BuildContext context, String itemId) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete menu item?'),
        content: const Text(
          'This will remove the item from your menu. You can add it again later if needed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE53E3E),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete != true || !context.mounted) {
      return;
    }

    final notifier = ref.read(restaurantPanelProvider.notifier);
    final success = await notifier.deleteMenuItemInBackend(foodItemId: itemId);

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Menu item deleted'
              : (notifier.lastBackendError ?? 'Could not delete menu item.'),
        ),
      ),
    );
  }
}

class RestaurantOrdersScreen extends ConsumerStatefulWidget {
  const RestaurantOrdersScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<RestaurantOrdersScreen> createState() =>
      _RestaurantOrdersScreenState();
}

class _RestaurantOrdersScreenState
    extends ConsumerState<RestaurantOrdersScreen> {
  String _filter = 'all';

  @override
  Widget build(BuildContext context) {
    final backendSync = ref.watch(restaurantPanelSyncProvider);
    final orders =
        ref.watch(restaurantPanelProvider.select((state) => state.orders));
    final filteredOrders = orders.where((order) {
      if (_filter == 'all') return true;
      return order.status == _filter;
    }).toList();

    return RestaurantPanelScaffold(
      currentRoute: '/admin/restaurant-panel/orders',
      title: 'Order Management',
      subtitle: 'Track and manage incoming orders',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (backendSync.isLoading) ...[
            const LinearProgressIndicator(minHeight: 3),
            const SizedBox(height: 12),
          ],
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _statusChip('all', 'All'),
                _statusChip('new', 'New'),
                _statusChip('accepted', 'Accepted'),
                _statusChip('preparing', 'Preparing'),
                _statusChip('ready', 'Ready'),
                _statusChip('picked_up', 'Picked Up'),
                _statusChip('rejected', 'Rejected'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ...filteredOrders.map((order) => _OrderManagementCard(order: order)),
        ],
      ),
    );
  }

  Widget _statusChip(String status, String label) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: _filter == status,
        onSelected: (_) => setState(() => _filter = status),
      ),
    );
  }
}

class RestaurantAnalyticsScreen extends ConsumerWidget {
  const RestaurantAnalyticsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items =
        ref.watch(restaurantPanelProvider.select((state) => state.menuItems));
    final orders =
        ref.watch(restaurantPanelProvider.select((state) => state.orders));

    final revenue = orders
        .where((o) => o.status != 'rejected')
        .fold<double>(0, (sum, o) => sum + o.total);
    final completedOrders = orders.where((o) => o.status == 'picked_up').length;
    final avgRating = 4.8;

    final categoryDistribution = <String, int>{};
    for (final item in items) {
      categoryDistribution[item.category] =
          (categoryDistribution[item.category] ?? 0) + 1;
    }

    return RestaurantPanelScaffold(
      currentRoute: '/admin/restaurant-panel/analytics',
      title: 'Analytics',
      subtitle: 'Sales reports and insights',
      child: Column(
        children: [
          _StatsGrid(
            cards: [
              _MetricData(
                icon: Icons.receipt_long_outlined,
                value: '${orders.length}',
                label: 'Weekly Orders',
              ),
              _MetricData(
                icon: Icons.attach_money,
                value: '\$${revenue.toStringAsFixed(0)}',
                label: 'Weekly Revenue',
              ),
              _MetricData(
                icon: Icons.star_outline,
                value: '$avgRating',
                label: 'Avg Rating',
              ),
              _MetricData(
                icon: Icons.trending_up,
                value: '+12.5%',
                label: 'Growth',
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _PanelCard(
                  title: 'Daily Revenue',
                  child: SizedBox(
                    height: 260,
                    child: _WeeklySalesChart(
                      values: const [980, 1120, 890, 1340, 1670, 1920, 1540],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _PanelCard(
                  title: 'Menu Distribution',
                  child: SizedBox(
                    height: 260,
                    child: _MenuDistributionChart(
                      values: categoryDistribution,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _PanelCard(
            title: 'Popular Items',
            child: Column(
              children: items
                  .where((item) => item.popular)
                  .map(
                    (item) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          item.imageUrl,
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 48,
                            height: 48,
                            color: Colors.grey.shade200,
                            child: const Icon(Icons.fastfood),
                          ),
                        ),
                      ),
                      title: Text(item.name),
                      subtitle: Text(item.category),
                      trailing: Text(
                        '\$${item.price.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Color(0xFFFF6B35),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'Completed this week: $completedOrders orders',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

class RestaurantProfileScreen extends ConsumerStatefulWidget {
  const RestaurantProfileScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<RestaurantProfileScreen> createState() =>
      _RestaurantProfileScreenState();
}

class _RestaurantProfileScreenState
    extends ConsumerState<RestaurantProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _profileImagePicker = ImagePicker();
  Uint8List? _selectedProfileImageBytes;
  String? _selectedProfileImageMimeType;
  bool _isPickingProfileImage = false;

  late final TextEditingController _nameController;
  late final TextEditingController _cuisineController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _addressController;
  late final TextEditingController _hoursController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _imageController;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(restaurantPanelProvider).profile;
    _nameController = TextEditingController(text: profile.name);
    _cuisineController = TextEditingController(text: profile.cuisine);
    _phoneController = TextEditingController(text: profile.phone);
    _emailController = TextEditingController(text: profile.email);
    _addressController = TextEditingController(text: profile.address);
    _hoursController = TextEditingController(text: profile.hours);
    _descriptionController = TextEditingController(text: profile.description);
    _imageController = TextEditingController(text: profile.imageUrl);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _cuisineController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _hoursController.dispose();
    _descriptionController.dispose();
    _imageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile =
        ref.watch(restaurantPanelProvider.select((state) => state.profile));

    return RestaurantPanelScaffold(
      currentRoute: '/admin/restaurant-panel/profile',
      title: 'Profile',
      subtitle: 'Business information',
      action: ElevatedButton.icon(
        onPressed: _saveProfile,
        icon: const Icon(Icons.save_outlined),
        label: const Text('Save Changes'),
      ),
      child: Column(
        children: [
          Form(
            key: _formKey,
            child: _PanelCard(
              title: 'Restaurant Details',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isNarrow = constraints.maxWidth < 560;

                      final image = ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: _selectedProfileImageBytes != null
                            ? Image.memory(
                                _selectedProfileImageBytes!,
                                width: 86,
                                height: 86,
                                fit: BoxFit.cover,
                              )
                            : Image.network(
                                _imageController.text,
                                width: 86,
                                height: 86,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 86,
                                  height: 86,
                                  color:
                                      const Color(0xFFFF6B35).withOpacity(0.15),
                                  child: const Icon(
                                    Icons.storefront_outlined,
                                    size: 32,
                                    color: Color(0xFFFF6B35),
                                  ),
                                ),
                              ),
                      );

                      final details = Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            profile.name,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            profile.cuisine,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      );

                      if (isNarrow) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            image,
                            const SizedBox(height: 12),
                            details,
                          ],
                        );
                      }

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          image,
                          const SizedBox(width: 16),
                          Expanded(child: details),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 18),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _isPickingProfileImage
                            ? null
                            : () async {
                                setState(() {
                                  _isPickingProfileImage = true;
                                });

                                try {
                                  final picked =
                                      await _profileImagePicker.pickImage(
                                    source: ImageSource.gallery,
                                    imageQuality: 85,
                                    maxWidth: 1800,
                                  );

                                  if (picked == null) {
                                    return;
                                  }

                                  final bytes = await picked.readAsBytes();
                                  if (!context.mounted) {
                                    return;
                                  }

                                  setState(() {
                                    _selectedProfileImageBytes = bytes;
                                    _selectedProfileImageMimeType =
                                        picked.mimeType ?? 'image/jpeg';
                                  });

                                  if (bytes.lengthInBytes > 2 * 1024 * 1024) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Large image selected — it will be compressed before upload.',
                                        ),
                                      ),
                                    );
                                  }
                                } finally {
                                  if (context.mounted) {
                                    setState(() {
                                      _isPickingProfileImage = false;
                                    });
                                  }
                                }
                              },
                        icon: _isPickingProfileImage
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.upload_file),
                        label: const Text('Upload Image'),
                      ),
                      OutlinedButton(
                        onPressed: () {
                          setState(() {
                            _selectedProfileImageBytes = null;
                            _selectedProfileImageMimeType = null;
                          });
                        },
                        child: const Text('Use URL only'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isNarrow = constraints.maxWidth < 780;
                      if (isNarrow) {
                        return Column(
                          children: [
                            _buildInput(_nameController, 'Restaurant Name'),
                            _buildInput(_cuisineController, 'Cuisine'),
                            _buildInput(_phoneController, 'Phone'),
                            _buildInput(_emailController, 'Email'),
                            _buildInput(_addressController, 'Address'),
                            _buildInput(_hoursController, 'Operating Hours'),
                          ],
                        );
                      }

                      return Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                  child: _buildInput(
                                      _nameController, 'Restaurant Name')),
                              const SizedBox(width: 12),
                              Expanded(
                                  child: _buildInput(
                                      _cuisineController, 'Cuisine')),
                            ],
                          ),
                          Row(
                            children: [
                              Expanded(
                                  child:
                                      _buildInput(_phoneController, 'Phone')),
                              const SizedBox(width: 12),
                              Expanded(
                                  child:
                                      _buildInput(_emailController, 'Email')),
                            ],
                          ),
                          Row(
                            children: [
                              Expanded(
                                  child: _buildInput(
                                      _addressController, 'Address')),
                              const SizedBox(width: 12),
                              Expanded(
                                  child: _buildInput(
                                      _hoursController, 'Operating Hours')),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: TextFormField(
                      controller: _imageController,
                      decoration: const InputDecoration(
                        labelText: 'Image URL (optional when uploaded)',
                      ),
                    ),
                  ),
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 3,
                    decoration: const InputDecoration(labelText: 'Description'),
                    validator: _requiredValidator,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          _PanelCard(
            title: 'Account',
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(
                Icons.logout,
                color: Color(0xFFE53E3E),
              ),
              title: const Text('Logout'),
              subtitle: const Text('Sign out from restaurant panel'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: _confirmAndLogout,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInput(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(labelText: label),
        validator: _requiredValidator,
      ),
    );
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Required';
    }
    return null;
  }

  Future<void> _saveProfile() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final profile = RestaurantProfileData(
      name: _nameController.text.trim(),
      cuisine: _cuisineController.text.trim(),
      phone: _phoneController.text.trim(),
      email: _emailController.text.trim(),
      address: _addressController.text.trim(),
      hours: _hoursController.text.trim(),
      description: _descriptionController.text.trim(),
      imageUrl: _imageController.text.trim(),
    );

    final notifier = ref.read(restaurantPanelProvider.notifier);
    final success = await notifier.updateProfileInBackend(
      profile,
      imageBytes: _selectedProfileImageBytes,
      imageMimeType: _selectedProfileImageMimeType,
    );

    if (!mounted) return;

    if (success) {
      final latestProfile = ref.read(restaurantPanelProvider).profile;
      if (latestProfile.imageUrl.isNotEmpty) {
        _imageController.text = latestProfile.imageUrl;
      }

      ref.invalidate(restaurantsProvider);
      ref.invalidate(featuredRestaurantsProvider);
      ref.invalidate(filteredRestaurantsProvider);

      setState(() {
        _selectedProfileImageBytes = null;
        _selectedProfileImageMimeType = null;
      });
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Profile updated successfully'
              : (notifier.lastBackendError ??
                  'Could not update profile right now.'),
        ),
      ),
    );
  }

  Future<void> _confirmAndLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE53E3E),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (shouldLogout == true && mounted) {
      ref.read(authProvider.notifier).logout();
      context.go('/login');
    }
  }
}

class RestaurantPanelScaffold extends StatelessWidget {
  final String currentRoute;
  final String title;
  final String subtitle;
  final Widget child;
  final Widget? action;

  const RestaurantPanelScaffold({
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

    final content = Container(
      color: theme.scaffoldBackgroundColor,
      child: CustomScrollView(
        slivers: [
          if (!isMobile)
            SliverToBoxAdapter(
              child: _TopHeader(
                title: title,
                subtitle: subtitle,
                action: action,
              ),
            ),
          if (isMobile && action != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: action!,
                ),
              ),
            ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverToBoxAdapter(child: child),
          ),
        ],
      ),
    );

    if (isMobile) {
      final isOverviewRoute = currentRoute == '/admin/restaurant-panel';
      return Scaffold(
        appBar: AppBar(
          title: Text(title),
          elevation: 0,
          automaticallyImplyLeading: false,
          leading: isOverviewRoute
              ? null
              : IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => context.go('/admin/restaurant-panel'),
                  tooltip: 'Back to Overview',
                ),
        ),
        body: content,
        bottomNavigationBar: CurvedPanelBottomNav(
          items: [
            CurvedNavItemData(
              icon: Icons.grid_view_rounded,
              selectedIcon: Icons.grid_view_rounded,
              label: 'Overview',
              isSelected: currentRoute == '/admin/restaurant-panel',
              onTap: () => context.go('/admin/restaurant-panel'),
            ),
            CurvedNavItemData(
              icon: Icons.restaurant_menu_outlined,
              selectedIcon: Icons.restaurant_menu,
              label: 'Menu',
              isSelected: currentRoute == '/admin/restaurant-panel/menu',
              onTap: () => context.go('/admin/restaurant-panel/menu'),
            ),
            CurvedNavItemData(
              icon: Icons.shopping_bag_outlined,
              selectedIcon: Icons.shopping_bag,
              label: 'Orders',
              isSelected: currentRoute == '/admin/restaurant-panel/orders',
              onTap: () => context.go('/admin/restaurant-panel/orders'),
            ),
            CurvedNavItemData(
              icon: Icons.person_outline,
              selectedIcon: Icons.person,
              label: 'Profile',
              isSelected: currentRoute == '/admin/restaurant-panel/profile' ||
                  currentRoute == '/admin/restaurant-panel/analytics',
              onTap: () => context.go('/admin/restaurant-panel/profile'),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      body: content,
    );
  }
}

class RestaurantPanelSidebar extends ConsumerWidget {
  final String currentRoute;
  final bool compact;

  const RestaurantPanelSidebar({
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
      valueListenable: _restaurantSidebarCollapsed,
      builder: (context, collapsedValue, _) {
        if (compact && collapsedValue) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_restaurantSidebarCollapsed.value) {
              _restaurantSidebarCollapsed.value = false;
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
                        'MY ACCOUNT',
                        style: TextStyle(
                          color: Color(0xFFFF7A00),
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.symmetric(horizontal: collapsed ? 8 : 8),
                  children: [
                    _SideItem(
                      icon: Icons.grid_view_rounded,
                      label: 'Overview',
                      active: currentRoute == '/admin/restaurant-panel',
                      collapsed: collapsed,
                      onTap: () => context.go('/admin/restaurant-panel'),
                    ),
                    _SideItem(
                      icon: Icons.restaurant_menu,
                      label: 'Menu',
                      active: currentRoute == '/admin/restaurant-panel/menu',
                      collapsed: collapsed,
                      onTap: () => context.go('/admin/restaurant-panel/menu'),
                    ),
                    _SideItem(
                      icon: Icons.shopping_bag_outlined,
                      label: 'Orders',
                      active: currentRoute == '/admin/restaurant-panel/orders',
                      collapsed: collapsed,
                      onTap: () => context.go('/admin/restaurant-panel/orders'),
                    ),
                    _SideItem(
                      icon: Icons.bar_chart,
                      label: 'Analytics',
                      active:
                          currentRoute == '/admin/restaurant-panel/analytics',
                      collapsed: collapsed,
                      onTap: () =>
                          context.go('/admin/restaurant-panel/analytics'),
                    ),
                    _SideItem(
                      icon: Icons.person_outline,
                      label: 'Profile',
                      active: currentRoute == '/admin/restaurant-panel/profile',
                      collapsed: collapsed,
                      onTap: () =>
                          context.go('/admin/restaurant-panel/profile'),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  border: Border(
                    top:
                        BorderSide(color: theme.dividerColor.withOpacity(0.15)),
                  ),
                ),
                child: Column(
                  children: [
                    _SideItem(
                      icon: isDark
                          ? Icons.light_mode_outlined
                          : Icons.dark_mode_outlined,
                      label: isDark ? 'Light Mode' : 'Dark Mode',
                      active: false,
                      collapsed: collapsed,
                      onTap: () {
                        ref.read(themeModeProvider.notifier).toggle();
                      },
                    ),
                    _SideItem(
                      icon: Icons.arrow_back,
                      label: 'Back to Home',
                      active: false,
                      collapsed: collapsed,
                      onTap: () => context.go('/'),
                    ),
                    if (allowCollapse)
                      _SideItem(
                        icon: collapsed
                            ? Icons.chevron_right
                            : Icons.chevron_left,
                        label: collapsed ? 'Expand' : 'Collapse',
                        active: false,
                        collapsed: collapsed,
                        onTap: () {
                          _restaurantSidebarCollapsed.value =
                              !_restaurantSidebarCollapsed.value;
                        },
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SideItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final bool collapsed;
  final VoidCallback onTap;

  const _SideItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.collapsed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final baseColor =
        active ? Colors.white : Theme.of(context).textTheme.bodyMedium?.color;
    final sideItem = Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: collapsed ? 10 : 14,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            color: active ? const Color(0xFFFF8A00) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment:
                collapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
            children: [
              Icon(icon, size: 20, color: baseColor),
              if (!collapsed) ...[
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    color: baseColor,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );

    if (!collapsed) return sideItem;
    return Tooltip(message: label, child: sideItem);
  }
}

class _TopHeader extends ConsumerWidget {
  final String title;
  final String subtitle;
  final Widget? action;

  const _TopHeader({
    required this.title,
    required this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border(
          bottom: BorderSide(color: theme.dividerColor.withOpacity(0.15)),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 900;

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(
                          isDense: true,
                          hintText: 'Search...',
                          prefixIcon: Icon(Icons.search),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () {
                        ref.read(themeModeProvider.notifier).toggle();
                      },
                      icon: Icon(
                        isDark
                            ? Icons.light_mode_outlined
                            : Icons.dark_mode_outlined,
                      ),
                    ),
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.notifications_none),
                    ),
                  ],
                ),
                if (action != null) ...[
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: action!,
                  ),
                ],
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
                      title,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 180,
                child: TextField(
                  decoration: const InputDecoration(
                    isDense: true,
                    hintText: 'Search...',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              IconButton(
                onPressed: () {
                  ref.read(themeModeProvider.notifier).toggle();
                },
                icon: Icon(
                  isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                ),
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.notifications_none),
              ),
              const SizedBox(width: 8),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF8A00),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.person_outline,
                    color: Colors.white, size: 18),
              ),
              if (action != null) ...[
                const SizedBox(width: 12),
                action!,
              ],
            ],
          );
        },
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  final List<_MetricData> cards;
  final int mobileCrossAxisCount;

  const _StatsGrid({
    required this.cards,
    this.mobileCrossAxisCount = 1,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final desiredCrossAxisCount = width > 1200
            ? 4
            : width > 850
                ? 2
                : mobileCrossAxisCount;
        final crossAxisCount = desiredCrossAxisCount.clamp(1, cards.length);

        final childAspectRatio = width < 480
            ? (crossAxisCount >= 2 ? 1.35 : 2.0)
            : (crossAxisCount >= 2 ? 1.9 : 2.2);

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: cards.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: childAspectRatio,
          ),
          itemBuilder: (context, index) {
            final card = cards[index];
            return Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Theme.of(context).dividerColor.withOpacity(0.12),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF8A00).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(card.icon,
                        color: const Color(0xFFFF7A00), size: 18),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    card.value,
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 2),
                  Text(card.label,
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _MetricData {
  final IconData icon;
  final String value;
  final String label;

  const _MetricData(
      {required this.icon, required this.value, required this.label});
}

class _PanelCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _PanelCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: Theme.of(context).dividerColor.withOpacity(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _CompactOrderCard extends StatelessWidget {
  final RestaurantPanelOrder order;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const _CompactOrderCard({
    required this.order,
    required this.onAccept,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFF8A00).withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  order.customerName,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              Text(
                '\$${order.total.toStringAsFixed(2)}',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(order.items.join(', '),
              style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 2),
          Text(order.timeAgo, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton(
                onPressed: onAccept,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1FB57A),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(88, 36),
                ),
                child: const Text('Accept'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: onReject,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE53E3E),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(88, 36),
                ),
                child: const Text('Reject'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActiveOrderRow extends StatelessWidget {
  final RestaurantPanelOrder order;

  const _ActiveOrderRow({required this.order});

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(order.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey.withOpacity(0.04),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 720;

          final info = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${order.id} — ${order.customerName}',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              Text(
                order.items.join(', '),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          );

          final meta = Wrap(
            spacing: 10,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  _statusLabel(order.status),
                  style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 12),
                ),
              ),
              Text(
                '\$${order.total.toStringAsFixed(2)}',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          );

          if (isNarrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                info,
                const SizedBox(height: 8),
                meta,
              ],
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
      ),
    );
  }
}

class _OrderManagementCard extends ConsumerWidget {
  final RestaurantPanelOrder order;

  const _OrderManagementCard({required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(restaurantPanelProvider.notifier);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: Theme.of(context).dividerColor.withOpacity(0.12)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 960;

          final leading = Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFFFF8A00).withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.receipt_long_outlined,
                color: Color(0xFFFF7A00)),
          );

          final details = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${order.id} • ${order.customerName}',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(order.items.join(', '),
                  style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 4),
              Text(
                '📍 ${order.address} · ${order.timeAgo}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          );

          final price = Text(
            '\$${order.total.toStringAsFixed(2)}',
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold),
          );

          final actions = _OrderActions(
            status: order.status,
            onAccept: () => notifier.updateOrderStatus(order.id, 'accepted'),
            onReject: () => notifier.updateOrderStatus(order.id, 'rejected'),
            onPreparing: () =>
                notifier.updateOrderStatus(order.id, 'preparing'),
            onReady: () => notifier.updateOrderStatus(order.id, 'ready'),
            onPicked: () => notifier.updateOrderStatus(order.id, 'picked_up'),
          );

          if (isNarrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    leading,
                    const SizedBox(width: 12),
                    Expanded(child: details),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    price,
                    Flexible(
                        child: Align(
                            alignment: Alignment.centerRight, child: actions))
                  ],
                ),
              ],
            );
          }

          return Row(
            children: [
              leading,
              const SizedBox(width: 14),
              Expanded(child: details),
              const SizedBox(width: 10),
              price,
              const SizedBox(width: 10),
              actions,
            ],
          );
        },
      ),
    );
  }
}

class _OrderActions extends StatelessWidget {
  final String status;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  final VoidCallback onPreparing;
  final VoidCallback onReady;
  final VoidCallback onPicked;

  const _OrderActions({
    required this.status,
    required this.onAccept,
    required this.onReject,
    required this.onPreparing,
    required this.onReady,
    required this.onPicked,
  });

  @override
  Widget build(BuildContext context) {
    if (status == 'new') {
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          ElevatedButton.icon(
            onPressed: onAccept,
            icon: const Icon(Icons.check, size: 16),
            label: const Text('Accept'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1FB57A),
              foregroundColor: Colors.white,
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: onReject,
            icon: const Icon(Icons.close, size: 16),
            label: const Text('Reject'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE53E3E),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      );
    }

    if (status == 'accepted') {
      return ElevatedButton.icon(
        onPressed: onPreparing,
        icon: const Icon(Icons.soup_kitchen_outlined, size: 16),
        label: const Text('Start Preparing'),
      );
    }

    if (status == 'preparing') {
      return ElevatedButton.icon(
        onPressed: onReady,
        icon: const Icon(Icons.done_all, size: 16),
        label: const Text('Mark Ready'),
      );
    }

    if (status == 'ready') {
      return ElevatedButton.icon(
        onPressed: onPicked,
        icon: const Icon(Icons.delivery_dining_outlined, size: 16),
        label: const Text('Mark Picked Up'),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _statusColor(status).withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        _statusLabel(status),
        style:
            TextStyle(color: _statusColor(status), fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _MenuItemCard extends StatelessWidget {
  final RestaurantMenuItem item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleVisibility;

  const _MenuItemCard({
    required this.item,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleVisibility,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: Theme.of(context).dividerColor.withOpacity(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(16)),
                  child: Image.network(
                    item.imageUrl,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.grey.shade200,
                      child:
                          const Center(child: Icon(Icons.fastfood, size: 36)),
                    ),
                  ),
                ),
                if (item.popular)
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF8A00),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        'Popular',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.name,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      Text(
                        '\$${item.price.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Color(0xFFFF6B35),
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: onToggleVisibility,
                          icon: Icon(item.isAvailable
                              ? Icons.visibility_off
                              : Icons.visibility),
                          label: Text(item.isAvailable ? 'Hide' : 'Show'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey.withOpacity(0.12),
                            foregroundColor:
                                Theme.of(context).textTheme.bodyMedium?.color,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                          onPressed: onEdit,
                          icon: const Icon(Icons.edit_outlined)),
                      IconButton(
                        onPressed: onDelete,
                        icon: const Icon(Icons.delete_outline,
                            color: Color(0xFFE53E3E)),
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
  }
}

class _WeeklySalesChart extends StatelessWidget {
  final List<double> values;

  const _WeeklySalesChart({required this.values});

  @override
  Widget build(BuildContext context) {
    final labels = const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return BarChart(
      BarChartData(
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          drawVerticalLine: false,
          horizontalInterval: 500,
          getDrawingHorizontalLine: (value) => FlLine(
            color: Colors.grey.withOpacity(0.2),
            strokeWidth: 1,
          ),
        ),
        barTouchData: BarTouchData(enabled: true),
        titlesData: FlTitlesData(
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 38,
              getTitlesWidget: (value, meta) => Text(
                value.toInt().toString(),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= labels.length) {
                  return const SizedBox.shrink();
                }
                return Text(labels[index],
                    style: Theme.of(context).textTheme.bodySmall);
              },
            ),
          ),
        ),
        barGroups: values
            .asMap()
            .entries
            .map(
              (entry) => BarChartGroupData(
                x: entry.key,
                barRods: [
                  BarChartRodData(
                    toY: entry.value,
                    color: const Color(0xFFFF6B00),
                    width: 24,
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(6)),
                  ),
                ],
              ),
            )
            .toList(),
      ),
    );
  }
}

class _MenuDistributionChart extends StatelessWidget {
  final Map<String, int> values;

  const _MenuDistributionChart({required this.values});

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) {
      return const _EmptyText('No menu items yet');
    }

    final colors = [
      const Color(0xFF3F7FE2),
      const Color(0xFFFF6B00),
      const Color(0xFF16B57F),
      const Color(0xFFF4A300),
      const Color(0xFF7B4CE0),
      const Color(0xFFE55D8B),
    ];

    final total = values.values.fold<int>(0, (sum, value) => sum + value);

    return Row(
      children: [
        Expanded(
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 44,
              sections: values.entries.toList().asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                final percentage = item.value / total;
                return PieChartSectionData(
                  value: item.value.toDouble(),
                  color: colors[index % colors.length],
                  title: '${(percentage * 100).toStringAsFixed(0)}%',
                  radius: 70,
                  titleStyle: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: values.entries.toList().asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final color = colors[index % colors.length];
              final percentage = (item.value / total) * 100;

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration:
                          BoxDecoration(color: color, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${item.key} ${percentage.toStringAsFixed(0)}%',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _EmptyText extends StatelessWidget {
  final String text;

  const _EmptyText(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(text, style: Theme.of(context).textTheme.bodySmall),
    );
  }
}

Color _statusColor(String status) {
  switch (status) {
    case 'new':
      return const Color(0xFF2563EB);
    case 'accepted':
      return const Color(0xFF16A34A);
    case 'preparing':
      return const Color(0xFFFF8A00);
    case 'ready':
      return const Color(0xFF0EA5E9);
    case 'picked_up':
      return const Color(0xFF10B981);
    case 'rejected':
      return const Color(0xFFDC2626);
    default:
      return Colors.grey;
  }
}

String _statusLabel(String status) {
  switch (status) {
    case 'new':
      return 'New';
    case 'accepted':
      return 'Accepted';
    case 'preparing':
      return 'Preparing';
    case 'ready':
      return 'Ready';
    case 'picked_up':
      return 'Picked Up';
    case 'rejected':
      return 'Rejected';
    default:
      return status;
  }
}
