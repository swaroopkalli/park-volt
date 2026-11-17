import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parkvolt/core/data.dart';
import 'package:parkvolt/main.dart';
import 'package:parkvolt/models/models.dart';

final _slots = [
  for (var i = 1; i <= 20; i++)
    Slot(id: i, slotNumber: 'P${i.toString().padLeft(2, '0')}', slotType: i > 10 ? 'EV' : 'REGULAR', status: ['AVAILABLE', 'RESERVED', 'OCCUPIED', 'UNAVAILABLE'][i % 4], floor: 'G'),
];
final _bookings = [
  Booking(id: 1, userId: 'student1', slotId: 11, slotNumber: 'P11', slotType: 'EV', vehicleNumber: 'KA03AB1234', bookingDate: DateTime(2026, 1, 1), status: 'CONFIRMED'),
];
final _stations = [Station(id: 1, stationName: 'EV01', powerKw: 7, connectorType: 'Type2', status: 'AVAILABLE')];
final _sessions = [
  ChargeSession(id: 1, userId: 'student1', bookingId: 1, stationId: 1, stationName: 'EV01', powerKw: 7, startTime: DateTime(2026, 1, 1), energyKwh: 3.2, totalCost: 25.6, targetKwh: 20, progressPercent: 16, status: 'ACTIVE'),
];

void main() {
  for (final size in const [Size(360, 740), Size(768, 1024), Size(1440, 900)]) {
    testWidgets('all sections render without errors at ${size.width.toInt()}px', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(ProviderScope(
        overrides: [
          slotsProvider.overrideWith((ref) async => _slots),
          bookingsProvider.overrideWith((ref) async => _bookings),
          stationsProvider.overrideWith((ref) async => _stations),
          sessionsProvider.overrideWith((ref) async => _sessions),
        ],
        child: const ParkVoltApp(),
      ));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Student 1'));
      await tester.pumpAndSettle(const Duration(milliseconds: 100), EnginePhase.sendSemanticsUpdate, const Duration(seconds: 10));
      for (final label in ['Parking', 'Bookings', 'Charging', 'Dashboard']) {
        await tester.tap(find.text(label).last);
        await tester.pump(const Duration(milliseconds: 900));
        await tester.pump(const Duration(milliseconds: 900));
        expect(tester.takeException(), isNull, reason: label);
      }
    });
  }
}
