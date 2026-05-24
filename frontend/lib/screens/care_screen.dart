import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../theme.dart';

const _categories = ['General', 'Medication', 'Appointment', 'Emergency'];

const _categoryColors = {
  'General': Color(0xFF4CAF50),
  'Medication': Color(0xFF9C27B0),
  'Appointment': Color(0xFF2196F3),
  'Emergency': Color(0xFFF44336),
};

const _categoryIcons = {
  'General': Icons.note_outlined,
  'Medication': Icons.medication_outlined,
  'Appointment': Icons.calendar_today_outlined,
  'Emergency': Icons.emergency_outlined,
};

Future<void> showAddCareNoteSheet(BuildContext context, String householdId) {
  return _showCareNoteBottomSheet(context, householdId);
}

Future<void> _showCareNoteBottomSheet(
  BuildContext context,
  String householdId,
) async {
  final titleController = TextEditingController();
  final descController = TextEditingController();
  final aboutController = TextEditingController();
  String selectedCategory = 'General';
  bool saving = false;

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetCtx) {
      return StatefulBuilder(
        builder: (ctx, setSheetState) {
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Add Care Note',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 20),
                    Wrap(
                      spacing: 8,
                      children: _categories.map((cat) {
                        final color = _categoryColors[cat]!;
                        final selected = selectedCategory == cat;
                        return GestureDetector(
                          onTap: () => setSheetState(() => selectedCategory = cat),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: selected ? color : color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _categoryIcons[cat],
                                  size: 14,
                                  color: selected ? Colors.white : color,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  cat,
                                  style: TextStyle(
                                    color: selected ? Colors.white : color,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        labelText: 'Title',
                        hintText: 'e.g. Medication given',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Details',
                        hintText: 'Any additional notes...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: aboutController,
                      decoration: InputDecoration(
                        labelText: 'About (optional)',
                        hintText: 'Who is this note about?',
                        prefixIcon: const Icon(Icons.person_outline),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: saving
                            ? null
                            : () async {
                                final title = titleController.text.trim();
                                if (title.isEmpty) {
                                  ScaffoldMessenger.of(ctx).showSnackBar(
                                    const SnackBar(content: Text('Title is required')),
                                  );
                                  return;
                                }
                                setSheetState(() => saving = true);

                                final uid = FirebaseAuth.instance.currentUser?.uid;
                                String userName = '';
                                String photoUrl = '';
                                if (uid != null) {
                                  final doc = await FirestoreService().getUserDocument(uid);
                                  final data = doc.data();
                                  if (data != null) {
                                    final name = data['name'] as String?;
                                    final email = FirebaseAuth.instance.currentUser?.email ?? '';
                                    userName = (name != null && name.isNotEmpty)
                                        ? name
                                        : email.split('@').first;
                                    photoUrl = data['photoUrl'] as String? ?? '';
                                  }
                                }

                                await FirestoreService().addCareNote(
                                  householdId: householdId,
                                  title: title,
                                  description: descController.text.trim(),
                                  category: selectedCategory,
                                  aboutName: aboutController.text.trim(),
                                  authorName: userName,
                                  authorPhotoUrl: photoUrl,
                                );
                                if (sheetCtx.mounted) Navigator.of(sheetCtx).pop();
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: saving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Text(
                                'Save Note',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

class CareScreen extends StatefulWidget {
  final String householdId;

  const CareScreen({super.key, required this.householdId});

  @override
  State<CareScreen> createState() => _CareScreenState();
}

class _CareScreenState extends State<CareScreen> {
  String _formatTime(Timestamp? ts) {
    if (ts == null) return '';
    final dt = ts.toDate();
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${(diff.inDays / 7).floor()}w ago';
  }

  void _showAddSheet() {
    showAddCareNoteSheet(context, widget.householdId);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.householdId.isEmpty) {
      return const Scaffold(
        backgroundColor: Color(0xFFF4F6FB),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Care Diary',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w700, fontSize: 20),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirestoreService().getCareNotes(widget.householdId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = [...(snapshot.data?.docs ?? [])]
            ..sort((a, b) {
              final aTs = (a.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
              final bTs = (b.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
              if (aTs == null && bTs == null) return 0;
              if (aTs == null) return 1;
              if (bTs == null) return -1;
              return bTs.compareTo(aTs);
            });

          if (docs.isEmpty) {
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
                    Icon(Icons.favorite_outline, size: 56, color: Colors.grey.shade300),
                    const SizedBox(height: 16),
                    Text(
                      'No care notes yet',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Tap "Add Note" to log a care entry.',
                      style: TextStyle(color: Colors.grey.shade400),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: _showAddSheet,
                      icon: const Icon(Icons.add),
                      label: const Text('Add First Note'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final doc = docs[i];
              final data = doc.data() as Map<String, dynamic>;
              final title = data['title'] as String? ?? '';
              final description = data['description'] as String? ?? '';
              final category = data['category'] as String? ?? 'General';
              final aboutName = data['aboutName'] as String? ?? '';
              final authorName = data['authorName'] as String? ?? '';
              final authorPhoto = data['authorPhotoUrl'] as String? ?? '';
              final createdAt = data['createdAt'] as Timestamp?;
              final color = _categoryColors[category] ?? const Color(0xFF4CAF50);
              final icon = _categoryIcons[category] ?? Icons.note_outlined;

              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: category == 'Emergency'
                      ? Border.all(color: Colors.red.withValues(alpha: 0.4), width: 1.5)
                      : null,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(icon, size: 13, color: color),
                              const SizedBox(width: 5),
                              Text(
                                category,
                                style: TextStyle(
                                  color: color,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        Text(
                          _formatTime(createdAt),
                          style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          tooltip: 'Delete',
                          onPressed: () async {
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Delete Note'),
                                content: const Text(
                                  'Are you sure you want to delete this care note?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(ctx).pop(false),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.of(ctx).pop(true),
                                    child: const Text(
                                      'Delete',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ],
                              ),
                            );
                            if (confirmed == true) {
                              await FirestoreService().deleteCareNote(doc.id);
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                    ),
                    if (description.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        description,
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 12,
                          backgroundImage:
                              authorPhoto.isNotEmpty ? NetworkImage(authorPhoto) : null,
                          backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                          child: authorPhoto.isEmpty
                              ? Text(
                                  authorName.isNotEmpty ? authorName[0].toUpperCase() : '?',
                                  style: const TextStyle(fontSize: 10, color: Color(0xFF5B8DEF)),
                                )
                              : null,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          authorName,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (aboutName.isNotEmpty) ...[
                          Text(
                            ' · About ',
                            style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                          ),
                          Text(
                            aboutName,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
