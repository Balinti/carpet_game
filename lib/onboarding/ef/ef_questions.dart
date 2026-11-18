// Question bank for the EF "getting-to-know-you" questionnaire.
// Items written by Shemer Arazi (2026-11-17): 6 for kids (never / sometimes /
// always), 6 for adults (1-5, 1 = not at all, 5 = very much).
// Score = friction: 1 = optimal .. 3 (kids) or 5 (adults) = high friction.
// Positively worded items (planning, noticing) are reverse-scored.
// Only Hebrew + English exist; Spanish falls back to English.
import '../../l10n/app_localizations.dart';
import 'ef_models.dart';

class AnswerOption {
  final String label;
  final int score;
  final String labelEn;
  const AnswerOption(this.label, this.score, this.labelEn);

  /// Label in [lang] (Hebrew, otherwise English).
  String labelIn(AppLanguage lang) =>
      lang == AppLanguage.hebrew ? label : labelEn;
}

class AssessmentQuestion {
  final String id;
  final Dimension dimension;
  final AgeGroup ageGroup;
  final String text;
  final String textEn;
  final List<AnswerOption> options;
  final bool isCore;

  const AssessmentQuestion({
    required this.id,
    required this.dimension,
    required this.ageGroup,
    required this.text,
    required this.textEn,
    required this.options,
    this.isCore = false,
  });

  /// Question text in [lang] (Hebrew, otherwise English).
  String textIn(AppLanguage lang) => lang == AppLanguage.hebrew ? text : textEn;

  double get weight => isCore ? coreWeight : extraWeight;

  static const double coreWeight = 1.5;
  static const double extraWeight = 1.0;

  AssessmentAnswer answer(AnswerOption o) => AssessmentAnswer(
        questionId: id,
        dimension: dimension,
        score: o.score,
        weight: weight,
        maxScore: options.length,
      );
}

const String kidIntro =
    'אפשר לענות יחד: הורה על הילד/ה, או הילד/ה בעזרת הורה. אין תשובות נכונות או לא נכונות.';
const String adultIntro =
    'ענו לפי מה שקורה ברוב הימים, לא ביום הכי טוב או הכי קשה. אין תשובות נכונות או לא נכונות.';

const List<AssessmentQuestion> kidQuestions = [
  AssessmentQuestion(
    id: 'kid_1',
    dimension: Dimension.initiation,
    ageGroup: AgeGroup.kid,
    text: 'לפני משימה גדולה, אני מחלק אותה בראש לחלקים קטנים.',
    textEn: 'Before a big task, I split it into small parts in my head.',
    options: [
      AnswerOption('😶  אף פעם', 3, 'Never'),
      AnswerOption('🤔  לפעמים', 2, 'Sometimes'),
      AnswerOption('💯  תמיד', 1, 'Always'),
    ],
  ),
  AssessmentQuestion(
    id: 'kid_2',
    dimension: Dimension.workingMemory,
    ageGroup: AgeGroup.kid,
    text: 'קשה לי להישאר ממוקד במשימה אחת לאורך זמן בלי שהמחשבות ינדדו.',
    textEn:
        'It\'s hard for me to stay focused on one task for a long time without my thoughts wandering.',
    options: [
      AnswerOption('😶  אף פעם', 1, 'Never'),
      AnswerOption('🤔  לפעמים', 2, 'Sometimes'),
      AnswerOption('💯  תמיד', 3, 'Always'),
    ],
  ),
  AssessmentQuestion(
    id: 'kid_3',
    dimension: Dimension.inhibition,
    ageGroup: AgeGroup.kid,
    text:
        'אם יש רעש או רעיון חדש בראש, אני מתקשה להגיד לעצמי "אסיים את זה קודם".',
    textEn:
        'If there is noise or a new idea in my head, it is hard for me to tell myself "I will finish this first".',
    options: [
      AnswerOption('😶  אף פעם', 1, 'Never'),
      AnswerOption('🤔  לפעמים', 2, 'Sometimes'),
      AnswerOption('💯  תמיד', 3, 'Always'),
    ],
  ),
  AssessmentQuestion(
    id: 'kid_4',
    dimension: Dimension.flexibility,
    ageGroup: AgeGroup.kid,
    text: 'אני ממשיך לעבוד בכוח גם כשהמוח שלי כבר לגמרי עייף.',
    textEn: 'I keep pushing on even when my brain is completely tired.',
    options: [
      AnswerOption('😶  אף פעם', 1, 'Never'),
      AnswerOption('🤔  לפעמים', 2, 'Sometimes'),
      AnswerOption('💯  תמיד', 3, 'Always'),
    ],
  ),
  AssessmentQuestion(
    id: 'kid_5',
    dimension: Dimension.flexibility,
    ageGroup: AgeGroup.kid,
    text: 'במהלך העבודה, אני שם לב אם אני עומד בקצב או מאבד זמן.',
    textEn: 'While working, I notice whether I\'m keeping pace or losing time.',
    options: [
      AnswerOption('😶  אף פעם', 3, 'Never'),
      AnswerOption('🤔  לפעמים', 2, 'Sometimes'),
      AnswerOption('💯  תמיד', 1, 'Always'),
    ],
  ),
  AssessmentQuestion(
    id: 'kid_6',
    dimension: Dimension.initiation,
    ageGroup: AgeGroup.kid,
    text: 'לקראת סוף המשימה, נגמרת לי לגמרי הסבלנות לסיים את הפרטים הקטנים.',
    textEn:
        'Near the end of a task, I completely run out of patience to finish the small details.',
    options: [
      AnswerOption('😶  אף פעם', 1, 'Never'),
      AnswerOption('🤔  לפעמים', 2, 'Sometimes'),
      AnswerOption('💯  תמיד', 3, 'Always'),
    ],
  ),
];

const List<AssessmentQuestion> adultQuestions = [
  AssessmentQuestion(
    id: 'adult_1',
    dimension: Dimension.initiation,
    ageGroup: AgeGroup.adult,
    text:
        'אני נוהג לתכנן מראש שלבי ביניים ולוחות זמנים לפני כניסה לפרויקט ארוך.',
    textEn:
        'I usually plan milestones and timelines before starting a long project.',
    options: [
      AnswerOption('1 – בכלל לא', 5, '1 – Not at all'),
      AnswerOption('2', 4, '2'),
      AnswerOption('3', 3, '3'),
      AnswerOption('4', 2, '4'),
      AnswerOption('5 – במידה רבה מאוד', 1, '5 – Very much'),
    ],
  ),
  AssessmentQuestion(
    id: 'adult_2',
    dimension: Dimension.workingMemory,
    ageGroup: AgeGroup.adult,
    text: 'קשה לי לשמור על רצף קשב מדויק לאורך שעת עבודה רצופה מבלי להתפזר.',
    textEn:
        'It\'s hard for me to keep precise, continuous attention through an hour of work without drifting.',
    options: [
      AnswerOption('1 – בכלל לא', 1, '1 – Not at all'),
      AnswerOption('2', 2, '2'),
      AnswerOption('3', 3, '3'),
      AnswerOption('4', 4, '4'),
      AnswerOption('5 – במידה רבה מאוד', 5, '5 – Very much'),
    ],
  ),
  AssessmentQuestion(
    id: 'adult_3',
    dimension: Dimension.inhibition,
    ageGroup: AgeGroup.adult,
    text:
        'אני מתקשה לחסום הסחות דעת חיצוניות ומחשבות מתפרצות בזמן עבודה מרוכזת.',
    textEn:
        'I struggle to block outside distractions and intrusive thoughts during focused work.',
    options: [
      AnswerOption('1 – בכלל לא', 1, '1 – Not at all'),
      AnswerOption('2', 2, '2'),
      AnswerOption('3', 3, '3'),
      AnswerOption('4', 4, '4'),
      AnswerOption('5 – במידה רבה מאוד', 5, '5 – Very much'),
    ],
  ),
  AssessmentQuestion(
    id: 'adult_4',
    dimension: Dimension.flexibility,
    ageGroup: AgeGroup.adult,
    text: 'אני מזהה מוקדם כשהבטריה הקוגניטיבית שלי מתרוקנת ומתאים את הקצב.',
    textEn:
        'I notice early when my mental battery is running low and adjust my pace.',
    options: [
      AnswerOption('1 – בכלל לא', 5, '1 – Not at all'),
      AnswerOption('2', 4, '2'),
      AnswerOption('3', 3, '3'),
      AnswerOption('4', 2, '4'),
      AnswerOption('5 – במידה רבה מאוד', 1, '5 – Very much'),
    ],
  ),
  AssessmentQuestion(
    id: 'adult_5',
    dimension: Dimension.flexibility,
    ageGroup: AgeGroup.adult,
    text:
        'אני עוצר מדי פעם לבחון האם אני ממוקד ביעד המקורי או טובל בפרטים שוליים.',
    textEn:
        'I stop now and then to check whether I\'m on the original goal or lost in side details.',
    options: [
      AnswerOption('1 – בכלל לא', 5, '1 – Not at all'),
      AnswerOption('2', 4, '2'),
      AnswerOption('3', 3, '3'),
      AnswerOption('4', 2, '4'),
      AnswerOption('5 – במידה רבה מאוד', 1, '5 – Very much'),
    ],
  ),
  AssessmentQuestion(
    id: 'adult_6',
    dimension: Dimension.initiation,
    ageGroup: AgeGroup.adult,
    text: 'אני מתקשה לשמור על אנרגיה וריכוז בשלב "הסגירה" הטכני של פרויקט.',
    textEn:
        'I struggle to keep energy and focus during the technical "wrap-up" stage of a project.',
    options: [
      AnswerOption('1 – בכלל לא', 1, '1 – Not at all'),
      AnswerOption('2', 2, '2'),
      AnswerOption('3', 3, '3'),
      AnswerOption('4', 4, '4'),
      AnswerOption('5 – במידה רבה מאוד', 5, '5 – Very much'),
    ],
  ),
];

const String kidIntroEn =
    'You can answer together: a parent about the child, or the child with a parent\'s help. There are no right or wrong answers.';
const String adultIntroEn =
    'Answer based on what happens on most days – not your best or hardest day. There are no right or wrong answers.';

String introFor(AppLanguage lang, AgeGroup a) => a == AgeGroup.kid
    ? (lang == AppLanguage.hebrew ? kidIntro : kidIntroEn)
    : (lang == AppLanguage.hebrew ? adultIntro : adultIntroEn);

List<AssessmentQuestion> questionsFor(AgeGroup a) =>
    a == AgeGroup.kid ? kidQuestions : adultQuestions;
