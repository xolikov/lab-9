import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/cart.dart';
import '../services/checkout_api.dart';

final checkoutApiProvider = Provider<CheckoutApi>((ref) => CheckoutApi());

final cartProvider =
    NotifierProvider<CartNotifier, CartState>(CartNotifier.new);

final canUndoProvider = Provider<bool>((ref) {
  return ref.watch(cartProvider.select((s) => s.canUndo));
});

class CartNotifier extends Notifier<CartState> {
  final List<CartState> _history = [];

  @override
  CartState build() => const CartState();

  void _pushHistory() {
    _history.add(state);
  }

  void add(Product p) {
    _pushHistory();
    state = state.copyWith(
      lines: state.lines.withProduct(p),
      canUndo: true,
    );
  }

  void remove(String id) {
    _pushHistory();
    state = state.copyWith(
      lines: state.lines.without(id),
      canUndo: true,
    );
  }

  void changeQty(String id, int delta) {
    _pushHistory();
    state = state.copyWith(
      lines: state.lines.changeQty(id, delta),
      canUndo: true,
    );
  }

  void applyCoupon(String code) {
    _pushHistory();
    if (code == 'SAVE10') {
      state = state.copyWith(
        coupon: code,
        couponError: null,
        canUndo: true,
      );
    } else {
      state = state.copyWith(
        coupon: null,
        couponError: 'Invalid coupon code',
        canUndo: true,
      );
    }
  }

  void undo() {
    if (_history.isEmpty) return;
    final previous = _history.removeLast();
    state = previous.copyWith(canUndo: _history.isNotEmpty);
  }

  Future<void> checkout() async {
    state = state.copyWith(status: CheckoutStatus.submitting);

    final api = ref.read(checkoutApiProvider);
    try {
      final orderId = await api.submit(state.total);
      state = const CartState(status: CheckoutStatus.success);
      _history.clear();
      // Store order id if needed
      state = state.copyWith(orderId: orderId);
    } on CheckoutException catch (e) {
      state = state.copyWith(
        status: CheckoutStatus.failure,
        checkoutError: e.message,
      );
    } catch (e) {
      state = state.copyWith(
        status: CheckoutStatus.failure,
        checkoutError: e.toString(),
      );
    }
  }
}
