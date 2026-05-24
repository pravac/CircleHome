import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const primary = Color(0xFF5B8DEF);
  static const background = Color(0xFFF4F6FB);

  // Leaderboard medals
  static const gold = Color(0xFFFFD700);
  static const silver = Color(0xFFC0C0C0);
  static const bronze = Color(0xFFCD7F32);

  static Color medal(int rank) {
    if (rank == 1) return gold;
    if (rank == 2) return silver;
    if (rank == 3) return bronze;
    return primary;
  }

  // Task categories
  static const _categoryColors = <String, Color>{
    'Cleaning': Colors.blue,
    'Groceries': Colors.green,
    'Laundry': Colors.orange,
    'Bills': Colors.red,
    'Other': Colors.grey,
  };

  static Color category(String cat) =>
      _categoryColors[cat] ?? Colors.grey;

  // Difficulty 1–5
  static const difficultyColors = <Color>[
    Colors.green,
    Color(0xFF8BC34A),
    Colors.orange,
    Colors.deepOrange,
    Colors.red,
  ];

  static Color difficulty(int d) =>
      difficultyColors[(d - 1).clamp(0, 4)];
}

class AppTextStyles {
  AppTextStyles._();

  static const appBarTitle = TextStyle(
    color: Colors.black87,
    fontWeight: FontWeight.w700,
    fontSize: 20,
  );

  static const sectionLabel = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.1,
  );
}

/// Small pill showing task difficulty (★1–★5).
class DifficultyBadge extends StatelessWidget {
  final int difficulty;
  final bool dimmed;

  const DifficultyBadge(this.difficulty, {super.key, this.dimmed = false});

  @override
  Widget build(BuildContext context) {
    final color = dimmed ? Colors.grey : AppColors.difficulty(difficulty);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
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
}

/// Small pill showing recurrence frequency with a repeat icon.
class RecurringBadge extends StatelessWidget {
  final String frequency;

  const RecurringBadge(this.frequency, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.purple.withValues(alpha: 0.1),
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
