import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import 'swap_sheet.dart';

class TaskFeedScreen extends StatefulWidget {
  final String householdId;

  const TaskFeedScreen({super.key, required this.householdId});

  @override
  State<TaskFeedScreen> createState() => _TaskFeedScreenState();
}

class _TaskFeedScreenState extends State<TaskFeedScreen> {
  bool _showMyTasks = false;
  String _userName = '';
  String _photoUrl = '';

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final doc = await FirestoreService().getUserDocument(uid);
    final data = doc.data();
    if (data != null && mounted) {
      final name = data['name'] as String?;
      final email = FirebaseAuth.instance.currentUser?.email;
      setState(() {
        _userName = (name != null && name.isNotEmpty)
            ? name
            : (email?.split('@').first ?? 'Member');
        _photoUrl = data['photoUrl'] as String? ?? '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
          _showMyTasks ? 'My Tasks' : 'All Tasks',
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  child: SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(
                        value: false,
                        label: Text('All Tasks'),
                        icon: Icon(Icons.list_alt),
                      ),
                      ButtonSegment(
                        value: true,
                        label: Text('My Tasks'),
                        icon: Icon(Icons.person),
                      ),
                    ],
                    selected: {_showMyTasks},
                    onSelectionChanged: (selected) {
                      setState(() => _showMyTasks = selected.first);
                    },
                  ),
                ),

                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirestoreService().getAllTasks(widget.householdId),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }

                      if (snapshot.hasError) {
                        return const Center(
                          child: Text('Error loading tasks.'),
                        );
                      }

                      var docs = [...(snapshot.data?.docs ?? [])];

                      if (_showMyTasks && _userName.isNotEmpty) {
                        docs = docs.where((d) {
                          final data = d.data() as Map<String, dynamic>;
                          return data['assignedTo'] == _userName;
                        }).toList();
                      }

                      docs.sort((a, b) {
                        final aData = a.data() as Map<String, dynamic>;
                        final bData = b.data() as Map<String, dynamic>;
                        final aTime = aData['dueDateTime'] as Timestamp?;
                        final bTime = bData['dueDateTime'] as Timestamp?;
                        if (aTime == null && bTime == null) return 0;
                        if (aTime == null) return 1;
                        if (bTime == null) return -1;
                        return aTime.compareTo(bTime);
                      });

                      if (docs.isEmpty) {
                        return Center(
                          child: Container(
                            margin: const EdgeInsets.all(24),
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.check_circle_outline,
                                  size: 56,
                                  color: Colors.grey.shade300,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _showMyTasks
                                      ? 'No tasks assigned to you'
                                      : 'No tasks yet',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _showMyTasks
                                      ? 'Switch to "All Tasks" to see household tasks.'
                                      : 'Add a task from the home screen to get started.',
                                  style: TextStyle(color: Colors.grey.shade400),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      final incomplete = docs.where((d) {
                        final data = d.data() as Map<String, dynamic>;
                        return data['completed'] != true;
                      }).toList();
                      final complete = docs.where((d) {
                        final data = d.data() as Map<String, dynamic>;
                        return data['completed'] == true;
                      }).toList();

                      return ListView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 8,
                        ),
                        children: [
                          if (incomplete.isNotEmpty) ...[
                            _sectionHeader('Open (${incomplete.length})', Colors.blue),
                            const SizedBox(height: 10),
                            ...incomplete.map((doc) => _taskCard(context, doc)),
                            const SizedBox(height: 24),
                          ],
                          if (complete.isNotEmpty) ...[
                            _sectionHeader('Completed (${complete.length})', Colors.green),
                            const SizedBox(height: 10),
                            ...complete.map((doc) => _taskCard(context, doc)),
                          ],
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _taskCard(BuildContext context, QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final title = data['title'] as String? ?? 'Untitled Task';
    final category = data['category'] as String? ?? 'Other';
    final assignedTo = data['assignedTo'] as String? ?? 'Unknown';
    final dueLabel = data['dueLabel'] as String? ?? '';
    final completed = data['completed'] as bool? ?? false;
    final difficulty = (data['difficulty'] as int?) ?? 0;
    final isRecurring = data['isRecurring'] as bool? ?? false;
    final recurrenceFrequency = data['recurrenceFrequency'] as String? ?? '';

    Color categoryColor;
    switch (category) {
      case 'Cleaning':
        categoryColor = Colors.blue;
        break;
      case 'Groceries':
        categoryColor = Colors.green;
        break;
      case 'Laundry':
        categoryColor = Colors.orange;
        break;
      case 'Bills':
        categoryColor = Colors.red;
        break;
      default:
        categoryColor = Colors.grey;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: completed ? const Color(0xFFF8F9FA) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: completed ? Border.all(color: Colors.grey.shade200) : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          IconButton(
            icon: Icon(
              completed ? Icons.check_circle : Icons.radio_button_unchecked,
              color: completed ? Colors.green : Colors.grey.shade400,
              size: 26,
            ),
            tooltip: completed ? 'Mark as incomplete' : null,
            onPressed: () async {
              if (completed) {
                await FirestoreService().uncompleteTask(doc.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Task marked incomplete.'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              } else {
                await FirestoreService().completeTask(
                  docId: doc.id,
                  title: title,
                  userName: _userName.isNotEmpty
                      ? _userName
                      : (FirebaseAuth.instance.currentUser?.email ?? 'Someone'),
                  householdId: widget.householdId,
                  photoUrl: _photoUrl,
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Task completed!'),
                      duration: const Duration(seconds: 4),
                      action: SnackBarAction(
                        label: 'Undo',
                        onPressed: () async {
                          await FirestoreService().uncompleteTask(doc.id);
                        },
                      ),
                    ),
                  );
                }
              }
            },
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: completed ? Colors.grey.shade400 : Colors.black87,
                          decoration: completed
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                          decorationColor: Colors.grey.shade400,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: completed
                            ? Colors.grey.shade100
                            : categoryColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        category,
                        style: TextStyle(
                          color: completed ? Colors.grey.shade400 : categoryColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (difficulty > 0) ...[
                      const SizedBox(width: 4),
                      _difficultyBadge(difficulty, dimmed: completed),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      assignedTo,
                      style: TextStyle(
                        color: completed
                            ? Colors.grey.shade400
                            : Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    ),
                    if (isRecurring &&
                        recurrenceFrequency.isNotEmpty &&
                        recurrenceFrequency != 'none' &&
                        !completed) ...[
                      const SizedBox(width: 6),
                      _recurringBadge(recurrenceFrequency),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                dueLabel,
                style: TextStyle(
                  color: completed ? Colors.grey.shade400 : Colors.orange,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              if (completed)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'Done',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 4),
          if (!completed)
            IconButton(
              icon: const Icon(Icons.swap_horiz, color: Color(0xFF5B8DEF)),
              tooltip: 'Swap or Reassign',
              onPressed: () {
                final uid =
                    FirebaseAuth.instance.currentUser?.uid ?? '';
                showSwapSheet(
                  context,
                  taskId: doc.id,
                  taskTitle: title,
                  householdId: widget.householdId,
                  currentUserId: uid,
                  currentUserName: _userName,
                );
              },
            ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            onPressed: () async {
              await FirestoreService().deleteTask(doc.id);
            },
          ),
        ],
      ),
    );
  }

  Widget _difficultyBadge(int difficulty, {bool dimmed = false}) {
    const colors = [
      Colors.green,
      Color(0xFF8BC34A),
      Colors.orange,
      Colors.deepOrange,
      Colors.red,
    ];
    final color = dimmed ? Colors.grey : colors[(difficulty - 1).clamp(0, 4)];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '★$difficulty',
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _recurringBadge(String frequency) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.purple.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.repeat, size: 11, color: Colors.purple),
          const SizedBox(width: 3),
          Text(
            frequency,
            style: const TextStyle(
              color: Colors.purple,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
