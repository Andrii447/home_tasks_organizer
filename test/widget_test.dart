import 'dart:ui' show Size;

import 'package:flutter_test/flutter_test.dart';
import 'package:home_tasks_organizer/app.dart';

void main() {
  testWidgets('login opens home with hardcoded tasks', (tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const DimPlanApp());
    expect(find.text('Вхід до ДімПлану'), findsOneWidget);

    await tester.tap(find.text('Увійти'));
    await tester.pumpAndSettle();

    expect(find.text('Наші домашні справи'), findsOneWidget);
    expect(find.text('Помити підлогу'), findsOneWidget);
  });

  testWidgets('forgot password shows neutral confirmation', (tester) async {
    await tester.pumpWidget(const DimPlanApp());

    await tester.tap(find.text('Забули пароль?'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Надіслати лист'));
    await tester.pumpAndSettle();

    expect(find.text('Перевірте пошту'), findsOneWidget);
  });
}
