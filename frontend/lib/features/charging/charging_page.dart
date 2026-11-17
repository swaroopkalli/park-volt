import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/api.dart';
import '../../core/auth.dart';
import '../../core/data.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../widgets/common.dart';
import '../../widgets/poller.dart';

class ChargingPage extends ConsumerWidget {
  const ChargingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stations = ref.watch(stationsProvider);
    final sessions = ref.watch(sessionsProvider);

    void refresh() {
      ref.invalidate(stationsProvider);
      ref.invalidate(sessionsProvider);
    }

    return Poller(
      interval: const Duration(seconds: 2),
      onTick: refresh,
      child: RefreshIndicator(
        onRefresh: () async => refresh(),
        child: ListView(padding: const EdgeInsets.all(16), children: [
          const Text('EV Charging', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.navy)),
          const SizedBox(height: 12),
          // Charging may be down while the rest of the app works: show one friendly banner.
          if (stations.hasError && !stations.hasValue) ErrorBanner(error: stations.error!, onRetry: refresh),
          if (sessions.hasValue) ...[
            for (final s in sessions.requireValue.where((s) => s.active)) Padding(padding: const EdgeInsets.only(bottom: 12), child: _LiveSessionCard(session: s)),
          ],
          if (stations.hasValue) ...[
            const Text('Stations', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            LayoutBuilder(builder: (context, c) {
              final cols = (c.maxWidth / 220).floor().clamp(1, 5);
              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: cols,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 2.0,
                children: [for (final s in stations.requireValue) _StationCard(station: s)],
              );
            }),
            const SizedBox(height: 20),
            _StartForm(stations: stations.requireValue),
          ] else if (!stations.hasError)
            const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator())),
          const SizedBox(height: 20),
          const Text('Session history', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          if (sessions.hasValue)
            if (sessions.requireValue.where((s) => !s.active).isEmpty)
              const Text('No past sessions', style: TextStyle(color: AppColors.grey))
            else
              for (final s in sessions.requireValue.where((s) => !s.active))
                Card(
                  child: ListTile(
                    title: Text('#${s.id} · ${s.stationName} · ${s.energyKwh.toStringAsFixed(2)} kWh'),
                    subtitle: Text('${DateFormat('d MMM HH:mm').format(s.startTime)} · ₹${s.totalCost.toStringAsFixed(2)}'),
                    trailing: StatusChip(s.status),
                  ),
                )
          else if (sessions.hasError)
            ErrorBanner(error: sessions.error!, onRetry: refresh),
        ]),
      ),
    );
  }
}

class _StationCard extends StatelessWidget {
  const _StationCard({required this.station});
  final Station station;
  @override
  Widget build(BuildContext context) {
    final c = AppColors.forStatus(station.status);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
          Row(children: [
            Icon(Icons.ev_station, color: c),
            const SizedBox(width: 6),
            Text(station.stationName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const Spacer(),
            StatusChip(station.status),
          ]),
          const SizedBox(height: 6),
          Text('${station.powerKw.toStringAsFixed(0)} kW · ${station.connectorType}', style: const TextStyle(color: AppColors.grey)),
        ]),
      ),
    );
  }
}

class _StartForm extends ConsumerStatefulWidget {
  const _StartForm({required this.stations});
  final List<Station> stations;
  @override
  ConsumerState<_StartForm> createState() => _StartFormState();
}

class _StartFormState extends ConsumerState<_StartForm> {
  int? bookingId;
  int? stationId;
  final _target = TextEditingController(text: '20');
  bool busy = false;

  @override
  void dispose() {
    _target.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    final user = ref.read(userProvider)!;
    setState(() => busy = true);
    final ok = await runAction(
      context,
      () => ref.read(apiProvider).startSession(user.id, bookingId!, stationId!, double.tryParse(_target.text)),
      success: 'Charging started',
    );
    if (!mounted) return;
    setState(() => busy = false);
    if (ok) {
      ref.invalidate(sessionsProvider);
      ref.invalidate(stationsProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider)!;
    final bookings = ref.watch(bookingsProvider);
    final free = widget.stations.where((s) => s.status == 'AVAILABLE').toList();
    final eligible = (bookings.value ?? []).where((b) => b.slotType == 'EV' && (b.status == 'CONFIRMED' || b.status == 'ACTIVE') && b.userId == user.id).toList();
    if (!eligible.any((b) => b.id == bookingId)) bookingId = null;
    if (!free.any((s) => s.id == stationId)) stationId = null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Text('Start charging', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          if (eligible.isEmpty)
            const Text('You need a CONFIRMED or ACTIVE booking on an EV slot (P11–P17) to charge.', style: TextStyle(color: AppColors.grey))
          else
            Wrap(spacing: 12, runSpacing: 12, crossAxisAlignment: WrapCrossAlignment.center, children: [
              SizedBox(
                width: 260,
                child: DropdownButtonFormField<int>(
                  value: bookingId,
                  decoration: const InputDecoration(labelText: 'Booking', border: OutlineInputBorder()),
                  items: [for (final b in eligible) DropdownMenuItem(value: b.id, child: Text('#${b.id} · ${b.slotNumber} · ${b.status}'))],
                  onChanged: (v) => setState(() => bookingId = v),
                ),
              ),
              SizedBox(
                width: 220,
                child: DropdownButtonFormField<int>(
                  value: stationId,
                  decoration: InputDecoration(labelText: free.isEmpty ? 'No free station' : 'Station', border: const OutlineInputBorder()),
                  items: [for (final s in free) DropdownMenuItem(value: s.id, child: Text('${s.stationName} · ${s.powerKw.toStringAsFixed(0)} kW'))],
                  onChanged: (v) => setState(() => stationId = v),
                ),
              ),
              SizedBox(
                width: 120,
                child: TextField(controller: _target, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Target kWh', border: OutlineInputBorder())),
              ),
              FilledButton.icon(
                onPressed: busy || bookingId == null || stationId == null ? null : _start,
                icon: const Icon(Icons.bolt),
                label: const Padding(padding: EdgeInsets.all(12), child: Text('Start')),
              ),
            ]),
        ]),
      ),
    );
  }
}

class _LiveSessionCard extends ConsumerWidget {
  const _LiveSessionCard({required this.session});
  final ChargeSession session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = session;
    return Card(
      color: AppColors.navy,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.bolt, color: Colors.amber),
            const SizedBox(width: 6),
            Text('Charging on ${s.stationName}', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
            const Spacer(),
            Text('#${s.id}', style: const TextStyle(color: Colors.white54)),
          ]),
          const SizedBox(height: 16),
          Wrap(spacing: 32, runSpacing: 8, children: [
            _Metric('Energy', '${s.energyKwh.toStringAsFixed(2)} kWh'),
            _Metric('Cost', '₹${s.totalCost.toStringAsFixed(2)}'),
            _Metric('Power', '${s.powerKw.toStringAsFixed(0)} kW'),
            _Metric('Target', '${s.targetKwh.toStringAsFixed(0)} kWh'),
          ]),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(value: s.progressPercent / 100, minHeight: 12, backgroundColor: Colors.white24, color: AppColors.green),
          ),
          const SizedBox(height: 6),
          Text('${s.progressPercent.toStringAsFixed(1)}%', style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 12),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.red),
            onPressed: () async {
              final ok = await runAction(context, () => ref.read(apiProvider).stopSession(s.id), success: 'Charging stopped');
              if (ok) {
                ref.invalidate(sessionsProvider);
                ref.invalidate(stationsProvider);
              }
            },
            child: const Text('Stop charging'),
          ),
        ]),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric(this.label, this.value);
  final String label, value;
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
      ]);
}
