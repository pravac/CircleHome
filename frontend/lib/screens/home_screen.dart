import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final bool isWide = width > 900;
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('No user signed in')),
      );
    }

    return FutureBuilder<String?>(
      future: FirestoreService().getHouseholdIdForUser(currentUser.uid),
      builder: (context, householdSnapshot) {
        if (householdSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final householdId = householdSnapshot.data;

        if (householdId == null) {
          return const Scaffold(
            body: Center(child: Text('No household found for user')),
          );
        }

        return Scaffold(
          backgroundColor: const Color(0xFFF4F6FB),
          body: SafeArea(
            child: Row(
              children: [
                if (isWide) _buildSidebar(),
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 24,
                      ),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1100),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildHeader(),
                            const SizedBox(height: 24),
                            _buildSummaryCards(householdId),
                            const SizedBox(height: 28),
                            _buildTasksSection(householdId),
                            const SizedBox(height: 28),
                            _buildActivitySection(householdId),
                            const SizedBox(height: 28),
                            _buildBottomButtons(context, householdId),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    final user = FirebaseAuth.instance.currentUser;

    return Row(
      children: [
        const CircleAvatar(
          radius: 28,
          backgroundColor: Colors.white,
          child: Icon(Icons.home, size: 30),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Text(
            "CircleHome",
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
          ),
        ),
        Text(
          user?.email ?? "",
          style: const TextStyle(fontSize: 14),
        ),
        const SizedBox(width: 10),
        IconButton(
          icon: const Icon(Icons.logout),
          onPressed: () async {
            await AuthService().signOut();
          },
        ),
      ],
    );
  }

  Widget _buildSummaryCards(String householdId) {
    final service = FirestoreService();

    return StreamBuilder<QuerySnapshot>(
      stream: service.getTasks(householdId),
      builder: (context, taskSnapshot) {
        final tasks = taskSnapshot.data?.docs ?? [];
        final incompleteCount = tasks.length;

        return StreamBuilder<QuerySnapshot>(
          stream: service.getActivities(householdId),
          builder: (context, activitySnapshot) {
            final activities = activitySnapshot.data?.docs ?? [];
            final activityCount = activities.length;

            return Row(
              children: [
                Expanded(
                  child: _SummaryCard(
                    incompleteCount.toString(),
                    "Tasks Today",
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _SummaryCard(
                    incompleteCount.toString(),
                    "Open Tasks",
                    Colors.red,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _SummaryCard(
                    activityCount.toString(),
                    "Recent Activity",
                    Colors.green,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildTasksSection(String householdId) {
    final service = FirestoreService();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "My Tasks",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 14),
        StreamBuilder<QuerySnapshot>(
          stream: service.getTasks(householdId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              );
            }

            if (snapshot.hasError) {
              return const Text("Error loading tasks.");
            }

            final docs = [...(snapshot.data?.docs ?? [])];

            docs.sort((a, b) {
              final aData = a.data() as Map<String, dynamic>;
              final bData = b.data() as Map<String, dynamic>;

              final aTime = aData['createdAt'] as Timestamp?;
              final bTime = bData['createdAt'] as Timestamp?;

              if (aTime == null && bTime == null) return 0;
              if (aTime == null) return 1;
              if (bTime == null) return -1;

              return bTime.compareTo(aTime);
            });

            if (docs.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Text("No tasks yet."),
              );
            }

            return Column(
              children: docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final title = data['title'] as String? ?? 'Untitled Task';
                final assignedTo =
                    data['assignedTo'] as String? ?? 'Unknown User';
                final dueLabel = data['dueLabel'] as String? ?? '';
                final completed = data['completed'] as bool? ?? false;

                return _taskTile(
                  context: context,
                  docId: doc.id,
                  title: title,
                  user: assignedTo,
                  time: dueLabel,
                  completed: completed,
                  householdId: householdId,
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _taskTile({
    required BuildContext context,
    required String docId,
    required String title,
    required String user,
    required String time,
    required bool completed,
    required String householdId,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              completed ? Icons.check_box : Icons.check_box_outline_blank,
              color: completed ? Colors.green : Colors.grey,
            ),
            onPressed: completed
                ? null
                : () async {
                    await FirestoreService().completeTask(
                      docId: docId,
                      title: title,
                      userName:
                          FirebaseAuth.instance.currentUser?.email ?? 'Someone',
                      householdId: householdId,
                    );
                  },
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  user,
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: const TextStyle(
              color: Colors.orange,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            onPressed: () async {
              await FirestoreService().deleteTask(docId);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActivitySection(String householdId) {
    final service = FirestoreService();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Recent Activity",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        StreamBuilder<QuerySnapshot>(
          stream: service.getActivities(householdId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              );
            }

            if (snapshot.hasError) {
              return const Text("Error loading activity.");
            }

            final docs = [...(snapshot.data?.docs ?? [])];

            docs.sort((a, b) {
              final aData = a.data() as Map<String, dynamic>;
              final bData = b.data() as Map<String, dynamic>;

              final aTime = aData['createdAt'] as Timestamp?;
              final bTime = bData['createdAt'] as Timestamp?;

              if (aTime == null && bTime == null) return 0;
              if (aTime == null) return 1;
              if (bTime == null) return -1;

              return bTime.compareTo(aTime);
            });

            if (docs.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Text("No recent activity yet."),
              );
            }

            return Column(
              children: docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final text = data['text'] as String? ?? 'Activity';
                final timeLabel = data['timeLabel'] as String? ?? '';

                return _ActivityTile(text, timeLabel);
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildBottomButtons(BuildContext context, String householdId) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: () => _showAddTaskDialog(context, householdId),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(vertical: 18),
            ),
            child: const Text("+ Add Task"),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(vertical: 18),
            ),
            child: const Text("+ Add Care Note"),
          ),
        ),
      ],
    );
  }

  Future<void> _showAddTaskDialog(
    BuildContext context,
    String householdId,
  ) async {
    final titleController = TextEditingController();
    final assignedToController = TextEditingController();
    final dueLabelController = TextEditingController();

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Add Task'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Task title'),
              ),
              TextField(
                controller: assignedToController,
                decoration: const InputDecoration(labelText: 'Assigned to'),
              ),
              TextField(
                controller: dueLabelController,
                decoration: const InputDecoration(labelText: 'Due label'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final title = titleController.text.trim();
                final assignedTo = assignedToController.text.trim();
                final dueLabel = dueLabelController.text.trim();

                if (title.isEmpty || assignedTo.isEmpty || dueLabel.isEmpty) {
                  return;
                }

                await FirestoreService().addTask(
                  title: title,
                  assignedTo: assignedTo,
                  householdId: householdId,
                  dueLabel: dueLabel,
                );

                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop();
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 90,
      color: Colors.white,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.home, size: 30),
          SizedBox(height: 30),
          Icon(Icons.check_box),
          SizedBox(height: 30),
          Icon(Icons.favorite),
          SizedBox(height: 30),
          Icon(Icons.people),
          SizedBox(height: 30),
          Icon(Icons.settings),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String number;
  final String label;
  final Color color;

  const _SummaryCard(this.number, this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Text(
            number,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 6),
          Text(label),
        ],
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  final String text;
  final String time;

  const _ActivityTile(this.text, this.time);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.person)),
        title: Text(text),
        trailing: Text(time),
      ),
    );
  }
}