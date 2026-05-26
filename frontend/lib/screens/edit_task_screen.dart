import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../theme.dart';

class EditTaskScreen extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> taskData;
  final String householdId;

  const EditTaskScreen({
    super.key,
    required this.docId,
    required this.taskData,
    required this.householdId,
  });

  @override
  State<EditTaskScreen> createState() => _EditTaskScreenState();
}

class _EditTaskScreenState extends State<EditTaskScreen> {
  late final TextEditingController _titleController;
  String? _selectedCategory;
  String? _selectedAssignee;
  late DateTime _selectedDate;
  TimeOfDay? _selectedTime;
  late int _selectedDifficulty;
  late bool _isRecurring;
  late String _recurrenceFrequency;
  bool _saving = false;

  static const _categories = ['Cleaning', 'Groceries', 'Laundry', 'Bills', 'Other'];
  static const _frequencies = [
    'Daily',
    'Every Other Day',
    'Weekly',
    'Biweekly',
    'Monthly',
    'Every 3 Months',
    'Yearly',
  ];

  @override
  void initState() {
    super.initState();
    final d = widget.taskData;
    _titleController = TextEditingController(text: d['title'] as String? ?? '');
    _selectedCategory = d['category'] as String?;
    _selectedAssignee = d['assignedTo'] as String?;
    _selectedDifficulty = (d['difficulty'] as int?) ?? 3;
    _isRecurring = d['isRecurring'] as bool? ?? false;
    final freq = d['recurrenceFrequency'] as String? ?? 'Weekly';
    _recurrenceFrequency = (freq == 'none' || freq.isEmpty) ? 'Weekly' : freq;

    final ts = d['dueDateTime'];
    final dt = ts is Timestamp ? ts.toDate() : DateTime.now();
    _selectedDate = dt;
    if (dt.hour != 0 || dt.minute != 0) {
      _selectedTime = TimeOfDay(hour: dt.hour, minute: dt.minute);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Color _difficultyColor(int d) => AppColors.difficulty(d);

  String _difficultyLabel(int d) {
    const labels = ['Very Easy', 'Easy', 'Moderate', 'Hard', 'Very Hard'];
    return labels[(d - 1).clamp(0, 4)];
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Task title is required')),
      );
      return;
    }
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category')),
      );
      return;
    }
    if (_selectedAssignee == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an assignee')),
      );
      return;
    }

    setState(() => _saving = true);

    final dueDateTime = _selectedTime != null
        ? DateTime(
            _selectedDate.year,
            _selectedDate.month,
            _selectedDate.day,
            _selectedTime!.hour,
            _selectedTime!.minute,
          )
        : DateTime(
            _selectedDate.year,
            _selectedDate.month,
            _selectedDate.day,
          );

    final month = _selectedDate.month.toString().padLeft(2, '0');
    final day = _selectedDate.day.toString().padLeft(2, '0');
    final year = _selectedDate.year.toString();
    final dueLabel = _selectedTime != null
        ? '$month/$day/$year • ${_selectedTime!.format(context)}'
        : '$month/$day/$year';

    await FirestoreService().updateTask(
      docId: widget.docId,
      title: title,
      category: _selectedCategory!,
      assignedTo: _selectedAssignee!,
      dueLabel: dueLabel,
      dueDateTime: dueDateTime,
      difficulty: _selectedDifficulty,
      isRecurring: _isRecurring,
      recurrenceFrequency: _isRecurring ? _recurrenceFrequency : 'none',
    );

    if (!mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Task updated!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Edit Task'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: const Text(
              'Save',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirestoreService().getHouseholdMembers(widget.householdId),
        builder: (context, snapshot) {
          final memberDocs = snapshot.data?.docs ?? [];
          final memberNames = memberDocs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final name = (data['name'] as String?)?.trim();
            final email = (data['email'] as String?)?.trim();
            return (name != null && name.isNotEmpty) ? name : (email ?? 'Member');
          }).toList();

          if (_selectedAssignee != null && !memberNames.contains(_selectedAssignee)) {
            memberNames.add(_selectedAssignee!);
          }

          final assigneeValue =
              memberNames.contains(_selectedAssignee) ? _selectedAssignee : null;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _card([
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Task Title',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(),
                    ),
                    items: _categories
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedCategory = v),
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: _pickDate,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Due Date',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.calendar_today, size: 18),
                      ),
                      child: Text(
                        '${_selectedDate.month.toString().padLeft(2, '0')}/${_selectedDate.day.toString().padLeft(2, '0')}/${_selectedDate.year}',
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: _pickTime,
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Due Time (optional)',
                        border: const OutlineInputBorder(),
                        suffixIcon: _selectedTime != null
                            ? GestureDetector(
                                onTap: () => setState(() => _selectedTime = null),
                                child: const Icon(Icons.clear, size: 18),
                              )
                            : const Icon(Icons.access_time, size: 18),
                      ),
                      child: Text(
                        _selectedTime == null
                            ? 'No time set'
                            : _selectedTime!.format(context),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: assigneeValue,
                    decoration: const InputDecoration(
                      labelText: 'Assign To',
                      border: OutlineInputBorder(),
                    ),
                    items: memberNames
                        .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedAssignee = v),
                  ),
                ]),
                const SizedBox(height: 16),
                _card([
                  Text(
                    'Difficulty',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(5, (i) {
                      final d = i + 1;
                      final isSelected = _selectedDifficulty == d;
                      final color = _difficultyColor(d);
                      return GestureDetector(
                        onTap: () => setState(() => _selectedDifficulty = d),
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
                  const SizedBox(height: 6),
                  Center(
                    child: Text(
                      _difficultyLabel(_selectedDifficulty),
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                    ),
                  ),
                ]),
                const SizedBox(height: 16),
                _card([
                  Row(
                    children: [
                      const Expanded(
                        child: Text('Recurring Task', style: TextStyle(fontSize: 15)),
                      ),
                      Switch(
                        value: _isRecurring,
                        onChanged: (v) => setState(() => _isRecurring = v),
                      ),
                    ],
                  ),
                  if (_isRecurring) ...[
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _recurrenceFrequency,
                      decoration: const InputDecoration(
                        labelText: 'Repeat',
                        border: OutlineInputBorder(),
                      ),
                      items: _frequencies
                          .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                          .toList(),
                      onChanged: (v) =>
                          setState(() => _recurrenceFrequency = v ?? 'Weekly'),
                    ),
                  ],
                ]),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _saving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Save Changes',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _card(List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}
