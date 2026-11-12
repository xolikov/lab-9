import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'bloc/cart_page_bloc.dart';
import 'cubit/cart_page_cubit.dart';
import 'riverpod/cart_page_riverpod.dart';
import 'setstate/cart_page_setstate.dart';

class AppBlocObserver extends BlocObserver {
  @override
  void onTransition(Bloc bloc, Transition transition) {
    super.onTransition(bloc, transition);
    debugPrint('BlocObserver Transition in ${bloc.runtimeType}: '
        '${transition.currentState.runtimeType} '
        '--(${transition.event.runtimeType})--> '
        '${transition.nextState.runtimeType}');
  }

  @override
  void onChange(BlocBase bloc, Change change) {
    super.onChange(bloc, change);
    debugPrint('BlocObserver Change in ${bloc.runtimeType}: '
        'current total=${(change.currentState as dynamic).total} -> '
        'next total=${(change.nextState as dynamic).total}');
  }
}

void main() {
  Bloc.observer = AppBlocObserver();
  runApp(
    const ProviderScope(
      child: MainApp(),
    ),
  );
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cart Four Ways',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cart State Management'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FilledButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const SetStateCartPage(),
                    ),
                  );
                },
                child: const Text('SetState Cart'),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const RiverpodCartPage(),
                    ),
                  );
                },
                child: const Text('Riverpod Cart'),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const CubitCartPage(),
                    ),
                  );
                },
                child: const Text('Cubit Cart'),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const BlocCartPage(),
                    ),
                  );
                },
                child: const Text('Bloc Cart'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
