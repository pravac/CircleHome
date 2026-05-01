import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import 'create_household_screen.dart';
import 'join_household_screen.dart';
import 'task_feed_screen.dart';
import 'profile_screen.dart';
import 'package:flutter/services.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  void _navigateToAllTasks(BuildContext context, String householdId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TaskFeedScreen(householdId: householdId),
      ),
    );
  }

  void _navigateToProfile(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ProfileScreen()),
    );
  }

  String _formatRelativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

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

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirestoreService().getUserStream(currentUser.uid),
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final userData = userSnapshot.data?.data();
        final householdId = userData?['householdId'] as String?;
        final userName = userData?['name'] as String? ??
            currentUser.email?.split('@').first ??
            'Member';
        final photoUrl = userData?['photoUrl'] as String? ?? '';

        if (householdId == null || householdId.isEmpty) {
          return _buildNoHouseholdScreen(context);
        }

        return Scaffold(
          backgroundColor: const Color(0xFFF4F6FB),
          bottomNavigationBar: isWide
              ? null
              : NavigationBar(
                  selectedIndex: 0,
                  onDestinationSelected: (index) {
                    if (index == 1) _navigateToAllTasks(context, householdId);
                    if (index == 2) _navigateToProfile(context);
                    if (index == 3) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Settings coming soon'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                  destinations: const [
                    NavigationDestination(
                      icon: Icon(Icons.home_outlined),
                      selectedIcon: Icon(Icons.home),
                      label: 'Home',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.checklist_outlined),
                      selectedIcon: Icon(Icons.checklist),
                      label: 'All Tasks',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.person_outline),
                      selectedIcon: Icon(Icons.person),
                      label: 'Profile',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.settings_outlined),
                      selectedIcon: Icon(Icons.settings),
                      label: 'Settings',
                    ),
                  ],
                ),
          body: SafeArea(
            child: Row(
              children: [
                if (isWide) _buildSidebar(context, householdId),
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
                            _buildHeader(context),
                            const SizedBox(height: 16),
                            _buildHouseholdCard(context, householdId),
                            const SizedBox(height: 24),
                            _buildSummaryCards(householdId, userName),
                            const SizedBox(height: 28),
                            _buildTasksSection(context, householdId, userName, photoUrl),
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

  Widget _buildNoHouseholdScreen(BuildContext context) {
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
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              Text(
                'You are not currently in a household. Create one or join one using an invite code.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade700, fontSize: 16),
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

  Widget _buildHeader(BuildContext context) {
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
        if (!householdSnapshot.hasData) return const SizedBox();

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

  Widget _buildSummaryCards(String householdId, String userName) {
    final service = FirestoreService();

    return StreamBuilder<QuerySnapshot>(
      stream: service.getTasks(householdId),
      builder: (context, taskSnapshot) {
        final allDocs = taskSnapshot.data?.docs ?? [];
        final allOpenCount = allDocs.length;
        final myOpenCount = allDocs.where((d) {
          final data = d.data() as Map<String, dynamic>;
          return data['assignedTo'] == userName;
        }).length;

        return StreamBuilder<QuerySnapshot>(
          stream: service.getActivities(householdId),
          builder: (context, activitySnapshot) {
            final activityCount = activitySnapshot.data?.docs.length ?? 0;

            return Row(
              children: [
                Expanded(
                  child: _SummaryCard(
                    myOpenCount.toString(),
                    "My Tasks",
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _SummaryCard(
                    allOpenCount.toString(),
                    "Open Tasks",
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _SummaryCard(
                    activityCount.toString(),
                    "Activity",
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

  Widget _buildTasksSection(
    BuildContext context,
    String householdId,
    String userName,
    String photoUrl,
  ) {
    final service = FirestoreService();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                "My Tasks",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            TextButton.icon(
              onPressed: () => _navigateToAllTasks(context, householdId),
              icon: const Icon(Icons.list_alt, size: 16),
              label: const Text('All Tasks'),
            ),
          ],
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

            final allDocs = snapshot.data?.docs ?? [];
            final myDocs = allDocs.where((d) {
              final data = d.data() as Map<String, dynamic>;
              return data['assignedTo'] == userName;
            }).toList();

            myDocs.sort((a, b) {
              final aData = a.data() as Map<String, dynamic>;
              final bData = b.data() as Map<String, dynamic>;
              final aTime = aData['dueDateTime'] as Timestamp?;
              final bTime = bData['dueDateTime'] as Timestamp?;
              if (aTime == null && bTime == null) return 0;
              if (aTime == null) return 1;
              if (bTime == null) return -1;
              return aTime.compareTo(bTime);
            });

            if (myDocs.isEmpty) {
              return Container(
                width: double.infinity,
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
                      size: 48,
                      color: Colors.grey.shade300,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No tasks assigned to you',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Tap "All Tasks" to see household tasks.',
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: myDocs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return _taskTile(
                  context: context,
                  docId: doc.id,
                  data: data,
                  householdId: householdId,
                  userName: userName,
                  photoUrl: photoUrl,
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
    required Map<String, dynamic> data,
    required String householdId,
    required String userName,
    String photoUrl = '',
  }) {
    final title = data['title'] as String? ?? 'Untitled Task';
    final category = data['category'] as String? ?? 'Other';
    final assignedTo = data['assignedTo'] as String? ?? 'Unknown User';
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
                      userName: userName,
                      householdId: householdId,
                      photoUrl: photoUrl,
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Task completed!'),
                          duration: const Duration(seconds: 4),
                          action: SnackBarAction(
                            label: 'Undo',
                            onPressed: () async {
                              await FirestoreService().uncompleteTask(docId);
                            },
                          ),
                        ),
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
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
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
                    if (difficulty > 0) ...[
                      const SizedBox(width: 4),
                      _difficultyBadge(difficulty),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      assignedTo,
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    if (isRecurring &&
                        recurrenceFrequency.isNotEmpty &&
                        recurrenceFrequency != 'none') ...[
                      const SizedBox(width: 8),
                      _recurringBadge(recurrenceFrequency),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Text(
            dueLabel,
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
                final createdAt = data['createdAt'] as Timestamp?;
                final timeLabel = createdAt != null
                    ? _formatRelativeTime(createdAt.toDate())
                    : (data['timeLabel'] as String? ?? '');
                final actorPhotoUrl = data['actorPhotoUrl'] as String? ?? '';
                return _ActivityTile(text, timeLabel, actorPhotoUrl);
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
    int selectedDifficulty = 3;
    bool isRecurring = false;
    String recurrenceFrequency = 'Weekly';

    final categories = ['Cleaning', 'Groceries', 'Laundry', 'Bills', 'Other'];
    final frequencies = ['Daily', 'Weekly', 'Monthly'];

    Color difficultyColor(int d) {
      const colors = [
        Colors.green,
        Color(0xFF8BC34A),
        Colors.orange,
        Colors.deepOrange,
        Colors.red,
      ];
      return colors[(d - 1).clamp(0, 4)];
    }

    String difficultyLabel(int d) {
      switch (d) {
        case 1:
          return 'Very Easy';
        case 2:
          return 'Easy';
        case 3:
          return 'Moderate';
        case 4:
          return 'Hard';
        case 5:
          return 'Very Hard';
        default:
          return '';
      }
    }

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
                setDialogState(() => selectedDate = picked);
              }
            }

            Future<void> pickTime() async {
              final picked = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.now(),
              );
              if (picked != null) {
                setDialogState(() => selectedTime = picked);
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

                    return SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
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
                            items: categories
                                .map((c) => DropdownMenuItem(
                                      value: c,
                                      child: Text(c),
                                    ))
                                .toList(),
                            onChanged: (v) =>
                                setDialogState(() => selectedCategory = v),
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
                            items: memberNames
                                .map((m) => DropdownMenuItem(
                                      value: m,
                                      child: Text(m),
                                    ))
                                .toList(),
                            onChanged: (v) =>
                                setDialogState(() => selectedAssignee = v),
                          ),
                          const SizedBox(height: 20),

                          Text(
                            'Difficulty',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: List.generate(5, (i) {
                              final d = i + 1;
                              final isSelected = selectedDifficulty == d;
                              final color = difficultyColor(d);
                              return GestureDetector(
                                onTap: () => setDialogState(
                                    () => selectedDifficulty = d),
                                child: Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? color
                                        : color.withOpacity(0.12),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      '$d',
                                      style: TextStyle(
                                        color: isSelected
                                            ? Colors.white
                                            : color,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                          const SizedBox(height: 4),
                          Center(
                            child: Text(
                              difficultyLabel(selectedDifficulty),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  'Recurring Task',
                                  style: TextStyle(fontSize: 15),
                                ),
                              ),
                              Switch(
                                value: isRecurring,
                                onChanged: (v) =>
                                    setDialogState(() => isRecurring = v),
                              ),
                            ],
                          ),

                          if (isRecurring) ...[
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              value: recurrenceFrequency,
                              decoration: const InputDecoration(
                                labelText: 'Repeat',
                                border: OutlineInputBorder(),
                              ),
                              items: frequencies
                                  .map((f) => DropdownMenuItem(
                                        value: f,
                                        child: Text(f),
                                      ))
                                  .toList(),
                              onChanged: (v) => setDialogState(
                                  () => recurrenceFrequency = v ?? 'Weekly'),
                            ),
                          ],
                        ],
                      ),
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
                        const SnackBar(
                            content: Text('Please select a category')),
                      );
                      return;
                    }
                    if (selectedDate == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Please select a due date')),
                      );
                      return;
                    }
                    if (selectedAssignee == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Please select an assignee')),
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
                    final day = selectedDate!.day.toString().padLeft(2, '0');
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
                      difficulty: selectedDifficulty,
                      isRecurring: isRecurring,
                      recurrenceFrequency:
                          isRecurring ? recurrenceFrequency : 'none',
                    );

                    if (dialogContext.mounted) {
                      Navigator.of(dialogContext).pop();
                    }
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Task added!')),
                      );
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

  Widget _difficultyBadge(int difficulty) {
    const colors = [
      Colors.green,
      Color(0xFF8BC34A),
      Colors.orange,
      Colors.deepOrange,
      Colors.red,
    ];
    final color = colors[(difficulty - 1).clamp(0, 4)];
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

  Widget _buildSidebar(BuildContext context, String householdId) {
    return Container(
      width: 90,
      color: Colors.white,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.home, size: 30, color: Colors.blue),
          const SizedBox(height: 30),
          IconButton(
            icon: const Icon(Icons.checklist),
            tooltip: 'All Tasks',
            onPressed: () => _navigateToAllTasks(context, householdId),
          ),
          const SizedBox(height: 30),
          IconButton(
            icon: const Icon(Icons.emoji_events_outlined),
            tooltip: 'Leaderboard',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Leaderboard coming soon'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
          const SizedBox(height: 30),
          IconButton(
            icon: const Icon(Icons.person_outline),
            tooltip: 'Profile',
            onPressed: () => _navigateToProfile(context),
          ),
          const SizedBox(height: 30),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Settings coming soon'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
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
  final String photoUrl;

  const _ActivityTile(this.text, this.time, this.photoUrl);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage:
              photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
          child: photoUrl.isEmpty ? const Icon(Icons.person) : null,
        ),
        title: Text(text),
        trailing: Text(time),
      ),
    );
  }
}
