import 'package:flutter/material.dart';

/// Order History Screen
class OrderHistoryScreen extends StatelessWidget {
  const OrderHistoryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Order History')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 5,
        itemBuilder: (context, index) => Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            title: Text('Order #${1001 + index}'),
            subtitle: const Text('The Golden Grill'),
            trailing: const Text('\$34.99'),
            onTap: () {},
          ),
        ),
      ),
    );
  }
}

/// User Favorites Screen
class UserFavoritesScreen extends StatelessWidget {
  const UserFavoritesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Favorites')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 5,
        itemBuilder: (context, index) => Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: const Icon(Icons.restaurant),
            title: Text('Restaurant ${index + 1}'),
            subtitle: const Text('Italian • Pizza'),
            trailing: const Icon(Icons.favorite, color: Colors.red),
          ),
        ),
      ),
    );
  }
}

/// User Addresses Screen
class UserAddressesScreen extends StatelessWidget {
  const UserAddressesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Saved Addresses')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 3,
        itemBuilder: (context, index) => Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: const Icon(Icons.location_on),
            title: Text('Address ${index + 1}'),
            subtitle: const Text('123 Main Street, City, State 12345'),
            trailing: IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {},
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        heroTag: 'user-sub-fab',
        child: const Icon(Icons.add),
      ),
    );
  }
}

/// User Settings Screen
class UserSettingsScreen extends StatelessWidget {
  const UserSettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SwitchListTile(
            title: Text('Email Notifications'),
            value: true,
            onChanged: null,
          ),
          const SwitchListTile(
            title: Text('Push Notifications'),
            value: true,
            onChanged: null,
          ),
          const Divider(),
          ListTile(title: const Text('Change Password'), onTap: () {}),
          ListTile(title: const Text('Privacy Policy'), onTap: () {}),
          ListTile(title: const Text('Logout'), onTap: () {}),
        ],
      ),
    );
  }
}
