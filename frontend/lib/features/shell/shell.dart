import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth.dart';
import '../../core/theme.dart';

class _Dest {
  const _Dest(this.path, this.label, this.icon);
  final String path, label;
  final IconData icon;
}

const _all = [
  _Dest('/dashboard', 'Dashboard', Icons.dashboard_outlined),
  _Dest('/parking', 'Parking', Icons.local_parking),
  _Dest('/bookings', 'Bookings', Icons.confirmation_number_outlined),
  _Dest('/charging', 'Charging', Icons.ev_station_outlined),
  _Dest('/admin', 'Admin', Icons.admin_panel_settings_outlined),
];

class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.location, required this.child});
  final String location;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    final dests = _all.where((d) => d.path != '/admin' || (user?.isAdmin ?? false)).toList();
    var index = dests.indexWhere((d) => location.startsWith(d.path));
    if (index < 0) index = 0;
    final wide = MediaQuery.sizeOf(context).width >= 800;

    void go(int i) => context.go(dests[i].path);

    final userChip = PopupMenuButton<String>(
      tooltip: 'Account',
      onSelected: (_) => ref.read(userProvider.notifier).logout(),
      itemBuilder: (_) => const [PopupMenuItem(value: 'logout', child: Text('Switch user / log out'))],
      child: Chip(avatar: const Icon(Icons.person, size: 18), label: Text(user?.name ?? '')),
    );

    return Scaffold(
      appBar: wide
          ? null
          : AppBar(title: const Text('ParkVolt', style: TextStyle(fontWeight: FontWeight.w800)), actions: [userChip, const SizedBox(width: 8)]),
      bottomNavigationBar: wide
          ? null
          : NavigationBar(
              selectedIndex: index,
              onDestinationSelected: go,
              destinations: [for (final d in dests) NavigationDestination(icon: Icon(d.icon), label: d.label)],
            ),
      body: Row(children: [
        if (wide)
          Container(
            color: AppColors.navy,
            child: NavigationRail(
              backgroundColor: AppColors.navy,
              extended: MediaQuery.sizeOf(context).width >= 1100,
              selectedIndex: index,
              onDestinationSelected: go,
              unselectedIconTheme: const IconThemeData(color: Colors.white70),
              selectedIconTheme: const IconThemeData(color: Colors.white),
              unselectedLabelTextStyle: const TextStyle(color: Colors.white70),
              selectedLabelTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
              indicatorColor: AppColors.blue,
              leading: const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.bolt, color: Colors.white),
                  SizedBox(width: 6),
                  Text('ParkVolt', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                ]),
              ),
              trailing: Expanded(child: Align(alignment: Alignment.bottomCenter, child: Padding(padding: const EdgeInsets.all(16), child: userChip))),
              destinations: [for (final d in dests) NavigationRailDestination(icon: Icon(d.icon), label: Text(d.label))],
            ),
          ),
        Expanded(child: child),
      ]),
    );
  }
}
