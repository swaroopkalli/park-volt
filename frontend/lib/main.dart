import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router.dart';
import 'core/theme.dart';
import 'widgets/motion.dart';

void main() => runApp(const ProviderScope(child: ParkVoltApp()));

class ParkVoltApp extends ConsumerWidget {
  const ParkVoltApp({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'ParkVolt',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      scrollBehavior: const AppScrollBehavior(),
      routerConfig: ref.watch(routerProvider),
    );
  }
}
