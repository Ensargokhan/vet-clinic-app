import 'dart:async';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/error_state.dart';
import '../../../../shared/widgets/loading_indicator.dart';
import '../../data/models/message_model.dart';

class ChatThreadScreen extends StatefulWidget {
  final int conversationId;
  final String? peerName;

  const ChatThreadScreen({super.key, required this.conversationId, this.peerName});

  @override
  State<ChatThreadScreen> createState() => _ChatThreadScreenState();
}

class _ChatThreadScreenState extends State<ChatThreadScreen> {
  List<MessageModel> _messages = [];
  bool _isLoading = true;
  String? _error;
  bool _sending = false;

  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _load();
    // Açıkken canlı yenileme
    _timer = Timer.periodic(const Duration(seconds: 6), (_) => _load(silent: true));
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    _scrollController.dispose();
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
      final res = await DioClient()
          .dio
          .get('/conversations/${widget.conversationId}/messages');
      if (res.data['success'] == true && mounted) {
        final List<dynamic> data = res.data['data'] ?? [];
        final msgs = data.map((e) => MessageModel.fromJson(e)).toList();
        final grew = msgs.length != _messages.length;
        setState(() {
          _messages = msgs;
          _isLoading = false;
        });
        if (grew) _scrollToBottom();
      }
    } catch (_) {
      if (mounted && !silent) {
        setState(() {
          _error = 'Mesajlar yüklenemedi.';
          _isLoading = false;
        });
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;

    setState(() => _sending = true);
    try {
      final res = await DioClient().dio.post(
        '/conversations/${widget.conversationId}/messages',
        data: {'body': text},
      );
      if (res.data['success'] == true && mounted) {
        _controller.clear();
        await _load(silent: true);
        _scrollToBottom();
      }
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.response?.data?['message'] ?? 'Mesaj gönderilemedi.'),
            backgroundColor: context.scheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.peerName ?? 'Mesajlar')),
      body: Column(
        children: [
          Expanded(child: _buildMessages()),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildMessages() {
    if (_isLoading) return const LoadingIndicator();
    if (_error != null) {
      return ErrorState(message: _error!, onRetry: _load);
    }
    if (_messages.isEmpty) {
      return Center(
        child: Text(
          'Henüz mesaj yok. İlk mesajı gönderin.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: _messages.length,
      itemBuilder: (context, i) => _bubble(_messages[i]),
    );
  }

  Widget _bubble(MessageModel m) {
    final isMine = m.isMine;
    final timeStr = DateFormat('HH:mm').format(m.createdAt);
    final bg = isMine ? context.scheme.primary : context.colors.surfaceAlt;
    final fg = isMine ? context.scheme.onPrimary : context.scheme.onSurface;

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: AppRadius.lgAll,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(m.body,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: fg)),
            const SizedBox(height: 2),
            Text(
              timeStr,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: fg.withOpacity(0.7),
                    fontSize: 10,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.sm),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.newline,
                decoration: const InputDecoration(
                  hintText: 'Mesaj yazın...',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            IconButton.filled(
              onPressed: _sending ? null : _send,
              icon: _sending
                  ? SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: context.scheme.onPrimary),
                    )
                  : const Icon(Icons.send),
            ),
          ],
        ),
      ),
    );
  }
}
