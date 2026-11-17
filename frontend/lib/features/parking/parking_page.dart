import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api.dart';
import '../../core/auth.dart';
import '../../core/data.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../widgets/common.dart';
import '../../widgets/poller.dart';

class ParkingPage extends ConsumerStatefulWidget {
  const ParkingPage({super.key});
  @override
  ConsumerState<ParkingPage> createState() => _ParkingPageState();
}

class _ParkingPageState extends ConsumerState<ParkingPage> {
  int? selectedId;

  Future<void> _openReserve(Slot slot) async {
    setState(() => selectedId = slot.id);
    final wide = MediaQuery.sizeOf(context).width >= 800;
    final panel = _ReservePanel(slot: slot);
    if (wide) {
      await showDialog(context: context, builder: (_) => Dialog(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 420), child: panel)));
    } else {
      await showModalBottomSheet(context: context, isScrollControlled: true, builder: (_) => Padding(padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom), child: panel));
    }
    if (mounted) setState(() => selectedId = null);
  }

  @override
  Widget build(BuildContext context) {
    final slots = ref.watch(slotsProvider);
    return Poller(
      interval: const Duration(seconds: 10),
      onTick: () => ref.invalidate(slotsProvider),
      child: RefreshIndicator(
        onRefresh: () async => ref.invalidate(slotsProvider),
        child: ListView(padding: const EdgeInsets.all(16), children: [
          const Text('Parking', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.navy)),
          const SizedBox(height: 8),
          const Wrap(spacing: 14, runSpacing: 4, children: [
            _Legend('Available', AppColors.green),
            _Legend('Reserved', AppColors.orange),
            _Legend('Occupied', AppColors.red),
            _Legend('Unavailable', AppColors.grey),
            _Legend('Selected', AppColors.blue),
          ]),
          const SizedBox(height: 12),
          AsyncView<List<Slot>>(
            value: slots,
            onRetry: () => ref.invalidate(slotsProvider),
            isEmpty: (l) => l.isEmpty,
            emptyText: 'No parking slots configured',
            builder: (list) => LayoutBuilder(builder: (context, c) {
              final cols = (c.maxWidth / 140).floor().clamp(2, 8);
              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: cols,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.15,
                children: [
                  for (final s in list)
                    _SlotCard(
                      slot: s,
                      selected: s.id == selectedId,
                      onTap: s.status == 'AVAILABLE'
                          ? () => _openReserve(s)
                          : () => showSnack(context, 'Slot ${s.slotNumber} is ${s.status.toLowerCase()}'),
                    ),
                ],
              );
            }),
          ),
        ]),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend(this.label, this.color);
  final String label;
  final Color color;
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12)),
      ]);
}

class _SlotCard extends StatelessWidget {
  const _SlotCard({required this.slot, required this.selected, required this.onTap});
  final Slot slot;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.blue : AppColors.forSlot(slot.status);
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          border: Border.all(color: color, width: selected ? 3 : 1.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(slot.slotNumber, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
            if (slot.slotType == 'EV') Icon(Icons.bolt, size: 18, color: color),
            if (slot.slotType == 'ACCESSIBLE') Icon(Icons.accessible, size: 18, color: color),
          ]),
          Text('${slot.slotType} · floor ${slot.floor}', style: const TextStyle(fontSize: 11, color: AppColors.navy)),
          const SizedBox(height: 2),
          Text(slot.status, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
        ]),
      ),
    );
  }
}

class _ReservePanel extends ConsumerStatefulWidget {
  const _ReservePanel({required this.slot});
  final Slot slot;
  @override
  ConsumerState<_ReservePanel> createState() => _ReservePanelState();
}

class _ReservePanelState extends ConsumerState<_ReservePanel> {
  final _vehicle = TextEditingController();
  final _form = GlobalKey<FormState>();
  bool busy = false;
  ApiError? error;

  @override
  void dispose() {
    _vehicle.dispose();
    super.dispose();
  }

  Future<void> _reserve() async {
    if (!_form.currentState!.validate()) return;
    final user = ref.read(userProvider)!;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final b = await ref.read(apiProvider).createBooking(user.id, widget.slot.id, _vehicle.text.trim().toUpperCase());
      ref.invalidate(slotsProvider);
      ref.invalidate(bookingsProvider);
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop();
      messenger.showSnackBar(SnackBar(content: Text('Reserved ${b.slotNumber} · Booking ID #${b.id}'), backgroundColor: AppColors.green, behavior: SnackBarBehavior.floating));
    } catch (e) {
      if (mounted) setState(() => error = ApiError.from(e));
      ref.invalidate(slotsProvider);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.slot;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _form,
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('Reserve ${s.slotNumber}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.navy)),
          const SizedBox(height: 4),
          Text('${s.slotType} · floor ${s.floor}', style: const TextStyle(color: AppColors.grey)),
          const SizedBox(height: 16),
          TextFormField(
            controller: _vehicle,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(labelText: 'Vehicle number', hintText: 'KA03AB1234', border: OutlineInputBorder()),
            validator: (v) => (v == null || v.trim().length < 4) ? 'Enter a vehicle number' : null,
            onFieldSubmitted: (_) => _reserve(),
          ),
          if (error != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(error!.message, style: const TextStyle(color: AppColors.red))),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: busy ? null : _reserve,
            child: Padding(padding: const EdgeInsets.all(12), child: busy ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Reserve')),
          ),
        ]),
      ),
    );
  }
}
