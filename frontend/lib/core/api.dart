import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/models.dart';
import 'auth.dart';

const apiBase = String.fromEnvironment('API_BASE', defaultValue: 'http://localhost:8000/api');

/// A friendly error carrying the gateway's error payload.
class ApiError implements Exception {
  ApiError(this.message, {this.status, this.code, this.service});
  final String message;
  final int? status;
  final String? code;
  final String? service;

  bool get isUnavailable => status == 503;

  static ApiError from(Object e) {
    if (e is ApiError) return e;
    if (e is DioException) {
      final data = e.response?.data;
      final status = e.response?.statusCode;
      if (data is Map) {
        final svc = data['service'] as String?;
        if (status == 503) {
          return ApiError('${_pretty(svc)} is unavailable', status: 503, code: 'SERVICE_UNAVAILABLE', service: svc);
        }
        return ApiError((data['message'] ?? 'Request failed').toString(), status: status, code: data['error']?.toString());
      }
      if (status == null) {
        return ApiError('Cannot reach the server. Is the gateway running at $apiBase?', status: 503, code: 'NETWORK');
      }
      return ApiError('Request failed ($status)', status: status);
    }
    return ApiError(e.toString());
  }

  static String _pretty(String? svc) {
    switch (svc) {
      case 'parking-service':
        return 'Parking service';
      case 'booking-service':
        return 'Booking service';
      case 'charging-service':
        return 'Charging service';
      default:
        return 'A backend service';
    }
  }

  @override
  String toString() => message;
}

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(BaseOptions(
    baseUrl: apiBase,
    connectTimeout: const Duration(seconds: 5),
    receiveTimeout: const Duration(seconds: 15),
    headers: {'Content-Type': 'application/json'},
  ));
  dio.interceptors.add(InterceptorsWrapper(onRequest: (o, h) {
    final u = ref.read(userProvider);
    if (u != null) {
      o.headers['X-User-Id'] = u.id;
      o.headers['X-User-Role'] = u.role;
    }
    h.next(o);
  }));
  return dio;
});

final apiProvider = Provider<Api>((ref) => Api(ref.watch(dioProvider)));

class Api {
  Api(this._d);
  final Dio _d;

  Future<T> _run<T>(Future<T> Function() f) async {
    try {
      return await f();
    } catch (e) {
      throw ApiError.from(e);
    }
  }

  List<T> _list<T>(Response r, T Function(Map<String, dynamic>) f) =>
      (r.data as List).map((e) => f(Map<String, dynamic>.from(e as Map))).toList();

  // parking
  Future<List<Slot>> slots() => _run(() async => _list(await _d.get('/parking/slots'), Slot.fromJson));
  Future<void> addSlot(String number, String type, String floor) =>
      _run(() => _d.post('/parking/slots', data: {'slotNumber': number, 'slotType': type, 'floor': floor}));
  Future<void> deleteSlot(int id) => _run(() => _d.delete('/parking/slots/$id'));
  Future<void> setSlotStatus(int id, String s) => _run(() => _d.patch('/parking/slots/$id/status', data: {'status': s}));
  Future<void> slotAction(int id, String action) => _run(() => _d.post('/parking/slots/$id/$action'));

  // bookings
  Future<List<Booking>> bookings({String? userId}) => _run(() async =>
      _list(await _d.get(userId == null ? '/bookings' : '/bookings/user/$userId'), Booking.fromJson));
  Future<Booking> createBooking(String userId, int slotId, String vehicle) => _run(() async {
        final r = await _d.post('/bookings', data: {'userId': userId, 'slotId': slotId, 'vehicleNumber': vehicle});
        return Booking.fromJson(Map<String, dynamic>.from(r.data as Map));
      });
  Future<void> bookingAction(int id, String action) => _run(() => _d.patch('/bookings/$id/$action'));

  // charging
  Future<List<Station>> stations() => _run(() async => _list(await _d.get('/charging/stations'), Station.fromJson));
  Future<void> setStationStatus(int id, String s) => _run(() => _d.patch('/charging/stations/$id/status', data: {'status': s}));
  Future<List<ChargeSession>> sessions({String? userId}) => _run(() async =>
      _list(await _d.get('/charging/sessions', queryParameters: {if (userId != null) 'userId': userId}), ChargeSession.fromJson));
  Future<ChargeSession> session(int id) => _run(() async =>
      ChargeSession.fromJson(Map<String, dynamic>.from((await _d.get('/charging/sessions/$id')).data as Map)));
  Future<ChargeSession> startSession(String userId, int bookingId, int stationId, double? target) => _run(() async {
        final r = await _d.post('/charging/sessions/start',
            data: {'userId': userId, 'bookingId': bookingId, 'stationId': stationId, if (target != null) 'targetKwh': target});
        return ChargeSession.fromJson(Map<String, dynamic>.from(r.data as Map));
      });
  Future<void> stopSession(int id) => _run(() => _d.patch('/charging/sessions/$id/stop'));
}
