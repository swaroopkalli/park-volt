import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/models.dart';
import 'api.dart';
import 'auth.dart';

final slotsProvider = FutureProvider.autoDispose<List<Slot>>((ref) => ref.watch(apiProvider).slots());

final stationsProvider = FutureProvider.autoDispose<List<Station>>((ref) => ref.watch(apiProvider).stations());

/// Admin sees every booking, students only their own (GET /bookings is admin-only at the gateway).
final bookingsProvider = FutureProvider.autoDispose<List<Booking>>((ref) {
  final u = ref.watch(userProvider);
  return ref.watch(apiProvider).bookings(userId: u == null || u.isAdmin ? null : u.id);
});

final sessionsProvider = FutureProvider.autoDispose<List<ChargeSession>>((ref) {
  final u = ref.watch(userProvider);
  return ref.watch(apiProvider).sessions(userId: u == null || u.isAdmin ? null : u.id);
});
