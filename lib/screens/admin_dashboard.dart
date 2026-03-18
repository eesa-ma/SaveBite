import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:save_bite/services/auth_serivce.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();

  Future<void> _setUserStatus(String userId, String status) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User status updated to $status.')),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update user status: $e')),
      );
    }
  }

  Future<void> _deleteUserDocument(String userId) async {
    final confirmed = await _showConfirmationDialog(
      title: 'Delete user account?',
      message:
          'This removes the user document from Firestore. Authentication account is not deleted by this action.',
      confirmLabel: 'Delete',
      isDestructive: true,
    );

    if (confirmed != true) {
      return;
    }

    try {
      await _firestore.collection('users').doc(userId).delete();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('User document deleted.')));
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete user document: $e')),
      );
    }
  }

  Future<void> _setRestaurantStatus(String restaurantId, String status) async {
    try {
      await _firestore.collection('restaurants').doc(restaurantId).update({
        'status': status,
        'isOpen': status == 'approved',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Restaurant status updated to $status.')),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update restaurant status: $e')),
      );
    }
  }

  Future<void> _deleteRestaurant(String restaurantId) async {
    final confirmed = await _showConfirmationDialog(
      title: 'Remove restaurant?',
      message: 'This permanently deletes the restaurant document.',
      confirmLabel: 'Remove',
      isDestructive: true,
    );

    if (confirmed != true) {
      return;
    }

    try {
      await _firestore.collection('restaurants').doc(restaurantId).delete();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Restaurant removed from platform.')),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to remove restaurant: $e')),
      );
    }
  }

  Future<bool?> _showConfirmationDialog({
    required String title,
    required String message,
    required String confirmLabel,
    bool isDestructive = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: isDestructive ? Colors.red : null,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    await _authService.logout();
    if (!mounted) {
      return;
    }
    Navigator.of(context).pushNamedAndRemoveUntil('/entry', (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Admin Panel'),
          actions: [
            IconButton(
              tooltip: 'Logout',
              onPressed: _logout,
              icon: const Icon(Icons.logout),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.dashboard), text: 'Dashboard'),
              Tab(icon: Icon(Icons.people), text: 'Users'),
              Tab(icon: Icon(Icons.store), text: 'Restaurants'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _DashboardTab(firestore: _firestore),
            _UserManagementTab(
              firestore: _firestore,
              onSuspendUser: (userId) => _setUserStatus(userId, 'suspended'),
              onActivateUser: (userId) => _setUserStatus(userId, 'active'),
              onDeleteUser: _deleteUserDocument,
            ),
            _RestaurantManagementTab(
              firestore: _firestore,
              onApprove: (restaurantId) =>
                  _setRestaurantStatus(restaurantId, 'approved'),
              onReject: (restaurantId) =>
                  _setRestaurantStatus(restaurantId, 'suspended'),
              onSuspend: (restaurantId) =>
                  _setRestaurantStatus(restaurantId, 'suspended'),
              onDelete: _deleteRestaurant,
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardTab extends StatelessWidget {
  const _DashboardTab({required this.firestore});

  final FirebaseFirestore firestore;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: firestore.collection('users').snapshots(),
      builder: (context, usersSnapshot) {
        if (usersSnapshot.hasError) {
          return _ErrorState(
            message: 'Failed to load users: ${usersSnapshot.error}',
          );
        }
        if (!usersSnapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: firestore.collection('restaurants').snapshots(),
          builder: (context, restaurantsSnapshot) {
            if (restaurantsSnapshot.hasError) {
              return _ErrorState(
                message:
                    'Failed to load restaurants: ${restaurantsSnapshot.error}',
              );
            }
            if (!restaurantsSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final totalUsers = usersSnapshot.data!.docs.where((doc) {
              final role = (doc.data()['role'] ?? '').toString().toLowerCase();
              return role == 'user';
            }).length;
            final restaurants = restaurantsSnapshot.data!.docs;
            final totalRestaurants = restaurants.length;
            final openRestaurants = restaurants
                .where((doc) => (doc.data()['isOpen'] ?? false) == true)
                .length;
            final closedRestaurants = totalRestaurants - openRestaurants;

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _StatsCard(
                  title: 'Total Users',
                  value: totalUsers.toString(),
                  icon: Icons.people_alt,
                  color: Colors.blue,
                ),
                const SizedBox(height: 12),
                _StatsCard(
                  title: 'Total Restaurants',
                  value: totalRestaurants.toString(),
                  icon: Icons.storefront,
                  color: Colors.green,
                ),
                const SizedBox(height: 12),
                _StatsCard(
                  title: 'Open Restaurants',
                  value: openRestaurants.toString(),
                  icon: Icons.check_circle_outline,
                  color: Colors.teal,
                ),
                const SizedBox(height: 12),
                _StatsCard(
                  title: 'Closed Restaurants',
                  value: closedRestaurants.toString(),
                  icon: Icons.pause_circle_outline,
                  color: Colors.orange,
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _UserManagementTab extends StatelessWidget {
  const _UserManagementTab({
    required this.firestore,
    required this.onSuspendUser,
    required this.onActivateUser,
    required this.onDeleteUser,
  });

  final FirebaseFirestore firestore;
  final Future<void> Function(String userId) onSuspendUser;
  final Future<void> Function(String userId) onActivateUser;
  final Future<void> Function(String userId) onDeleteUser;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: firestore.collection('users').orderBy('name').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _ErrorState(
            message: 'Failed to load users: ${snapshot.error}',
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs.where((doc) {
          final role = (doc.data()['role'] ?? '').toString().toLowerCase();
          return role == 'user' || role == 'customer';
        }).toList();
        if (docs.isEmpty) {
          return const _EmptyState(message: 'No customer users found.');
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data();
            final name = (data['name'] ?? 'Unknown').toString();
            final email = (data['email'] ?? 'No email').toString();
            final phone = (data['phone'] ?? '-').toString();
            final role = (data['role'] ?? 'User').toString();
            final status = (data['status'] ?? 'active').toString();
            final isSuspended = status.toLowerCase() == 'suspended';

            return Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        _StatusChip(label: status, isDanger: isSuspended),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text('Email: $email'),
                    Text('Phone: $phone'),
                    Text('Role: $role'),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        FilledButton.tonalIcon(
                          onPressed: () => isSuspended
                              ? onActivateUser(doc.id)
                              : onSuspendUser(doc.id),
                          icon: Icon(
                            isSuspended
                                ? Icons.check_circle_outline
                                : Icons.block,
                          ),
                          label: Text(isSuspended ? 'Activate' : 'Suspend'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => onDeleteUser(doc.id),
                          icon: const Icon(Icons.delete_outline),
                          label: const Text('Delete'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _RestaurantManagementTab extends StatelessWidget {
  const _RestaurantManagementTab({
    required this.firestore,
    required this.onApprove,
    required this.onReject,
    required this.onSuspend,
    required this.onDelete,
  });

  final FirebaseFirestore firestore;
  final Future<void> Function(String restaurantId) onApprove;
  final Future<void> Function(String restaurantId) onReject;
  final Future<void> Function(String restaurantId) onSuspend;
  final Future<void> Function(String restaurantId) onDelete;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: firestore.collection('users').snapshots(),
      builder: (context, usersSnapshot) {
        if (usersSnapshot.hasError) {
          return _ErrorState(
            message: 'Failed to load owners: ${usersSnapshot.error}',
          );
        }

        final ownerNameById = <String, String>{};
        for (final userDoc
            in usersSnapshot.data?.docs ??
                const <QueryDocumentSnapshot<Map<String, dynamic>>>[]) {
          final data = userDoc.data();
          ownerNameById[userDoc.id] = (data['name'] ?? 'Unknown owner')
              .toString();
        }

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: firestore
              .collection('restaurants')
              .orderBy('name')
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return _ErrorState(
                message: 'Failed to load restaurants: ${snapshot.error}',
              );
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final docs = snapshot.data!.docs;
            if (docs.isEmpty) {
              return const _EmptyState(message: 'No restaurants found.');
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: docs.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final doc = docs[index];
                final data = doc.data();
                final name = (data['name'] ?? 'Unknown Restaurant').toString();
                final address = (data['address'] ?? '-').toString();
                final ownerId = (data['ownerId'] ?? '').toString();
                final ownerName = ownerNameById[ownerId] ?? 'Unknown owner';
                final status = (data['status'] ?? 'pending').toString();
                final isSuspended = status.toLowerCase() == 'suspended';

                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                name,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                            _StatusChip(label: status, isDanger: isSuspended),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text('Address: $address'),
                        Text('Owner: $ownerName'),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            FilledButton.tonalIcon(
                              onPressed: status.toLowerCase() == 'approved'
                                  ? null
                                  : () => onApprove(doc.id),
                              icon: const Icon(Icons.verified_outlined),
                              label: const Text('Approve'),
                            ),
                            FilledButton.tonalIcon(
                              onPressed: status.toLowerCase() == 'pending'
                                  ? () => onReject(doc.id)
                                  : null,
                              icon: const Icon(Icons.close),
                              label: const Text('Reject'),
                            ),
                            OutlinedButton.icon(
                              onPressed: isSuspended
                                  ? null
                                  : () => onSuspend(doc.id),
                              icon: const Icon(Icons.block),
                              label: const Text('Suspend'),
                            ),
                            OutlinedButton.icon(
                              onPressed: () => onDelete(doc.id),
                              icon: const Icon(Icons.delete_outline),
                              label: const Text('Delete'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

class _StatsCard extends StatelessWidget {
  const _StatsCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.12),
          child: Icon(icon, color: color),
        ),
        title: Text(title),
        subtitle: Text(value, style: Theme.of(context).textTheme.headlineSmall),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.isDanger});

  final String label;
  final bool isDanger;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label),
      backgroundColor: isDanger
          ? Colors.red.withValues(alpha: 0.12)
          : Colors.green.withValues(alpha: 0.12),
      side: BorderSide.none,
      labelStyle: TextStyle(
        color: isDanger ? Colors.red.shade700 : Colors.green.shade700,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(message, style: Theme.of(context).textTheme.bodyLarge),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.red),
        ),
      ),
    );
  }
}
