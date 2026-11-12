import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/cart.dart';
import '../services/checkout_api.dart';

class CartCubit extends Cubit<CartState> {
  CartCubit([CheckoutApi? api])
      : _api = api ?? CheckoutApi(),
        super(const CartState());

  final CheckoutApi _api;
  final List<CartState> _history = [];

  void _pushHistory() {
    _history.add(state);
  }

  void add(Product p) {
    _pushHistory();
    emit(state.copyWith(
      lines: state.lines.withProduct(p),
      canUndo: true,
    ));
  }

  void remove(String id) {
    _pushHistory();
    emit(state.copyWith(
      lines: state.lines.without(id),
      canUndo: true,
    ));
  }

  void changeQty(String id, int delta) {
    _pushHistory();
    emit(state.copyWith(
      lines: state.lines.changeQty(id, delta),
      canUndo: true,
    ));
  }

  void applyCoupon(String code) {
    _pushHistory();
    if (code == 'SAVE10') {
      emit(state.copyWith(
        coupon: code,
        couponError: null,
        canUndo: true,
      ));
    } else {
      emit(state.copyWith(
        coupon: null,
        couponError: 'Invalid coupon code',
        canUndo: true,
      ));
    }
  }

  void undo() {
    if (_history.isEmpty) return;
    final previous = _history.removeLast();
    emit(previous.copyWith(canUndo: _history.isNotEmpty));
  }

  Future<void> checkout() async {
    emit(state.copyWith(status: CheckoutStatus.submitting));

    try {
      final orderId = await _api.submit(state.total);
      if (isClosed) return;
      _history.clear();
      emit(CartState(
        status: CheckoutStatus.success,
        orderId: orderId,
      ));
    } on CheckoutException catch (e) {
      if (isClosed) return;
      emit(state.copyWith(
        status: CheckoutStatus.failure,
        checkoutError: e.message,
      ));
    } catch (e) {
      if (isClosed) return;
      emit(state.copyWith(
        status: CheckoutStatus.failure,
        checkoutError: e.toString(),
      ));
    }
  }
}
