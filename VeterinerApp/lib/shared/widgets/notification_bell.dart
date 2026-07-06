import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/network/dio_client.dart';
import '../../core/theme/app_colors.dart';

/// AppBar'a eklenen zil ikonu + okunmamış bildirim rozeti.
/// Tıklandığında bildirim merkezine gider ve dönüşte sayacı yeniler.
class NotificationBell extends StatefulWidget {
  /// İkon rengi (primary zemin gibi yerlerde onPrimary verilebilir). Null ise tema varsayılanı.
  final Color? color;
  const NotificationBell({super.key, this.color});

  @override
  State<NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends State<NotificationBell> {
  int _unread = 0;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    try {
      final response = await DioClient().dio.get('/notifications/unread-count');
      if (response.data['success'] == true && mounted) {
        setState(() => _unread = response.data['data']['count'] ?? 0);
      }
    } catch (_) {
      // sessiz geç
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        IconButton(
          icon: Icon(Icons.notifications_outlined, color: widget.color),
          tooltip: 'Bildirimler',
          onPressed: () => context.push('/notifications').then((_) => _fetch()),
        ),
        if (_unread > 0)
          Positioned(
            right: 6,
            top: 6,
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
