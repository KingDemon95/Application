// import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import '../main.dart' show navigatorKey;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  /// Payload yang belum sempat diproses (app masih loading)
  String? _pendingPayload;

  Future<void> init() async {
    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      InitializationSettings(android: androidSettings, iOS: iosSettings),
      onDidReceiveNotificationResponse: _onNotificationTap,
      onDidReceiveBackgroundNotificationResponse: _onBackgroundNotifTap,
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    // Cek apakah app di-launch dari notifikasi (kondisi terminated)
    final launchDetails = await _plugin.getNotificationAppLaunchDetails();
    if (launchDetails != null &&
        launchDetails.didNotificationLaunchApp &&
        launchDetails.notificationResponse?.payload != null) {
      // Simpan dulu, belum bisa navigate karena navigator belum siap
      _pendingPayload = launchDetails.notificationResponse!.payload;
    }
  }

  /// Panggil ini di HomeScreen.initState() setelah login
  void handlePendingNavigation() {
    if (_pendingPayload != null) {
      final payload = _pendingPayload!;
      _pendingPayload = null;
      Future.delayed(const Duration(milliseconds: 300), () {
        _navigateFromPayload(payload);
      });
    }
  }

  void _onNotificationTap(NotificationResponse response) {
    final payload = response.payload ?? '';
    if (payload.isEmpty) return;

    final navigator = navigatorKey.currentState;
    if (navigator != null) {
      _navigateFromPayload(payload);
    } else {
      _pendingPayload = payload;
    }
  }

  void _navigateFromPayload(String payload) {
    print('🔔 navigateFromPayload: $payload');
    print('🔔 navigatorKey state: ${navigatorKey.currentState}');
    if (payload.isEmpty) return;

    final parts = payload.split('|');
    final pengingatId = parts[0];
    final namaObat = parts.length > 1 ? parts[1] : '';

    navigatorKey.currentState?.pushNamed(
      '/pengingat-detail',
      arguments: {
        'pengingatId': pengingatId,
        'namaObat': namaObat,
      },
    );
  }

  Future<void> jadwalkanPengingat({
    required int baseId,
    required String pengingatId,
    required String namaObat,
    required List<Map<String, dynamic>> jadwal,
  }) async {
    await batalkanPengingat(baseId: baseId, jumlah: 10);

    for (final j in jadwal) {
      final urutan = j['urutan'] as int;
      final jam = j['jam'] as int;
      final menit = j['menit'] as int;

      await _plugin.zonedSchedule(
        baseId + urutan,
        '💊 Waktunya minum obat!',
        '$namaObat – dosis ke-$urutan (${_formatWaktu(jam, menit)})',
        _nextInstanceOfTime(jam, menit),
        _notifDetails(namaObat),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: '$pengingatId|$namaObat',
      );
    }
  }

  Future<void> batalkanPengingat({
    required int baseId,
    int jumlah = 10,
  }) async {
    for (int i = 1; i <= jumlah; i++) {
      await _plugin.cancel(baseId + i);
    }
  }

  Future<void> batalkanSemua() async => _plugin.cancelAll();

  tz.TZDateTime _nextInstanceOfTime(int jam, int menit) {
    final now = tz.TZDateTime.now(tz.local);
    var t = tz.TZDateTime(tz.local, now.year, now.month, now.day, jam, menit);
    if (t.isBefore(now)) t = t.add(const Duration(days: 1));
    return t;
  }

  NotificationDetails _notifDetails(String namaObat) => NotificationDetails(
        android: AndroidNotificationDetails(
          'pengingat_obat',
          'Pengingat Minum Obat',
          channelDescription: 'Notifikasi pengingat waktu minum obat harian',
          importance: Importance.max,
          priority: Priority.high,
          ticker: 'Waktunya minum $namaObat',
          enableVibration: true,
          playSound: true,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );

  String _formatWaktu(int jam, int menit) =>
      '${jam.toString().padLeft(2, '0')}:${menit.toString().padLeft(2, '0')}';
}

@pragma('vm:entry-point')
void _onBackgroundNotifTap(NotificationResponse response) {
  // Tidak bisa navigate dari isolate background,
  // payload akan dihandle via getNotificationAppLaunchDetails saat app buka
}