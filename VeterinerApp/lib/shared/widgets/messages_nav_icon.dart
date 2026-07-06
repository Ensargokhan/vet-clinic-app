import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/network/dio_client.dart';
import '../../core/theme/app_colors.dart';

/// Alt navigasyondaki "Mesajlar" sekmesi ikonu + okunmamış mesaj rozeti.
/// Kendi kendine periyodik olarak okunmamış sayısını çeker (push-öncelikli tasarımı tamamlar).
class MessagesNavIcon extends StatefulWidget {
  const MessagesNavIcon({super.key});

  @override
  State<MessagesNavIcon> createState() => _MessagesNavIconState();
}

class _MessagesNavIconState extends State<MessagesNavIcon> {
  int _unread = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _fetch();
    _timer = Timer.periodic(const Duration(seconds: 20), (_) => _fetch());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetch() async {
    try {
      final response = await DioClient().dio.get('/conversations/unread-count');
      if (response.data['success'] == true && mounted) {
        setState(() => _unread = response.data['data']['count'] ?? 0);
      }
    } catch (_) {
      // sessiz geç
    }
  }

  @override
  Widget build(BuildContext context) {
    // Renk verilmez: NavigationBar seçili/seçili değil durumuna göre IconTheme uygular.
    return Stack(
      clipBehavior: Clip.none,
      children: [
        const Icon(Icons.chat_bubble_outline),
        if (_unread > 0)
          Positioned(
            right: -6,
            top: -4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              decoration: BoxDecoration(
                color: context.scheme.error,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Text(
                _unread > 99 ? '99+' : '$_unread',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: context.scheme.onError,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
