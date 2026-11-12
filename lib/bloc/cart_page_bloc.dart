import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/cart.dart';
import '../services/checkout_api.dart';
import '../widgets/cart_body.dart';
import '../widgets/cart_summary_card.dart';
import 'cart_bloc.dart';
import 'cart_event.dart';

class BlocSummaryCard extends StatelessWidget {
  const BlocSummaryCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocSelector<CartBloc, CartState, double>(
      selector: (state) => state.total,
      builder: (context, total) {
        debugPrint('BlocSummaryCard rebuilt with total $total');
        final state = context.watch<CartBloc>().state;
        return CartSummaryCard(
          itemCount: state.itemCount,
          subtotal: state.subtotal,
          discount: state.discount,
          total: total,
        );
      },
    );
  }
}

class BlocCartPage extends StatelessWidget {
  const BlocCartPage({super.key, this.api});

  final CheckoutApi? api;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CartBloc(api),
      child: const _BlocCartView(),
    );
  }
}

class _BlocCartView extends StatelessWidget {
  const _BlocCartView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cart · Bloc'),
        actions: [
          BlocSelector<CartBloc, CartState, bool>(
            selector: (state) => state.canUndo,
            builder: (context, canUndo) {
              return IconButton(
                icon: const Icon(Icons.undo),
                tooltip: 'Undo',
                onPressed: canUndo
                    ? () => context.read<CartBloc>().add(const CartUndone())
                    : null,
              );
            },
          ),
        ],
      ),
      body: BlocListener<CartBloc, CartState>(
        listenWhen: (prev, curr) => prev.status != curr.status,
        listener: (context, state) {
          if (state.status == CheckoutStatus.success) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Order placed: ${state.orderId ?? ''}')),
            );
          } else if (state.status == CheckoutStatus.failure) {
            ScaffoldMessenger.of(context).showMaterialBanner(
              MaterialBanner(
                content: Text(state.checkoutError ?? 'Checkout failed'),
                actions: [
                  TextButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
                    },
                    child: const Text('DISMISS'),
                  ),
                ],
              ),
            );
          }
        },
        child: BlocBuilder<CartBloc, CartState>(
          builder: (context, state) {
            return CartBody(
              lines: state.lines,
              onAdd: (product) =>
                  context.read<CartBloc>().add(CartProductAdded(product)),
              onRemove: (productId) => context
                  .read<CartBloc>()
                  .add(CartProductRemoved(productId)),
              onQtyChanged: (productId, delta) => context
                  .read<CartBloc>()
                  .add(CartQtyChanged(productId, delta)),
              coupon: state.coupon,
              couponError: state.couponError,
              onApplyCoupon: (code) =>
                  context.read<CartBloc>().add(CartCouponApplied(code)),
              isSubmitting: state.status == CheckoutStatus.submitting,
              onCheckout: state.lines.isNotEmpty
                  ? () =>
                      context.read<CartBloc>().add(const CartCheckoutRequested())
                  : null,
              summaryCard: const BlocSummaryCard(),
            );
          },
        ),
      ),
    );
  }
}
