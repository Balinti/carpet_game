import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../ef/ef_models.dart';
import '../ef/ef_questions.dart';
import '../ef/questionnaire_result.dart';
import '../onboarding_strings.dart';
import 'onboarding_ui.dart';

/// EF questionnaire: an intro page (kids: "answer with a parent"), then one
/// question per page with big option buttons, a progress bar and a back
/// button. Laid out for a short, wide landscape screen: question on one side,
/// options on the other.
///
/// Picking the last answer scores everything exactly like EF Trainer and
/// calls [onDone].
class QuestionnaireScreen extends StatefulWidget {
  const QuestionnaireScreen({
    super.key,
    required this.ageGroup,
    required this.onDone,
    this.onExit,
  });

  final AgeGroup ageGroup;
  final void Function(QuestionnaireResult result) onDone;

  /// Back from the intro page. When null, no back button there.
  final VoidCallback? onExit;

  @override
  State<QuestionnaireScreen> createState() => _QuestionnaireScreenState();
}

class _QuestionnaireScreenState extends State<QuestionnaireScreen> {
  late final List<AssessmentQuestion> _questions =
      questionsFor(widget.ageGroup);
  late final List<AnswerOption?> _picked =
      List<AnswerOption?>.filled(_questions.length, null);

  /// -1 = intro page.
  int _index = -1;
  bool _finished = false;

  bool get _isKid => widget.ageGroup == AgeGroup.kid;

  static const _dimColors = [
    Color(0xFFFF8A65),
    Color(0xFF4FC3F7),
    Color(0xFF81C784),
    Color(0xFFBA68C8),
  ];

  static String _emoji(Dimension d) => switch (d) {
        Dimension.inhibition => '🏎️',
        Dimension.workingMemory => '🎒',
        Dimension.flexibility => '🧩',
        Dimension.initiation => '🚀',
      };

  void _choose(AnswerOption o) {
    if (_finished) return;
    setState(() => _picked[_index] = o);
    if (_index < _questions.length - 1) {
      setState(() => _index++);
      return;
    }
    _finished = true;
    final answers = [
      for (var i = 0; i < _questions.length; i++)
        _questions[i].answer(_picked[i]!),
    ];
    widget.onDone(QuestionnaireResult.evaluate(widget.ageGroup, answers));
  }

  void _back() {
    if (_finished) return;
    if (_index >= 0) {
      setState(() => _index--);
    } else {
      widget.onExit?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = AppLocalizations.of(context).language;
    final s = OnboardingStrings.of(context);
    return OnboardingBackground(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        child: _index < 0 ? _intro(lang, s) : _question(lang, s),
      ),
    );
  }

  Widget _backButton(OnboardingStrings s) => SizedBox(
        width: 56,
        height: 56,
        child: IconButton(
          key: const ValueKey('q_back'),
          tooltip: s.back,
          iconSize: 30,
          color: onboardingStyle.onTray,
          style: IconButton.styleFrom(
            backgroundColor: onboardingStyle.trayCard.withOpacity(0.85),
          ),
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: _back,
        ),
      );

  Widget _intro(AppLanguage lang, OnboardingStrings s) {
    final st = onboardingStyle;
    return Center(
      child: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  if (widget.onExit != null) ...[
                    _backButton(s),
                    const SizedBox(width: 12),
                  ],
                  if (_isKid)
                    const Padding(
                      padding: EdgeInsetsDirectional.only(end: 10),
                      child: Text('👨‍👧', style: TextStyle(fontSize: 36)),
                    ),
                  Expanded(
                    child: OnboardingTitle(
                        _isKid ? s.kidIntroHeading : s.adultIntroHeading),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                introFor(lang, widget.ageGroup),
                key: const ValueKey('q_intro_text'),
                style: TextStyle(color: st.onTray, fontSize: 18, height: 1.35),
              ),
              const SizedBox(height: 18),
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 260),
                  child: BigButton(
                    key: const ValueKey('q_start'),
                    label: s.start,
                    icon: Icons.play_arrow_rounded,
                    onPressed: () => setState(() => _index = 0),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _question(AppLanguage lang, OnboardingStrings s) {
    final st = onboardingStyle;
    final q = _questions[_index];
    final accent = _isKid ? _dimColors[q.dimension.index] : st.boardFrame;
    final progress = (_index + 1) / _questions.length;

    final header = Row(
      children: [
        _backButton(s),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                s.questionOf(_index + 1, _questions.length),
                style: TextStyle(
                    color: st.onTray.withOpacity(0.8),
                    fontSize: 14,
                    fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  key: const ValueKey('q_progress'),
                  value: progress,
                  minHeight: 10,
                  color: accent,
                  backgroundColor: st.onTray.withOpacity(0.15),
                ),
              ),
            ],
          ),
        ),
      ],
    );

    final questionText = Text(
      q.textIn(lang),
      key: ValueKey('q_${q.id}'),
      style: TextStyle(
        color: st.onTray,
        fontSize: _isKid ? 21 : 19,
        fontWeight: FontWeight.w700,
        height: 1.3,
      ),
    );

    final options = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < q.options.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _OptionButton(
              key: ValueKey('opt_${q.id}_$i'),
              label: q.options[i].labelIn(lang),
              selected: identical(_picked[_index], q.options[i]),
              accent: accent,
              onTap: () => _choose(q.options[i]),
            ),
          ),
      ],
    );

    return LayoutBuilder(builder: (context, c) {
      final wide = c.maxWidth >= 560;
      if (!wide) {
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              header,
              const SizedBox(height: 12),
              questionText,
              const SizedBox(height: 12),
              options,
            ],
          ),
        );
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 5,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  header,
                  const SizedBox(height: 14),
                  if (_isKid)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(_emoji(q.dimension),
                          style: const TextStyle(fontSize: 34)),
                    ),
                  questionText,
                ],
              ),
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            flex: 6,
            child: Center(child: SingleChildScrollView(child: options)),
          ),
        ],
      );
    });
  }
}

class _OptionButton extends StatelessWidget {
  const _OptionButton({
    super.key,
    required this.label,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final st = onboardingStyle;
    final radius = BorderRadius.circular(18);
    return Material(
      color: selected ? accent.withOpacity(0.35) : st.trayCard.withOpacity(0.9),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(
          color: selected ? accent : accent.withOpacity(0.45),
          width: 2.5,
        ),
      ),
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                label,
                style: TextStyle(
                  color: st.onTray,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
