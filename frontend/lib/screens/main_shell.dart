import 'package:flutter/material.dart';
import '../theme.dart';
import 'home_screen.dart';
import 'task_feed_screen.dart';
import '../services/notification_service.dart';
import 'care_screen.dart' show CareScreen, showAddCareNoteSheet;
import 'leaderboard_screen.dart';
import 'settings_screen.dart';
import 'add_task_dialog.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;
  final _householdId = ValueNotifier<String>('');

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    NotificationService.initialize();
    _screens = [
      HomeScreen(onHouseholdLoaded: (id) {
        _householdId.value = id;
      }),
      _HouseholdDependent(
        notifier: _householdId,
        builder: (id) => id.isEmpty
            ? const _LoadingPlaceholder()
            : TaskFeedScreen(householdId: id),
      ),
      _HouseholdDependent(
        notifier: _householdId,
        builder: (id) => CareScreen(householdId: id),
      ),
      _HouseholdDependent(
        notifier: _householdId,
        builder: (id) => LeaderboardScreen(householdId: id),
      ),
      const SettingsScreen(),
    ];
  }

  @override
  void dispose() {
    _householdId.dispose();
    super.dispose();
  }

  Widget? _buildFab() {
    if (_selectedIndex == 1 && _householdId.value.isNotEmpty) {
      return FloatingActionButton.extended(
        onPressed: () => showAddTaskDialog(context, _householdId.value),
        icon: const Icon(Icons.add),
        label: const Text('Add Task'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      );
    }
    if (_selectedIndex == 2 && _householdId.value.isNotEmpty) {
      return FloatingActionButton.extended(
        onPressed: () => showAddCareNoteSheet(context, _householdId.value),
        icon: const Icon(Icons.add),
        label: const Text('Add Note'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      );
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 900;

    if (isWide) {
      return ValueListenableBuilder<String>(
        valueListenable: _householdId,
        builder: (context, _, _) => Scaffold(
          floatingActionButton: _buildFab(),
          body: Row(
            children: [
              _buildSidebar(),
              Expanded(
                child: IndexedStack(
                  index: _selectedIndex,
                  children: _screens,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ValueListenableBuilder<String>(
      valueListenable: _householdId,
      builder: (context, _, _) => Scaffold(
      floatingActionButton: _buildFab(),
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.checklist_outlined),
            selectedIcon: Icon(Icons.checklist),
            label: 'Tasks',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_outline),
            selectedIcon: Icon(Icons.favorite),
            label: 'Care',
          ),
          NavigationDestination(
            icon: Icon(Icons.leaderboard_outlined),
            selectedIcon: Icon(Icons.leaderboard),
            label: 'Leaderboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 90,
      color: Colors.white,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: Icon(Icons.home,
                color: _selectedIndex == 0 ? AppColors.primary : Colors.grey),
            tooltip: 'Home',
            onPressed: () => setState(() => _selectedIndex = 0),
          ),
          const SizedBox(height: 20),
          IconButton(
            icon: Icon(Icons.checklist,
                color: _selectedIndex == 1 ? AppColors.primary : Colors.grey),
            tooltip: 'Tasks',
            onPressed: () => setState(() => _selectedIndex = 1),
          ),
          const SizedBox(height: 20),
          IconButton(
            icon: Icon(Icons.favorite,
                color: _selectedIndex == 2 ? AppColors.primary : Colors.grey),
            tooltip: 'Care Notes',
            onPressed: () => setState(() => _selectedIndex = 2),
          ),
          const SizedBox(height: 20),
          IconButton(
            icon: Icon(Icons.leaderboard,
                color: _selectedIndex == 3 ? AppColors.primary : Colors.grey),
            tooltip: 'Leaderboard',
            onPressed: () => setState(() => _selectedIndex = 3),
          ),
          const SizedBox(height: 20),
          IconButton(
            icon: Icon(Icons.settings_outlined,
                color: _selectedIndex == 4 ? AppColors.primary : Colors.grey),
            tooltip: 'Settings',
            onPressed: () => setState(() => _selectedIndex = 4),
          ),
        ],
      ),
    );
  }
}

class _HouseholdDependent extends StatelessWidget {
  final ValueNotifier<String> notifier;
  final Widget Function(String householdId) builder;

  const _HouseholdDependent({required this.notifier, required this.builder});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: notifier,
      builder: (context, id, _) => builder(id),
    );
  }
}

class _LoadingPlaceholder extends StatelessWidget {
  const _LoadingPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.background,
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
