/// Medical Disclaimer Injector
///
/// Deterministic safety net behind the system prompt: the prompt already asks
/// the model to say it is an AI and to route diagnosis, medication and
/// treatment questions to a professional, so this only fires on clinical
/// vocabulary and stays silent when the reply already made that referral.
///
/// The disclaimer is only added once (idempotent) and is appended at the
/// end of the response.
library;


/// Clinical terms only: diagnoses, disorders, medication, treatment.
/// Everyday emotion words (căng thẳng, lo âu, khóc, mất ngủ, stress) are the
/// app's daily vocabulary and appear in meditation titles, so they no longer
/// count — the old list stamped the notice under a plain list of meditations.
final List<RegExp> _disclaimerTriggerPatterns = [
  // Vietnamese
  RegExp(r'trầm\s*cảm', caseSensitive: false),
  RegExp(r'tram\s*cam', caseSensitive: false),
  RegExp(r'rối\s*loạn', caseSensitive: false),
  RegExp(r'roi\s*loan', caseSensitive: false),
  RegExp(r'tâm\s*thần', caseSensitive: false),
  RegExp(r'tam\s*than', caseSensitive: false),
  RegExp(r'bệnh', caseSensitive: false),
  RegExp(r'triệu\s*chứng', caseSensitive: false),
  RegExp(r'trieu\s*chung', caseSensitive: false),
  RegExp(r'chẩn\s*đoán', caseSensitive: false),
  RegExp(r'chan\s*doan', caseSensitive: false),
  RegExp(r'thuốc', caseSensitive: false),
  RegExp(r'thuoc', caseSensitive: false),
  RegExp(r'trị\s*liệu', caseSensitive: false),
  RegExp(r'tri\s*lieu', caseSensitive: false),
  RegExp(r'binge\s*eating', caseSensitive: false),

  // English equivalents
  RegExp(r'\bdepression\b', caseSensitive: false),
  RegExp(r'\bpanic\s*attack\b', caseSensitive: false),
  RegExp(r'\bptsd\b', caseSensitive: false),
  RegExp(r'\bocd\b', caseSensitive: false),
  RegExp(r'\bbipolar\b', caseSensitive: false),
  RegExp(r'\bschizophrenia\b', caseSensitive: false),
  RegExp(r'\btherapy\b', caseSensitive: false),
  RegExp(r'\bmedication\b', caseSensitive: false),
  RegExp(r'\bdiagnos', caseSensitive: false),
  RegExp(r'\bsymptom', caseSensitive: false),
  RegExp(r'\bdisorder\b', caseSensitive: false),
];

/// Plain text, same voice as the system prompt ("mình"/"bạn"): the chat
/// bubble renders a bare Text(), so the old `_…_` italics showed up raw.
const String _disclaimerText =
    '\n\n⚕️ Mình là trợ lý AI, không thay thế bác sĩ hay chuyên gia tâm lý. '
    'Nếu bạn cần giúp gấp, hãy gọi 115.';

class DisclaimerInjector {
  /// Append a medical disclaimer if any trigger keywords are present
  /// in either the [userInput] or the [aiResponse].
  ///
  /// Returns the original response unchanged if no triggers match,
  /// or the response with the disclaimer appended.
  static String maybeAdd({
    required String aiResponse,
    String? userInput,
  }) {
    if (aiResponse.trim().isEmpty) return aiResponse;

    // Already contains a disclaimer — don't duplicate.
    if (_alreadyHasDisclaimer(aiResponse)) return aiResponse;

    // Raw text only. The old diacritic-stripped pass turned "quen thuộc"
    // into "quen thuoc" and matched the medication pattern; typing without
    // diacritics is already covered by the ASCII patterns above.
    final combined = [aiResponse, userInput ?? ''].join(' ');
    for (final pattern in _disclaimerTriggerPatterns) {
      if (pattern.hasMatch(combined)) return '$aiResponse$_disclaimerText';
    }
    return aiResponse;
  }

  /// Check whether the response already discloses or refers out: either the
  /// notice itself, or the model doing what the prompt asks (naming itself as
  /// AI, pointing to a doctor or specialist). Appending on top of that reads
  /// as nagging.
  static bool _alreadyHasDisclaimer(String response) {
    final lower = response.toLowerCase();
    return lower.contains('⚕️') ||
        lower.contains('không thay thế') ||
        lower.contains('not a substitute') ||
        lower.contains('trợ lý ai') ||
        lower.contains('bác sĩ') ||
        lower.contains('chuyên gia') ||
        lower.contains('professional') ||
        lower.contains('therapist') ||
        lower.contains('doctor');
  }
}
