import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import 'profile_screen.dart';
import 'create_household_screen.dart';
import 'join_household_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _name = '';
  String _photoUrl = '';
  String _householdId = '';
  bool _loading = true;
  AuthorizationStatus? _notifStatus;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadNotifStatus();
  }

  Future<void> _loadNotifStatus() async {
    final settings = await FirebaseMessaging.instance.getNotificationSettings();
    if (mounted) {
      setState(() => _notifStatus = settings.authorizationStatus);
    }
  }

  Future<void> _loadProfile() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final doc = await FirestoreService().getUserDocument(uid);
    final data = doc.data();
    if (data != null && mounted) {
  setState(() {
    _name = data['name'] as String? ?? '';
    _photoUrl = data['photoUrl'] as String? ?? '';
    _householdId = data['householdId'] as String? ?? '';
    _loading = false;
  });
    } else {
      setState(() => _loading = false);
    }
  }

Future<void> _confirmLeaveHousehold() async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Leave Household'),
      content: const Text(
        'Are you sure you want to leave your current household? You will need an invite code to rejoin.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: const Text(
            'Leave',
            style: TextStyle(color: Colors.red),
          ),
        ),
      ],
    ),
  );
  if (confirmed == true) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await FirestoreService().leaveHousehold(uid, _householdId);
  }
}


  Future<void> _confirmLogOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Log Out', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await AuthService().signOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final displayName = _name.isNotEmpty
        ? _name
        : (user?.email?.split('@').first ?? 'Member');
    final initials = displayName
        .split(' ')
        .where((e) => e.isNotEmpty)
        .map((e) => e[0])
        .take(2)
        .join()
        .toUpperCase();

    ImageProvider? avatarImage =
        _photoUrl.isNotEmpty ? NetworkImage(_photoUrl) : null;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Settings',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      // Profile card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundColor:
                                  const Color(0xFF5B8DEF).withOpacity(0.15),
                              backgroundImage: avatarImage,
                              onBackgroundImageError:
                                  avatarImage != null ? (e, s) {} : null,
                              child: avatarImage == null
                                  ? Text(
                                      initials,
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF5B8DEF),
                                      ),
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    displayName,
                                    style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    user?.email ?? '',
                                    style: TextStyle(
                                      color: Colors.grey.shade500,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit_outlined,
                                  color: Color(0xFF5B8DEF)),
                              tooltip: 'Edit Profile',
                              onPressed: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const ProfileScreen(),
                                  ),
                                );
                                _loadProfile(); // refresh after editing
                              },
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Household section
                      Text(
                        'HOUSEHOLD',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey.shade500,
                          letterSpacing: 1.1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: _householdId.isEmpty
                            ? Column(
                                children: [
                                  _settingsRow(
                                    icon: Icons.add_home_outlined,
                                    label: 'Create New Household',
                                    onTap: () async {
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => const CreateHouseholdScreen(),
                                        ),
                                      );
                                      _loadProfile();
                                    },
                                  ),
                                  Divider(height: 1, indent: 56, color: Colors.grey.shade100),
                                  _settingsRow(
                                    icon: Icons.group_add_outlined,
                                    label: 'Join a Household',
                                    onTap: () async {
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => const JoinHouseholdScreen(),
                                        ),
                                      );
                                      _loadProfile();
                                    },
                                  ),
                                ],
                              )
                            : Column(
                                children: [
                                  _settingsRow(
                                    icon: Icons.exit_to_app,
                                    label: 'Leave Household',
                                    iconColor: Colors.red,
                                    labelColor: Colors.red,
                                    onTap: _confirmLeaveHousehold,
                                  ),
                                ],
                              ),
                      ),


                      const SizedBox(height: 24),

                      // Account section
                      Text(
                        'ACCOUNT',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey.shade500,
                          letterSpacing: 1.1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Column(
                          children: [
                            _settingsRow(
                              icon: Icons.notifications_outlined,
                              label: 'Notifications',
                              trailing: _notifStatus == AuthorizationStatus.authorized
                                  ? const Row(mainAxisSize: MainAxisSize.min, children: [
                                      Icon(Icons.check_circle, color: Colors.green, size: 16),
                                      SizedBox(width: 4),
                                      Text('Enabled', style: TextStyle(color: Colors.green, fontSize: 13)),
                                    ])
                                  : const Text('Manage in device settings',
                                      style: TextStyle(color: Colors.grey, fontSize: 12)),
                              onTap: null,
                            ),
                            Divider(
                                height: 1,
                                indent: 56,
                                color: Colors.grey.shade100),
                            _settingsRow(
                              icon: Icons.logout,
                              label: 'Log Out',
                              iconColor: Colors.red,
                              labelColor: Colors.red,
                              onTap: _confirmLogOut,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _settingsRow({
    required IconData icon,
    required String label,
    Widget? trailing,
    Color? iconColor,
    Color? labelColor,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? Colors.grey.shade600, size: 22),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: labelColor ?? Colors.black87,
        ),
      ),
      trailing: trailing ??
          (onTap != null
              ? Icon(Icons.chevron_right, color: Colors.grey.shade400)
              : null),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    );
  }
}