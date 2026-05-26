import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../theme.dart';
import 'create_household_screen.dart';
import 'join_household_screen.dart';

Future<void> showHouseholdSwitcherSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => const _HouseholdSwitcherSheet(),
  );
}

class _HouseholdSwitcherSheet extends StatefulWidget {
  const _HouseholdSwitcherSheet();

  @override
  State<_HouseholdSwitcherSheet> createState() =>
      _HouseholdSwitcherSheetState();
}

class _HouseholdSwitcherSheetState extends State<_HouseholdSwitcherSheet> {
  bool _switching = false;

  Future<void> _switchTo(String uid, String householdId) async {
    setState(() => _switching = true);
    await FirestoreService().switchHousehold(uid, householdId);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _leave(String uid, String householdId, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Leave Household'),
        content: Text('Are you sure you want to leave "$name"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Leave', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await FirestoreService().leaveHousehold(uid, householdId);
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirestoreService().getUserStream(uid),
      builder: (context, userSnap) {
        final userData = userSnap.data?.data() ?? {};
        final activeId = userData['householdId'] as String? ?? '';
        final rawIds = userData['householdIds'];
        final List<String> householdIds = rawIds is List
            ? List<String>.from(rawIds)
            : (activeId.isNotEmpty ? [activeId] : []);

        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 16),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(24, 16, 24, 12),
                  child: Text(
                    'My Households',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (userSnap.connectionState == ConnectionState.waiting)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (householdIds.isEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                    child: Text(
                      'You are not in any households yet.',
                      style: TextStyle(color: Colors.grey.shade500),
                    ),
                  )
                else
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 320),
                    child: ListView(
                      shrinkWrap: true,
                      children: householdIds
                          .map((id) => _HouseholdTile(
                                householdId: id,
                                isActive: id == activeId,
                                switching: _switching,
                                onSwitch: () => _switchTo(uid, id),
                                onLeave: (name) => _leave(uid, id, name),
                              ))
                          .toList(),
                    ),
                  ),
                const Divider(height: 1),
                const SizedBox(height: 4),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child:
                        const Icon(Icons.add, color: Colors.blue, size: 20),
                  ),
                  title: const Text(
                    'Create New Household',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const CreateHouseholdScreen()),
                  ),
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child:
                        const Icon(Icons.link, color: Colors.green, size: 20),
                  ),
                  title: const Text(
                    'Join with Invite Code',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const JoinHouseholdScreen()),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _HouseholdTile extends StatefulWidget {
  final String householdId;
  final bool isActive;
  final bool switching;
  final VoidCallback onSwitch;
  final void Function(String name) onLeave;

  const _HouseholdTile({
    required this.householdId,
    required this.isActive,
    required this.switching,
    required this.onSwitch,
    required this.onLeave,
  });

  @override
  State<_HouseholdTile> createState() => _HouseholdTileState();
}

class _HouseholdTileState extends State<_HouseholdTile> {
  String _name = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadName();
  }

  Future<void> _loadName() async {
    final data = await FirestoreService().getHousehold(widget.householdId);
    if (mounted) {
      setState(() {
        _name = data?['name'] as String? ?? 'Unnamed Household';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 24),
        leading: CircleAvatar(
          backgroundColor: Colors.grey.shade100,
          child: const Icon(Icons.home_outlined, color: Colors.grey, size: 20),
        ),
        title: Container(
          height: 14,
          width: 120,
          color: Colors.grey.shade200,
        ),
      );
    }

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
      leading: CircleAvatar(
        backgroundColor: widget.isActive
            ? AppColors.primary.withValues(alpha: 0.15)
            : Colors.grey.shade100,
        child: Icon(
          Icons.home,
          color:
              widget.isActive ? AppColors.primary : Colors.grey.shade500,
          size: 20,
        ),
      ),
      title: Text(
        _name,
        style: TextStyle(
          fontWeight:
              widget.isActive ? FontWeight.w700 : FontWeight.w500,
          color: widget.isActive
              ? AppColors.primary
              : Colors.black87,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.isActive)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Active',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            )
          else if (widget.switching)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            TextButton(
              onPressed: widget.onSwitch,
              style: TextButton.styleFrom(
                minimumSize: Size.zero,
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('Switch'),
            ),
          const SizedBox(width: 4),
          IconButton(
            icon: Icon(
              Icons.logout,
              size: 18,
              color: Colors.grey.shade400,
            ),
            tooltip: 'Leave household',
            onPressed: () => widget.onLeave(_name),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}
