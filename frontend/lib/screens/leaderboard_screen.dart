import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/firestore_service.dart';

class LeaderboardScreen extends StatelessWidget {
  final String householdId;

  const LeaderboardScreen({super.key, required this.householdId});

  @override
  Widget build(BuildContext context) {
    if (householdId.isEmpty) {
      return const Scaffold(
        backgroundColor: Color(0xFFF4F6FB),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Leaderboard',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirestoreService().getAllTasks(householdId),
        builder: (context, taskSnap) {
          return StreamBuilder<QuerySnapshot>(
            stream: FirestoreService().getHouseholdMembers(householdId),
            builder: (context, memberSnap) {
              if (taskSnap.connectionState == ConnectionState.waiting ||
                  memberSnap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final tasks = taskSnap.data?.docs ?? [];
              final members = memberSnap.data?.docs ?? [];

              // Build member metadata map: name -> {photoUrl, uid}
              final memberMeta = <String, Map<String, String>>{};
              for (final doc in members) {
                final data = doc.data() as Map<String, dynamic>;
                final name = (data['name'] as String?)?.trim();
                final email = data['email'] as String? ?? '';
                final displayName = (name != null && name.isNotEmpty)
                    ? name
                    : email.split('@').first;
                memberMeta[displayName] = {
                  'photoUrl': data['photoUrl'] as String? ?? '',
                  'uid': doc.id,
                };
              }

              // Tally scores from completed tasks
              final scores = <String, int>{};
              final taskCounts = <String, int>{};
              for (final doc in tasks) {
                final data = doc.data() as Map<String, dynamic>;
                if (data['completed'] != true) continue;
                final assignee = data['assignedTo'] as String? ?? '';
                if (assignee.isEmpty) continue;
                final difficulty = (data['difficulty'] as int?) ?? 1;
                scores[assignee] = (scores[assignee] ?? 0) + difficulty.clamp(1, 5);
                taskCounts[assignee] = (taskCounts[assignee] ?? 0) + 1;
              }

              // Add members with 0 score so everyone appears
              for (final name in memberMeta.keys) {
                scores.putIfAbsent(name, () => 0);
                taskCounts.putIfAbsent(name, () => 0);
              }

              final ranked = scores.entries.toList()
                ..sort((a, b) => b.value.compareTo(a.value));

              if (ranked.isEmpty) {
                return Center(
                  child: Container(
                    margin: const EdgeInsets.all(32),
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.leaderboard_outlined,
                            size: 56, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text(
                          'No scores yet',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade500,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Complete tasks to earn points!',
                          style: TextStyle(color: Colors.grey.shade400),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (ranked.length >= 3)
                          _Podium(
                            ranked: ranked,
                            taskCounts: taskCounts,
                            memberMeta: memberMeta,
                          ),
                        if (ranked.length >= 3) const SizedBox(height: 28),
                        Text(
                          'RANKINGS',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.grey.shade500,
                            letterSpacing: 1.1,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ...ranked.asMap().entries.map((entry) {
                          final rank = entry.key + 1;
                          final name = entry.value.key;
                          final pts = entry.value.value;
                          final count = taskCounts[name] ?? 0;
                          final photo = memberMeta[name]?['photoUrl'] ?? '';
                          return _RankRow(
                            rank: rank,
                            name: name,
                            photoUrl: photo,
                            points: pts,
                            taskCount: count,
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _Podium extends StatelessWidget {
  final List<MapEntry<String, int>> ranked;
  final Map<String, int> taskCounts;
  final Map<String, Map<String, String>> memberMeta;

  const _Podium({
    required this.ranked,
    required this.taskCounts,
    required this.memberMeta,
  });

  @override
  Widget build(BuildContext context) {
    final first = ranked[0];
    final second = ranked[1];
    final third = ranked[2];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 2nd place
          Expanded(
            child: _PodiumSlot(
              name: second.key,
              pts: second.value,
              photoUrl: memberMeta[second.key]?['photoUrl'] ?? '',
              rank: 2,
              height: 90,
            ),
          ),
          // 1st place
          Expanded(
            child: _PodiumSlot(
              name: first.key,
              pts: first.value,
              photoUrl: memberMeta[first.key]?['photoUrl'] ?? '',
              rank: 1,
              height: 120,
            ),
          ),
          // 3rd place
          Expanded(
            child: _PodiumSlot(
              name: third.key,
              pts: third.value,
              photoUrl: memberMeta[third.key]?['photoUrl'] ?? '',
              rank: 3,
              height: 70,
            ),
          ),
        ],
      ),
    );
  }
}

class _PodiumSlot extends StatelessWidget {
  final String name;
  final int pts;
  final String photoUrl;
  final int rank;
  final double height;

  const _PodiumSlot({
    required this.name,
    required this.pts,
    required this.photoUrl,
    required this.rank,
    required this.height,
  });

  static const _medals = {
    1: Color(0xFFFFD700),
    2: Color(0xFFC0C0C0),
    3: Color(0xFFCD7F32),
  };

  static const _icons = {
    1: '🥇',
    2: '🥈',
    3: '🥉',
  };

  @override
  Widget build(BuildContext context) {
    final color = _medals[rank]!;
    final initials = name
        .split(' ')
        .where((e) => e.isNotEmpty)
        .map((e) => e[0])
        .take(2)
        .join()
        .toUpperCase();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(_icons[rank]!, style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 6),
        CircleAvatar(
          radius: rank == 1 ? 30 : 24,
          backgroundColor: color.withValues(alpha: 0.2),
          backgroundImage: photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
          child: photoUrl.isEmpty
              ? Text(
                  initials,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: rank == 1 ? 16 : 13,
                    color: color,
                  ),
                )
              : null,
        ),
        const SizedBox(height: 8),
        Text(
          name.split(' ').first,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          '$pts pts',
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: height,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
          ),
          child: Center(
            child: Text(
              '#$rank',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w800,
                fontSize: 20,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _RankRow extends StatelessWidget {
  final int rank;
  final String name;
  final String photoUrl;
  final int points;
  final int taskCount;

  const _RankRow({
    required this.rank,
    required this.name,
    required this.photoUrl,
    required this.points,
    required this.taskCount,
  });

  @override
  Widget build(BuildContext context) {
    final initials = name
        .split(' ')
        .where((e) => e.isNotEmpty)
        .map((e) => e[0])
        .take(2)
        .join()
        .toUpperCase();

    final Color rankColor;
    if (rank == 1) {
      rankColor = const Color(0xFFFFD700);
    } else if (rank == 2) {
      rankColor = const Color(0xFFC0C0C0);
    } else if (rank == 3) {
      rankColor = const Color(0xFFCD7F32);
    } else {
      rankColor = Colors.grey.shade400;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: rank <= 3
            ? Border.all(color: rankColor.withValues(alpha: 0.4), width: 1.5)
            : null,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text(
              '#$rank',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 15,
                color: rankColor,
              ),
            ),
          ),
          const SizedBox(width: 4),
          CircleAvatar(
            radius: 20,
            backgroundColor: const Color(0xFF5B8DEF).withValues(alpha: 0.15),
            backgroundImage: photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
            child: photoUrl.isEmpty
                ? Text(
                    initials,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF5B8DEF),
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                Text(
                  '$taskCount task${taskCount == 1 ? '' : 's'} completed',
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: rank <= 3
                  ? rankColor.withValues(alpha: 0.12)
                  : const Color(0xFF5B8DEF).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$points pts',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: rank <= 3 ? rankColor : const Color(0xFF5B8DEF),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
