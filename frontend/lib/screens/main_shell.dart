import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'task_feed_screen.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;
  String _householdId = '';

  List<Widget> get _screens => [
    HomeScreen(onHouseholdLoaded: (id) {
      if (_householdId != id) setState(() => _householdId = id);
    }),
    TaskFeedScreen(householdId: _householdId),
    const CareNotesPlaceholder(),
    const LeaderboardPlaceholder(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 900;

    if (isWide) {
      return Scaffold(
        body: Row(
          children: [
            _buildSidebar(),
            Expanded(child: _screens[_selectedIndex]),
          ],
        ),
      );
    }

    return Scaffold(
      body: _screens[_selectedIndex],
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
                color: _selectedIndex == 0 ? Colors.blue : Colors.grey),
            tooltip: 'Home',
            onPressed: () => setState(() => _selectedIndex = 0),
          ),
          const SizedBox(height: 20),
          IconButton(
            icon: Icon(Icons.checklist,
                color: _selectedIndex == 1 ? Colors.blue : Colors.grey),
            tooltip: 'Tasks',
            onPressed: () => setState(() => _selectedIndex = 1),
          ),
          const SizedBox(height: 20),
          IconButton(
            icon: Icon(Icons.favorite,
                color: _selectedIndex == 2 ? Colors.blue : Colors.grey),
            tooltip: 'Care Notes',
            onPressed: () => setState(() => _selectedIndex = 2),
          ),
          const SizedBox(height: 20),
          IconButton(
            icon: Icon(Icons.leaderboard,
                color: _selectedIndex == 3 ? Colors.blue : Colors.grey),
            tooltip: 'Leaderboard',
            onPressed: () => setState(() => _selectedIndex = 3),
          ),
          const SizedBox(height: 20),
          IconButton(
            icon: Icon(Icons.settings_outlined,
                color: _selectedIndex == 4 ? Colors.blue : Colors.grey),
            tooltip: 'Settings',
            onPressed: () => setState(() => _selectedIndex = 4),
          ),
        ],
      ),
    );
  }
}

// Temporary placeholder screens
class CareNotesPlaceholder extends StatelessWidget {
  const CareNotesPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFF4F6FB),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.favorite, size: 64, color: Colors.pinkAccent),
            SizedBox(height: 16),
            Text('Care Notes', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('Coming soon!', style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

class LeaderboardPlaceholder extends StatelessWidget {
  const LeaderboardPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFF4F6FB),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.leaderboard, size: 64, color: Colors.amber),
            SizedBox(height: 16),
            Text('Leaderboard', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('Coming soon!', style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}