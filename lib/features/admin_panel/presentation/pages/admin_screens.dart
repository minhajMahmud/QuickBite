import 'package:flutter/material.dart';

/// Admin Dashboard Screen
class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Dashboard')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              title: const Text('Users'),
              subtitle: const Text('Manage platform users'),
              trailing: const Icon(Icons.arrow_forward),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const UserManagementScreen(),
                ),
              ),
            ),
          ),
          Card(
            margin: const EdgeInsets.only(top: 12),
            child: ListTile(
              title: const Text('Restaurants'),
              subtitle: const Text('Manage restaurants'),
              trailing: const Icon(Icons.arrow_forward),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const RestaurantManagementScreen(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// User Management Screen
class UserManagementScreen extends StatelessWidget {
  const UserManagementScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('User Management')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 10,
        itemBuilder: (context, index) => Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(child: Text('U${index + 1}')),
            title: Text('User ${index + 1}'),
            subtitle: const Text('user@example.com'),
            trailing: PopupMenuButton(
              itemBuilder: (context) => [
                const PopupMenuItem(child: Text('Edit')),
                const PopupMenuItem(child: Text('Ban')),
                const PopupMenuItem(child: Text('Delete')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Restaurant Management Screen
class RestaurantManagementScreen extends StatelessWidget {
  const RestaurantManagementScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Restaurant Management')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 8,
        itemBuilder: (context, index) => Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: const Icon(Icons.restaurant),
            title: Text('Restaurant ${index + 1}'),
            subtitle: const Text('Italian • Pizza • 4.7★'),
            trailing: PopupMenuButton(
              itemBuilder: (context) => [
                const PopupMenuItem(child: Text('Edit')),
                const PopupMenuItem(child: Text('View Orders')),
                const PopupMenuItem(child: Text('Delete')),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        heroTag: 'admin-dashboard-fab',
        child: const Icon(Icons.add),
      ),
    );
  }
}
