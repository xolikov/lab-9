import 'package:flutter/material.dart';
import '../models/cart.dart';

class CartBody extends StatefulWidget {
  const CartBody({
    super.key,
    required this.lines,
    required this.onAdd,
    required this.onRemove,
    this.onQtyChanged,
    this.coupon,
    this.couponError,
    this.onApplyCoupon,
    this.summaryCard,
    this.isSubmitting = false,
    this.onCheckout,
  });

  final List<CartLine> lines;
  final void Function(Product) onAdd;
  final void Function(String productId) onRemove;
  final void Function(String productId, int delta)? onQtyChanged;
  final String? coupon;
  final String? couponError;
  final void Function(String couponCode)? onApplyCoupon;
  final Widget? summaryCard;
  final bool isSubmitting;
  final VoidCallback? onCheckout;

  @override
  State<CartBody> createState() => _CartBodyState();
}

class _CartBodyState extends State<CartBody> {
  late final TextEditingController _couponController;

  @override
  void initState() {
    super.initState();
    _couponController = TextEditingController(text: widget.coupon ?? '');
  }

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Product Catalog Chips
        Padding(
          padding: const EdgeInsets.all(12),
          child: Wrap(
            spacing: 8,
            children: [
              for (final p in catalog)
                ActionChip(
                  key: ValueKey('chip_${p.id}'),
                  label: Text('${p.name} · ${p.price.toStringAsFixed(0)}'),
                  onPressed: () => widget.onAdd(p),
                ),
            ],
          ),
        ),

        // Cart items list
        Expanded(
          child: widget.lines.isEmpty
              ? const Center(child: Text('Cart is empty'))
              : ListView(
                  children: [
                    for (final l in widget.lines)
                      ListTile(
                        key: ValueKey(l.product.id),
                        title: Text(l.product.name),
                        subtitle: Text('× ${l.qty}'),
                        trailing: widget.onQtyChanged != null
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    key: ValueKey('minus_${l.product.id}'),
                                    icon: const Icon(Icons.remove),
                                    onPressed: () =>
                                        widget.onQtyChanged!(l.product.id, -1),
                                  ),
                                  IconButton(
                                    key: ValueKey('plus_${l.product.id}'),
                                    icon: const Icon(Icons.add),
                                    onPressed: () =>
                                        widget.onQtyChanged!(l.product.id, 1),
                                  ),
                                ],
                              )
                            : IconButton(
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () => widget.onRemove(l.product.id),
                              ),
                      ),
                  ],
                ),
        ),

        // Coupon input section
        if (widget.onApplyCoupon != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        key: const ValueKey('coupon_field'),
                        controller: _couponController,
                        decoration: const InputDecoration(
                          labelText: 'Coupon code',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      key: const ValueKey('apply_button'),
                      onPressed: () {
                        widget.onApplyCoupon!(_couponController.text.trim());
                      },
                      child: const Text('Apply'),
                    ),
                  ],
                ),
                if (widget.couponError != null &&
                    widget.couponError!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    widget.couponError!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ],
              ],
            ),
          ),

        // Summary Card or fallback subtotal
        if (widget.summaryCard != null)
          widget.summaryCard!
        else
          ListTile(
            title: const Text('Subtotal'),
            trailing: Text(widget.lines.subtotal.toStringAsFixed(2)),
          ),

        // Checkout Button
        if (widget.onCheckout != null)
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                key: const ValueKey('checkout_button'),
                onPressed: widget.isSubmitting ? null : widget.onCheckout,
                child: widget.isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Checkout'),
              ),
            ),
          ),
      ],
    );
  }
}
