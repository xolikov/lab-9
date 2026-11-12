import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/cart.dart';
import '../services/checkout_api.dart';
import 'cart_event.dart';

class CartBloc extends Bloc<CartEvent, CartState> {
  CartBloc([CheckoutApi? api])
      : _api = api ?? CheckoutApi(),
        super(const CartState()) {
    on<CartProductAdded>(_onProductAdded);
    on<CartProductRemoved>(_onProductRemoved);
    on<CartQtyChanged>(_onQtyChanged);
    on<CartCouponApplied>(_onCouponApplied);
    on<CartCheckoutRequested>(_onCheckoutRequested, transformer: droppable());
    on<CartUndone>(_onUndone);
  }

  final CheckoutApi _api;
  final List<CartState> _history = [];

  void _pushHistory() {
    _history.add(state);
  }

  void _onProductAdded(CartProductAdded event, Emitter<CartState> emit) {
    _pushHistory();
    emit(state.copyWith(
      lines: state.lines.withProduct(event.product),
      canUndo: true,
    ));
  }

  void _onProductRemoved(CartProductRemoved event, Emitter<CartState> emit) {
    _pushHistory();
    emit(state.copyWith(
      lines: state.lines.without(event.productId),
      canUndo: true,
    ));
  }

  void _onQtyChanged(CartQtyChanged event, Emitter<CartState> emit) {
    _pushHistory();
    emit(state.copyWith(
      lines: state.lines.changeQty(event.productId, event.delta),
      canUndo: true,
    ));
  }

  void _onCouponApplied(CartCouponApplied event, Emitter<CartState> emit) {
    _pushHistory();
    if (event.code == 'SAVE10') {
      emit(state.copyWith(
        coupon: event.code,
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

  Future<void> _onCheckoutRequested(
      CartCheckoutRequested event, Emitter<CartState> emit) async {
    emit(state.copyWith(status: CheckoutStatus.submitting));

    try {
      final orderId = await _api.submit(state.total);
      if (emit.isDone) return;
      _history.clear();
      emit(CartState(
        status: CheckoutStatus.success,
        orderId: orderId,
      ));
    } on CheckoutException catch (e) {
      if (emit.isDone) return;
      emit(state.copyWith(
        status: CheckoutStatus.failure,
        checkoutError: e.message,
      ));
    } catch (e) {
      if (emit.isDone) return;
      emit(state.copyWith(
        status: CheckoutStatus.failure,
        checkoutError: e.toString(),
      ));
    }
  }

  void _onUndone(CartUndone event, Emitter<CartState> emit) {
    if (_history.isEmpty) return;
    final previous = _history.removeLast();
    emit(previous.copyWith(canUndo: _history.isNotEmpty));
  }
}
