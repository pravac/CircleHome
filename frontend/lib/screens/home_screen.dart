import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import 'create_household_screen.dart';
import 'join_household_screen.dart';
import 'task_feed_screen.dart';
import 'package:flutter/services.dart';

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

        if (householdId == null || householdId.isEmpty) {
          return Scaffold(
            backgroundColor: const Color(0xFFF4F6FB),
            body: Center(
              child: Container(
                width: 520,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Welcome to CircleHome',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'You are not currently in a household. Create one or join one using an invite code.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 28),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              final created = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const CreateHouseholdScreen(),
                                ),
                              );

                              if (created == true && context.mounted) {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const HomeScreen(),
                                  ),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Text('Create Household'),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              final joined = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const JoinHouseholdScreen(),
                                ),
                              );

                              if (joined == true && context.mounted) {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const HomeScreen(),
                                  ),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Text('Join Household'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
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
                            const SizedBox(height: 16),
                            _buildHouseholdCard(context, householdId),
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
          backgroundImage: AssetImage('lib/assets/images/CircleHomeLogo.png'),
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

  Widget _buildHouseholdCard(BuildContext context, String householdId) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: FirestoreService().getHousehold(householdId),
      builder: (context, householdSnapshot) {
        if (!householdSnapshot.hasData) {
          return const SizedBox();
        }

        final householdData = householdSnapshot.data!;
        final name = householdData['name'] ?? 'Household';
        final code = householdData['code'] ?? '';

        return StreamBuilder<QuerySnapshot>(
          stream: FirestoreService().getHouseholdMembers(householdId),
          builder: (context, memberSnapshot) {
            final memberDocs = memberSnapshot.data?.docs ?? [];
            final memberCount = memberDocs.length;

            return Container(
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
                      Expanded(
                        child: Text(
                          name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          final created = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const CreateHouseholdScreen(),
                            ),
                          );

                          if (created == true && context.mounted) {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const HomeScreen(),
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                        ),
                        child: const Text('Create New'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () async {
                          final joined = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const JoinHouseholdScreen(),
                            ),
                          );

                          if (joined == true && context.mounted) {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const HomeScreen(),
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                        ),
                        child: const Text('Join'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  Row(
                    children: [
                      Text(
                        'Invite Code: $code',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.copy, size: 18),
                        tooltip: 'Copy code',
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: code));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Invite code copied!'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 6),
                  Text(
                    '$memberCount member${memberCount == 1 ? '' : 's'} in household',
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 15,
                    ),
                  ),

                  const SizedBox(height: 14),

                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: memberDocs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final displayName =
                          (data['name'] as String?)?.trim().isNotEmpty == true
                              ? data['name'] as String
                              : (data['email'] as String? ?? 'Member');

                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF4F6FB),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircleAvatar(
                              radius: 14,
                              child: Icon(Icons.person, size: 16),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              displayName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            );
          },
        );
      },
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
        Builder(
          builder: (context) => Row(
            children: [
              const Expanded(
                child: Text(
                  "My Tasks",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              TextButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        TaskFeedScreen(householdId: householdId),
                  ),
                ),
                icon: const Icon(Icons.list_alt, size: 16),
                label: const Text('View All'),
              ),
            ],
          ),
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
                final category = data['category'] as String? ?? 'Other';
                final assignedTo =
                    data['assignedTo'] as String? ?? 'Unknown User';
                final dueLabel = data['dueLabel'] as String? ?? '';
                final completed = data['completed'] as bool? ?? false;

                return _taskTile(
                  context: context,
                  docId: doc.id,
                  title: title,
                  category: category,
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
    required String category,
    required String user,
    required String time,
    required bool completed,
    required String householdId,
  }) {
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
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // 🔥 CATEGORY TAG
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: categoryColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        category,
                        style: TextStyle(
                          color: categoryColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
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

    String? selectedCategory;
    String? selectedAssignee;
    DateTime? selectedDate;
    TimeOfDay? selectedTime;

    final categories = ['Cleaning', 'Groceries', 'Laundry', 'Bills', 'Other'];

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> pickDate() async {
              final picked = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime.now().subtract(const Duration(days: 1)),
                lastDate: DateTime(2100),
              );

              if (picked != null) {
                setDialogState(() {
                  selectedDate = picked;
                });
              }
            }

            Future<void> pickTime() async {
              final picked = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.now(),
              );

              if (picked != null) {
                setDialogState(() {
                  selectedTime = picked;
                });
              }
            }

            return AlertDialog(
              title: const Text('Add Task'),
              content: SizedBox(
                width: 420,
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirestoreService().getHouseholdMembers(householdId),
                  builder: (context, snapshot) {
                    final memberDocs = snapshot.data?.docs ?? [];

                    final memberNames = memberDocs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final name = (data['name'] as String?)?.trim();
                      final email = (data['email'] as String?)?.trim();

                      if (name != null && name.isNotEmpty) return name;
                      return email ?? 'Member';
                    }).toList();

                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: titleController,
                          decoration: const InputDecoration(
                            labelText: 'Task Title',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),

                        DropdownButtonFormField<String>(
                          value: selectedCategory,
                          decoration: const InputDecoration(
                            labelText: 'Category',
                            border: OutlineInputBorder(),
                          ),
                          items: categories.map((category) {
                            return DropdownMenuItem(
                              value: category,
                              child: Text(category),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setDialogState(() {
                              selectedCategory = value;
                            });
                          },
                        ),
                        const SizedBox(height: 16),

                        InkWell(
                          onTap: pickDate,
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Due Date',
                              border: OutlineInputBorder(),
                            ),
                            child: Text(
                              selectedDate == null
                                  ? 'Select date'
                                  : '${selectedDate!.month.toString().padLeft(2, '0')}/${selectedDate!.day.toString().padLeft(2, '0')}/${selectedDate!.year}',
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),

                        InkWell(
                          onTap: pickTime,
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Due Time',
                              border: OutlineInputBorder(),
                            ),
                            child: Text(
                              selectedTime == null
                                  ? 'Select time'
                                  : selectedTime!.format(context),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        DropdownButtonFormField<String>(
                          value: selectedAssignee,
                          decoration: const InputDecoration(
                            labelText: 'Assign To',
                            border: OutlineInputBorder(),
                          ),
                          items: memberNames.map((member) {
                            return DropdownMenuItem(
                              value: member,
                              child: Text(member),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setDialogState(() {
                              selectedAssignee = value;
                            });
                          },
                        ),
                      ],
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final title = titleController.text.trim();

                    if (title.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Task title is required')),
                      );
                      return;
                    }

                    if (selectedCategory == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please select a category')),
                      );
                      return;
                    }

                    if (selectedDate == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please select a due date')),
                      );
                      return;
                    }

                    if (selectedAssignee == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please select an assignee')),
                      );
                      return;
                    }

                    final dueDateTime = selectedTime != null
                      ? DateTime(
                          selectedDate!.year,
                          selectedDate!.month,
                          selectedDate!.day,
                          selectedTime!.hour,
                          selectedTime!.minute,
                        )
                      : DateTime(
                          selectedDate!.year,
                          selectedDate!.month,
                          selectedDate!.day,
                        );

                    final month =
                        selectedDate!.month.toString().padLeft(2, '0');
                    final day =
                        selectedDate!.day.toString().padLeft(2, '0');
                    final year = selectedDate!.year.toString();
                    final dueLabel = selectedTime != null
                      ? '$month/$day/$year • ${selectedTime!.format(context)}'
                      : '$month/$day/$year';

                    await FirestoreService().addTask(
                      title: title,
                      category: selectedCategory!,
                      assignedTo: selectedAssignee!,
                      householdId: householdId,
                      dueLabel: dueLabel,
                      dueDateTime: dueDateTime,
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
      },
    );
  }

  Widget _buildSidebar() {
    return Builder(
      builder: (context) {
        final householdFuture = FirestoreService().getHouseholdIdForUser(
          FirebaseAuth.instance.currentUser!.uid,
        );

        return Container(
          width: 90,
          color: Colors.white,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.home, size: 30),
              const SizedBox(height: 30),
              FutureBuilder<String?>(
                future: householdFuture,
                builder: (context, snap) => IconButton(
                  icon: const Icon(Icons.check_box),
                  tooltip: 'All Tasks',
                  onPressed: snap.data != null && snap.data!.isNotEmpty
                      ? () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  TaskFeedScreen(householdId: snap.data!),
                            ),
                          )
                      : null,
                ),
              ),
              const SizedBox(height: 30),
              const Icon(Icons.favorite),
              const SizedBox(height: 30),
              const Icon(Icons.people),
              const SizedBox(height: 30),
              const Icon(Icons.settings),
            ],
          ),
        );
      },
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