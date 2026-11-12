import 'package:flutter/material.dart';
import '../models/cart.dart';
import '../services/checkout_api.dart';
import '../widgets/cart_body.dart';
import '../widgets/cart_summary_card.dart';

class SetStateCartPage extends StatefulWidget {
  const SetStateCartPage({super.key, this.api});

  final CheckoutApi? api;

  @override
  State<SetStateCartPage> createState() => _SetStateCartPageState();
}

class _SetStateCartPageState extends State<SetStateCartPage> {
  CartState _state = const CartState();
  final List<CartState> _history = [];
  late final CheckoutApi _api;

  @override
  void initState() {
    super.initState();
    _api = widget.api ?? CheckoutApi();
  }

  void _pushHistory() {
    _history.add(_state);
  }

  void _add(Product p) {
    _pushHistory();
    setState(() {
      _state = _state.copyWith(
        lines: _state.lines.withProduct(p),
        canUndo: true,
      );
    });
  }

  void _remove(String id) {
    _pushHistory();
    setState(() {
      _state = _state.copyWith(
        lines: _state.lines.without(id),
        canUndo: true,
      );
    });
  }

  void _changeQty(String id, int delta) {
    _pushHistory();
    setState(() {
      _state = _state.copyWith(
        lines: _state.lines.changeQty(id, delta),
        canUndo: true,
      );
    });
  }

  void _applyCoupon(String code) {
    _pushHistory();
    setState(() {
      if (code == 'SAVE10') {
        _state = _state.copyWith(
          coupon: code,
          couponError: null,
          canUndo: true,
        );
      } else {
        _state = _state.copyWith(
          coupon: null,
          couponError: 'Invalid coupon code',
          canUndo: true,
        );
      }
    });
  }

  void _undo() {
    if (_history.isEmpty) return;
    final previous = _history.removeLast();
    setState(() {
      _state = previous.copyWith(canUndo: _history.isNotEmpty);
    });
  }

  Future<void> _checkout() async {
    setState(() {
      _state = _state.copyWith(status: CheckoutStatus.submitting);
    });

    try {
      final orderId = await _api.submit(_state.total);
      if (!mounted) return;

      setState(() {
        _state = const CartState(status: CheckoutStatus.success);
        _history.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Order placed: $orderId')),
      );
    } on CheckoutException catch (e) {
      if (!mounted) return;

      setState(() {
        _state = _state.copyWith(
          status: CheckoutStatus.failure,
          checkoutError: e.message,
        );
      });

      ScaffoldMessenger.of(context).showMaterialBanner(
        MaterialBanner(
          content: Text(e.message),
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
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _state = _state.copyWith(
          status: CheckoutStatus.failure,
          checkoutError: e.toString(),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cart · setState'),
        actions: [
          IconButton(
            icon: const Icon(Icons.undo),
            tooltip: 'Undo',
            onPressed: _history.isNotEmpty ? _undo : null,
          ),
        ],
      ),
      body: CartBody(
        lines: _state.lines,
        onAdd: _add,
        onRemove: _remove,
        onQtyChanged: _changeQty,
        coupon: _state.coupon,
        couponError: _state.couponError,
        onApplyCoupon: _applyCoupon,
        isSubmitting: _state.status == CheckoutStatus.submitting,
        onCheckout: _state.lines.isNotEmpty ? _checkout : null,
        summaryCard: CartSummaryCard(
          itemCount: _state.itemCount,
          subtotal: _state.subtotal,
          discount: _state.discount,
          total: _state.total,
        ),
      ),
    );
  }
}
