import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cart_four_ways/bloc/cart_bloc.dart';
import 'package:cart_four_ways/bloc/cart_event.dart';
import 'package:cart_four_ways/models/cart.dart';
import 'package:cart_four_ways/services/checkout_api.dart';

class MockCheckoutApi extends Mock implements CheckoutApi {}

void main() {
  const keyboard = Product(id: 'p1', name: 'Keyboard', price: 49);

  group('CartBloc', () {
    blocTest<CartBloc, CartState>(
      'emits 3 states on adding keyboard twice and applying SAVE10 coupon',
      build: () => CartBloc(),
      act: (bloc) => bloc
        ..add(const CartProductAdded(keyboard))
        ..add(const CartProductAdded(keyboard))
        ..add(const CartCouponApplied('SAVE10')),
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

    blocTest<CartBloc, CartState>(
      'emits submitting followed by failure when checkout throws',
      build: () {
        final mockApi = MockCheckoutApi();
        when(() => mockApi.submit(any()))
            .thenThrow(const CheckoutException('Card declined'));
        return CartBloc(mockApi);
      },
      seed: () => const CartState(
        lines: [CartLine(product: keyboard, qty: 1)],
        canUndo: true,
      ),
      act: (bloc) => bloc.add(const CartCheckoutRequested()),
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

    blocTest<CartBloc, CartState>(
      'drops duplicate CartCheckoutRequested events thanks to droppable()',
      build: () {
        final mockApi = MockCheckoutApi();
        when(() => mockApi.submit(any())).thenAnswer(
          (_) async {
            await Future<void>.delayed(const Duration(milliseconds: 100));
            return 'ORD-1234';
          },
        );
        return CartBloc(mockApi);
      },
      seed: () => const CartState(
        lines: [CartLine(product: keyboard, qty: 1)],
        canUndo: true,
      ),
      act: (bloc) {
        bloc.add(const CartCheckoutRequested());
        bloc.add(const CartCheckoutRequested());
      },
      wait: const Duration(milliseconds: 200),
      expect: () => [
        const CartState(
          lines: [CartLine(product: keyboard, qty: 1)],
          status: CheckoutStatus.submitting,
          canUndo: true,
        ),
        const CartState(
          status: CheckoutStatus.success,
          orderId: 'ORD-1234',
        ),
      ],
    );
  });
}
