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
import 'auth.dart';

final routerProvider = Provider<GoRouter>((ref) {
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
          GoRoute(path: '/dashboard', builder: (_, __) => const DashboardPage()),
          GoRoute(path: '/parking', builder: (_, __) => const ParkingPage()),
          GoRoute(path: '/bookings', builder: (_, __) => const BookingsPage()),
          GoRoute(path: '/charging', builder: (_, __) => const ChargingPage()),
          GoRoute(path: '/admin', builder: (_, __) => const AdminPage()),
        ],
      ),
    ],
  );
});
