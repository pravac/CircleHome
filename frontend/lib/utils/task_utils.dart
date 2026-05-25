import 'package:flutter/material.dart';

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

bool isTaskOverdue(DateTime dueDate, {DateTime? now}) {
  return dueDate.isBefore(now ?? DateTime.now());
}
