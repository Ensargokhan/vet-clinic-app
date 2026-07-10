import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/error_state.dart';
import '../../../../shared/widgets/loading_indicator.dart';
import '../../data/models/notification_model.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<NotificationModel> _notifications = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await DioClient().dio.get('/notifications');
      if (response.data['success'] == true) {
        final List<dynamic> data = response.data['data'] ?? [];
        setState(() {
          _notifications =
              data.map((e) => NotificationModel.fromJson(e)).toList();
          _isLoading = false;
        });
      }
    } on DioException catch (e) {
      setState(() {
        _errorMessage = e.response?.data?['message'] ?? 'Bildirimler yüklenemedi';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Beklenmeyen bir hata oluştu.';
        _isLoading = false;
      });
    }
  }

  Future<void> _markRead(NotificationModel n) async {
    if (n.isRead) return;
    try {
      await DioClient().dio.put('/notifications/${n.id}/read');
      _load();
    } catch (_) {
      // sessiz geç; liste yenilenince güncel gelir
    }
  }

  Future<void> _markAllRead() async {
    try {
      await DioClient().dio.put('/notifications/read-all');
      _load();
    } catch (_) {}
  }

  IconData _iconFor(String type) {
    switch (type) {
      case 'appointment_created':
        return Icons.event_available_outlined;
      case 'appointment_status':
        return Icons.event_note_outlined;
      case 'appointment_reminder':
        return Icons.alarm_outlined;
      case 'vaccine_reminder':
        return Icons.vaccines_outlined;
      case 'new_message':
        return Icons.chat_bubble_outline;
      case 'clinic_announcement':
        return Icons.campaign_outlined;
      case 'new_review':
        return Icons.star_outline;
      default:
        return Icons.notifications_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasUnread = _notifications.any((n) => !n.isRead);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bildirimler'),
        actions: [
          if (!_isLoading && _errorMessage == null && hasUnread)
            TextButton(
              onPressed: _markAllRead,
              child: const Text('Tümünü okundu yap'),
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const LoadingIndicator();
    if (_errorMessage != null) {
      return ErrorState(message: _errorMessage!, onRetry: _load);
    }
    if (_notifications.isEmpty) {
      return const EmptyState(
        icon: Icons.notifications_none_outlined,
        message: 'Henüz bildiriminiz yok.',
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      color: context.scheme.primary,
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.lg),
        itemCount: _notifications.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
        itemBuilder: (context, index) => _card(_notifications[index]),
      ),
    );
  }

  Widget _card(NotificationModel n) {
    final unread = !n.isRead;
    final dateStr =
        DateFormat('dd MMM yyyy, HH:mm', 'tr_TR').format(n.createdAt);
    final accent = context.scheme.primary;

    return AppCard(
      onTap: () => _markRead(n),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: accent.withOpacity(unread ? 0.14 : 0.08),
              borderRadius: AppRadius.mdAll,
            ),
            child: Icon(_iconFor(n.type),
                color: unread ? accent : context.colors.textSecondary, size: 20),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        n.title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight:
                                  unread ? FontWeight.w700 : FontWeight.w600,
                            ),
                      ),
                    ),
                    if (unread)
                      Container(
                        width: 9,
                        height: 9,
                        margin: const EdgeInsets.only(left: AppSpacing.sm, top: 4),
                        decoration:
                            BoxDecoration(color: accent, shape: BoxShape.circle),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(n.body, style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: AppSpacing.xs),
                Text(dateStr, style: Theme.of(context).textTheme.labelSmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
