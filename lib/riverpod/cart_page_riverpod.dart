import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/cart.dart';
import '../widgets/cart_body.dart';
import '../widgets/cart_summary_card.dart';
import 'cart_notifier.dart';

class RiverpodSummaryCard extends ConsumerWidget {
  const RiverpodSummaryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    debugPrint('RiverpodSummaryCard rebuilt');
    final total = ref.watch(cartProvider.select((s) => s.total));
    final itemCount = ref.watch(cartProvider.select((s) => s.itemCount));
    final subtotal = ref.watch(cartProvider.select((s) => s.subtotal));
    final discount = ref.watch(cartProvider.select((s) => s.discount));

    return CartSummaryCard(
      itemCount: itemCount,
      subtotal: subtotal,
      discount: discount,
      total: total,
    );
  }
}

class RiverpodCartPage extends ConsumerWidget {
  const RiverpodCartPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lines = ref.watch(cartProvider.select((s) => s.lines));
    final coupon = ref.watch(cartProvider.select((s) => s.coupon));
    final couponError = ref.watch(cartProvider.select((s) => s.couponError));
    final isSubmitting = ref.watch(
      cartProvider.select((s) => s.status == CheckoutStatus.submitting),
    );
    final canUndo = ref.watch(canUndoProvider);
    final cart = ref.read(cartProvider.notifier);

    ref.listen<CheckoutStatus>(
      cartProvider.select((s) => s.status),
      (prev, next) {
        if (next == CheckoutStatus.success) {
          final orderId = ref.read(cartProvider).orderId ?? '';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Order placed: $orderId')),
          );
        } else if (next == CheckoutStatus.failure) {
          final error = ref.read(cartProvider).checkoutError ?? 'Checkout failed';
          ScaffoldMessenger.of(context).showMaterialBanner(
            MaterialBanner(
              content: Text(error),
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
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cart · Riverpod'),
        actions: [
          IconButton(
            icon: const Icon(Icons.undo),
            tooltip: 'Undo',
            onPressed: canUndo ? cart.undo : null,
          ),
        ],
      ),
      body: CartBody(
        lines: lines,
        onAdd: cart.add,
        onRemove: cart.remove,
        onQtyChanged: cart.changeQty,
        coupon: coupon,
        couponError: couponError,
        onApplyCoupon: cart.applyCoupon,
        isSubmitting: isSubmitting,
        onCheckout: lines.isNotEmpty ? cart.checkout : null,
        summaryCard: const RiverpodSummaryCard(),
      ),
    );
  }
}
