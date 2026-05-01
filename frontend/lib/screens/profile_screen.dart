import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/firestore_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();
  final _photoUrlController = TextEditingController();
  int _workload = 3;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final doc = await FirestoreService().getUserDocument(uid);
    final data = doc.data();
    if (data != null && mounted) {
      setState(() {
        _nameController.text = data['name'] as String? ?? '';
        _photoUrlController.text = data['photoUrl'] as String? ?? '';
        _workload = (data['workload'] as int?) ?? 3;
        _loading = false;
      });
    } else {
      setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    setState(() => _saving = true);
    final photoUrl = _photoUrlController.text.trim();
    await FirestoreService().updateUserProfile(
      uid,
      name: _nameController.text.trim(),
      workload: _workload,
      photoUrl: photoUrl.isEmpty ? null : photoUrl,
    );
    if (mounted) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile saved!')),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _photoUrlController.dispose();
    super.dispose();
  }

  Color _workloadColor(int w) {
    switch (w) {
      case 1:
        return Colors.green;
      case 2:
        return const Color(0xFF8BC34A);
      case 3:
        return Colors.orange;
      case 4:
        return Colors.deepOrange;
      case 5:
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  String _workloadLabel(int w) {
    switch (w) {
      case 1:
        return 'Very light — lots of capacity available';
      case 2:
        return 'Light — some capacity available';
      case 3:
        return 'Moderate — balanced workload';
      case 4:
        return 'Heavy — limited capacity';
      case 5:
        return 'Very heavy — minimal capacity';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final photoUrl = _photoUrlController.text.trim();
    final name = _nameController.text.trim();
    final initials = name.isNotEmpty
        ? name
            .split(' ')
            .where((e) => e.isNotEmpty)
            .map((e) => e[0])
            .take(2)
            .join()
            .toUpperCase()
        : (user?.email?.substring(0, 1).toUpperCase() ?? '?');

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'My Profile',
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
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 16),

                      // Avatar
                      CircleAvatar(
                        radius: 52,
                        backgroundColor:
                            const Color(0xFF5B8DEF).withOpacity(0.15),
                        backgroundImage:
                            photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
                        onBackgroundImageError:
                            photoUrl.isNotEmpty ? (_, __) {} : null,
                        child: photoUrl.isEmpty
                            ? Text(
                                initials,
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF5B8DEF),
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(height: 32),

                      // Name field
                      TextField(
                        controller: _nameController,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          labelText: 'Display Name',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          prefixIcon: const Icon(Icons.person_outline),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Photo URL field
                      TextField(
                        controller: _photoUrlController,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          labelText: 'Profile Photo URL (optional)',
                          hintText: 'https://...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          prefixIcon: const Icon(Icons.image_outlined),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Email (read-only)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.email_outlined,
                              color: Colors.grey.shade500,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                user?.email ?? '',
                                style:
                                    TextStyle(color: Colors.grey.shade700),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Workload section
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text(
                                  'Weekly Workload',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _workloadColor(_workload)
                                        .withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '$_workload / 5',
                                    style: TextStyle(
                                      color: _workloadColor(_workload),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _workloadLabel(_workload),
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 12),
                            SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                activeTrackColor: _workloadColor(_workload),
                                thumbColor: _workloadColor(_workload),
                                overlayColor:
                                    _workloadColor(_workload).withOpacity(0.15),
                                inactiveTrackColor: Colors.grey.shade200,
                              ),
                              child: Slider(
                                value: _workload.toDouble(),
                                min: 1,
                                max: 5,
                                divisions: 4,
                                onChanged: (v) =>
                                    setState(() => _workload = v.round()),
                              ),
                            ),
                            const Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Light',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                                Text(
                                  'Heavy',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Save button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _saving ? null : _save,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF5B8DEF),
                            padding:
                                const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: _saving
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'Save Profile',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
