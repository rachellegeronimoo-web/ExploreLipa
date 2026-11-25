
import 'package:flutter_test/flutter_test.dart';
import 'package:explore_lipa/main.dart';

void main() {
  testWidgets('Explore Lipa app launches', (WidgetTester tester) async {
    await tester.pumpWidget(const ExploreLipaApp());

    expect(find.text('EXPLORE LIPA'), findsOneWidget);
  });
}
