import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Scaffold renders body content', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Center(child: Text('Hello CircleHome'))),
      ),
    );
    expect(find.text('Hello CircleHome'), findsOneWidget);
  });

  testWidgets('NavigationBar shows correct labels', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: const SizedBox.shrink(),
          bottomNavigationBar: NavigationBar(
            destinations: const [
              NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
              NavigationDestination(icon: Icon(Icons.checklist), label: 'Tasks'),
              NavigationDestination(icon: Icon(Icons.favorite), label: 'Care'),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Tasks'), findsOneWidget);
    expect(find.text('Care'), findsOneWidget);
  });

  testWidgets('CircularProgressIndicator is visible during loading', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      ),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('Empty state shows message and button', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('No care notes yet'),
                ElevatedButton(
                  onPressed: () {},
                  child: const Text('Add First Note'),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.text('No care notes yet'), findsOneWidget);
    expect(find.text('Add First Note'), findsOneWidget);
  });
}
