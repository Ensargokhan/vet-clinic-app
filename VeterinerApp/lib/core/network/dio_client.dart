import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DioClient {
  // Android Emulator için localhost IP'si 10.0.2.2'dir. Gerçek cihazda makinenin yerel IP'si yazılmalı.
  static const String baseUrl = 'http://10.0.2.2:5295/api';

  late final Dio _dio;

  DioClient() {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Eğer kullanıcı giriş yapmışsa Firebase token'ını alıp header'a ekleriz.
          final user = FirebaseAuth.instance.currentUser;
          if (user != null) {
            try {
              final token = await user.getIdToken();
              if (token != null) {
                options.headers['Authorization'] = 'Bearer $token';
              }
            } catch (e) {
              // Token alınamazsa istek yine de gönderilir, backend 401 döner
            }
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) {
          if (e.response?.statusCode == 429) {
            final retryAfter = e.response?.headers.value('Retry-After');
            final waitTime = retryAfter != null ? '$retryAfter saniye' : 'bir süre';
            
            final customError = DioException(
              requestOptions: e.requestOptions,
              response: e.response,
              type: e.type,
              error: 'Çok fazla istek gönderildi. Lütfen $waitTime bekleyip tekrar deneyin.',
            );
            return handler.next(customError);
          }
          
          // Hata yönetimi burada merkezi olarak yapılabilir
          return handler.next(e);
        },
      ),
    );
  }

  Dio get dio => _dio;
}

// Riverpod Provider kullanımı için ileride buraya Provider eklenecek.
