import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/loading_indicator.dart';
import '../../data/models/ai_chat_message_model.dart';
import '../../data/models/ai_report_model.dart';

/// AI ön muayene sohbeti (tam ekran). Randevu akışındaki "Ön Muayene" adımından açılır.
/// Bittiğinde [context.pop] ile üretilen [AiReportModel] geri döner (atlanırsa null).
class AiChatScreen extends StatefulWidget {
  final int animalId;
  final String? animalName;

  const AiChatScreen({super.key, required this.animalId, this.animalName});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final List<AiChatMessageModel> _messages = [];
  int? _sessionId;

  bool _starting = true; // oturum başlatılıyor
  bool _sending = false; // asistan yanıtı bekleniyor ("yazıyor…")
  bool _finalizing = false; // rapor hazırlanıyor
  String? _startError;

  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // İlk kare sonrası yasal uyarıyı göster, onaylanırsa oturumu başlat
    WidgetsBinding.instance.addPostFrameCallback((_) => _showDisclaimerThenStart());
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _showDisclaimerThenStart() async {
    final accepted = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Bilgilendirme'),
        content: const Text(
          'Bu yapay zeka asistanı teşhis koymaz ve veteriner hekim muayenesinin '
          'yerine geçmez. Amacı, birkaç soruyla durumu anlayıp hekiminize yardımcı '
          'olacak bir ön rapor hazırlamaktır. Acil bir durumda lütfen vakit '
          'kaybetmeden en yakın veteriner kliniğine başvurun.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Anladım, Başla'),
          ),
        ],
      ),
    );

    if (accepted == true) {
      _startSession();
    } else if (mounted) {
      Navigator.of(context).pop(); // raporsuz geri dön
    }
  }

  Future<void> _startSession() async {
    setState(() {
      _starting = true;
      _startError = null;
    });
    try {
      final res = await DioClient().dio.post(
        '/ai/start-session',
        data: {'animalId': widget.animalId},
      );
      if (res.data['success'] == true && mounted) {
        final data = res.data['data'];
        setState(() {
          _sessionId = data['sessionId'];
          _messages.add(AiChatMessageModel.fromJson(data['message']));
          _starting = false;
        });
        _scrollToBottom();
      }
    } on DioException catch (e) {
      if (mounted) {
        setState(() {
          _startError =
              e.response?.data?['message'] ?? 'Ön muayene başlatılamadı.';
          _starting = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _startError = 'Beklenmeyen bir hata oluştu.';
          _starting = false;
        });
      }
    }
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending || _sessionId == null) return;

    setState(() {
      _messages.add(AiChatMessageModel(
        id: -DateTime.now().millisecondsSinceEpoch, // geçici yerel id
        role: 'user',
        content: text,
        createdAt: DateTime.now(),
      ));
      _sending = true;
      _controller.clear();
    });
    _scrollToBottom();

    try {
      final res = await DioClient().dio.post(
        '/ai/sessions/$_sessionId/chat',
        data: {'message': text},
      );
      if (res.data['success'] == true && mounted) {
        setState(() {
          _messages.add(AiChatMessageModel.fromJson(res.data['data']));
        });
      }
    } on DioException catch (e) {
      if (mounted) {
        _snack(e.response?.data?['message'] ?? 'Yanıt alınamadı.',
            isError: true);
      }
    } catch (_) {
      if (mounted) _snack('Beklenmeyen bir hata oluştu.', isError: true);
    } finally {
      if (mounted) setState(() => _sending = false);
      _scrollToBottom();
    }
  }

  Future<void> _finalize() async {
    if (_sessionId == null || _finalizing) return;

    setState(() => _finalizing = true);
    try {
      final res = await DioClient().dio.post('/ai/sessions/$_sessionId/finalize');
      if (res.data['success'] == true && mounted) {
        final report = AiReportModel.fromJson(res.data['data']);
        Navigator.of(context).pop(report); // raporu randevu akışına döndür
        return;
      }
    } on DioException catch (e) {
      if (mounted) {
        _snack(e.response?.data?['message'] ?? 'Rapor hazırlanamadı.',
            isError: true);
      }
    } catch (_) {
      if (mounted) _snack('Beklenmeyen bir hata oluştu.', isError: true);
    }
    if (mounted) setState(() => _finalizing = false);
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

  void _snack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? context.scheme.error : context.colors.success,
      ),
    );
  }

  bool get _hasUserMessage => _messages.any((m) => m.role == 'user');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.animalName == null
              ? 'Ön Muayene'
              : 'Ön Muayene — ${widget.animalName}',
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_starting) return const LoadingIndicator();

    if (_startError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: context.scheme.error),
              const SizedBox(height: AppSpacing.md),
              Text(_startError!, textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.lg),
              FilledButton(onPressed: _startSession, child: const Text('Tekrar Dene')),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        Expanded(child: _buildMessages()),
        _buildFinalizeBar(),
        _buildInputBar(),
      ],
    );
  }

  Widget _buildMessages() {
    // "yazıyor…" göstergesi için sanal bir öğe ekle
    final itemCount = _messages.length + (_sending ? 1 : 0);
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: itemCount,
      itemBuilder: (context, i) {
        if (_sending && i == _messages.length) return _typingBubble();
        return _bubble(_messages[i]);
      },
    );
  }

  Widget _bubble(AiChatMessageModel m) {
    final isMine = m.role == 'user';
    final bg = isMine ? context.scheme.primary : context.colors.surfaceAlt;
    final fg = isMine ? context.scheme.onPrimary : context.scheme.onSurface;

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        decoration: BoxDecoration(color: bg, borderRadius: AppRadius.lgAll),
        child: Text(
          m.content,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: fg),
        ),
      ),
    );
  }

  Widget _typingBubble() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: context.colors.surfaceAlt,
          borderRadius: AppRadius.lgAll,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 14,
              width: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: context.colors.textSecondary,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text('yazıyor…',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: context.colors.textSecondary,
                    )),
          ],
        ),
      ),
    );
  }

  Widget _buildFinalizeBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0),
      child: SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: (_hasUserMessage && !_finalizing && !_sending)
              ? _finalize
              : null,
          icon: _finalizing
              ? SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: context.scheme.onPrimary),
                )
              : const Icon(Icons.summarize_outlined),
          label: Text(_finalizing ? 'Hazırlanıyor…' : 'Ön Raporu Hazırla'),
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
                enabled: !_finalizing,
                textInputAction: TextInputAction.newline,
                decoration: const InputDecoration(
                  hintText: 'Yanıtınızı yazın...',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            IconButton.filled(
              onPressed: (_sending || _finalizing) ? null : _send,
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
