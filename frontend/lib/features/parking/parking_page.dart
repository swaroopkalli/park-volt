import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api.dart';
import '../../core/auth.dart';
import '../../core/data.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../widgets/common.dart';
import '../../widgets/motion.dart';
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
              return _ZoomableMap(
                child: GridView(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: cols, mainAxisSpacing: 10, crossAxisSpacing: 10, mainAxisExtent: 100),
                  children: [
                    for (var i = 0; i < list.length; i++)
                      _SlotCard(
                        key: ValueKey(list[i].id),
                        slot: list[i],
                        selected: list[i].id == selectedId,
                        onTap: list[i].status == 'AVAILABLE'
                            ? () => _openReserve(list[i])
                            : () => showSnack(context, 'Slot ${list[i].slotNumber} is ${list[i].status.toLowerCase()}'),
                      ).enter(context, index: i, stepMs: 35),
                  ],
                ),
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

class _SlotCard extends StatefulWidget {
  const _SlotCard({super.key, required this.slot, required this.selected, required this.onTap});
  final Slot slot;
  final bool selected;
  final VoidCallback onTap;
  @override
  State<_SlotCard> createState() => _SlotCardState();
}

class _SlotCardState extends State<_SlotCard> {
  bool hover = false;

  @override
  Widget build(BuildContext context) {
    final slot = widget.slot;
    final selected = widget.selected;
    final color = selected ? AppColors.blue : AppColors.forSlot(slot.status);
    final clickable = slot.status == 'AVAILABLE';
    return MouseRegion(
      cursor: clickable ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => hover = true),
      onExit: (_) => setState(() => hover = false),
      child: AnimatedScale(
        scale: hover && clickable ? 1.04 : 1,
        duration: motion(context, 150),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
        duration: motion(context, 350),
        curve: Curves.easeOut,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          border: Border.all(color: color, width: selected ? 3 : 1.5),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            ...glow(AppColors.blue, selected),
            if (hover && clickable) BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 12, offset: const Offset(0, 4)),
          ],
        ),
        child: FittedBox(fit: BoxFit.scaleDown, child: Column(mainAxisSize: MainAxisSize.min, children: [
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(slot.slotNumber, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
            if (slot.slotType == 'EV') Icon(Icons.bolt, size: 18, color: color),
            if (slot.slotType == 'ACCESSIBLE') Icon(Icons.accessible, size: 18, color: color),
          ]),
          Text('${slot.slotType} · floor ${slot.floor}', style: const TextStyle(fontSize: 11, color: AppColors.navy)),
          const SizedBox(height: 2),
          Text(slot.status, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
        ])),
      ),
        ),
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
  String? doneMsg;

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
      final nav = Navigator.of(context);
      setState(() => doneMsg = 'Reserved ${b.slotNumber}\nBooking ID #${b.id}');
      await Future.delayed(motion(context, 1100));
      nav.pop();
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
    if (doneMsg != null) return _SuccessCheck(doneMsg!);
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

/// Pinch / ctrl-wheel zoom for the parking map. Panning only activates once zoomed in,
/// so normal page scrolling keeps working at 1x.
class _ZoomableMap extends StatefulWidget {
  const _ZoomableMap({required this.child});
  final Widget child;
  @override
  State<_ZoomableMap> createState() => _ZoomableMapState();
}

class _ZoomableMapState extends State<_ZoomableMap> {
  final _ctrl = TransformationController();
  bool zoomed = false;

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(() {
      final z = _ctrl.value.getMaxScaleOnAxis() > 1.02;
      if (z != zoomed) setState(() => zoomed = z);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTap: () => _ctrl.value = Matrix4.identity(),
      child: InteractiveViewer(
        transformationController: _ctrl,
        minScale: 1,
        maxScale: 3,
        panEnabled: zoomed,
        clipBehavior: Clip.none,
        child: widget.child,
      ),
    );
  }
}

/// Animated tick shown after a successful reservation.
class _SuccessCheck extends StatelessWidget {
  const _SuccessCheck(this.message);
  final String message;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: motion(context, 600),
          curve: Curves.elasticOut,
          builder: (_, v, __) => Transform.scale(
            scale: v.clamp(0.0, 1.2),
            child: const CircleAvatar(radius: 36, backgroundColor: AppColors.green, child: Icon(Icons.check, color: Colors.white, size: 44)),
          ),
        ),
        const SizedBox(height: 16),
        Text(message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.navy)),
      ]),
    );
  }
}
