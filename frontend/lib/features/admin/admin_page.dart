import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/api.dart';
import '../../core/data.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../widgets/common.dart';
import '../bookings/bookings_page.dart';

class AdminPage extends StatelessWidget {
  const AdminPage({super.key});
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Column(children: [
        const Material(
          color: Colors.white,
          child: TabBar(isScrollable: true, tabAlignment: TabAlignment.start, tabs: [
            Tab(text: 'Slots'),
            Tab(text: 'Stations'),
            Tab(text: 'Bookings'),
            Tab(text: 'Sessions'),
          ]),
        ),
        const Expanded(child: TabBarView(children: [_SlotsTab(), _StationsTab(), _BookingsTab(), _SessionsTab()])),
      ]),
    );
  }
}

class _SlotsTab extends ConsumerWidget {
  const _SlotsTab();

  Future<void> _add(BuildContext context, WidgetRef ref) async {
    final num = TextEditingController();
    final floor = TextEditingController(text: '1');
    String type = 'REGULAR';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('Add slot'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: num, decoration: const InputDecoration(labelText: 'Slot number (e.g. P21)')),
            TextField(controller: floor, decoration: const InputDecoration(labelText: 'Floor')),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: type,
              items: [for (final t in ['REGULAR', 'EV', 'ACCESSIBLE']) DropdownMenuItem(value: t, child: Text(t))],
              onChanged: (v) => setS(() => type = v!),
            ),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Add')),
          ],
        ),
      ),
    );
    if (ok == true && context.mounted) {
      final done = await runAction(context, () => ref.read(apiProvider).addSlot(num.text.trim(), type, floor.text.trim()), success: 'Slot added');
      if (done) ref.invalidate(slotsProvider);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final slots = ref.watch(slotsProvider);
    final api = ref.read(apiProvider);
    Future<void> act(Future<void> Function() f, String ok) async {
      if (await runAction(context, f, success: ok)) {
        ref.invalidate(slotsProvider);
        ref.invalidate(bookingsProvider);
      }
    }

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(slotsProvider),
      child: ListView(padding: const EdgeInsets.all(16), children: [
        Row(children: [
          const Text('Slots', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          const Spacer(),
          FilledButton.icon(onPressed: () => _add(context, ref), icon: const Icon(Icons.add), label: const Text('Add slot')),
        ]),
        const SizedBox(height: 12),
        AsyncView<List<Slot>>(
          value: slots,
          onRetry: () => ref.invalidate(slotsProvider),
          builder: (list) {
            final counts = <String, int>{};
            for (final s in list) {
              counts[s.status] = (counts[s.status] ?? 0) + 1;
            }
            return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _StatusChart(counts),
              const SizedBox(height: 12),
              Card(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(columns: const [
                    DataColumn(label: Text('Slot')),
                    DataColumn(label: Text('Type')),
                    DataColumn(label: Text('Status')),
                    DataColumn(label: Text('Vehicle')),
                    DataColumn(label: Text('Actions')),
                  ], rows: [
                    for (final s in list)
                      DataRow(cells: [
                        DataCell(Text('${s.slotNumber} (${s.floor})')),
                        DataCell(Text(s.slotType)),
                        DataCell(StatusChip(s.status)),
                        DataCell(Text(s.vehicleNumber ?? '—')),
                        DataCell(Row(children: [
                          if (s.status == 'RESERVED') TextButton(onPressed: () => act(() => api.slotAction(s.id, 'entry'), '${s.slotNumber}: vehicle entered'), child: const Text('Simulate entry')),
                          if (s.status == 'OCCUPIED') TextButton(onPressed: () => act(() => api.slotAction(s.id, 'exit'), '${s.slotNumber}: vehicle exited'), child: const Text('Simulate exit')),
                          if (s.status == 'AVAILABLE') TextButton(onPressed: () => act(() => api.setSlotStatus(s.id, 'UNAVAILABLE'), '${s.slotNumber} disabled'), child: const Text('Disable')),
                          if (s.status == 'UNAVAILABLE') TextButton(onPressed: () => act(() => api.setSlotStatus(s.id, 'AVAILABLE'), '${s.slotNumber} enabled'), child: const Text('Enable')),
                          if (s.status == 'AVAILABLE' || s.status == 'UNAVAILABLE')
                            IconButton(tooltip: 'Remove', icon: const Icon(Icons.delete_outline, color: AppColors.red), onPressed: () => act(() => api.deleteSlot(s.id), '${s.slotNumber} removed')),
                        ])),
                      ]),
                  ]),
                ),
              ),
            ]);
          },
        ),
      ]),
    );
  }
}

class _StatusChart extends StatelessWidget {
  const _StatusChart(this.counts);
  final Map<String, int> counts;
  @override
  Widget build(BuildContext context) {
    const order = ['AVAILABLE', 'RESERVED', 'OCCUPIED', 'UNAVAILABLE'];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: 160,
          child: BarChart(BarChartData(
            gridData: const FlGridData(show: false),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 28, interval: 5)),
              topTitles: const AxisTitles(),
              rightTitles: const AxisTitles(),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (v, _) => Padding(padding: const EdgeInsets.only(top: 6), child: Text(order[v.toInt()].substring(0, 5), style: const TextStyle(fontSize: 11))),
                ),
              ),
            ),
            barGroups: [
              for (var i = 0; i < order.length; i++)
                BarChartGroupData(x: i, barRods: [BarChartRodData(toY: (counts[order[i]] ?? 0).toDouble(), color: AppColors.forSlot(order[i]), width: 28, borderRadius: BorderRadius.circular(4))]),
            ],
          )),
        ),
      ),
    );
  }
}

class _StationsTab extends ConsumerWidget {
  const _StationsTab();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stations = ref.watch(stationsProvider);
    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(stationsProvider),
      child: ListView(padding: const EdgeInsets.all(16), children: [
        const Text('Charging stations', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        AsyncView<List<Station>>(
          value: stations,
          onRetry: () => ref.invalidate(stationsProvider),
          builder: (list) => Column(children: [
            for (final s in list)
              Card(
                child: ListTile(
                  title: Text('${s.stationName} · ${s.powerKw.toStringAsFixed(0)} kW ${s.connectorType}'),
                  subtitle: Align(alignment: Alignment.centerLeft, child: Padding(padding: const EdgeInsets.only(top: 4), child: StatusChip(s.status))),
                  trailing: s.status == 'CHARGING'
                      ? const Text('In use', style: TextStyle(color: AppColors.grey))
                      : Switch(
                          value: s.status == 'AVAILABLE',
                          onChanged: (on) async {
                            if (await runAction(context, () => ref.read(apiProvider).setStationStatus(s.id, on ? 'AVAILABLE' : 'OFFLINE'), success: '${s.stationName} ${on ? 'online' : 'offline'}')) {
                              ref.invalidate(stationsProvider);
                            }
                          },
                        ),
                ),
              ),
          ]),
        ),
      ]),
    );
  }
}

class _BookingsTab extends ConsumerWidget {
  const _BookingsTab();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookings = ref.watch(bookingsProvider);
    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(bookingsProvider),
      child: ListView(padding: const EdgeInsets.all(16), children: [
        const Text('All bookings', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        AsyncView<List<Booking>>(
          value: bookings,
          onRetry: () => ref.invalidate(bookingsProvider),
          isEmpty: (l) => l.isEmpty,
          emptyText: 'No bookings yet',
          builder: (list) => Column(children: [for (final b in list) Padding(padding: const EdgeInsets.only(bottom: 10), child: BookingCard(booking: b))]),
        ),
      ]),
    );
  }
}

class _SessionsTab extends ConsumerWidget {
  const _SessionsTab();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessions = ref.watch(sessionsProvider);
    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(sessionsProvider),
      child: ListView(padding: const EdgeInsets.all(16), children: [
        const Text('Charging sessions', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        AsyncView<List<ChargeSession>>(
          value: sessions,
          onRetry: () => ref.invalidate(sessionsProvider),
          isEmpty: (l) => l.isEmpty,
          emptyText: 'No sessions yet',
          builder: (list) => Card(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(columns: const [
                DataColumn(label: Text('ID')),
                DataColumn(label: Text('User')),
                DataColumn(label: Text('Station')),
                DataColumn(label: Text('Started')),
                DataColumn(label: Text('kWh')),
                DataColumn(label: Text('Cost')),
                DataColumn(label: Text('Status')),
              ], rows: [
                for (final s in list)
                  DataRow(cells: [
                    DataCell(Text('${s.id}')),
                    DataCell(Text(s.userId)),
                    DataCell(Text(s.stationName)),
                    DataCell(Text(DateFormat('d MMM HH:mm').format(s.startTime))),
                    DataCell(Text(s.energyKwh.toStringAsFixed(2))),
                    DataCell(Text('₹${s.totalCost.toStringAsFixed(2)}')),
                    DataCell(StatusChip(s.status)),
                  ]),
              ]),
            ),
          ),
        ),
      ]),
    );
  }
}
