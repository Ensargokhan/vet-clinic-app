import 'dart:async';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/error_state.dart';
import '../../../../shared/widgets/loading_indicator.dart';
import '../../data/models/conversation_model.dart';
import '../../data/models/contact_model.dart';

class MessagesListScreen extends StatefulWidget {
  const MessagesListScreen({super.key});

  @override
  State<MessagesListScreen> createState() => _MessagesListScreenState();
}

class _MessagesListScreenState extends State<MessagesListScreen> {
  List<ConversationModel> _conversations = [];
  bool _isLoading = true;
  String? _error;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _load();
    // Hafif periyodik yenileme (push-öncelikli tasarımı tamamlar)
    _timer = Timer.periodic(const Duration(seconds: 12), (_) => _load(silent: true));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }
    try {
      final res = await DioClient().dio.get('/conversations');
      if (res.data['success'] == true && mounted) {
        final List<dynamic> data = res.data['data'] ?? [];
        setState(() {
          _conversations = data.map((e) => ConversationModel.fromJson(e)).toList();
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted && !silent) {
        setState(() {
          _error = 'Konuşmalar yüklenemedi.';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _openThread(int conversationId, String peerName) async {
    await context.push('/messages/$conversationId', extra: {'peerName': peerName});
    _load(silent: true);
  }

  Future<void> _startNew() async {
    List<ContactModel> contacts = [];
    try {
      final res = await DioClient().dio.get('/conversations/contacts');
      if (res.data['success'] == true) {
        final List<dynamic> data = res.data['data'] ?? [];
        contacts = data.map((e) => ContactModel.fromJson(e)).toList();
      }
    } catch (_) {}

    if (!mounted) return;
    if (contacts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Mesajlaşabileceğiniz kişi yok (ortak randevu gerekli).')),
      );
      return;
    }

    final selected = await showModalBottomSheet<ContactModel>(
      context: context,
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Text('Yeni Mesaj',
                  style: Theme.of(ctx).textTheme.titleLarge),
            ),
            for (final c in contacts)
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: ctx.scheme.primary.withOpacity(0.12),
                  child: Icon(Icons.person_outline, color: ctx.scheme.primary),
                ),
                title: Text(c.displayName),
                onTap: () => Navigator.pop(ctx, c),
              ),
          ],
        ),
      ),
    );

    if (selected == null || !mounted) return;

    try {
      final res = await DioClient()
          .dio
          .post('/conversations', data: {'peerUserId': selected.userId});
      if (res.data['success'] == true && mounted) {
        final convId = res.data['data']['conversationId'];
        await context.push('/messages/$convId', extra: {'peerName': selected.name});
        _load(silent: true);
      }
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.response?.data?['message'] ?? 'Konuşma başlatılamadı.'),
            backgroundColor: context.scheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mesajlar')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _startNew,
        icon: const Icon(Icons.edit_outlined),
        label: const Text('Yeni Mesaj'),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const LoadingIndicator();
    if (_error != null) {
      return ErrorState(message: _error!, onRetry: _load);
    }
    if (_conversations.isEmpty) {
      return const EmptyState(
        icon: Icons.forum_outlined,
        message: 'Henüz mesajınız yok.\n"Yeni Mesaj" ile bir konuşma başlatın.',
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      color: context.scheme.primary,
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.lg),
        itemCount: _conversations.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
        itemBuilder: (context, i) => _conversationCard(_conversations[i]),
      ),
    );
  }

  Widget _conversationCard(ConversationModel c) {
    final unread = c.unreadCount > 0;
    final timeStr = DateFormat('dd.MM HH:mm').format(c.lastMessageAt);

    return AppCard(
      onTap: () => _openThread(c.id, c.displayName),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            backgroundColor: context.scheme.primary.withOpacity(0.12),
            child: Icon(Icons.person_outline, color: context.scheme.primary),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  c.displayName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: unread ? FontWeight.w700 : FontWeight.w600,
                      ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  c.lastMessagePreview ?? 'Yeni konuşma',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: unread
                            ? context.scheme.onSurface
                            : context.colors.textSecondary,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(timeStr, style: Theme.of(context).textTheme.labelSmall),
              const SizedBox(height: AppSpacing.xs),
              if (unread)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  constraints: const BoxConstraints(minWidth: 20),
                  decoration: BoxDecoration(
                    color: context.scheme.primary,
                    borderRadius: AppRadius.pillAll,
                  ),
                  child: Text(
                    c.unreadCount > 99 ? '99+' : '${c.unreadCount}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: context.scheme.onPrimary,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
