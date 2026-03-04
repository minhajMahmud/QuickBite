import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../authentication/presentation/providers/auth_provider.dart';
import '../../../authentication/data/models/user_role.dart';
import '../../../../config/theme/app_theme.dart';
import '../../../../presentation/providers/app_providers.dart';
import '../../../../presentation/widgets/curved_panel_bottom_nav.dart';
import '../widgets/user_dashboard_sidebar.dart';

/// User Notifications Screen
class UserNotificationsScreen extends ConsumerWidget {
  const UserNotificationsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isCompact = MediaQuery.of(context).size.width < 900;
    final preferences = ref.watch(notificationPreferencesProvider);

    final notifications = [
      {
        'title': 'Order Delivered',
        'message': 'Your order from The Golden Grill has been delivered',
        'time': '2 hours ago',
        'icon': Icons.check_circle,
        'color': Colors.green,
      },
      {
        'title': 'Order Confirmed',
        'message': 'Sakura House confirmed your order',
        'time': '5 hours ago',
        'icon': Icons.shopping_bag,
        'color': Colors.blue,
      },
      {
        'title': 'Special Offer',
        'message': '20% off on your next order at Bella Napoli',
        'time': '1 day ago',
        'icon': Icons.local_offer,
        'color': Colors.orange,
      },
      {
        'title': 'Loyalty Points',
        'message': 'You earned 50 loyalty points!',
        'time': '2 days ago',
        'icon': Icons.card_giftcard,
        'color': Colors.purple,
      },
    ];

    final filteredNotifications = preferences.notificationsEnabled
        ? notifications.where((notif) {
            final title = (notif['title'] as String).toLowerCase();
            final isPromotion = title.contains('offer');
            final isOrderUpdate = title.contains('order');

            if (isPromotion && !preferences.promotions) {
              return false;
            }
            if (isOrderUpdate && !preferences.orderUpdates) {
              return false;
            }
            return true;
          }).toList()
        : <Map<String, Object>>[];

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
                      onPressed: () {},
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
                  child: filteredNotifications.isEmpty
                      ? const Center(
                          child: Text('No notifications for current settings.'),
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: (notif['color'] as Color)
                                            .withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        notif['icon'] as IconData,
                                        color: notif['color'] as Color,
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
                                            notif['title'] as String,
                                            style: theme.textTheme.titleSmall
                                                ?.copyWith(
                                                    fontWeight:
                                                        FontWeight.bold),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            notif['message'] as String,
                                            style: theme.textTheme.bodySmall,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            notif['time'] as String,
                                            style: theme.textTheme.labelSmall,
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
              onPressed: () {
                ref.read(authProvider.notifier).updateCustomerProfile(
                      fullName: nameController.text.trim(),
                      email: emailController.text.trim(),
                      phone: phoneController.text.trim(),
                      profilePicture: photoController.text.trim(),
                      dateOfBirth: dob,
                      gender: gender,
                    );
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Profile updated successfully')),
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
