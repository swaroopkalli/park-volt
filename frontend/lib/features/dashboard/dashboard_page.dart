import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api.dart';
import '../../core/auth.dart';
import '../../core/data.dart';
import '../../core/theme.dart';
import '../../widgets/common.dart';
import '../../widgets/poller.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    final slots = ref.watch(slotsProvider);
    final bookings = ref.watch(bookingsProvider);
    final stations = ref.watch(stationsProvider);
    final sessions = ref.watch(sessionsProvider);

    void refresh() {
      ref.invalidate(slotsProvider);
      ref.invalidate(bookingsProvider);
      ref.invalidate(stationsProvider);
      ref.invalidate(sessionsProvider);
    }

    String stat<T>(AsyncValue<List<T>> v, int Function(List<T>) f) => v.hasValue ? '${f(v.requireValue)}' : '—';

    final errors = [slots, bookings, stations, sessions].where((v) => v.hasError && !v.hasValue).map((v) => v.error!).toList();

    final cards = [
      StatCard(label: 'Total slots', value: stat(slots, (l) => l.length), icon: Icons.local_parking),
      StatCard(label: 'Available', value: stat(slots, (l) => l.where((s) => s.status == 'AVAILABLE').length), icon: Icons.check_circle_outline, color: AppColors.green),
      StatCard(label: 'Occupied / reserved', value: stat(slots, (l) => l.where((s) => s.status == 'OCCUPIED' || s.status == 'RESERVED').length), icon: Icons.directions_car, color: AppColors.orange),
      StatCard(label: user?.isAdmin ?? false ? 'Active bookings' : 'My active bookings', value: stat(bookings, (l) => l.where((b) => b.status == 'CONFIRMED' || b.status == 'ACTIVE').length), icon: Icons.confirmation_number_outlined),
      StatCard(label: 'Free chargers', value: stat(stations, (l) => l.where((s) => s.status == 'AVAILABLE').length), icon: Icons.ev_station, color: AppColors.green),
      StatCard(label: 'Active sessions', value: stat(sessions, (l) => l.where((s) => s.active).length), icon: Icons.bolt, color: AppColors.blue),
    ];

    return Poller(
      interval: const Duration(seconds: 10),
      onTick: refresh,
      child: RefreshIndicator(
        onRefresh: () async => refresh(),
        child: ListView(padding: const EdgeInsets.all(16), children: [
          Text('Welcome, ${user?.name ?? ''}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.navy)),
          const SizedBox(height: 4),
          const Text('Live overview · refreshes every 10 seconds', style: TextStyle(color: AppColors.grey)),
          const SizedBox(height: 16),
          if (errors.isNotEmpty) ErrorBanner(error: errors.first is ApiError ? errors.first : ApiError.from(errors.first), onRetry: refresh),
          LayoutBuilder(builder: (context, c) {
            final cols = c.maxWidth >= 900 ? 3 : (c.maxWidth >= 560 ? 2 : 1);
            return GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: cols,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: cols == 1 ? 3.6 : 3.0,
              children: cards,
            );
          }),
        ]),
      ),
    );
  }
}
