import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/api.dart';
import '../../core/auth.dart';
import '../../core/data.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../widgets/common.dart';
import '../../widgets/motion.dart';

class BookingsPage extends ConsumerWidget {
  const BookingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookings = ref.watch(bookingsProvider);
    final user = ref.watch(userProvider);
    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(bookingsProvider),
      child: ListView(padding: const EdgeInsets.all(16), children: [
        Text(user?.isAdmin ?? false ? 'All bookings' : 'My bookings', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.navy)),
        const SizedBox(height: 12),
        AsyncView<List<Booking>>(
          value: bookings,
          onRetry: () => ref.invalidate(bookingsProvider),
          isEmpty: (l) => l.isEmpty,
          emptyText: 'No bookings yet. Reserve a slot from the Parking tab.',
          builder: (list) => Column(children: [
            for (var i = 0; i < list.length; i++)
              Padding(padding: const EdgeInsets.only(bottom: 10), child: _Swipeable(booking: list[i]).enter(context, index: i, stepMs: 50)),
          ]),
        ),
      ]),
    );
  }
}

class BookingCard extends ConsumerWidget {
  const BookingCard({super.key, required this.booking});
  final Booking booking;

  Future<void> _do(BuildContext context, WidgetRef ref, String action, String ok) async {
    final done = await runAction(context, () => ref.read(apiProvider).bookingAction(booking.id, action), success: ok);
    if (done) {
      ref.invalidate(bookingsProvider);
      ref.invalidate(slotsProvider);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final b = booking;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text('#${b.id}  ${b.slotNumber}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.navy)),
            const SizedBox(width: 8),
            Text(b.slotType, style: const TextStyle(color: AppColors.grey)),
            const Spacer(),
            StatusChip(b.status),
          ]),
          const SizedBox(height: 6),
          Text('${b.vehicleNumber} · ${b.userId} · ${DateFormat('d MMM, HH:mm').format(b.bookingDate)}', style: const TextStyle(color: AppColors.grey)),
          if (b.parkingFee != null) Padding(padding: const EdgeInsets.only(top: 6), child: Text('Parking fee: ₹${b.parkingFee!.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w700))),
          if (b.status == 'CONFIRMED' || b.status == 'ACTIVE')
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Wrap(spacing: 8, children: [
                if (b.status == 'CONFIRMED') FilledButton(onPressed: () => _do(context, ref, 'check-in', 'Checked in to ${b.slotNumber}'), child: const Text('Check-in')),
                if (b.status == 'ACTIVE') FilledButton(onPressed: () => _do(context, ref, 'complete', 'Booking #${b.id} completed'), child: const Text('Complete')),
                if (b.status == 'CONFIRMED') OutlinedButton(onPressed: () => _do(context, ref, 'cancel', 'Booking #${b.id} cancelled'), child: const Text('Cancel')),
              ]),
            ),
        ]),
      ),
    );
  }
}

/// Swipe left on a CONFIRMED booking to cancel it (with confirmation).
class _Swipeable extends ConsumerWidget {
  const _Swipeable({required this.booking});
  final Booking booking;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final b = booking;
    if (b.status != 'CONFIRMED') return BookingCard(booking: b);
    return Dismissible(
      key: ValueKey('booking-${b.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(color: AppColors.red, borderRadius: BorderRadius.circular(12)),
        child: const Row(mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.end, children: [Icon(Icons.cancel, color: Colors.white), SizedBox(width: 8), Text('Cancel', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700))]),
      ),
      confirmDismiss: (_) async {
        final yes = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text('Cancel booking #${b.id}?'),
            content: Text('Slot ${b.slotNumber} will be released.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Keep')),
              FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Cancel booking')),
            ],
          ),
        );
        if (yes != true || !context.mounted) return false;
        await runAction(context, () => ref.read(apiProvider).bookingAction(b.id, 'cancel'), success: 'Booking #${b.id} cancelled');
        ref.invalidate(bookingsProvider);
        ref.invalidate(slotsProvider);
        return false; // list refreshes from the server; avoid a stale dismissed item
      },
      child: BookingCard(booking: b),
    );
  }
}
