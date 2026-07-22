import 'package:flutter_test/flutter_test.dart';
import 'package:wide_color_tool_example/main.dart';

void main() {
  testWidgets('renders and navigates through the color demo', (tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('WideColor Demo Home Page'), findsOneWidget);
    expect(find.text('Color Mix'), findsOneWidget);
    expect(find.text('Mix RGB Colors'), findsOneWidget);
    expect(find.text('Mixed Color: #FF7F007F'), findsOneWidget);

    await tester.tap(find.text('Conversions'));
    await tester.pumpAndSettle();
    expect(find.text('RGB: (255, 0, 0)'), findsOneWidget);

    await tester.tap(find.text('Contrast'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Contrast Ratio:'), findsOneWidget);
    expect(find.text('Sample Text'), findsOneWidget);
  });
}
