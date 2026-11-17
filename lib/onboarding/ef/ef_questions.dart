// Question bank for the EF "getting-to-know-you" questionnaire.
// Ported verbatim (texts, scores, weights) from EF Trainer:
//   ef-trainer/lib/features/assessment/questions.dart
// 4 axes x 3 items per age group = 12 items. Core items weigh 1.5, extras 1.0.
// Each option maps to a score: 1 = optimal, 2 = some friction, 3 = high friction.
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
      );
}

const String kidIntro =
    'אפשר לענות יחד: הורה על הילד/ה, או הילד/ה בעזרת הורה. אין תשובות נכונות או לא נכונות.';
const String adultIntro =
    'ענו לפי מה שקורה ברוב הימים, לא ביום הכי טוב או הכי קשה. אין תשובות נכונות או לא נכונות.';

const List<AssessmentQuestion> kidQuestions = [
  // ---- inhibition ----
  AssessmentQuestion(
    id: 'kid_inh_core',
    dimension: Dimension.inhibition,
    ageGroup: AgeGroup.kid,
    isCore: true,
    text: 'כשיש משהו שאתה מאוד רוצה להגיד/לעשות, כמה קשה לך לחכות לתורך?',
    textEn:
        "When there's something you really want to say or do, how hard is it to wait for your turn?",
    options: [
      AnswerOption(
        'בדרך כלל מצליח/ה לחכות בסבלנות',
        1,
        "Usually manages to wait patiently",
      ),
      AnswerOption(
        'לפעמים קופץ/ת לפני התור',
        2,
        "Sometimes jumps in before their turn",
      ),
      AnswerOption(
        'כמעט תמיד המילים יוצאות לפני שמגיע התור',
        3,
        "Almost always the words come out before it's their turn",
      ),
    ],
  ),
  AssessmentQuestion(
    id: 'kid_inh_2',
    dimension: Dimension.inhibition,
    ageGroup: AgeGroup.kid,
    text: 'כשהמורה או ההורה מבקשים לעצור משחק באמצע, מה קורה בדרך כלל?',
    textEn:
        "When a teacher or parent asks to stop a game in the middle, what usually happens?",
    options: [
      AnswerOption(
        'עוצר/ת די מהר, אולי עם קצת אכזבה',
        1,
        "Stops pretty quickly, maybe a little disappointed",
      ),
      AnswerOption(
        'צריך/ה כמה תזכורות עד שעוצר/ת',
        2,
        "Needs a few reminders before stopping",
      ),
      AnswerOption(
        'קשה מאוד לעצור, לרוב זה נגמר בוויכוח או בבכי',
        3,
        "Very hard to stop – it usually ends in an argument or tears",
      ),
    ],
  ),
  AssessmentQuestion(
    id: 'kid_inh_3',
    dimension: Dimension.inhibition,
    ageGroup: AgeGroup.kid,
    text: 'כשמישהו לוקח לילד/ה צעצוע או עוקף בתור, איך הגוף מגיב?',
    textEn:
        "When someone takes your child's toy or cuts in line, how does their body react?",
    options: [
      AnswerOption(
        'אומר/ת במילים מה מפריע',
        1,
        "Says in words what's bothering them",
      ),
      AnswerOption(
        'לפעמים דוחף/ת או צועק/ת לפני שחושב/ת',
        2,
        "Sometimes pushes or shouts before thinking",
      ),
      AnswerOption(
        'לרוב הידיים או הצעקה מגיעות ראשונות',
        3,
        "Usually hands or shouting come first",
      ),
    ],
  ),
  // ---- working memory ----
  AssessmentQuestion(
    id: 'kid_wm_core',
    dimension: Dimension.workingMemory,
    ageGroup: AgeGroup.kid,
    isCore: true,
    text: 'כששולחים אותך להביא שני דברים מהחדר, האם אתה שוכח בדרך?',
    textEn:
        "When you're sent to bring two things from your room, do you forget on the way?",
    options: [
      AnswerOption(
        'בדרך כלל חוזר/ת עם שניהם',
        1,
        "Usually comes back with both",
      ),
      AnswerOption(
        'לפעמים חוזר/ת עם אחד בלבד',
        2,
        "Sometimes comes back with just one",
      ),
      AnswerOption(
        'לרוב מגיע/ה לחדר ולא זוכר/ת מה רצית',
        3,
        "Usually gets to the room and can't remember what they wanted",
      ),
    ],
  ),
  AssessmentQuestion(
    id: 'kid_wm_2',
    dimension: Dimension.workingMemory,
    ageGroup: AgeGroup.kid,
    text: 'בבוקר, כמה פעמים צריך להזכיר לילד/ה לקחת תיק, בקבוק או כריך?',
    textEn:
        "In the morning, how many times do you need to remind your child to take their bag, bottle or sandwich?",
    options: [
      AnswerOption(
        'כמעט אף פעם, זוכר/ת לבד',
        1,
        "Almost never – remembers on their own",
      ),
      AnswerOption(
        'צריך להזכיר פעם או פעמיים',
        2,
        "Needs a reminder once or twice",
      ),
      AnswerOption(
        'כמעט כל בוקר משהו נשכח בבית',
        3,
        "Almost every morning something gets left at home",
      ),
    ],
  ),
  AssessmentQuestion(
    id: 'kid_wm_3',
    dimension: Dimension.workingMemory,
    ageGroup: AgeGroup.kid,
    text:
        'כשנותנים הוראה עם כמה שלבים ("תתלבש, תצחצח שיניים ותבוא לאכול"), מה קורה?',
    textEn:
        "When you give an instruction with a few steps (\"get dressed, brush your teeth and come eat\"), what happens?",
    options: [
      AnswerOption(
        'מבצע/ת את כל השלבים לפי הסדר',
        1,
        "Does all the steps in order",
      ),
      AnswerOption(
        'עושה חלק ומתבלבל/ת באמצע',
        2,
        "Does some and gets mixed up in the middle",
      ),
      AnswerOption(
        'לרוב רק השלב הראשון נעשה',
        3,
        "Usually only the first step gets done",
      ),
    ],
  ),
  // ---- flexibility ----
  AssessmentQuestion(
    id: 'kid_flex_core',
    dimension: Dimension.flexibility,
    ageGroup: AgeGroup.kid,
    isCore: true,
    text: 'מה קורה כשתוכנית משתנה פתאום או כשהחוקים במשחק מתהפכים?',
    textEn:
        "What happens when a plan suddenly changes, or the rules of a game flip?",
    options: [
      AnswerOption('מתאים/ה את עצמו/ה די מהר', 1, "Adjusts pretty quickly"),
      AnswerOption(
        'מתבאס/ת קצת ואחרי זמן מה ממשיך/ה',
        2,
        "Is a bit bummed, then carries on after a while",
      ),
      AnswerOption(
        'נתקע/ת, כועס/ת או מסרב/ת להמשיך',
        3,
        "Gets stuck, angry, or refuses to continue",
      ),
    ],
  ),
  AssessmentQuestion(
    id: 'kid_flex_2',
    dimension: Dimension.flexibility,
    ageGroup: AgeGroup.kid,
    text: 'כשדרך מסוימת לפתור תרגיל או לבנות משהו לא עובדת, מה הילד/ה עושה?',
    textEn:
        "When one way of solving a problem or building something doesn't work, what does your child do?",
    options: [
      AnswerOption('מנסה דרך אחרת', 1, "Tries a different way"),
      AnswerOption(
        'מנסה שוב ושוב את אותה דרך לפני שמחליף/ה',
        2,
        "Tries the same way again and again before switching",
      ),
      AnswerOption(
        'ממשיך/ה באותה דרך או עוזב/ת בתסכול',
        3,
        "Keeps going the same way or gives up in frustration",
      ),
    ],
  ),
  AssessmentQuestion(
    id: 'kid_flex_3',
    dimension: Dimension.flexibility,
    ageGroup: AgeGroup.kid,
    text: 'כשצריך לעבור מפעילות אהובה (מסך, משחק) לפעילות אחרת, כמה קשה המעבר?',
    textEn:
        "When it's time to switch from a favourite activity (screen, game) to something else, how hard is the switch?",
    options: [
      AnswerOption(
        'עובר/ת עם התראה קצרה מראש',
        1,
        "Switches with a short heads-up",
      ),
      AnswerOption(
        'צריך/ה כמה דקות ועזרה כדי לעבור',
        2,
        "Needs a few minutes and some help to switch",
      ),
      AnswerOption(
        'כמעט כל מעבר כזה מרגיש כמו מאבק',
        3,
        "Almost every switch like this feels like a battle",
      ),
    ],
  ),
  // ---- initiation ----
  AssessmentQuestion(
    id: 'kid_init_core',
    dimension: Dimension.initiation,
    ageGroup: AgeGroup.kid,
    isCore: true,
    text: 'כשצריך להתחיל משימה שלא בא לך עליה, כמה קשה הצעד הראשון?',
    textEn:
        "When you need to start a task you don't feel like doing, how hard is the first step?",
    options: [
      AnswerOption('מתחיל/ה אחרי תזכורת אחת', 1, "Starts after one reminder"),
      AnswerOption(
        'מתחיל/ה רק אחרי כמה תזכורות',
        2,
        "Starts only after several reminders",
      ),
      AnswerOption(
        'כמעט לא מצליח/ה להתחיל בלי מבוגר לצידו/ה',
        3,
        "Can hardly start without an adult beside them",
      ),
    ],
  ),
  AssessmentQuestion(
    id: 'kid_init_2',
    dimension: Dimension.initiation,
    ageGroup: AgeGroup.kid,
    text: 'כשמבקשים לסדר את החדר, מה קורה?',
    textEn: "When you ask your child to tidy their room, what happens?",
    options: [
      AnswerOption(
        'יודע/ת מאיפה להתחיל ומסדר/ת',
        1,
        "Knows where to start and tidies up",
      ),
      AnswerOption(
        'מתחיל/ה ומתפזר/ת באמצע',
        2,
        "Starts, then drifts off in the middle",
      ),
      AnswerOption(
        'עומד/ת מול הבלגן ולא יודע/ת מאיפה להתחיל',
        3,
        "Stands in front of the mess, not knowing where to start",
      ),
    ],
  ),
  AssessmentQuestion(
    id: 'kid_init_3',
    dimension: Dimension.initiation,
    ageGroup: AgeGroup.kid,
    text: 'כשיש שיעורי בית או פרויקט לכמה ימים, איך זה מתנהל?',
    textEn:
        "When there's homework or a project spread over a few days, how does it go?",
    options: [
      AnswerOption(
        'מתחיל/ה מוקדם ומתקדם/ת בחלקים',
        1,
        "Starts early and moves forward bit by bit",
      ),
      AnswerOption(
        'מתחיל/ה רק כשהמועד מתקרב',
        2,
        "Starts only when the deadline gets close",
      ),
      AnswerOption(
        'לרוב נזכר/ת ברגע האחרון או בכלל לא',
        3,
        "Usually remembers at the last minute, or not at all",
      ),
    ],
  ),
];

const List<AssessmentQuestion> adultQuestions = [
  // ---- inhibition ----
  AssessmentQuestion(
    id: 'adult_inh_core',
    dimension: Dimension.inhibition,
    ageGroup: AgeGroup.adult,
    isCore: true,
    text: 'במצבי לחץ, באיזו תדירות אתה פולט מילים או מגיב באימפולסיביות?',
    textEn:
        "Under pressure, how often do you blurt things out or react on impulse?",
    options: [
      AnswerOption(
        'לעיתים רחוקות, בדרך כלל עוצר לחשוב',
        1,
        "Rarely – I usually stop to think",
      ),
      AnswerOption(
        'מדי פעם, בעיקר כשאני עייף או מוצף',
        2,
        "Now and then, mostly when I'm tired or overwhelmed",
      ),
      AnswerOption(
        'לעיתים קרובות, ומתחרט אחר כך',
        3,
        "Often, and I regret it afterwards",
      ),
    ],
  ),
  AssessmentQuestion(
    id: 'adult_inh_2',
    dimension: Dimension.inhibition,
    ageGroup: AgeGroup.adult,
    text: 'כשמגיע מייל או הודעה מעצבנים, כמה מהר אתה עונה?',
    textEn:
        "When an irritating email or message arrives, how fast do you reply?",
    options: [
      AnswerOption(
        'מחכה, נושם ועונה כשאני רגוע',
        1,
        "I wait, breathe, and reply once I'm calm",
      ),
      AnswerOption(
        'לפעמים עונה מיד ומתקן אחר כך',
        2,
        "Sometimes I reply right away and fix it later",
      ),
      AnswerOption(
        'כמעט תמיד עונה מיד, בטון חריף',
        3,
        "Almost always right away, in a sharp tone",
      ),
    ],
  ),
  AssessmentQuestion(
    id: 'adult_inh_3',
    dimension: Dimension.inhibition,
    ageGroup: AgeGroup.adult,
    text: 'כשאתה באמצע עבודה ומגיעה התראה בטלפון, מה קורה?',
    textEn:
        "When you're in the middle of work and a phone notification pops up, what happens?",
    options: [
      AnswerOption(
        'ממשיך במשימה ובודק אחר כך',
        1,
        "I keep going and check later",
      ),
      AnswerOption(
        'מציץ, ולפעמים נשאב לכמה דקות',
        2,
        "I glance, and sometimes get pulled in for a few minutes",
      ),
      AnswerOption(
        'כמעט תמיד פותח ומאבד את רצף העבודה',
        3,
        "I almost always open it and lose my flow",
      ),
    ],
  ),
  // ---- working memory ----
  AssessmentQuestion(
    id: 'adult_wm_core',
    dimension: Dimension.workingMemory,
    ageGroup: AgeGroup.adult,
    isCore: true,
    text: 'עד כמה הזיכרון לטווח קצר מוצף (מאבד חפצים/שוכח מטלות)?',
    textEn:
        "How overloaded does your short-term memory feel (losing things, forgetting tasks)?",
    options: [
      AnswerOption(
        'כמעט לא, אני זוכר את רוב הדברים',
        1,
        "Hardly at all – I remember most things",
      ),
      AnswerOption(
        'כמה פעמים בשבוע משהו נשכח או הולך לאיבוד',
        2,
        "A few times a week something is forgotten or misplaced",
      ),
      AnswerOption(
        'כל יום – מפתחות, משימות, דברים שהבטחתי',
        3,
        "Every day – keys, tasks, things I promised",
      ),
    ],
  ),
  AssessmentQuestion(
    id: 'adult_wm_2',
    dimension: Dimension.workingMemory,
    ageGroup: AgeGroup.adult,
    text: 'באמצע שיחה או ישיבה, כמה פעמים אתה מאבד את החוט של מה שרצית להגיד?',
    textEn:
        "In the middle of a conversation or meeting, how often do you lose the thread of what you wanted to say?",
    options: [
      AnswerOption('לעיתים רחוקות', 1, "Rarely"),
      AnswerOption(
        'מדי פעם, בעיקר כשיש הרבה פרטים',
        2,
        "Now and then, mostly when there are lots of details",
      ),
      AnswerOption(
        'לעיתים קרובות, המחשבה "נמחקת" באמצע',
        3,
        "Often – the thought gets \"erased\" midway",
      ),
    ],
  ),
  AssessmentQuestion(
    id: 'adult_wm_3',
    dimension: Dimension.workingMemory,
    ageGroup: AgeGroup.adult,
    text: 'כשאתה מנהל כמה ערוצים במקביל (מייל, צ\'אט, טלפון), מה קורה למשימות?',
    textEn:
        "When you juggle several channels at once (email, chat, phone), what happens to your tasks?",
    options: [
      AnswerOption(
        'אני עוקב אחרי הכול בלי קושי מיוחד',
        1,
        "I keep track of everything without much trouble",
      ),
      AnswerOption(
        'לפעמים משהו נופל בין הכיסאות',
        2,
        "Sometimes something falls through the cracks",
      ),
      AnswerOption(
        'משימות נופלות באופן קבוע ואני מגלה באיחור',
        3,
        "Tasks fall through regularly and I find out late",
      ),
    ],
  ),
  // ---- flexibility ----
  AssessmentQuestion(
    id: 'adult_flex_core',
    dimension: Dimension.flexibility,
    ageGroup: AgeGroup.adult,
    isCore: true,
    text: 'כשתוכניות משתנות, באיזו מידה אתה חווה תקיעות ותסכול מנטלי?',
    textEn:
        "When plans change, how much do you feel stuck or mentally frustrated?",
    options: [
      AnswerOption(
        'מעט, אני מתאים את עצמי די מהר',
        1,
        "A little – I adjust fairly quickly",
      ),
      AnswerOption(
        'במידה בינונית, לוקח לי זמן להתארגן מחדש',
        2,
        "Somewhat – it takes me a while to regroup",
      ),
      AnswerOption(
        'במידה רבה, השינוי תוקע אותי לשעות',
        3,
        "A lot – the change can stall me for hours",
      ),
    ],
  ),
  AssessmentQuestion(
    id: 'adult_flex_2',
    dimension: Dimension.flexibility,
    ageGroup: AgeGroup.adult,
    text: 'כשמישהו מציע דרך עבודה שונה משלך, מה התגובה הראשונה שלך?',
    textEn:
        "When someone suggests a way of working that's different from yours, what's your first reaction?",
    options: [
      AnswerOption(
        'סקרנות – בודק אם זה עדיף',
        1,
        "Curiosity – I check whether it's better",
      ),
      AnswerOption(
        'התנגדות ראשונית, ואז שוקל',
        2,
        "Some initial pushback, then I consider it",
      ),
      AnswerOption(
        'קשה לי לזוז מהדרך שלי גם כשהיא לא עובדת',
        3,
        "It's hard to move off my way, even when it isn't working",
      ),
    ],
  ),
  AssessmentQuestion(
    id: 'adult_flex_3',
    dimension: Dimension.flexibility,
    ageGroup: AgeGroup.adult,
    text: 'כמה קל לך לעבור בין משימות שונות לאורך היום (למשל מישיבה לכתיבה)?',
    textEn:
        "How easy is it to switch between different tasks during the day (e.g. from a meeting to writing)?",
    options: [
      AnswerOption(
        'קל, אני נכנס למשימה הבאה תוך דקות',
        1,
        "Easy – I'm into the next task within minutes",
      ),
      AnswerOption(
        'לוקח זמן "להחליף דיסק"',
        2,
        "It takes a while to \"change gears\"",
      ),
      AnswerOption(
        'קשה מאוד, הראש נשאר במשימה הקודמת',
        3,
        "Very hard – my head stays on the previous task",
      ),
    ],
  ),
  // ---- initiation ----
  AssessmentQuestion(
    id: 'adult_init_core',
    dimension: Dimension.initiation,
    ageGroup: AgeGroup.adult,
    isCore: true,
    text: 'עד כמה אתה דוחה משימות אדמיניסטרטיביות עד הרגע האחרון?',
    textEn: "How much do you put off admin tasks until the last minute?",
    options: [
      AnswerOption(
        'כמעט לא, אני מטפל בהן בזמן',
        1,
        "Hardly ever – I handle them on time",
      ),
      AnswerOption(
        'לפעמים, בעיקר כשהן משעממות',
        2,
        "Sometimes, mostly when they're boring",
      ),
      AnswerOption(
        'כמעט תמיד, עד שזה הופך לדחוף',
        3,
        "Almost always, until it becomes urgent",
      ),
    ],
  ),
  AssessmentQuestion(
    id: 'adult_init_2',
    dimension: Dimension.initiation,
    ageGroup: AgeGroup.adult,
    text: 'מול פרויקט גדול, כמה קל לך לפרק אותו לצעד ראשון ברור?',
    textEn:
        "Facing a big project, how easy is it to break it down into a clear first step?",
    options: [
      AnswerOption(
        'קל, אני יודע מה הדבר הראשון לעשות',
        1,
        "Easy – I know the first thing to do",
      ),
      AnswerOption(
        'לוקח זמן, ולפעמים אני מתחיל מהקצה הלא נכון',
        2,
        "It takes time, and sometimes I start at the wrong end",
      ),
      AnswerOption(
        'אני משותק מול הגודל ולא מתחיל',
        3,
        "I freeze at the size of it and don't start",
      ),
    ],
  ),
  AssessmentQuestion(
    id: 'adult_init_3',
    dimension: Dimension.initiation,
    ageGroup: AgeGroup.adult,
    text:
        'כמה זמן עובר מהרגע שהחלטת לעשות משהו (טלפון, טופס) ועד שהתחלת בפועל?',
    textEn:
        "How much time passes between deciding to do something (a call, a form) and actually starting?",
    options: [
      AnswerOption('דקות עד שעות', 1, "Minutes to hours"),
      AnswerOption('כמה ימים', 2, "A few days"),
      AnswerOption(
        'שבועות, או שזה נשאר ברשימה',
        3,
        "Weeks – or it just stays on the list",
      ),
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
