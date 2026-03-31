import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../authentication/presentation/providers/auth_provider.dart';
import '../../../authentication/data/models/user_role.dart';
import '../../../authentication/data/services/api_client.dart';
import '../../../../config/theme/app_theme.dart';
import '../../../../presentation/providers/app_providers.dart';
import '../../../../presentation/widgets/curved_panel_bottom_nav.dart';
import '../widgets/user_dashboard_sidebar.dart';

/// User Notifications Screen
class UserNotificationsScreen extends ConsumerStatefulWidget {
  const UserNotificationsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<UserNotificationsScreen> createState() =>
      _UserNotificationsScreenState();
}

class _UserNotificationsScreenState
    extends ConsumerState<UserNotificationsScreen> {
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = false;

  Future<void> _loadNotifications() async {
    final token = ref.read(authProvider).token;
    if (token == null || token.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final rows = await ApiClient().getMyNotifications(token: token);
      if (!mounted) return;
      setState(() {
        _notifications = rows;
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

  Future<void> _markAllRead() async {
    final token = ref.read(authProvider).token;
    if (token == null || token.isEmpty) return;

    try {
      await ApiClient().markAllNotificationsRead(token: token);
      await _loadNotifications();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
      );
    }
  }

  String _formatTime(String? iso) {
    if (iso == null || iso.isEmpty) return 'just now';
    final parsed = DateTime.tryParse(iso);
    if (parsed == null) return 'just now';
    final diff = DateTime.now().difference(parsed.toLocal());
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes} min ago';
    if (diff.inDays < 1) return '${diff.inHours} hours ago';
    return '${diff.inDays} days ago';
  }

  IconData _iconForType(String? type) {
    final t = (type ?? '').toLowerCase();
    if (t.contains('offer') || t.contains('promo')) return Icons.local_offer;
    if (t.contains('order') || t.contains('delivery')) {
      return Icons.shopping_bag;
    }
    return Icons.notifications;
  }

  Color _colorForType(String? type) {
    final t = (type ?? '').toLowerCase();
    if (t.contains('offer') || t.contains('promo')) return Colors.orange;
    if (t.contains('order') || t.contains('delivery')) return Colors.blue;
    return Colors.purple;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCompact = MediaQuery.of(context).size.width < 900;
    final preferences = ref.watch(notificationPreferencesProvider);

    final filteredNotifications = preferences.notificationsEnabled
        ? _notifications.where((notif) {
            final title = (notif['title'] ?? '').toString().toLowerCase();
            final type = (notif['type'] ?? '').toString().toLowerCase();
            final isPromotion = title.contains('offer') ||
                type.contains('offer') ||
                type.contains('promo');
            final isOrderUpdate = title.contains('order') ||
                type.contains('order') ||
                type.contains('delivery');

            if (isPromotion && !preferences.promotions) {
              return false;
            }
            if (isOrderUpdate && !preferences.orderUpdates) {
              return false;
            }
            return true;
          }).toList()
        : <Map<String, dynamic>>[];

    return Scaffold(
      drawer: isCompact
          ? const Drawer(
              child: SafeArea(
                child: UserDashboardSidebar(
                  currentRoute: '/dashboard/notifications',
                  compact: true,
                ),
              ),
            )
          : null,
      body: Row(
        children: [
          if (!isCompact)
            const UserDashboardSidebar(
                currentRoute: '/dashboard/notifications'),
          Expanded(
            child: Column(
              children: [
                AppBar(
                  title: const Text('Notifications'),
                  elevation: 0,
                  automaticallyImplyLeading: isCompact,
                  actions: [
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: Icon(
                        preferences.promotions
                            ? Icons.check_circle_outline
                            : Icons.remove_circle_outline,
                        color: preferences.promotions
                            ? Colors.green
                            : AppColors.muted,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.mark_email_read_outlined),
                      onPressed: _markAllRead,
                    ),
                    const SizedBox(width: 8),
                    const CircleAvatar(
                      backgroundColor: Color(0xFFFF6B35),
                      child: Icon(Icons.person, color: Colors.white),
                    ),
                    const SizedBox(width: 16),
                  ],
                ),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : filteredNotifications.isEmpty
                          ? const Center(
                              child: Text(
                                  'No notifications for current settings.'),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: filteredNotifications.length,
                              itemBuilder: (context, index) {
                                final notif = filteredNotifications[index];
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          width: 44,
                                          height: 44,
                                          decoration: BoxDecoration(
                                            color: _colorForType(notif['type'])
                                                .withOpacity(0.1),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Icon(
                                            _iconForType(notif['type']),
                                            color: _colorForType(notif['type']),
                                            size: 22,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                (notif['title'] ??
                                                        'Notification')
                                                    .toString(),
                                                style: theme
                                                    .textTheme.titleSmall
                                                    ?.copyWith(
                                                        fontWeight:
                                                            FontWeight.bold),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                (notif['message'] ?? '')
                                                    .toString(),
                                                style:
                                                    theme.textTheme.bodySmall,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                _formatTime(
                                                  notif['createdAt']
                                                      ?.toString(),
                                                ),
                                                style:
                                                    theme.textTheme.labelSmall,
                                              ),
                                            ],
                                          ),
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
        ],
      ),
      bottomNavigationBar: _userSettingsBottomNav(context,
          currentRoute: '/dashboard/notifications'),
    );
  }
}

/// User Settings Screen
class UserSettingsScreen extends ConsumerStatefulWidget {
  const UserSettingsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<UserSettingsScreen> createState() => _UserSettingsScreenState();
}

class _UserSettingsScreenState extends ConsumerState<UserSettingsScreen> {
  static final Uri _repoUri = Uri.parse(
    'https://github.com/minhajMahmud/QuickBite',
  );

  String _language = 'English';

  Future<void> _openRepository() async {
    final opened = await launchUrl(
      _repoUri,
      mode: LaunchMode.externalApplication,
    );

    if (opened) return;

    await Clipboard.setData(
      const ClipboardData(text: 'https://github.com/minhajMahmud/QuickBite'),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Could not open browser. Repository URL copied.'),
      ),
    );
  }

  Future<void> _showEditProfileDialog() async {
    final authState = ref.read(authProvider);
    final user = authState.user;
    if (user == null) return;

    final nameController = TextEditingController(text: user.name);
    final emailController = TextEditingController(text: user.email);
    final phoneController = TextEditingController(text: user.phone ?? '');
    final photoController = TextEditingController(text: user.avatar);
    DateTime? dob = user.dateOfBirth;
    String? gender = user.gender;

    Future<void> pickDob(StateSetter setDialogState) async {
      final selected = await showDatePicker(
        context: context,
        initialDate: dob ?? DateTime(DateTime.now().year - 18),
        firstDate: DateTime(1900),
        lastDate: DateTime.now(),
      );
      if (selected == null) return;
      setDialogState(() => dob = selected);
    }

    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit Profile'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Full Name'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: 'Email Address'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(labelText: 'Phone Number'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: photoController,
                  decoration:
                      const InputDecoration(labelText: 'Profile Picture URL'),
                ),
                const SizedBox(height: 8),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Date of Birth (Optional)'),
                  subtitle: Text(
                    dob == null
                        ? 'Not set'
                        : '${dob!.day.toString().padLeft(2, '0')}/${dob!.month.toString().padLeft(2, '0')}/${dob!.year}',
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.calendar_today_outlined),
                    onPressed: () => pickDob(setDialogState),
                  ),
                ),
                DropdownButtonFormField<String>(
                  value: gender,
                  decoration:
                      const InputDecoration(labelText: 'Gender (Optional)'),
                  items: const [
                    DropdownMenuItem(value: 'Male', child: Text('Male')),
                    DropdownMenuItem(value: 'Female', child: Text('Female')),
                    DropdownMenuItem(value: 'Other', child: Text('Other')),
                    DropdownMenuItem(
                      value: 'Prefer not to say',
                      child: Text('Prefer not to say'),
                    ),
                  ],
                  onChanged: (value) => setDialogState(() => gender = value),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                await ref.read(authProvider.notifier).updateCustomerProfile(
                      fullName: nameController.text.trim(),
                      email: emailController.text.trim(),
                      phone: phoneController.text.trim(),
                      profilePicture: photoController.text.trim(),
                      dateOfBirth: dob,
                      gender: gender,
                    );

                final latestAuthState = ref.read(authProvider);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      latestAuthState.error ??
                          latestAuthState.successMessage ??
                          'Profile update completed',
                    ),
                  ),
                );
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showChangePasswordDialog() async {
    final currentController = TextEditingController();
    final newController = TextEditingController();
    final confirmController = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Current Password'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: newController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'New Password'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: confirmController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Confirm Password'),
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
              if (newController.text != confirmController.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Passwords do not match.')),
                );
                return;
              }
              if (newController.text.length < 6) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content:
                        Text('New password must be at least 6 characters.'),
                  ),
                );
                return;
              }

              final ok = ref.read(authProvider.notifier).changePassword(
                    currentPassword: currentController.text,
                    newPassword: newController.text,
                  );
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(ok
                      ? 'Password changed successfully.'
                      : (ref.read(authProvider).error ??
                          'Unable to change password.')),
                ),
              );
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCompact = MediaQuery.of(context).size.width < 900;
    final isDarkMode = ref.watch(themeModeProvider) == ThemeMode.dark;
    final notificationPreferences = ref.watch(notificationPreferencesProvider);
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final isCustomer = user?.role == UserRole.customer;

    return Scaffold(
      drawer: isCompact
          ? const Drawer(
              child: SafeArea(
                child: UserDashboardSidebar(
                  currentRoute: '/dashboard/settings',
                  compact: true,
                ),
              ),
            )
          : null,
      body: Row(
        children: [
          if (!isCompact)
            const UserDashboardSidebar(currentRoute: '/dashboard/settings'),
          Expanded(
            child: Column(
              children: [
                AppBar(
                  title: const Text('Account Settings'),
                  elevation: 0,
                  automaticallyImplyLeading: isCompact,
                  actions: [
                    const CircleAvatar(
                      backgroundColor: Color(0xFFFF6B35),
                      child: Icon(Icons.person, color: Colors.white),
                    ),
                    const SizedBox(width: 16),
                  ],
                ),
                Expanded(
                  child: ListView(
                    children: [
                      // Account Section
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'Account',
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      _buildSettingsTile(
                        theme,
                        icon: Icons.person,
                        title: 'Profile',
                        subtitle: user == null
                            ? 'Edit your personal information'
                            : '${user.name} • ${user.email}',
                        onTap: _showEditProfileDialog,
                      ),
                      _buildSettingsTile(
                        theme,
                        icon: Icons.lock,
                        title: 'Change Password',
                        subtitle: 'Password is securely hashed',
                        onTap: _showChangePasswordDialog,
                      ),
                      if (isCustomer)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 4),
                          child: Text(
                            'Customer profile includes full name, email, phone, profile picture, date of birth, and gender.',
                            style: theme.textTheme.bodySmall
                                ?.copyWith(color: AppColors.muted),
                          ),
                        ),
                      const Divider(height: 32),
                      // Notification Section
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'Notifications',
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      SwitchListTile(
                        title: const Text('Enable Notifications'),
                        value: notificationPreferences.notificationsEnabled,
                        onChanged: (bool value) {
                          ref
                              .read(notificationPreferencesProvider.notifier)
                              .setNotificationsEnabled(value);
                        },
                      ),
                      SwitchListTile(
                        title: const Text('Order Updates'),
                        subtitle: const Text('Track your order status'),
                        value: notificationPreferences.orderUpdates,
                        onChanged: (bool value) {
                          ref
                              .read(notificationPreferencesProvider.notifier)
                              .setOrderUpdates(value);
                        },
                      ),
                      SwitchListTile(
                        title: const Text('Promotions & Deals'),
                        subtitle: const Text('Receive special offers'),
                        value: notificationPreferences.promotions,
                        onChanged: (bool value) {
                          ref
                              .read(notificationPreferencesProvider.notifier)
                              .setPromotions(value);
                        },
                      ),
                      const Divider(height: 32),
                      // Preferences Section
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'Preferences',
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      _buildSettingsTile(
                        theme,
                        icon: Icons.language,
                        title: 'Language',
                        subtitle: _language,
                        onTap: () {},
                      ),
                      SwitchListTile(
                        secondary: Icon(
                          isDarkMode
                              ? Icons.dark_mode_outlined
                              : Icons.light_mode_outlined,
                          color: theme.primaryColor,
                        ),
                        title: const Text('Dark Mode'),
                        subtitle: Text(isDarkMode
                            ? 'Using dark gradient theme'
                            : 'Using light theme'),
                        value: isDarkMode,
                        onChanged: (value) {
                          ref.read(themeModeProvider.notifier).setMode(
                              value ? ThemeMode.dark : ThemeMode.light);
                        },
                      ),
                      _buildSettingsTile(
                        theme,
                        icon: Icons.help,
                        title: 'Help & Support',
                        subtitle: 'Get help or report an issue',
                        onTap: () {},
                      ),
                      _buildSettingsTile(
                        theme,
                        icon: Icons.code,
                        title: 'QuickBite GitHub',
                        subtitle: 'minhajMahmud/QuickBite',
                        onTap: _openRepository,
                      ),
                      _buildSettingsTile(
                        theme,
                        icon: Icons.description,
                        title: 'Terms & Privacy',
                        subtitle: 'View our policies',
                        onTap: () {},
                      ),
                      const Divider(height: 32),
                      // Logout
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: () {},
                          child: const Text(
                            'Log Out',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar:
          _userSettingsBottomNav(context, currentRoute: '/dashboard/settings'),
    );
  }

  Widget _buildSettingsTile(
    ThemeData theme, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: theme.primaryColor),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }
}

Widget _userSettingsBottomNav(BuildContext context,
    {required String currentRoute}) {
  return CurvedPanelBottomNav(
    items: [
      CurvedNavItemData(
        icon: Icons.home_outlined,
        selectedIcon: Icons.home,
        label: 'Home',
        isSelected: currentRoute == '/dashboard',
        onTap: () => context.go('/'),
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
