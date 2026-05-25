import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:circlehome/utils/task_utils.dart';

void main() {
  group('difficultyLabel', () {
    test('returns Very Easy for 1', () => expect(difficultyLabel(1), 'Very Easy'));
    test('returns Easy for 2', () => expect(difficultyLabel(2), 'Easy'));
    test('returns Moderate for 3', () => expect(difficultyLabel(3), 'Moderate'));
    test('returns Hard for 4', () => expect(difficultyLabel(4), 'Hard'));
    test('returns Very Hard for 5', () => expect(difficultyLabel(5), 'Very Hard'));
    test('returns empty string for out-of-range value', () => expect(difficultyLabel(0), ''));
  });

  group('difficultyColor', () {
    test('returns green for difficulty 1', () => expect(difficultyColor(1), Colors.green));
    test('returns orange for difficulty 3', () => expect(difficultyColor(3), Colors.orange));
    test('returns red for difficulty 5', () => expect(difficultyColor(5), Colors.red));
    test('clamps to valid range for 0', () => expect(difficultyColor(0), Colors.green));
    test('clamps to valid range for 6', () => expect(difficultyColor(6), Colors.red));
  });

  group('isTaskOverdue', () {
    test('returns true for a date in the past', () {
      final past = DateTime(2020, 1, 1);
      expect(isTaskOverdue(past), true);
    });

    test('returns false for a date in the future', () {
      final future = DateTime(2099, 12, 31);
      expect(isTaskOverdue(future), false);
    });

    test('uses provided now parameter', () {
      final now = DateTime(2026, 5, 25, 12, 0);
      final due = DateTime(2026, 5, 25, 11, 0);
      expect(isTaskOverdue(due, now: now), true);
    });

    test('not overdue when due is after now', () {
      final now = DateTime(2026, 5, 25, 12, 0);
      final due = DateTime(2026, 5, 25, 13, 0);
      expect(isTaskOverdue(due, now: now), false);
    });
  });
}
