# Lab Notes: One Cart, Four Ways (setState, Riverpod, Cubit, Bloc)

## Part 1 Inline Questions

### Why is CartLine immutable with a copyWith instead of a mutable qty field? Which of the four styles would still "work" with mutation, and why is that a trap?
1. **Immutability and State Change Detection**: In reactive state management architectures like Riverpod, Cubit, and Bloc, state emissions rely on equality checks (`identical` or `operator ==`) to detect whether the state has changed. If `qty` was mutable and mutated in-place, the object reference would remain the same and listeners wouldn't receive notification of an update unless dirty flags or manual forced notifications are triggered.
2. **Which style still "works"**: `setState` in Flutter would still "work" because calling `setState(() { line.qty++; })` does not check object equality; it unconditionally marks the widget's `Element` as dirty and schedules a build on the next frame.
3. **Why it's a trap**:
   - It breaks time-travel, undo/redo, and change histories: mutating an object in-place mutates it across all historical references stored in a `_history` list.
   - It creates severe bugs in Riverpod and Bloc/Cubit where `distinct` filters, `buildWhen`, `listenWhen`, and stream equality drop updates because `oldState == newState` evaluates to `true`.
   - It introduces mutable shared state, making concurrency, debugging, and testing unpredictable.

### Why does CartBody take callbacks rather than importing a provider or a bloc directly?
- `CartBody` is designed as a **dumb (presentational) component**.
- Taking primitives/data and callback closures (`onAdd`, `onRemove`, `onQtyChanged`, `onApplyCoupon`, `onCheckout`) makes the widget completely decoupled from any state management library or framework.
- This enables 100% code reuse across all four architectural implementations (setState, Riverpod, Cubit, and Bloc), as well as simplified widget testing using pure mock callbacks without needing wrapper providers or blocs.

---

## Part 2 Inline Questions (setState)

### After T4, how would a second page (say an order history) read the cart? What would you have to change?
- Because `_state` is a private field on `_SetStateCartPageState`, it is tightly scoped to the widget element and dies when the page is popped.
- To share the cart with a sibling or second page (e.g. order history), the state must be lifted above both pages in the widget tree (e.g., in a parent widget holding the cart state) and passed down via constructor arguments (prop drilling) or through an `InheritedWidget`.

### After T5, where does _history live, and what happens to it on hot restart versus hot reload?
- `_history` lives in memory as a private instance member of the `_SetStateCartPageState` object.
- **Hot reload**: Preserves the State object in memory, so `_history` and current cart state remain intact.
- **Hot restart**: Destroys the entire Flutter runtime and state tree, recreating everything from scratch; `_history` is completely reset to its empty initial state.

---

## Part 3 Inline Questions (Riverpod)

### Name the three places you used ref.read and the two places you used ref.watch, and justify each.
1. **`ref.read`**:
   - Inside `CartPageRiverpod` build method for obtaining `ref.read(cartProvider.notifier)` to call callbacks (`add`, `remove`, `changeQty`, `applyCoupon`, `undo`, `checkout`) — callbacks only need to dispatch actions without establishing subscriptions.
   - Inside `ref.listen` callback to retrieve current `orderId` or `checkoutError` at the moment the event happens (`ref.read(cartProvider).orderId`), avoiding rebuild triggers.
   - Inside `CartNotifier.checkout()` method to get `ref.read(checkoutApiProvider)` to call `api.submit(state.total)` without subscribing to provider changes.
2. **`ref.watch`**:
   - In `CartPageRiverpod.build` to subscribe to state slices: `ref.watch(cartProvider.select((s) => s.lines))`, `ref.watch(canUndoProvider)`.
   - In `RiverpodSummaryCard.build` watching `ref.watch(cartProvider.select((s) => s.total))` and other summary getters so the card only rebuilds when computed totals change.

### Why does the summary card in T3 rebuild less often than the setState version?
- In `setState`, any call to `setState()` marks the entire page element dirty, causing `CartPage` and all child widgets (including the summary card) to rebuild on every keystroke or cart update.
- In Riverpod, `RiverpodSummaryCard` uses fine-grained projection with `cartProvider.select((s) => s.total)`. Typing in the coupon field updates `coupon` but not `total` (until a valid coupon is applied), so Riverpod skips rebuilding `RiverpodSummaryCard`.

---

## Part 4 Inline Questions (Cubit)

### What would break if you put BlocProvider inside CartBody?
- `BlocProvider` creates and scopes the `CartCubit` to its subtree. If placed inside `CartBody`:
  1. `Scaffold` and its `AppBar` (where the Undo button lives) are ancestors of `CartBody` and cannot access `CartCubit` via `context.read<CartCubit>()` (throwing `ProviderNotFoundException`).
  2. Every time `CartBody` rebuilds or is recreated, the Cubit would be disposed and recreated, wiping the cart state and history.

### Give the Riverpod equivalent of each of:
- `BlocProvider` $\rightarrow$ `ProviderScope` (or declaring a provider `final cartProvider = ...`)
- `BlocBuilder` $\rightarrow$ `ref.watch(...)` inside a `Consumer` or `ConsumerWidget`
- `BlocListener` $\rightarrow$ `ref.listen(...)`
- `context.read` $\rightarrow$ `ref.read(...)`
- `buildWhen` $\rightarrow$ `ref.watch(provider.select(...))`

---

## Part 5 Inline Questions (Bloc)

### When is the event layer worth its boilerplate? Give one feature in this cart where Bloc is clearly better than Cubit and one where it is pure overhead.
- **Worth its boilerplate**:
  - Event concurrency management (e.g. `droppable()`, `debounce()`, `restartable()`).
  - Full analytics/audit logging via `BlocObserver.onTransition` which records `currentState -> Event -> nextState`.
- **Feature where Bloc is clearly better**: Checkout button spam prevention (`CartCheckoutRequested` with `droppable()`) seamlessly drops subsequent taps declaratively without boolean flags in the state or UI.
- **Feature where Bloc is pure overhead**: Simple synchronous mutations like `CartProductAdded(product)` or `CartProductRemoved(id)`, where creating event classes and mapping handlers is redundant compared to simple Cubit/Notifier methods.

### Which of the four styles let you implement T4's "drop duplicate taps" declaratively, and how would you do it in the others?
- **Bloc**: Implements it completely declaratively using `transformer: droppable()` from `bloc_concurrency` on the event handler.
- **In setState, Riverpod, and Cubit**: Must be implemented imperatively by guarding with an explicit status check (e.g., `if (state.status == CheckoutStatus.submitting) return;` or disabling the button while `isSubmitting` is true).

---

## Checkpoint Questions

### 1. For each of the four styles, state in one line where the state lives and when it dies:
- **setState**: Lives in the `_SetStateCartPageState` object in the Flutter element tree; dies when the page widget is unmounted/popped.
- **Riverpod**: Lives in the `CartNotifier` inside the root `ProviderContainer` (owned by `ProviderScope`); survives navigation and dies only when the container/app is disposed (unless marked `.autoDispose`).
- **Cubit**: Lives in the `CartCubit` instance held by `BlocProvider` in the widget tree; dies when `BlocProvider` is unmounted/disposed on page pop.
- **Bloc**: Lives in the `CartBloc` instance held by `BlocProvider` in the widget tree; dies when `BlocProvider` is unmounted/disposed on page pop.

### 2. What is the single public mutation API in Riverpod's Notifier, in Cubit and in Bloc? Which style has none?
- **Riverpod Notifier**: Calling public methods defined on the `Notifier` subclass (and internally assigning `state = ...`).
- **Cubit**: Calling public methods defined on the `Cubit` subclass (and internally calling `emit(...)`).
- **Bloc**: `bloc.add(event)`.
- **Which style has none**: `setState` has no distinct public mutation API or separate state holder — mutation is executed directly within `setState(() { ... })` closures on the State class.

### 3. Map these to each other:
- `ref.watch` $\leftrightarrow$ `BlocBuilder` (and `context.watch`)
- `ref.read` $\leftrightarrow$ `context.read`
- `ref.listen` $\leftrightarrow$ `BlocListener`
- **Where does setState fit**: `setState` conflates subscription, state management, and rebuilding all into one: calling `setState` marks the State's element dirty, triggering `build(context)` on the next frame.

### 4. Why do Riverpod, Cubit and Bloc all skip notifying when the new state == the old one, and what two things must you do to CartState so that this behaves correctly?
- **Why they skip notifying**: To avoid unnecessary re-renders and computations when state hasn't meaningfully changed, boosting performance.
- **Two things to do to CartState**:
  1. Implement value equality by overriding `operator ==` and `hashCode` (or extending `Equatable`).
  2. Implement deep equality for collections (`List<CartLine>`), e.g. using Flutter's `listEquals(lines, other.lines)`.

### 5. After the await in checkout, what guard did each style need (mounted, nothing, isClosed, emit.isDone) and why do they differ?
- **setState**: Requires `if (!mounted) return;` because the State object might be unmounted if the user pops the route while checkout was awaiting; calling `setState` on an unmounted state throws a Flutter framework exception.
- **Riverpod**: Requires **nothing** because Riverpod state lives outside the widget tree in `ProviderContainer`. Modifying state in a Notifier is independent of any widget lifecycle. UI side effects are safely handled in `ref.listen`.
- **Cubit**: Requires `if (isClosed) return;` because if the user navigates away, `BlocProvider` closes the Cubit, and calling `emit` after `close()` throws a `StateError`.
- **Bloc**: Requires `if (emit.isDone) return;` (or checking `isClosed`) because the handler's scoped `Emitter` is completed if the bloc closes during the async gap, and emitting on a completed emitter throws a `StateError`.

---

## Comparison Table

| Style | Lines of Code (T1–T5) | Lines of Test Code | Number of Files | One Strength | One Weakness |
|---|---|---|---|---|---|
| **setState** | ~140 lines | ~40 lines | 2 files (`cart_page_setstate.dart`, `test/setstate_cart_test.dart`) | Zero setup, built directly into Flutter framework, lowest conceptual overhead | Tied strictly to widget lifecycle, cannot easily share state across screens without prop drilling |
| **Riverpod** | ~120 lines | ~45 lines | 3 files (`cart_notifier.dart`, `cart_page_riverpod.dart`, `test/riverpod_cart_test.dart`) | State lives outside widget tree, fine-grained `.select()`, easy headless unit testing | Requires global `ProviderScope` and special widgets (`ConsumerWidget`, `WidgetRef`) |
| **Cubit** | ~130 lines | ~55 lines | 3 files (`cart_cubit.dart`, `cart_page_cubit.dart`, `test/cubit_cart_test.dart`) | Straightforward method-based API with explicit stream states and testability via `blocTest` | Scoped by default to widget tree via `BlocProvider`, requires manual `isClosed` checks |
| **Bloc** | ~150 lines | ~75 lines | 4 files (`cart_event.dart`, `cart_bloc.dart`, `cart_page_bloc.dart`, `test/bloc_cart_test.dart`) | Explicit event stream allows declarative transformers (`droppable`, `debounce`) and full event traceability | Highest boilerplate with separate event classes and handler wiring |
