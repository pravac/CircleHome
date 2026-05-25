import 'package:flutter_test/flutter_test.dart';
import 'package:circlehome/utils/time_utils.dart';

void main() {
  final now = DateTime(2026, 5, 25, 12, 0, 0);

  group('formatRelativeTime', () {
    test('shows seconds for times under a minute ago', () {
      final dt = now.subtract(const Duration(seconds: 30));
      expect(formatRelativeTime(dt, now: now), '30s ago');
    });

    test('shows minutes for times under an hour ago', () {
      final dt = now.subtract(const Duration(minutes: 15));
      expect(formatRelativeTime(dt, now: now), '15m ago');
    });

    test('shows hours for times under a day ago', () {
      final dt = now.subtract(const Duration(hours: 3));
      expect(formatRelativeTime(dt, now: now), '3h ago');
    });

    test('shows days for times under a week ago', () {
      final dt = now.subtract(const Duration(days: 4));
      expect(formatRelativeTime(dt, now: now), '4d ago');
    });

    test('shows weeks for times over a week ago', () {
      final dt = now.subtract(const Duration(days: 14));
      expect(formatRelativeTime(dt, now: now), '2w ago');
    });

    test('rounds down for partial weeks', () {
      final dt = now.subtract(const Duration(days: 10));
      expect(formatRelativeTime(dt, now: now), '1w ago');
    });

    test('shows 59s ago for 59 seconds', () {
      final dt = now.subtract(const Duration(seconds: 59));
      expect(formatRelativeTime(dt, now: now), '59s ago');
    });

    test('shows 1m ago at exactly 60 seconds', () {
      final dt = now.subtract(const Duration(seconds: 60));
      expect(formatRelativeTime(dt, now: now), '1m ago');
    });
  });
}
