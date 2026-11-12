import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cart_four_ways/models/cart.dart';
import 'package:cart_four_ways/riverpod/cart_notifier.dart';
import 'package:cart_four_ways/services/checkout_api.dart';

class MockCheckoutApi extends Mock implements CheckoutApi {}

void main() {
  test('add twice and applyCoupon SAVE10 results in total 88.2', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    const keyboard = Product(id: 'p1', name: 'Keyboard', price: 49);
    final notifier = container.read(cartProvider.notifier);

    notifier.add(keyboard);
    notifier.add(keyboard);
    notifier.applyCoupon('SAVE10');

    expect(container.read(cartProvider).total, 88.2);
  });

  test('checkout failure leaves lines intact and status failure', () async {
    final mockApi = MockCheckoutApi();
    when(() => mockApi.submit(any())).thenThrow(const CheckoutException('Card declined'));

    final container = ProviderContainer(
      overrides: [
        checkoutApiProvider.overrideWithValue(mockApi),
      ],
    );
    addTearDown(container.dispose);

    const keyboard = Product(id: 'p1', name: 'Keyboard', price: 49);
    final notifier = container.read(cartProvider.notifier);
    notifier.add(keyboard);

    await notifier.checkout();

    final state = container.read(cartProvider);
    expect(state.status, CheckoutStatus.failure);
    expect(state.lines.length, 1);
  });
}
