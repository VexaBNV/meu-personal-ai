import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meu_personal_ai/core/network/api_client.dart';
import 'package:meu_personal_ai/core/theme/app_theme.dart';

// ── Provider ─────────────────────────────────────────────────

final _feedbackProvider = FutureProvider.family<String, String>(
  (ref, sessionId) async {
    final api = ref.read(apiClientProvider);
    final res = await api.dio.get('/workout/$sessionId/feedback');
    return res.data['feedback'] as String;
  },
);

// ── Widget ────────────────────────────────────────────────────

/// Exibir na WorkoutCompleteScreen logo abaixo dos stats.
/// Faz GET /workout/:sessionId/feedback e exibe a resposta
/// da IA com animação de digitação.
///
/// Uso:
///   AiPostWorkoutFeedback(sessionId: session.id)
class AiPostWorkoutFeedback extends ConsumerWidget {
  final String sessionId;
  const AiPostWorkoutFeedback({super.key, required this.sessionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedbackAsync = ref.watch(_feedbackProvider(sessionId));

    return feedbackAsync.when(
      loading: () => _LoadingBubble(),
      error:   (_, __) => const SizedBox.shrink(), // falha silenciosa
      data:    (text)  => _FeedbackBubble(text: text),
    );
  }
}

class _LoadingBubble extends StatefulWidget {
  @override
  createState() => _LoadingBubbleState();
}

class _LoadingBubbleState extends State<_LoadingBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 800))
      ..repeat(reverse: true);
    _fade = Tween(begin: 0.4, end: 1.0).animate(_ctrl);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: context.cardColor,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: context.divColor),
    ),
    child: Row(children: [
      _CoachAvatar(),
      const SizedBox(width: 12),
      Expanded(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FadeTransition(
            opacity: _fade,
            child: Text('Coach está analisando seu treino...',
              style: TextStyle(fontSize: 12, color: context.textSecColor,
                fontStyle: FontStyle.italic)),
          ),
          const SizedBox(height: 8),
          Row(children: [
            for (int i = 0; i < 3; i++) ...[
              FadeTransition(
                opacity: _fade,
                child: Container(
                  width: 6, height: 6,
                  decoration: BoxDecoration(
                    color: AppColors.brandPrimary,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              if (i < 2) const SizedBox(width: 4),
            ],
          ]),
        ],
      )),
    ]),
  );
}

class _FeedbackBubble extends StatefulWidget {
  final String text;
  const _FeedbackBubble({required this.text});
  @override
  createState() => _FeedbackBubbleState();
}

class _FeedbackBubbleState extends State<_FeedbackBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _slide, _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 400));
    _slide = Tween(begin: 16.0, end: 0.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _fade  = Tween(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeIn));
    _ctrl.forward();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _ctrl,
    builder: (_, child) => Transform.translate(
      offset: Offset(0, _slide.value),
      child: Opacity(opacity: _fade.value, child: child),
    ),
    child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.divColor),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _CoachAvatar(),
        const SizedBox(width: 12),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Coach', style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w600,
              color: AppColors.brandPrimary)),
            const SizedBox(height: 4),
            Text(widget.text, style: TextStyle(
              fontSize: 13, color: context.textColor,
              height: 1.55)),
          ],
        )),
      ]),
    ),
  );
}

class _CoachAvatar extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    width: 34, height: 34,
    decoration: BoxDecoration(
      color: AppColors.brandPrimary,
      shape: BoxShape.circle,
    ),
    child: const Center(child: Text('🤖',
      style: TextStyle(fontSize: 16))),
  );
}
