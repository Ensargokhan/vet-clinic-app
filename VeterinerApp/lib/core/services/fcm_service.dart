import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../network/dio_client.dart';
import '../router/app_router.dart';

/// Uygulama arka plandayken/kapalıyken gelen mesajlar için top-level handler.
/// (main.dart'ta `FirebaseMessaging.onBackgroundMessage` ile kaydedilir.)
/// Sistem, notification payload'ını otomatik gösterir; burada ekstra iş gerekmez.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {}

/// Push bildirim (FCM) yönetimi: izin, token kaydı, foreground gösterimi ve
/// bildirime tıklayınca yönlendirme. Tekil (singleton).
class FcmService {
  FcmService._internal();
  static final FcmService _instance = FcmService._internal();
  factory FcmService() => _instance;

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'patilife_default',
    'Genel Bildirimler',
    description: 'Randevu ve klinik bildirimleri',
    importance: Importance.high,
  );

  bool _initialized = false;

  /// main.dart'ta Firebase.initializeApp sonrası bir kez çağrılır.
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    // Bildirim izni (Android 13+ runtime izni burada sorulur)
    await _messaging.requestPermission();

    // Local notifications: foreground'da banner göstermek için
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);
    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) =>
          _handlePayload(response.payload),
    );

    // Android bildirim kanalını oluştur
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    // Uygulama önplandayken gelen mesaj → local notification göster
    FirebaseMessaging.onMessage.listen(_showLocalNotification);

    // Bildirime tıklayıp uygulamayı açma (arka plandan)
    FirebaseMessaging.onMessageOpenedApp.listen(
      (message) => _navigateFromData(message.data),
    );

    // Uygulama tamamen kapalıyken bildirime tıklayıp açma
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _navigateFromData(initialMessage.data);
    }
  }

  /// Giriş yaptıktan SONRA çağrılır: FCM token'ını backend'e kaydeder.
  Future<void> registerToken() async {
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        await _sendTokenToBackend(token);
      }
      // Token yenilenirse tekrar kaydet
      _messaging.onTokenRefresh.listen(_sendTokenToBackend);
    } catch (_) {
      // Token alınamazsa akışı bozma
    }
  }

  /// Çıkışta çağrılır: token'ı backend'den ve cihazdan temizler.
  Future<void> clearToken() async {
    try {
      await DioClient().dio.delete('/notifications/device-token');
      await _messaging.deleteToken();
    } catch (_) {}
  }

  Future<void> _sendTokenToBackend(String token) async {
    try {
      await DioClient()
          .dio
          .post('/notifications/device-token', data: {'token': token});
    } catch (_) {}
  }

  void _showLocalNotification(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
      payload: _encodePayload(message.data),
    );
  }

  String _encodePayload(Map<String, dynamic> data) {
    final type = data['type']?.toString() ?? '';
    final relatedId = data['relatedId']?.toString() ?? '';
    return '$type|$relatedId';
  }

  void _handlePayload(String? payload) {
    if (payload == null) return;
    final parts = payload.split('|');
    final type = parts.isNotEmpty ? parts[0] : '';
    final relatedId = parts.length > 1 ? parts[1] : '';
    _navigate(type, relatedId);
  }

  void _navigateFromData(Map<String, dynamic> data) {
    _navigate(
      data['type']?.toString() ?? '',
      data['relatedId']?.toString() ?? '',
    );
  }

  /// Bildirim tipine göre yönlendirme. Yeni mesajda ilgili sohbete, aksi halde
  /// bildirim merkezine gider.
  void _navigate(String type, String relatedId) {
    if (type == 'new_message' && relatedId.isNotEmpty) {
      AppRouter.router.push('/messages/$relatedId');
      return;
    }
    AppRouter.router.push('/notifications');
  }
}
