import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cart_four_ways/setstate/cart_page_setstate.dart';

void main() {
  testWidgets('pump SetStateCartPage, tap Keyboard twice, enter SAVE10, tap Apply, and assert total reads 88.20', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SetStateCartPage(),
      ),
    );

    // Tap Keyboard twice
    final keyboardChip = find.byKey(const ValueKey('chip_p1'));
    expect(keyboardChip, findsOneWidget);
    await tester.tap(keyboardChip);
    await tester.pump();
    await tester.tap(keyboardChip);
    await tester.pump();

    // Enter SAVE10 into coupon field
    final couponField = find.byKey(const ValueKey('coupon_field'));
    expect(couponField, findsOneWidget);
    await tester.enterText(couponField, 'SAVE10');
    await tester.pump();

    // Tap Apply
    final applyButton = find.byKey(const ValueKey('apply_button'));
    expect(applyButton, findsOneWidget);
    await tester.tap(applyButton);
    await tester.pump();

    // Assert total reads 88.20
    final totalText = find.byKey(const ValueKey('cart_total_text'));
    expect(totalText, findsOneWidget);
    expect(find.text('88.20'), findsOneWidget);
  });
}
