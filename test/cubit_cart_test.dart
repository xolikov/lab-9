import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cart_four_ways/cubit/cart_cubit.dart';
import 'package:cart_four_ways/models/cart.dart';
import 'package:cart_four_ways/services/checkout_api.dart';

class MockCheckoutApi extends Mock implements CheckoutApi {}

void main() {
  const keyboard = Product(id: 'p1', name: 'Keyboard', price: 49);

  group('CartCubit', () {
    blocTest<CartCubit, CartState>(
      'emits 3 states on adding keyboard twice and applying SAVE10 coupon',
      build: () => CartCubit(),
      act: (cubit) {
        cubit.add(keyboard);
        cubit.add(keyboard);
        cubit.applyCoupon('SAVE10');
      },
      expect: () => [
        const CartState(
          lines: [CartLine(product: keyboard, qty: 1)],
          canUndo: true,
        ),
        const CartState(
          lines: [CartLine(product: keyboard, qty: 2)],
          canUndo: true,
        ),
        const CartState(
          lines: [CartLine(product: keyboard, qty: 2)],
          coupon: 'SAVE10',
          canUndo: true,
        ),
      ],
    );

    blocTest<CartCubit, CartState>(
      'emits submitting followed by failure when checkout throws',
      build: () {
        final mockApi = MockCheckoutApi();
        when(() => mockApi.submit(any()))
            .thenThrow(const CheckoutException('Card declined'));
        return CartCubit(mockApi);
      },
      seed: () => const CartState(
        lines: [CartLine(product: keyboard, qty: 1)],
        canUndo: true,
      ),
      act: (cubit) => cubit.checkout(),
      expect: () => [
        const CartState(
          lines: [CartLine(product: keyboard, qty: 1)],
          status: CheckoutStatus.submitting,
          canUndo: true,
        ),
        const CartState(
          lines: [CartLine(product: keyboard, qty: 1)],
          status: CheckoutStatus.failure,
          checkoutError: 'Card declined',
          canUndo: true,
        ),
      ],
    );
  });
}
