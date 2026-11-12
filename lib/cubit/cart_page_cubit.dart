import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/cart.dart';
import '../services/checkout_api.dart';
import '../widgets/cart_body.dart';
import '../widgets/cart_summary_card.dart';
import 'cart_cubit.dart';

class CubitSummaryCard extends StatelessWidget {
  const CubitSummaryCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocSelector<CartCubit, CartState, double>(
      selector: (state) => state.total,
      builder: (context, total) {
        debugPrint('CubitSummaryCard rebuilt with total $total');
        final state = context.watch<CartCubit>().state;
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

class CubitCartPage extends StatelessWidget {
  const CubitCartPage({super.key, this.api});

  final CheckoutApi? api;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CartCubit(api),
      child: const _CubitCartView(),
    );
  }
}

class _CubitCartView extends StatelessWidget {
  const _CubitCartView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cart · Cubit'),
        actions: [
          BlocSelector<CartCubit, CartState, bool>(
            selector: (state) => state.canUndo,
            builder: (context, canUndo) {
              return IconButton(
                icon: const Icon(Icons.undo),
                tooltip: 'Undo',
                onPressed: canUndo ? context.read<CartCubit>().undo : null,
              );
            },
          ),
        ],
      ),
      body: BlocListener<CartCubit, CartState>(
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
        child: BlocBuilder<CartCubit, CartState>(
          builder: (context, state) {
            return CartBody(
              lines: state.lines,
              onAdd: context.read<CartCubit>().add,
              onRemove: context.read<CartCubit>().remove,
              onQtyChanged: context.read<CartCubit>().changeQty,
              coupon: state.coupon,
              couponError: state.couponError,
              onApplyCoupon: context.read<CartCubit>().applyCoupon,
              isSubmitting: state.status == CheckoutStatus.submitting,
              onCheckout: state.lines.isNotEmpty
                  ? context.read<CartCubit>().checkout
                  : null,
              summaryCard: const CubitSummaryCard(),
            );
          },
        ),
      ),
    );
  }
}
