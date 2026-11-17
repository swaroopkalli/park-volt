class Slot {
  Slot({required this.id, required this.slotNumber, required this.slotType, required this.status, required this.floor, this.vehicleNumber});
  final int id;
  final String slotNumber, slotType, status, floor;
  final String? vehicleNumber;
  factory Slot.fromJson(Map<String, dynamic> j) => Slot(
        id: j['id'],
        slotNumber: j['slotNumber'],
        slotType: j['slotType'],
        status: j['status'],
        floor: j['floor'],
        vehicleNumber: j['vehicleNumber'],
      );
}

class Booking {
  Booking({required this.id, required this.userId, required this.slotId, required this.slotNumber, required this.slotType,
      required this.vehicleNumber, required this.bookingDate, required this.status, this.parkingFee});
  final int id, slotId;
  final String userId, slotNumber, slotType, vehicleNumber, status;
  final DateTime bookingDate;
  final double? parkingFee;
  factory Booking.fromJson(Map<String, dynamic> j) => Booking(
        id: j['id'],
        userId: j['userId'],
        slotId: j['slotId'],
        slotNumber: j['slotNumber'],
        slotType: j['slotType'],
        vehicleNumber: j['vehicleNumber'],
        bookingDate: DateTime.parse(j['bookingDate']).toLocal(),
        status: j['status'],
        parkingFee: (j['parkingFee'] as num?)?.toDouble(),
      );
}

class Station {
  Station({required this.id, required this.stationName, required this.powerKw, required this.connectorType, required this.status});
  final int id;
  final String stationName, connectorType, status;
  final double powerKw;
  factory Station.fromJson(Map<String, dynamic> j) => Station(
        id: j['id'],
        stationName: j['stationName'],
        powerKw: (j['powerKw'] as num).toDouble(),
        connectorType: j['connectorType'],
        status: j['status'],
      );
}

class ChargeSession {
  ChargeSession({required this.id, required this.userId, required this.bookingId, required this.stationId, required this.stationName,
      required this.powerKw, required this.startTime, this.endTime, required this.energyKwh, required this.totalCost,
      required this.targetKwh, required this.progressPercent, required this.status});
  final int id, bookingId, stationId;
  final String userId, stationName, status;
  final double powerKw, energyKwh, totalCost, targetKwh, progressPercent;
  final DateTime startTime;
  final DateTime? endTime;
  bool get active => status == 'ACTIVE';
  factory ChargeSession.fromJson(Map<String, dynamic> j) => ChargeSession(
        id: j['id'],
        userId: j['userId'],
        bookingId: j['bookingId'],
        stationId: j['stationId'],
        stationName: j['stationName'],
        powerKw: (j['powerKw'] as num).toDouble(),
        startTime: DateTime.parse(j['startTime']).toLocal(),
        endTime: j['endTime'] == null ? null : DateTime.parse(j['endTime']).toLocal(),
        energyKwh: (j['energyKwh'] as num).toDouble(),
        totalCost: (j['totalCost'] as num).toDouble(),
        targetKwh: (j['targetKwh'] as num).toDouble(),
        progressPercent: (j['progressPercent'] as num).toDouble(),
        status: j['status'],
      );
}
