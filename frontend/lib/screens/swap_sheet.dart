import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/firestore_service.dart';

enum _SwapStep { chooseType, chooseMember, chooseTask }

enum _SwapType { swap, reassign }

Future<void> showSwapSheet(
  BuildContext context, {
  required String taskId,
  required String taskTitle,
  required String householdId,
  required String currentUserId,
  required String currentUserName,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _SwapSheet(
      taskId: taskId,
      taskTitle: taskTitle,
      householdId: householdId,
      currentUserId: currentUserId,
      currentUserName: currentUserName,
    ),
  );
}

class _SwapSheet extends StatefulWidget {
  final String taskId;
  final String taskTitle;
  final String householdId;
  final String currentUserId;
  final String currentUserName;

  const _SwapSheet({
    required this.taskId,
    required this.taskTitle,
    required this.householdId,
    required this.currentUserId,
    required this.currentUserName,
  });

  @override
  State<_SwapSheet> createState() => _SwapSheetState();
}

class _SwapSheetState extends State<_SwapSheet> {
  _SwapStep _step = _SwapStep.chooseType;
  _SwapType _swapType = _SwapType.reassign;
  String? _selectedMemberId;
  String? _selectedMemberName;
  bool _sending = false;

  Future<void> _sendRequest({
    String? requestTaskId,
    String? requestTaskTitle,
  }) async {
    setState(() => _sending = true);
    try {
      await FirestoreService().createSwapRequest(
        type: _swapType == _SwapType.swap ? 'swap' : 'reassign',
        fromUserId: widget.currentUserId,
        fromUserName: widget.currentUserName,
        toUserId: _selectedMemberId!,
        toUserName: _selectedMemberName!,
        offerTaskId: widget.taskId,
        offerTaskTitle: widget.taskTitle,
        householdId: widget.householdId,
        requestTaskId: requestTaskId,
        requestTaskTitle: requestTaskTitle,
      );
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      final label = _swapType == _SwapType.swap ? 'Swap' : 'Reassign';
      Navigator.of(context).pop();
      messenger.showSnackBar(
        SnackBar(
          content: Text('$label request sent to $_selectedMemberName'),
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _sending = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to send request. Try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: switch (_step) {
            _SwapStep.chooseType => _buildChooseType(),
            _SwapStep.chooseMember => _buildChooseMember(),
            _SwapStep.chooseTask => _buildChooseTask(),
          },
        ),
      ),
    );
  }

  Widget _buildChooseType() {
    return Padding(
      key: const ValueKey('type'),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _handle(),
          const SizedBox(height: 16),
          Text(
            '"${widget.taskTitle}"',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            'What would you like to do with this task?',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          ),
          const SizedBox(height: 20),
          _optionTile(
            icon: Icons.swap_horiz,
            color: const Color(0xFF5B8DEF),
            title: 'Swap Tasks',
            subtitle: 'Trade this task for another member\'s task',
            onTap: () => setState(() {
              _swapType = _SwapType.swap;
              _step = _SwapStep.chooseMember;
            }),
          ),
          const SizedBox(height: 12),
          _optionTile(
            icon: Icons.arrow_forward,
            color: Colors.orange,
            title: 'Reassign',
            subtitle: 'Hand this task off to another member',
            onTap: () => setState(() {
              _swapType = _SwapType.reassign;
              _step = _SwapStep.chooseMember;
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildChooseMember() {
    return Padding(
      key: const ValueKey('member'),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _handle(),
          const SizedBox(height: 16),
          _backRow(
            title: _swapType == _SwapType.swap
                ? 'Who to swap with?'
                : 'Assign to whom?',
            onBack: () => setState(() => _step = _SwapStep.chooseType),
          ),
          const SizedBox(height: 16),
          StreamBuilder<QuerySnapshot>(
            stream:
                FirestoreService().getHouseholdMembers(widget.householdId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              final members = (snapshot.data?.docs ?? [])
                  .where((d) => d.id != widget.currentUserId)
                  .toList();
              if (members.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'No other members in your household.',
                    style: TextStyle(color: Colors.grey.shade500),
                  ),
                );
              }
              return Column(
                children: members.map((d) {
                  final data = d.data() as Map<String, dynamic>;
                  final name = data['name'] as String? ??
                      (data['email'] as String?)?.split('@').first ??
                      'Member';
                  final photoUrl = data['photoUrl'] as String? ?? '';
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor:
                          const Color(0xFF5B8DEF).withValues(alpha: 0.15),
                      backgroundImage: photoUrl.isNotEmpty
                          ? NetworkImage(photoUrl)
                          : null,
                      child: photoUrl.isEmpty
                          ? Text(
                              name.isNotEmpty
                                  ? name[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                color: Color(0xFF5B8DEF),
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : null,
                    ),
                    title: Text(
                      name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    trailing: _sending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.chevron_right),
                    onTap: _sending
                        ? null
                        : () {
                            setState(() {
                              _selectedMemberId = d.id;
                              _selectedMemberName = name;
                              if (_swapType == _SwapType.swap) {
                                _step = _SwapStep.chooseTask;
                              }
                            });
                            if (_swapType == _SwapType.reassign) {
                              _sendRequest();
                            }
                          },
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildChooseTask() {
    return Padding(
      key: const ValueKey('task'),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _handle(),
          const SizedBox(height: 16),
          _backRow(
            title: "${_selectedMemberName ?? ''}'s tasks",
            onBack: () => setState(() => _step = _SwapStep.chooseMember),
          ),
          const SizedBox(height: 4),
          Text(
            'Pick a task to receive in exchange for "${widget.taskTitle}"',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),
          StreamBuilder<QuerySnapshot>(
            stream: FirestoreService().getMemberTasks(
              widget.householdId,
              _selectedMemberName!,
            ),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              final tasks = (snapshot.data?.docs ?? []).where((d) {
                final data = d.data() as Map<String, dynamic>;
                return data['completed'] != true;
              }).toList();
              if (tasks.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    '$_selectedMemberName has no open tasks to swap.',
                    style: TextStyle(color: Colors.grey.shade500),
                  ),
                );
              }
              return ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 280),
                child: ListView(
                  shrinkWrap: true,
                  children: tasks.map((d) {
                    final data = d.data() as Map<String, dynamic>;
                    final title =
                        data['title'] as String? ?? 'Untitled Task';
                    final dueLabel = data['dueLabel'] as String? ?? '';
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        title,
                        style:
                            const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: dueLabel.isNotEmpty ? Text(dueLabel) : null,
                      trailing: _sending
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2),
                            )
                          : const Icon(Icons.chevron_right),
                      onTap: _sending
                          ? null
                          : () => _sendRequest(
                                requestTaskId: d.id,
                                requestTaskTitle: title,
                              ),
                    );
                  }).toList(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _handle() {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }

  Widget _backRow({required String title, required VoidCallback onBack}) {
    return Row(
      children: [
        GestureDetector(
          onTap: onBack,
          child: const Icon(Icons.arrow_back, size: 22),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _optionTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: color,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: color),
          ],
        ),
      ),
    );
  }
}
