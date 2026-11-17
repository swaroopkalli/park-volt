import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/admin/admin_page.dart';
import '../features/auth/login_page.dart';
import '../features/bookings/bookings_page.dart';
import '../features/charging/charging_page.dart';
import '../features/dashboard/dashboard_page.dart';
import '../features/parking/parking_page.dart';
import '../features/shell/shell.dart';
import 'package:animations/animations.dart';

import 'auth.dart';
import 'theme.dart';

/// Fade-through transition between sections (skipped when reduced motion is requested).
GoRoute _page(String path, Widget child) => GoRoute(
      path: path,
      pageBuilder: (context, state) => CustomTransitionPage<void>(
        key: state.pageKey,
        child: child,
        transitionDuration: MediaQuery.maybeOf(context)?.disableAnimations == true ? Duration.zero : const Duration(milliseconds: 300),
        transitionsBuilder: (context, animation, secondary, c) =>
            FadeThroughTransition(animation: animation, secondaryAnimation: secondary, fillColor: AppColors.bg, child: c),
      ),
    );

final routerProvider =Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.listen(userProvider, (_, __) => refresh.value++);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: '/dashboard',
    refreshListenable: refresh,
    redirect: (context, state) {
      final u = ref.read(userProvider);
      final loc = state.matchedLocation;
      if (u == null) return loc == '/login' ? null : '/login';
      if (loc == '/login') return '/dashboard';
      if (loc == '/admin' && !u.isAdmin) return '/dashboard';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginPage()),
      ShellRoute(
        builder: (_, state, child) => AppShell(location: state.matchedLocation, child: child),
        routes: [
          _page('/dashboard', const DashboardPage()),
          _page('/parking', const ParkingPage()),
          _page('/bookings', const BookingsPage()),
          _page('/charging', const ChargingPage()),
          _page('/admin', const AdminPage()),
        ],
      ),
    ],
  );
});
