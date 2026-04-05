import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../presentation/widgets/curved_panel_bottom_nav.dart';
import '../../../authentication/data/services/api_client.dart';
import '../../../authentication/presentation/providers/auth_provider.dart';
import '../widgets/admin_sidebar.dart';

class _AdminPageScaffold extends StatelessWidget {
  final String currentRoute;
  final String title;
  final Widget body;
  final Widget? floatingActionButton;

  const _AdminPageScaffold({
    Key? key,
    required this.currentRoute,
    required this.title,
    required this.body,
    this.floatingActionButton,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 900;

    if (isMobile) {
      return Scaffold(
        appBar: AppBar(
          title: Text(title),
          elevation: 0,
        ),
        drawer: Drawer(
          child: SafeArea(
            child: AdminSidebar(
              currentRoute: currentRoute,
              compact: true,
            ),
          ),
        ),
        body: body,
        floatingActionButton: floatingActionButton,
        bottomNavigationBar: _adminBottomNav(context, currentRoute),
      );
    }

    return Scaffold(
      body: Row(
        children: [
          AdminSidebar(currentRoute: currentRoute),
          Expanded(
            child: Column(
              children: [
                AppBar(
                  automaticallyImplyLeading: false,
                  title: Text(title),
                  elevation: 0,
                ),
                Expanded(child: body),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: _adminBottomNav(context, currentRoute),
    );
  }
}

/// User Management Screen
class UserManagementScreen extends ConsumerStatefulWidget {
  const UserManagementScreen({super.key});

  @override
  ConsumerState<UserManagementScreen> createState() =>
      _UserManagementScreenState();
}

class _UserManagementScreenState extends ConsumerState<UserManagementScreen> {
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _pendingUsers = [];
  bool _isLoading = false;
  String? _updatingUserId;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadUsers());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    final token = ref.read(authProvider).token;
    if (token == null || token.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please log in as admin to manage users.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final api = ApiClient();
      final users = await api.getAdminUsers(token: token);
      final pending = await api.getPendingApprovalUsers(token: token);
      if (!mounted) return;
      setState(() {
        _users = users;
        _pendingUsers = pending;
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

  Future<void> _setApproval({
    required String userId,
    required bool approved,
  }) async {
    final token = ref.read(authProvider).token;
    if (token == null || token.isEmpty) return;

    setState(() => _updatingUserId = userId);
    try {
      final res = await ApiClient().setUserApprovalStatus(
        token: token,
        userId: userId,
        approved: approved,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            (res['message']?.toString().isNotEmpty ?? false)
                ? res['message'].toString()
                : (approved
                    ? 'Account approved successfully'
                    : 'Account rejected successfully'),
          ),
        ),
      );

      await _loadUsers();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _updatingUserId = null);
    }
  }

  String _roleLabel(String? role) {
    switch (role) {
      case 'restaurant':
        return 'Restaurant';
      case 'delivery_partner':
        return 'Delivery Partner';
      case 'admin':
        return 'Admin';
      default:
        return 'Customer';
    }
  }

  Color _roleColor(String? role) {
    switch (role) {
      case 'restaurant':
        return Colors.deepOrange;
      case 'delivery_partner':
        return Colors.indigo;
      case 'admin':
        return Colors.purple;
      default:
        return Colors.teal;
    }
  }

  bool _matchesSearch(Map<String, dynamic> user) {
    if (_searchQuery.trim().isEmpty) return true;
    final q = _searchQuery.trim().toLowerCase();
    final name = user['name']?.toString().toLowerCase() ?? '';
    final email = user['email']?.toString().toLowerCase() ?? '';
    final role = _roleLabel(user['role']?.toString()).toLowerCase();
    return name.contains(q) || email.contains(q) || role.contains(q);
  }

  String _approvalLabel(bool approved) => approved ? 'Approved' : 'Pending';

  Widget _buildSectionTitle(
    BuildContext context, {
    required String title,
    required int count,
    IconData? icon,
  }) {
    final theme = Theme.of(context);
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 20, color: theme.primaryColor),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: Text(
            title,
            style: theme.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: theme.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            '$count',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.primaryColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPendingUserCard(
    BuildContext context,
    Map<String, dynamic> user,
  ) {
    final theme = Theme.of(context);
    final role = user['role']?.toString();
    final color = _roleColor(role);
    final userId = user['id']?.toString() ?? '';
    final isUpdating = _updatingUserId == userId;
    final name = user['name']?.toString() ?? 'Unknown';
    final email = user['email']?.toString() ?? '-';

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 3,
      shadowColor: theme.shadowColor.withValues(alpha: 0.08),
      surfaceTintColor: Colors.transparent,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 3,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withValues(alpha: 0.95),
                  color.withValues(alpha: 0.55),
                ],
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  theme.cardColor,
                  theme.cardColor.withValues(alpha: 0.95),
                ],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: color.withValues(alpha: 0.12),
                        child: Text(
                          name.isNotEmpty ? name[0].toUpperCase() : '?',
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(email, style: theme.textTheme.bodySmall),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(99),
                          border: Border.all(
                            color: color.withValues(alpha: 0.22),
                          ),
                        ),
                        child: Text(
                          _roleLabel(role),
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Divider(
                    color: theme.dividerColor.withValues(alpha: 0.2),
                    height: 1,
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilledButton.icon(
                        onPressed: isUpdating
                            ? null
                            : () => _setApproval(
                                  userId: userId,
                                  approved: true,
                                ),
                        icon: const Icon(Icons.check),
                        label: const Text('Approve'),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: isUpdating
                            ? null
                            : () => _setApproval(
                                  userId: userId,
                                  approved: false,
                                ),
                        icon: const Icon(Icons.close),
                        label: const Text('Reject'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      if (isUpdating)
                        const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
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

  Widget _buildAccountRowCard(BuildContext context, Map<String, dynamic> user) {
    final theme = Theme.of(context);
    final role = user['role']?.toString();
    final roleColor = _roleColor(role);
    final approved = user['approved'] == true;
    final name = user['name']?.toString() ?? 'Unknown';
    final email = user['email']?.toString() ?? '-';

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 2,
      surfaceTintColor: Colors.transparent,
      shadowColor: theme.shadowColor.withValues(alpha: 0.06),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.14)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: roleColor.withValues(alpha: 0.12),
          child: Text(
            name.isNotEmpty ? name[0].toUpperCase() : '?',
            style: TextStyle(color: roleColor, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          name,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text('$email • ${_roleLabel(role)}'),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: approved
                ? Colors.green.withValues(alpha: 0.12)
                : Colors.orange.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: (approved ? Colors.green : Colors.orange)
                  .withValues(alpha: 0.25),
            ),
          ),
          child: Text(
            _approvalLabel(approved),
            style: TextStyle(
              color: approved ? Colors.green : Colors.orange,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filteredUsers = _users.where(_matchesSearch).toList();
    final filteredPending = _pendingUsers.where(_matchesSearch).toList();
    final approvedCount = _users.where((u) => u['approved'] == true).length;
    final pendingCount = _pendingUsers.length;

    return _AdminPageScaffold(
      currentRoute: '/admin/users',
      title: 'User Management',
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadUsers,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: theme.dividerColor.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Account Operations Center',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Review pending signups, monitor user roles, and keep account quality high.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.hintColor,
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: _searchController,
                          onChanged: (value) {
                            setState(() => _searchQuery = value);
                          },
                          decoration: InputDecoration(
                            hintText: 'Search by name, email, or role...',
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: _searchQuery.isEmpty
                                ? null
                                : IconButton(
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() => _searchQuery = '');
                                    },
                                    icon: const Icon(Icons.close),
                                  ),
                            filled: true,
                            fillColor: theme.scaffoldBackgroundColor
                                .withValues(alpha: 0.7),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _AccountSummaryCard(
                        icon: Icons.groups_2_outlined,
                        label: 'Total Users',
                        value: '${_users.length}',
                      ),
                      _AccountSummaryCard(
                        icon: Icons.hourglass_top,
                        label: 'Pending Approval',
                        value: '$pendingCount',
                        valueColor: Colors.orange,
                      ),
                      _AccountSummaryCard(
                        icon: Icons.verified_outlined,
                        label: 'Approved',
                        value: '$approvedCount',
                        valueColor: Colors.green,
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _buildSectionTitle(
                    context,
                    title: 'Pending Signups',
                    count: filteredPending.length,
                    icon: Icons.pending_actions_outlined,
                  ),
                  const SizedBox(height: 10),
                  if (filteredPending.isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Text(
                          _searchQuery.isEmpty
                              ? 'No pending account approvals 🎉'
                              : 'No pending approvals for this search.',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    )
                  else
                    ...filteredPending
                        .map((user) => _buildPendingUserCard(context, user)),
                  const SizedBox(height: 20),
                  _buildSectionTitle(
                    context,
                    title: 'All Accounts',
                    count: filteredUsers.length,
                    icon: Icons.people_alt_outlined,
                  ),
                  const SizedBox(height: 10),
                  if (filteredUsers.isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Text(
                          'No users match your current search.',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    )
                  else
                    ...filteredUsers
                        .map((user) => _buildAccountRowCard(context, user)),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadUsers,
        heroTag: 'admin-users-fab',
        child: const Icon(Icons.refresh),
      ),
    );
  }
}

/// Restaurant Management Screen
class RestaurantManagementScreen extends ConsumerStatefulWidget {
  const RestaurantManagementScreen({super.key});

  @override
  ConsumerState<RestaurantManagementScreen> createState() =>
      _RestaurantManagementScreenState();
}

class _RestaurantManagementScreenState
    extends ConsumerState<RestaurantManagementScreen> {
  List<Map<String, dynamic>> _restaurants = [];
  bool _isLoading = false;
  String? _error;
  String? _updatingRestaurantId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadRestaurants());
  }

  Future<void> _loadRestaurants() async {
    final token = ref.read(authProvider).token;
    if (token == null || token.isEmpty) {
      if (!mounted) return;
      setState(() {
        _error = 'Please log in as admin to manage restaurants.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final restaurants = await ApiClient().getAdminRestaurants(token: token);
      if (!mounted) return;
      setState(() => _restaurants = restaurants);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _setRestaurantApproval({
    required String restaurantId,
    required bool approved,
  }) async {
    final token = ref.read(authProvider).token;
    if (token == null || token.isEmpty) return;

    setState(() => _updatingRestaurantId = restaurantId);
    try {
      final result = await ApiClient().setAdminRestaurantApproval(
        token: token,
        restaurantId: restaurantId,
        approved: approved,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result['message']?.toString() ??
                (approved
                    ? 'Restaurant approved successfully'
                    : 'Restaurant rejected successfully'),
          ),
        ),
      );

      await _loadRestaurants();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _updatingRestaurantId = null);
    }
  }

  Future<void> _setRestaurantRestriction({
    required String restaurantId,
    required bool restricted,
  }) async {
    final token = ref.read(authProvider).token;
    if (token == null || token.isEmpty) return;

    setState(() => _updatingRestaurantId = restaurantId);
    try {
      final result = await ApiClient().setAdminRestaurantRestriction(
        token: token,
        restaurantId: restaurantId,
        restricted: restricted,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result['message']?.toString() ??
                (restricted
                    ? 'Restaurant has been restricted'
                    : 'Restaurant restriction removed'),
          ),
        ),
      );

      await _loadRestaurants();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _updatingRestaurantId = null);
    }
  }

  List<Map<String, dynamic>> get _requestRestaurants => _restaurants
      .where((restaurant) => _stateOf(restaurant) == 'request')
      .toList();

  List<Map<String, dynamic>> get _activeRestaurants => _restaurants
      .where((restaurant) => _stateOf(restaurant) == 'active')
      .toList();

  List<Map<String, dynamic>> get _restrictedRestaurants => _restaurants
      .where((restaurant) => _stateOf(restaurant) == 'restricted')
      .toList();

  List<Map<String, dynamic>> get _closedRestaurants => _restaurants
      .where((restaurant) => _stateOf(restaurant) == 'inactive')
      .toList();

  String _stateOf(Map<String, dynamic> restaurant) {
    final state = restaurant['admin_state']?.toString().toLowerCase();
    if (state != null && state.isNotEmpty) return state;

    final ownerStatus = restaurant['owner_status']?.toString().toLowerCase();
    final isApproved = restaurant['is_approved'] == true;
    final status = restaurant['status']?.toString().toLowerCase();

    if (ownerStatus == 'banned') return 'restricted';
    if (!isApproved) return 'request';
    if (status == 'open') return 'active';
    return 'inactive';
  }

  String _stateLabel(String state) {
    switch (state) {
      case 'request':
        return 'Request';
      case 'restricted':
        return 'Restricted';
      case 'inactive':
        return 'Closed';
      default:
        return 'Active';
    }
  }

  Color _stateColor(String state) {
    switch (state) {
      case 'request':
        return Colors.orange;
      case 'restricted':
        return Colors.redAccent;
      case 'inactive':
        return Colors.grey;
      default:
        return Colors.green;
    }
  }

  String _fmtRating(dynamic value) {
    final rating =
        (value is num) ? value.toDouble() : double.tryParse('$value');
    if (rating == null) return '-';
    return rating.toStringAsFixed(1);
  }

  String _fmtMoney(dynamic value) {
    final amount =
        (value is num) ? value.toDouble() : double.tryParse('$value') ?? 0;
    return amount.toStringAsFixed(2);
  }

  String _fmtDate(dynamic value) {
    final parsed = value == null ? null : DateTime.tryParse(value.toString());
    if (parsed == null) return '-';
    final day = parsed.day.toString().padLeft(2, '0');
    final month = parsed.month.toString().padLeft(2, '0');
    final year = parsed.year.toString();
    return '$day/$month/$year';
  }

  Widget _buildSectionTitle(
    BuildContext context, {
    required String title,
    required int count,
    IconData? icon,
  }) {
    final theme = Theme.of(context);
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 20, color: theme.primaryColor),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: Text(
            title,
            style: theme.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: theme.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            '$count',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.primaryColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  String _fullAddress(Map<String, dynamic> restaurant) {
    final parts = [
      restaurant['street_address']?.toString(),
      restaurant['city']?.toString(),
      restaurant['state']?.toString(),
      restaurant['postal_code']?.toString(),
    ]
        .whereType<String>()
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();

    return parts.isEmpty ? 'Not provided' : parts.join(', ');
  }

  Widget _buildStatCard({
    required ThemeData theme,
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      shadowColor: theme.shadowColor.withValues(alpha: 0.06),
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.14)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    color.withValues(alpha: 0.95),
                    color.withValues(alpha: 0.65)
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    label,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.hintColor,
                      fontWeight: FontWeight.w500,
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

  Widget _buildStateChip(BuildContext context, String state) {
    final color = _stateColor(state);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        _stateLabel(state),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildMetricPill(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  Future<void> _showRestaurantDetails(Map<String, dynamic> restaurant) async {
    final state = _stateOf(restaurant);
    final color = _stateColor(state);
    final restaurantId = restaurant['id']?.toString() ?? '';

    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final theme = Theme.of(context);
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.82,
          minChildSize: 0.6,
          maxChildSize: 0.95,
          builder: (_, controller) {
            return SingleChildScrollView(
              controller: controller,
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          color.withValues(alpha: 0.95),
                          color.withValues(alpha: 0.65),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: Colors.white.withValues(alpha: 0.16),
                          child: Text(
                            (restaurant['name']?.toString().isNotEmpty ?? false)
                                ? restaurant['name'].toString()[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                restaurant['name']?.toString() ?? 'Restaurant',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '${restaurant['cuisine']?.toString() ?? 'Food'} • ${restaurant['price_range']?.toString() ?? '\$\$'}',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.95),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  _buildStateChip(context, state),
                                  _buildMetricPill(
                                      'Rating',
                                      _fmtRating(restaurant['rating']),
                                      Colors.white),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Restaurant details',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildInfoCard(
                      context,
                      'Owner',
                      restaurant['owner_name']?.toString().isNotEmpty == true
                          ? restaurant['owner_name'].toString()
                          : 'Unknown',
                      restaurant['owner_email']?.toString().isNotEmpty == true
                          ? restaurant['owner_email'].toString()
                          : '-'),
                  const SizedBox(height: 12),
                  _buildInfoCard(
                    context,
                    'Contact',
                    restaurant['phone']?.toString().isNotEmpty == true
                        ? restaurant['phone'].toString()
                        : 'No phone',
                    restaurant['email']?.toString().isNotEmpty == true
                        ? restaurant['email'].toString()
                        : 'No email',
                  ),
                  const SizedBox(height: 12),
                  _buildInfoCard(
                    context,
                    'Location',
                    _fullAddress(restaurant),
                    'Created: ${_fmtDate(restaurant['created_at'])}',
                  ),
                  const SizedBox(height: 12),
                  _buildInfoCard(
                    context,
                    'Performance',
                    'Orders: ${restaurant['total_orders']?.toString() ?? '0'}',
                    'Revenue: \$${_fmtMoney(restaurant['total_revenue'])}',
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: state == 'restricted'
                          ? Colors.red.withValues(alpha: 0.08)
                          : Colors.orange.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: (state == 'restricted'
                                ? Colors.redAccent
                                : Colors.orange)
                            .withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          state == 'restricted'
                              ? Icons.lock
                              : Icons.info_outline,
                          color: state == 'restricted'
                              ? Colors.redAccent
                              : Colors.orange,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            state == 'restricted'
                                ? 'This restaurant is restricted. The owner account is banned, so dashboard, menu, and order access are blocked.'
                                : state == 'request'
                                    ? 'This is a pending restaurant request. Review details before approval.'
                                    : 'This restaurant is active and allowed to manage menu and orders.',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  if (restaurantId.isNotEmpty)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (state == 'request') ...[
                          FilledButton.icon(
                            onPressed: () {
                              Navigator.of(context).pop();
                              _setRestaurantApproval(
                                restaurantId: restaurantId,
                                approved: true,
                              );
                            },
                            icon: const Icon(Icons.check),
                            label: const Text('Approve'),
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed: () {
                              Navigator.of(context).pop();
                              _setRestaurantApproval(
                                restaurantId: restaurantId,
                                approved: false,
                              );
                            },
                            icon: const Icon(Icons.close),
                            label: const Text('Reject'),
                          ),
                        ],
                        if (state == 'restricted')
                          FilledButton.icon(
                            onPressed: () {
                              Navigator.of(context).pop();
                              _setRestaurantRestriction(
                                restaurantId: restaurantId,
                                restricted: false,
                              );
                            },
                            icon: const Icon(Icons.lock_open),
                            label: const Text('Unban / Restore Access'),
                          )
                        else
                          OutlinedButton.icon(
                            onPressed: () {
                              Navigator.of(context).pop();
                              _setRestaurantRestriction(
                                restaurantId: restaurantId,
                                restricted: true,
                              );
                            },
                            icon: const Icon(Icons.block),
                            label: const Text('Ban / Restrict'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.redAccent,
                            ),
                          ),
                      ],
                    ),
                  if (_updatingRestaurantId == restaurantId)
                    const Padding(
                      padding: EdgeInsets.only(top: 12),
                      child: LinearProgressIndicator(minHeight: 3),
                    ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                      label: const Text('Close'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildInfoCard(
    BuildContext context,
    String title,
    String primary,
    String secondary,
  ) {
    final theme = Theme.of(context);
    return Card(
      elevation: 1,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.14)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(primary, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 4),
            Text(
              secondary,
              style:
                  theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRestaurantCard(
      BuildContext context, Map<String, dynamic> restaurant) {
    final theme = Theme.of(context);
    final state = _stateOf(restaurant);
    final color = _stateColor(state);
    final name = restaurant['name']?.toString() ?? 'Restaurant';
    final cuisine = restaurant['cuisine']?.toString() ?? 'Food';
    final rating = _fmtRating(restaurant['rating']);
    final deliveryTime = restaurant['delivery_time']?.toString() ?? 'N/A';
    final orders = restaurant['total_orders']?.toString() ?? '0';
    final revenue = _fmtMoney(restaurant['total_revenue']);
    final ownerName = restaurant['owner_name']?.toString().isNotEmpty == true
        ? restaurant['owner_name'].toString()
        : 'No owner linked';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 3,
      shadowColor: theme.shadowColor.withValues(alpha: 0.08),
      surfaceTintColor: Colors.transparent,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 4,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withValues(alpha: 0.95),
                  color.withValues(alpha: 0.55)
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: color.withValues(alpha: 0.12),
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : '?',
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text('$cuisine • $deliveryTime • ★ $rating'),
                        ],
                      ),
                    ),
                    _buildStateChip(context, state),
                  ],
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildMetricPill('Orders', orders, Colors.orange),
                    _buildMetricPill('Revenue', '\$$revenue', Colors.green),
                    _buildMetricPill('Owner', ownerName, Colors.blue),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  restaurant['description']?.toString().isNotEmpty == true
                      ? restaurant['description'].toString()
                      : 'No description available.',
                  style: theme.textTheme.bodyMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => _showRestaurantDetails(restaurant),
                      icon: const Icon(Icons.visibility_outlined),
                      label: const Text('View details'),
                    ),
                    const SizedBox(width: 8),
                    if (state == 'restricted')
                      TextButton.icon(
                        onPressed: () => _showRestaurantDetails(restaurant),
                        icon: const Icon(Icons.lock_outline),
                        label: const Text('Restricted'),
                      )
                    else if (state == 'request')
                      TextButton.icon(
                        onPressed: () => _showRestaurantDetails(restaurant),
                        icon: const Icon(Icons.pending_actions_outlined),
                        label: const Text('Review request'),
                      )
                    else
                      TextButton.icon(
                        onPressed: () => _showRestaurantDetails(restaurant),
                        icon: const Icon(Icons.info_outline),
                        label: const Text('Profile'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final requestRestaurants = _requestRestaurants;
    final restrictedRestaurants = _restrictedRestaurants;
    final activeRestaurants = _activeRestaurants;
    final closedRestaurants = _closedRestaurants;

    return _AdminPageScaffold(
      currentRoute: '/admin/restaurants',
      title: 'Restaurant Management',
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Failed to load restaurants',
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: _loadRestaurants,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadRestaurants,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _buildStatCard(
                            theme: theme,
                            icon: Icons.storefront_outlined,
                            label: 'Total Restaurants',
                            value: '${_restaurants.length}',
                            color: Colors.orange,
                          ),
                          _buildStatCard(
                            theme: theme,
                            icon: Icons.pending_actions_outlined,
                            label: 'Requests',
                            value: '${requestRestaurants.length}',
                            color: Colors.orange,
                          ),
                          _buildStatCard(
                            theme: theme,
                            icon: Icons.verified_outlined,
                            label: 'Active',
                            value: '${activeRestaurants.length}',
                            color: Colors.green,
                          ),
                          _buildStatCard(
                            theme: theme,
                            icon: Icons.lock_outline,
                            label: 'Restricted',
                            value: '${restrictedRestaurants.length}',
                            color: Colors.redAccent,
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: theme.dividerColor.withValues(alpha: 0.14),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.verified_user_outlined,
                                color: Colors.orange),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Restaurant requests are shown separately, and restaurants linked to banned owner accounts are marked as restricted. Restricted restaurants cannot access dashboard orders, menu editing, or analytics.',
                                style: theme.textTheme.bodyMedium,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      if (requestRestaurants.isNotEmpty) ...[
                        _buildSectionTitle(
                          context,
                          title: 'Request Restaurants',
                          count: requestRestaurants.length,
                          icon: Icons.pending_actions_outlined,
                        ),
                        const SizedBox(height: 10),
                        ...requestRestaurants.map((restaurant) =>
                            _buildRestaurantCard(context, restaurant)),
                        const SizedBox(height: 18),
                      ],
                      if (restrictedRestaurants.isNotEmpty) ...[
                        _buildSectionTitle(
                          context,
                          title: 'Restricted / Banned Owners',
                          count: restrictedRestaurants.length,
                          icon: Icons.lock_outline,
                        ),
                        const SizedBox(height: 10),
                        ...restrictedRestaurants.map((restaurant) =>
                            _buildRestaurantCard(context, restaurant)),
                        const SizedBox(height: 18),
                      ],
                      _buildSectionTitle(
                        context,
                        title: 'Approved Restaurants',
                        count: activeRestaurants.length,
                        icon: Icons.verified_outlined,
                      ),
                      const SizedBox(height: 10),
                      if (activeRestaurants.isEmpty)
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(18),
                            child: Text(
                              'No approved restaurants found.',
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                        )
                      else
                        ...activeRestaurants.map((restaurant) =>
                            _buildRestaurantCard(context, restaurant)),
                      if (closedRestaurants.isNotEmpty) ...[
                        const SizedBox(height: 18),
                        _buildSectionTitle(
                          context,
                          title: 'Closed Restaurants',
                          count: closedRestaurants.length,
                          icon: Icons.do_not_disturb_alt_outlined,
                        ),
                        const SizedBox(height: 10),
                        ...closedRestaurants.map((restaurant) =>
                            _buildRestaurantCard(context, restaurant)),
                      ],
                    ],
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadRestaurants,
        heroTag: 'admin-restaurants-fab',
        child: const Icon(Icons.refresh),
      ),
    );
  }
}

/// Delivery Management Screen
class DeliveryManagementScreen extends ConsumerStatefulWidget {
  const DeliveryManagementScreen({super.key});

  @override
  ConsumerState<DeliveryManagementScreen> createState() =>
      _DeliveryManagementScreenState();
}

class _DeliveryManagementScreenState
    extends ConsumerState<DeliveryManagementScreen> {
  List<Map<String, dynamic>> _deliveryAccounts = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _loadDeliveryAccounts());
  }

  Future<void> _loadDeliveryAccounts() async {
    final token = ref.read(authProvider).token;
    if (token == null || token.isEmpty) {
      setState(() {
        _error = 'Please log in as admin to manage deliveries.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final api = ApiClient();
      final users = await api.getAdminUsers(token: token);

      final deliveryAccounts = users.where((u) {
        final role = u['role']?.toString();
        return role == 'delivery_partner';
      }).toList();

      if (!mounted) return;
      setState(() {
        _deliveryAccounts = deliveryAccounts;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _statusOf(Map<String, dynamic> account) {
    final status = account['status']?.toString().toLowerCase() ?? 'active';
    final approved = account['approved'] == true;

    if (status == 'banned' || status == 'suspended') return 'suspended';
    if (!approved) return 'pending';
    return 'active';
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'suspended':
        return 'Suspended';
      case 'pending':
        return 'Pending Approval';
      default:
        return 'Active';
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'suspended':
        return Colors.redAccent;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.green;
    }
  }

  Widget _buildSectionTitle(
    BuildContext context, {
    required String title,
    required int count,
    IconData? icon,
  }) {
    final theme = Theme.of(context);
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 20, color: theme.primaryColor),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: Text(
            title,
            style: theme.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: theme.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            '$count',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.primaryColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDeliveryCard(
      BuildContext context, Map<String, dynamic> account) {
    final theme = Theme.of(context);
    final name = account['name']?.toString() ?? 'Unknown';
    final email = account['email']?.toString() ?? '-';
    final status = _statusOf(account);
    final color = _statusColor(status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      surfaceTintColor: Colors.transparent,
      shadowColor: theme.shadowColor.withValues(alpha: 0.06),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.dividerColor.withValues(alpha: 0.14),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 3,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withValues(alpha: 0.95),
                  color.withValues(alpha: 0.55),
                ],
              ),
            ),
          ),
          ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            leading: CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.12),
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: TextStyle(color: color, fontWeight: FontWeight.w700),
              ),
            ),
            title: Text(
              name,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('$email • ${_statusLabel(status)}'),
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: color.withValues(alpha: 0.25)),
              ),
              child: Text(
                _statusLabel(status),
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalAccounts = _deliveryAccounts.length;
    final activeList =
        _deliveryAccounts.where((a) => _statusOf(a) == 'active').toList();
    final pendingList =
        _deliveryAccounts.where((a) => _statusOf(a) == 'pending').toList();
    final suspendedList =
        _deliveryAccounts.where((a) => _statusOf(a) == 'suspended').toList();

    return _AdminPageScaffold(
      currentRoute: '/admin/deliveries',
      title: 'Delivery Partner Accounts',
      floatingActionButton: FloatingActionButton(
        onPressed: _loadDeliveryAccounts,
        heroTag: 'admin-delivery-accounts-fab',
        child: const Icon(Icons.refresh),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Failed to load delivery accounts',
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: _loadDeliveryAccounts,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadDeliveryAccounts,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _AccountSummaryCard(
                            icon: Icons.people_outline,
                            label: 'Total Accounts',
                            value: '$totalAccounts',
                          ),
                          _AccountSummaryCard(
                            icon: Icons.check_circle_outline,
                            label: 'Active',
                            value: '${activeList.length}',
                            valueColor: Colors.green,
                          ),
                          _AccountSummaryCard(
                            icon: Icons.pending_actions_outlined,
                            label: 'Pending',
                            value: '${pendingList.length}',
                            valueColor: Colors.orange,
                          ),
                          _AccountSummaryCard(
                            icon: Icons.block_outlined,
                            label: 'Suspended',
                            value: '${suspendedList.length}',
                            valueColor: Colors.redAccent,
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: theme.dividerColor.withValues(alpha: 0.14),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.local_shipping_outlined,
                                color: Colors.orange),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Delivery account operations center: monitor active riders, review pending approvals, and quickly identify suspended accounts.',
                                style: theme.textTheme.bodyMedium,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      if (_deliveryAccounts.isEmpty)
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              'No delivery partner accounts found.',
                              style: theme.textTheme.bodyLarge
                                  ?.copyWith(color: Colors.grey),
                            ),
                          ),
                        )
                      else ...[
                        if (pendingList.isNotEmpty) ...[
                          _buildSectionTitle(
                            context,
                            title: 'Pending Approval',
                            count: pendingList.length,
                            icon: Icons.pending_actions_outlined,
                          ),
                          const SizedBox(height: 10),
                          ...pendingList.map((account) =>
                              _buildDeliveryCard(context, account)),
                          const SizedBox(height: 16),
                        ],
                        if (activeList.isNotEmpty) ...[
                          _buildSectionTitle(
                            context,
                            title: 'Active Partners',
                            count: activeList.length,
                            icon: Icons.check_circle_outline,
                          ),
                          const SizedBox(height: 10),
                          ...activeList.map((account) =>
                              _buildDeliveryCard(context, account)),
                          const SizedBox(height: 16),
                        ],
                        if (suspendedList.isNotEmpty) ...[
                          _buildSectionTitle(
                            context,
                            title: 'Suspended Partners',
                            count: suspendedList.length,
                            icon: Icons.block_outlined,
                          ),
                          const SizedBox(height: 10),
                          ...suspendedList.map((account) =>
                              _buildDeliveryCard(context, account)),
                        ],
                      ],
                    ],
                  ),
                ),
    );
  }
}

class _AccountSummaryCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _AccountSummaryCard({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 250,
      child: Card(
        elevation: 2,
        shadowColor: theme.shadowColor.withValues(alpha: 0.06),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: theme.dividerColor.withValues(alpha: 0.14),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFFFB347), Color(0xFFFF8A00)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: valueColor,
                      ),
                    ),
                    Text(
                      label,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.hintColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _adminBottomNav(BuildContext context, String currentRoute) {
  return CurvedPanelBottomNav(
    items: [
      CurvedNavItemData(
        icon: Icons.dashboard_outlined,
        selectedIcon: Icons.dashboard,
        label: 'Dashboard',
        isSelected: currentRoute == '/admin',
        onTap: () => context.go('/admin'),
      ),
      CurvedNavItemData(
        icon: Icons.people_outline,
        selectedIcon: Icons.people,
        label: 'Users',
        isSelected: currentRoute == '/admin/users',
        onTap: () => context.go('/admin/users'),
      ),
      CurvedNavItemData(
        icon: Icons.local_shipping_outlined,
        selectedIcon: Icons.local_shipping,
        label: 'Delivery',
        isSelected: currentRoute == '/admin/deliveries',
        onTap: () => context.go('/admin/deliveries'),
      ),
      CurvedNavItemData(
        icon: Icons.settings_outlined,
        selectedIcon: Icons.settings,
        label: 'Settings',
        isSelected: currentRoute == '/admin/settings' ||
            currentRoute == '/admin/coupons' ||
            currentRoute == '/admin/restaurants',
        onTap: () => context.go('/admin/settings'),
      ),
    ],
  );
}

/// Coupon Management Screen
class CouponManagementScreen extends ConsumerStatefulWidget {
  const CouponManagementScreen({super.key});

  @override
  ConsumerState<CouponManagementScreen> createState() =>
      _CouponManagementScreenState();
}

class _CouponManagementScreenState
    extends ConsumerState<CouponManagementScreen> {
  List<Map<String, dynamic>> _coupons = [];
  bool _isLoading = false;
  String? _error;
  String? _updatingCouponId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadOffers());
  }

  Future<void> _loadOffers() async {
    final token = ref.read(authProvider).token;
    if (token == null || token.isEmpty) {
      setState(() {
        _error = 'Please log in as admin to manage coupons.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final offers = await ApiClient().getAdminCoupons(token: token);
      if (!mounted) return;
      setState(() => _coupons = offers);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _setCouponStatus({
    required String couponId,
    required bool isActive,
  }) async {
    final token = ref.read(authProvider).token;
    if (token == null || token.isEmpty) return;

    setState(() => _updatingCouponId = couponId);
    try {
      final result = await ApiClient().setAdminCouponStatus(
        token: token,
        couponId: couponId,
        isActive: isActive,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result['message']?.toString() ??
                (isActive
                    ? 'Coupon reopened successfully'
                    : 'Coupon manually closed successfully'),
          ),
        ),
      );

      await _loadOffers();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _updatingCouponId = null);
    }
  }

  String _stateOf(Map<String, dynamic> coupon) {
    final state = coupon['adminState']?.toString();
    if (state != null && state.isNotEmpty) return state;
    final validity = coupon['validity'] is Map
        ? Map<String, dynamic>.from(coupon['validity'] as Map)
        : <String, dynamic>{};
    return validity['isActive'] == true ? 'active' : 'manual_closed';
  }

  String _stateLabel(String state) {
    switch (state) {
      case 'auto_closed_timer':
        return 'Auto Closed (Timer)';
      case 'auto_closed_usage':
        return 'Auto Closed (Usage)';
      case 'manual_closed':
        return 'Manually Closed';
      case 'scheduled':
        return 'Scheduled';
      default:
        return 'Active';
    }
  }

  Color _stateColor(String state) {
    switch (state) {
      case 'auto_closed_timer':
      case 'auto_closed_usage':
        return Colors.blueGrey;
      case 'manual_closed':
        return Colors.redAccent;
      case 'scheduled':
        return Colors.orange;
      default:
        return Colors.green;
    }
  }

  String _fmtDate(dynamic value) {
    final parsed = value == null ? null : DateTime.tryParse(value.toString());
    if (parsed == null) return '-';
    final day = parsed.day.toString().padLeft(2, '0');
    final month = parsed.month.toString().padLeft(2, '0');
    final year = parsed.year.toString();
    return '$day/$month/$year';
  }

  String _countdownText(dynamic untilValue) {
    if (untilValue == null) return 'No expiry';
    final until = DateTime.tryParse(untilValue.toString());
    if (until == null) return 'No expiry';
    final now = DateTime.now();
    final diff = until.difference(now);
    if (diff.isNegative) return 'Expired';

    final days = diff.inDays;
    if (days > 0) return '$days day${days == 1 ? '' : 's'} left';

    final hours = diff.inHours;
    if (hours > 0) return '$hours hour${hours == 1 ? '' : 's'} left';

    final mins = diff.inMinutes;
    return '$mins min${mins == 1 ? '' : 's'} left';
  }

  Widget _buildSectionTitle(
    BuildContext context, {
    required String title,
    required int count,
    IconData? icon,
  }) {
    final theme = Theme.of(context);
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 20, color: theme.primaryColor),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: Text(
            title,
            style: theme.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: theme.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            '$count',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.primaryColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCouponCard(BuildContext context, Map<String, dynamic> coupon) {
    final theme = Theme.of(context);
    final state = _stateOf(coupon);
    final color = _stateColor(state);
    final code = coupon['code']?.toString() ?? '-';
    final discount = coupon['discountDisplay']?.toString() ??
        coupon['discountType']?.toString() ??
        '-';
    final usage = coupon['usage'] is Map<String, dynamic>
        ? coupon['usage'] as Map<String, dynamic>
        : <String, dynamic>{};
    final used = usage['current']?.toString() ?? '0';
    final total = usage['total']?.toString() ?? 'Unlimited';
    final validity = coupon['validity'] is Map<String, dynamic>
        ? coupon['validity'] as Map<String, dynamic>
        : <String, dynamic>{};
    final closeReason = coupon['closeReason']?.toString() ?? _stateLabel(state);
    final couponId = coupon['id']?.toString() ?? '';
    final isUpdating = _updatingCouponId == couponId;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      surfaceTintColor: Colors.transparent,
      shadowColor: theme.shadowColor.withValues(alpha: 0.06),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.dividerColor.withValues(alpha: 0.14),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 3,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withValues(alpha: 0.95),
                  color.withValues(alpha: 0.55),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        code,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                        border:
                            Border.all(color: color.withValues(alpha: 0.25)),
                      ),
                      child: Text(
                        _stateLabel(state),
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Discount: $discount', style: theme.textTheme.bodyMedium),
                const SizedBox(height: 4),
                Text(
                  'Usage: $used / $total',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.hintColor),
                ),
                const SizedBox(height: 4),
                Text(
                  'Validity: ${_fmtDate(validity['from'])} → ${_fmtDate(validity['until'])}',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.hintColor),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        closeReason,
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    if (state == 'active')
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          _countdownText(validity['until']),
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                if (couponId.isNotEmpty)
                  Row(
                    children: [
                      if (state == 'active' || state == 'scheduled')
                        OutlinedButton.icon(
                          onPressed: isUpdating
                              ? null
                              : () => _setCouponStatus(
                                    couponId: couponId,
                                    isActive: false,
                                  ),
                          icon: const Icon(Icons.pause_circle_outline),
                          label: const Text('Close Manually'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.redAccent,
                          ),
                        )
                      else if (state == 'manual_closed')
                        FilledButton.icon(
                          onPressed: isUpdating
                              ? null
                              : () => _setCouponStatus(
                                    couponId: couponId,
                                    isActive: true,
                                  ),
                          icon: const Icon(Icons.play_arrow_rounded),
                          label: const Text('Reopen Coupon'),
                        )
                      else
                        Text(
                          'Auto-closed coupon cannot be reopened directly.',
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: theme.hintColor),
                        ),
                      if (isUpdating) ...[
                        const SizedBox(width: 12),
                        const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ],
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeCoupons =
        _coupons.where((c) => _stateOf(c) == 'active').toList();
    final scheduledCoupons =
        _coupons.where((c) => _stateOf(c) == 'scheduled').toList();
    final autoClosedCoupons = _coupons
        .where((c) =>
            _stateOf(c) == 'auto_closed_timer' ||
            _stateOf(c) == 'auto_closed_usage')
        .toList();
    final manualClosedCoupons =
        _coupons.where((c) => _stateOf(c) == 'manual_closed').toList();

    return _AdminPageScaffold(
      currentRoute: '/admin/coupons',
      title: 'Coupon Management',
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Failed to load coupons',
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: _loadOffers,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadOffers,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _AccountSummaryCard(
                            icon: Icons.confirmation_num_outlined,
                            label: 'Total Coupons',
                            value: '${_coupons.length}',
                          ),
                          _AccountSummaryCard(
                            icon: Icons.check_circle_outline,
                            label: 'Active',
                            value: '${activeCoupons.length}',
                            valueColor: Colors.green,
                          ),
                          _AccountSummaryCard(
                            icon: Icons.schedule,
                            label: 'Auto Closed',
                            value: '${autoClosedCoupons.length}',
                            valueColor: Colors.blueGrey,
                          ),
                          _AccountSummaryCard(
                            icon: Icons.cancel_outlined,
                            label: 'Manually Closed',
                            value: '${manualClosedCoupons.length}',
                            valueColor: Colors.redAccent,
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: theme.dividerColor.withValues(alpha: 0.14),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.auto_awesome_outlined,
                                color: Colors.orange),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Coupon command center: distinguish active campaigns, auto-closed coupons (timer/usage), and manually closed coupons at a glance.',
                                style: theme.textTheme.bodyMedium,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      if (_coupons.isEmpty)
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              'No coupons found.',
                              style: theme.textTheme.bodyLarge
                                  ?.copyWith(color: Colors.grey),
                            ),
                          ),
                        )
                      else ...[
                        if (activeCoupons.isNotEmpty) ...[
                          _buildSectionTitle(
                            context,
                            title: 'Active Coupons',
                            count: activeCoupons.length,
                            icon: Icons.check_circle_outline,
                          ),
                          const SizedBox(height: 10),
                          ...activeCoupons.map(
                              (coupon) => _buildCouponCard(context, coupon)),
                          const SizedBox(height: 16),
                        ],
                        if (scheduledCoupons.isNotEmpty) ...[
                          _buildSectionTitle(
                            context,
                            title: 'Scheduled Coupons',
                            count: scheduledCoupons.length,
                            icon: Icons.schedule,
                          ),
                          const SizedBox(height: 10),
                          ...scheduledCoupons.map(
                              (coupon) => _buildCouponCard(context, coupon)),
                          const SizedBox(height: 16),
                        ],
                        if (autoClosedCoupons.isNotEmpty) ...[
                          _buildSectionTitle(
                            context,
                            title: 'Auto Closed Coupons',
                            count: autoClosedCoupons.length,
                            icon: Icons.timer_off_outlined,
                          ),
                          const SizedBox(height: 10),
                          ...autoClosedCoupons.map(
                              (coupon) => _buildCouponCard(context, coupon)),
                          const SizedBox(height: 16),
                        ],
                        if (manualClosedCoupons.isNotEmpty) ...[
                          _buildSectionTitle(
                            context,
                            title: 'Manually Closed Coupons',
                            count: manualClosedCoupons.length,
                            icon: Icons.gpp_bad_outlined,
                          ),
                          const SizedBox(height: 10),
                          ...manualClosedCoupons.map(
                              (coupon) => _buildCouponCard(context, coupon)),
                        ],
                      ],
                    ],
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadOffers,
        heroTag: 'admin-coupons-fab',
        child: const Icon(Icons.refresh),
      ),
    );
  }
}

/// Admin Settings Screen
class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  bool _maintenanceMode = false;
  bool _allowNewUsers = true;
  bool _allowNewRestaurants = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return _AdminPageScaffold(
      currentRoute: '/admin/settings',
      title: 'Admin Settings',
      body: ListView(
        children: [
          // System Settings
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'System Settings',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          SwitchListTile(
            title: const Text('Maintenance Mode'),
            subtitle: const Text('Disable app for all users'),
            value: _maintenanceMode,
            onChanged: (bool value) {
              setState(() => _maintenanceMode = value);
            },
          ),
          const Divider(height: 32),
          // Platform Settings
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Platform Settings',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          SwitchListTile(
            title: const Text('Allow New User Registration'),
            value: _allowNewUsers,
            onChanged: (bool value) {
              setState(() => _allowNewUsers = value);
            },
          ),
          SwitchListTile(
            title: const Text('Allow New Restaurant Registration'),
            value: _allowNewRestaurants,
            onChanged: (bool value) {
              setState(() => _allowNewRestaurants = value);
            },
          ),
          const Divider(height: 32),
          // System Info
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'System Information',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          ListTile(
            title: const Text('App Version'),
            subtitle: const Text('1.0.0'),
          ),
          ListTile(
            title: const Text('Database'),
            subtitle: const Text('Connected'),
          ),
          ListTile(
            title: const Text('Last Backup'),
            subtitle: const Text('2 hours ago'),
          ),
        ],
      ),
    );
  }
}
