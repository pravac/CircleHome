import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/firestore_service.dart';

class MemberContributionScreen extends StatelessWidget {
  final String memberName;
  final String photoUrl;
  final String householdId;
  final int totalPoints;
  final int rank;

  const MemberContributionScreen({
    super.key,
    required this.memberName,
    required this.photoUrl,
    required this.householdId,
    required this.totalPoints,
    required this.rank,
  });

  static const _rankColors = {
    1: Color(0xFFFFD700),
    2: Color(0xFFC0C0C0),
    3: Color(0xFFCD7F32),
  };

  Color get _rankColor => _rankColors[rank] ?? const Color(0xFF5B8DEF);

  String get _rankLabel {
    if (rank == 1) return '🥇 1st Place';
    if (rank == 2) return '🥈 2nd Place';
    if (rank == 3) return '🥉 3rd Place';
    return '#$rank';
  }

  @override
  Widget build(BuildContext context) {
    final initials = memberName
        .split(' ')
        .where((e) => e.isNotEmpty)
        .map((e) => e[0])
        .take(2)
        .join()
        .toUpperCase();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          memberName,
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirestoreService().getMemberTasks(householdId, memberName),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final all = snapshot.data?.docs ?? [];
          final completed = all.where((d) {
            return (d.data() as Map<String, dynamic>)['completed'] == true;
          }).toList();
          final pending = all.where((d) {
            return (d.data() as Map<String, dynamic>)['completed'] != true;
          }).toList();

          completed.sort((a, b) {
            final aTs = (a.data() as Map<String, dynamic>)['completedAt'] as Timestamp?;
            final bTs = (b.data() as Map<String, dynamic>)['completedAt'] as Timestamp?;
            if (aTs == null && bTs == null) return 0;
            if (aTs == null) return 1;
            if (bTs == null) return -1;
            return bTs.compareTo(aTs);
          });

          pending.sort((a, b) {
            final aTs = (a.data() as Map<String, dynamic>)['dueDateTime'] as Timestamp?;
            final bTs = (b.data() as Map<String, dynamic>)['dueDateTime'] as Timestamp?;
            if (aTs == null && bTs == null) return 0;
            if (aTs == null) return 1;
            if (bTs == null) return -1;
            return aTs.compareTo(bTs);
          });

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProfileCard(initials, completed.length, pending.length),
                    const SizedBox(height: 24),
                    _buildSection(
                      label: 'COMPLETED',
                      count: completed.length,
                      color: Colors.green,
                      icon: Icons.check_circle_outline,
                      tasks: completed,
                      emptyMessage: 'No completed tasks yet.',
                    ),
                    const SizedBox(height: 20),
                    _buildSection(
                      label: 'PENDING',
                      count: pending.length,
                      color: Colors.orange,
                      icon: Icons.pending_outlined,
                      tasks: pending,
                      emptyMessage: 'No pending tasks.',
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileCard(String initials, int completedCount, int pendingCount) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: _rankColor.withValues(alpha: 0.15),
            backgroundImage: photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
            child: photoUrl.isEmpty
                ? Text(
                    initials,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: _rankColor,
                    ),
                  )
                : null,
          ),
          const SizedBox(height: 12),
          Text(
            memberName,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: _rankColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _rankLabel,
              style: TextStyle(
                color: _rankColor,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _StatChip(
                  value: '$totalPoints',
                  label: 'Points',
                  color: _rankColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatChip(
                  value: '$completedCount',
                  label: 'Completed',
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatChip(
                  value: '$pendingCount',
                  label: 'Pending',
                  color: Colors.orange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String label,
    required int count,
    required Color color,
    required IconData icon,
    required List<QueryDocumentSnapshot> tasks,
    required String emptyMessage,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              '$label ($count)',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (tasks.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              emptyMessage,
              style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          )
        else
          ...tasks.map((doc) => _TaskRow(
                data: doc.data() as Map<String, dynamic>,
                isCompleted: label == 'COMPLETED',
              )),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _StatChip({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color.withValues(alpha: 0.8),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskRow extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool isCompleted;

  const _TaskRow({required this.data, required this.isCompleted});

  static const _categoryColors = {
    'Cleaning': Colors.blue,
    'Groceries': Colors.green,
    'Laundry': Colors.orange,
    'Bills': Colors.red,
  };

  static const _difficultyColors = [
    Colors.green,
    Color(0xFF8BC34A),
    Colors.orange,
    Colors.deepOrange,
    Colors.red,
  ];

  @override
  Widget build(BuildContext context) {
    final title = data['title'] as String? ?? 'Untitled';
    final category = data['category'] as String? ?? 'Other';
    final dueLabel = data['dueLabel'] as String? ?? '';
    final difficulty = (data['difficulty'] as int? ?? 0).clamp(0, 5);
    final categoryColor = _categoryColors[category] ?? Colors.grey;

    final dueTs = data['dueDateTime'] as Timestamp?;
    final isOverdue = !isCompleted &&
        dueTs != null &&
        dueTs.toDate().isBefore(DateTime.now());

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isOverdue
            ? Border.all(color: Colors.red.withValues(alpha: 0.35), width: 1.5)
            : null,
      ),
      child: Row(
        children: [
          Icon(
            isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
            color: isCompleted ? Colors.green : Colors.grey.shade300,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    decoration: isCompleted ? TextDecoration.lineThrough : null,
                    color: isCompleted ? Colors.grey.shade500 : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: categoryColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        category,
                        style: TextStyle(
                          color: categoryColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (difficulty > 0) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: _difficultyColors[(difficulty - 1).clamp(0, 4)]
                              .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '★$difficulty',
                          style: TextStyle(
                            color: _difficultyColors[(difficulty - 1).clamp(0, 4)],
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (dueLabel.isNotEmpty)
            Text(
              dueLabel,
              style: TextStyle(
                fontSize: 12,
                color: isOverdue ? Colors.red : Colors.grey.shade400,
                fontWeight: isOverdue ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
        ],
      ),
    );
  }
}
