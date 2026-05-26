import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../theme.dart';

Future<void> showAddTaskDialog(
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
  List<String> memberNames = [];

  const categories = ['Cleaning', 'Groceries', 'Laundry', 'Bills', 'Other'];
  const frequencies = [
    'Daily', 'Every Other Day', 'Weekly', 'Biweekly',
    'Monthly', 'Every 3 Months', 'Yearly',
  ];

  String difficultyLabel(int d) {
    switch (d) {
      case 1: return 'Very Easy';
      case 2: return 'Easy';
      case 3: return 'Moderate';
      case 4: return 'Hard';
      case 5: return 'Very Hard';
      default: return '';
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
            if (picked != null) setDialogState(() => selectedDate = picked);
          }

          Future<void> pickTime() async {
            final picked = await showTimePicker(
              context: context,
              initialTime: TimeOfDay.now(),
            );
            if (picked != null) setDialogState(() => selectedTime = picked);
          }

          return AlertDialog(
            title: const Text('Add Task'),
            content: SizedBox(
              width: 420,
              child: StreamBuilder<QuerySnapshot>(
                stream: FirestoreService().getHouseholdMembers(householdId),
                builder: (context, snapshot) {
                  final memberDocs = snapshot.data?.docs ?? [];
                  memberNames = memberDocs.map((doc) {
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
                              .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                              .toList(),
                          onChanged: (v) => setDialogState(() => selectedCategory = v),
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
                          items: [
                            const DropdownMenuItem(
                              value: '__auto__',
                              child: Row(
                                children: [
                                  Icon(Icons.auto_awesome, size: 16, color: AppColors.primary),
                                  SizedBox(width: 8),
                                  Text('Auto-assign'),
                                ],
                              ),
                            ),
                            const DropdownMenuItem(
                              value: '__all__',
                              child: Row(
                                children: [
                                  Icon(Icons.group, size: 16, color: Color(0xFF43A047)),
                                  SizedBox(width: 8),
                                  Text('Assign to All'),
                                ],
                              ),
                            ),
                            ...memberNames.map((m) => DropdownMenuItem(value: m, child: Text(m))),
                          ],
                          onChanged: (v) => setDialogState(() => selectedAssignee = v),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Difficulty',
                          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: List.generate(5, (i) {
                            final d = i + 1;
                            final isSelected = selectedDifficulty == d;
                            final color = AppColors.difficulty(d);
                            return GestureDetector(
                              onTap: () => setDialogState(() => selectedDifficulty = d),
                              child: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: isSelected ? color : color.withValues(alpha: 0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    '$d',
                                    style: TextStyle(
                                      color: isSelected ? Colors.white : color,
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
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            const Expanded(
                              child: Text('Recurring Task', style: TextStyle(fontSize: 15)),
                            ),
                            Switch(
                              value: isRecurring,
                              onChanged: (v) => setDialogState(() => isRecurring = v),
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
                                .map((f) => DropdownMenuItem(value: f, child: Text(f)))
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
                      ? DateTime(selectedDate!.year, selectedDate!.month, selectedDate!.day,
                          selectedTime!.hour, selectedTime!.minute)
                      : DateTime(selectedDate!.year, selectedDate!.month, selectedDate!.day);

                  final month = selectedDate!.month.toString().padLeft(2, '0');
                  final day = selectedDate!.day.toString().padLeft(2, '0');
                  final year = selectedDate!.year.toString();
                  final dueLabel = selectedTime != null
                      ? '$month/$day/$year • ${selectedTime!.format(context)}'
                      : '$month/$day/$year';

                  if (selectedAssignee == '__all__') {
                    if (memberNames.isEmpty) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('No members found in household')),
                        );
                      }
                      return;
                    }
                    for (final member in memberNames) {
                      await FirestoreService().addTask(
                        title: title,
                        category: selectedCategory!,
                        assignedTo: member,
                        householdId: householdId,
                        dueLabel: dueLabel,
                        dueDateTime: dueDateTime,
                        difficulty: selectedDifficulty,
                        isRecurring: isRecurring,
                        recurrenceFrequency: isRecurring ? recurrenceFrequency : 'none',
                      );
                    }
                  } else {
                    String resolvedAssignee = selectedAssignee!;
                    if (selectedAssignee == '__auto__') {
                      final assigned = await FirestoreService().autoAssignTask(
                        householdId: householdId,
                        taskDifficulty: selectedDifficulty,
                      );
                      if (assigned == null) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Could not auto-assign: no members found')),
                          );
                        }
                        return;
                      }
                      resolvedAssignee = assigned;
                    }
                    await FirestoreService().addTask(
                      title: title,
                      category: selectedCategory!,
                      assignedTo: resolvedAssignee,
                      householdId: householdId,
                      dueLabel: dueLabel,
                      dueDateTime: dueDateTime,
                      difficulty: selectedDifficulty,
                      isRecurring: isRecurring,
                      recurrenceFrequency: isRecurring ? recurrenceFrequency : 'none',
                    );
                  }

                  if (dialogContext.mounted) Navigator.of(dialogContext).pop();
                  if (context.mounted) {
                    final msg = selectedAssignee == '__all__'
                        ? 'Task assigned to all ${memberNames.length} members!'
                        : 'Task added!';
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(msg)),
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
