import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../theme.dart';
import 'swap_sheet.dart';
import 'edit_task_screen.dart';

class TaskFeedScreen extends StatefulWidget {
  final String householdId;

  const TaskFeedScreen({super.key, required this.householdId});

  @override
  State<TaskFeedScreen> createState() => _TaskFeedScreenState();
}

enum _StatusFilter { all, overdue, completed }

class _TaskFeedScreenState extends State<TaskFeedScreen> {
  bool _showMyTasks = false;
  _StatusFilter _statusFilter = _StatusFilter.all;
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: Navigator.canPop(context),
        title: Text(
          _showMyTasks ? 'My Tasks' : 'All Tasks',
          style: AppTextStyles.appBarTitle,
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
                  child: Column(
                    children: [
                      SegmentedButton<bool>(
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
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          _filterChip('All', _StatusFilter.all, Colors.grey),
                          const SizedBox(width: 8),
                          _filterChip('Overdue', _StatusFilter.overdue, Colors.red),
                          const SizedBox(width: 8),
                          _filterChip('Completed', _StatusFilter.completed, Colors.green),
                        ],
                      ),
                    ],
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

                      final now2 = DateTime.now();
                      if (_statusFilter == _StatusFilter.overdue) {
                        docs = docs.where((d) {
                          final data = d.data() as Map<String, dynamic>;
                          if (data['completed'] == true) return false;
                          final dueTs = data['dueDateTime'] as Timestamp?;
                          return dueTs != null && dueTs.toDate().isBefore(now2);
                        }).toList();
                      } else if (_statusFilter == _StatusFilter.completed) {
                        docs = docs.where((d) {
                          final data = d.data() as Map<String, dynamic>;
                          return data['completed'] == true;
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

                      final now = DateTime.now();

                      final overdue = docs.where((d) {
                        final data = d.data() as Map<String, dynamic>;
                        if (data['completed'] == true) return false;
                        final dueTs = data['dueDateTime'] as Timestamp?;
                        return dueTs != null && dueTs.toDate().isBefore(now);
                      }).toList();

                      final open = docs.where((d) {
                        final data = d.data() as Map<String, dynamic>;
                        if (data['completed'] == true) return false;
                        final dueTs = data['dueDateTime'] as Timestamp?;
                        return dueTs == null || !dueTs.toDate().isBefore(now);
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
                          if (overdue.isNotEmpty) ...[
                            _sectionHeader('Overdue (${overdue.length})', Colors.red),
                            const SizedBox(height: 10),
                            ...overdue.map((doc) => _taskCard(context, doc)),
                            const SizedBox(height: 24),
                          ],
                          if (open.isNotEmpty) ...[
                            _sectionHeader('Open (${open.length})', Colors.blue),
                            const SizedBox(height: 10),
                            ...open.map((doc) => _taskCard(context, doc)),
                            const SizedBox(height: 24),
                          ],
                          if (complete.isNotEmpty) ...[
                            _sectionHeader('Completed (${complete.length})', Colors.green),
                            const SizedBox(height: 10),
                            ...complete.map((doc) => _taskCard(context, doc)),
                          ],
                          if (overdue.isEmpty && open.isEmpty && complete.isEmpty)
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.all(32),
                                child: Text(
                                  _showMyTasks
                                      ? 'No tasks assigned to you'
                                      : 'No tasks yet',
                                  style: TextStyle(
                                    color: Colors.grey.shade400,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
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

  Widget _filterChip(String label, _StatusFilter value, Color color) {
    final selected = _statusFilter == value;
    return GestureDetector(
      onTap: () => setState(() => _statusFilter = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.15) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? color : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? color : Colors.grey.shade600,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 13,
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
    final dueTs = data['dueDateTime'] as Timestamp?;
    final isOverdue = !completed &&
        dueTs != null &&
        dueTs.toDate().isBefore(DateTime.now());

    final categoryColor = AppColors.category(category);

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
              final messenger = ScaffoldMessenger.of(context);
              if (completed) {
                FirestoreService().uncompleteTask(doc.id);
                messenger
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    const SnackBar(
                      content: Text('Task marked incomplete.'),
                      duration: Duration(seconds: 2),
                    ),
                  );
              } else {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Mark as complete?'),
                    content: Text('"$title" will be marked done.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.of(ctx).pop(true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Complete'),
                      ),
                    ],
                  ),
                );
                if (confirmed != true || !context.mounted) return;
                FirestoreService().completeTask(
                  docId: doc.id,
                  title: title,
                  userName: _userName.isNotEmpty
                      ? _userName
                      : (FirebaseAuth.instance.currentUser?.email ?? 'Someone'),
                  householdId: widget.householdId,
                  photoUrl: _photoUrl,
                );
                messenger.hideCurrentSnackBar();
                final controller = messenger.showSnackBar(
                  SnackBar(
                    content: const Text('Task completed!'),
                    duration: const Duration(seconds: 3),
                    action: SnackBarAction(
                      label: 'Undo',
                      onPressed: () {
                        FirestoreService().uncompleteTask(doc.id);
                      },
                    ),
                  ),
                );
                Future.delayed(
                  const Duration(seconds: 4),
                  controller.close,
                );
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
                            : categoryColor.withValues(alpha: 0.15),
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
                      DifficultyBadge(difficulty, dimmed: completed),
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
                      RecurringBadge(recurrenceFrequency),
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
                  color: completed
                      ? Colors.grey.shade400
                      : isOverdue
                          ? Colors.red
                          : Colors.orange,
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
                    color: Colors.green.withValues(alpha: 0.12),
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
              icon: const Icon(Icons.edit_outlined, color: Colors.grey),
              tooltip: 'Edit Task',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EditTaskScreen(
                      docId: doc.id,
                      taskData: data,
                      householdId: widget.householdId,
                    ),
                  ),
                );
              },
            ),
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

}
