import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../../features/levels/models/level.dart';

/// Speaks the name of whatever level is displayed when it is started or
/// completed. Uses the browser's Web Speech API on web (flutter_tts_web)
/// and the platform TTS engine elsewhere.
///
/// On web the underlying plugin silently drops a `speak()` whenever the
/// engine's internal state is still "playing"/"paused" — and the browser
/// fires the cancel/end event that resets that state a tick *after*
/// `stop()` returns. So this service issues the speak, watches for the
/// browser's real start event, and retries until it hears it.
class TtsService {
  final FlutterTts _tts = FlutterTts();
  bool _muted = false;
  bool _configured = false;

  /// Completes when the browser confirms an utterance actually started.
  Completer<void>? _started;

  TtsService() {
    _tts.setStartHandler(_onStarted);
  }

  void _onStarted() {
    final completer = _started;
    _started = null;
    if (completer != null && !completer.isCompleted) {
      completer.complete();
    }
  }

  bool get muted => _muted;

  /// When [value] is true, speech is disabled until unmuted.
  void setMuted(bool value) {
    _muted = value;
  }

  Future<void> _ensureConfigured() async {
    if (_configured) return;
    try {
      // getVoices() primes the browser's voice list. Chrome fills the
      // list a beat after the page loads, so poll briefly — otherwise
      // the first speak settles for the male default voice.
      var voices = await _tts.getVoices;
      var female = pickFemaleVoice(voices);
      for (var attempt = 0; female == null && attempt < 8; attempt++) {
        await Future<void>.delayed(const Duration(milliseconds: 250));
        voices = await _tts.getVoices;
        female = pickFemaleVoice(voices);
      }
      if (female != null) {
        await _tts.setLanguage(female['locale']!);
        await _tts.setVoice(female);
        _configured = true;
      } else {
        await _tts.setLanguage('en-US');
        if (voices is List && voices.isNotEmpty) {
          // The engine has voices, just none we recognize as feminine:
          // accept the default so we don't re-poll on every speak.
          _configured = true;
        }
        // Otherwise the list was empty: stay unconfigured and retry on
        // the next speak, once the browser reports its voices.
      }
      // A subtly higher pitch and a natural pace make the utterance flow
      // like a person talking instead of a machine; a touch slower keeps
      // every word clearly articulated for young learners.
      await _tts.setPitch(1.15);
      await _tts.setSpeechRate(0.48);
    } catch (_) {
      // Non-fatal: speech simply stays silent if the engine is unusable.
    }
  }

  /// Picks a feminine English voice from the engine's voice list. The list
  /// shape is platform specific (web: {name, locale}), so this normalizes
  /// whatever is there and stays tolerant of missing fields. Voices that
  /// sound like real people (online/natural/google) are preferred; returns
  /// null when no feminine English voice exists.
  static Map<String, String>? pickFemaleVoice(dynamic voices) {
    if (voices is! List) return null;
    const femaleMarkers = [
      'female', 'woman', 'girl', 'google', 'siri', // explicit markers
      'aria', 'zira', 'jenny', 'samantha', 'karen', 'susan', 'julie',
      'hazel', 'salli', 'joanna', 'olivia', 'nicole', 'emma', 'ava',
      'allison', 'alison', 'ashley', 'kate', 'moira', 'tessa',
      'victoria', 'serena', 'michelle', 'sarah', 'sonia', 'heera',
      'veena', 'linda', 'kendra', 'natasha', 'helen', 'laura', 'amy',
      'alice', 'cora', 'heather', 'kathleen', 'vicki', 'jane', 'mary',
      'catherine', 'francine', 'martha', 'donna',
    ];
    final candidates = <Map<String, String>>[];
    for (final voice in voices.whereType<Map>()) {
      final name = (voice['name'] ?? '').toString().toLowerCase();
      final locale =
          (voice['locale'] ?? voice['lang'] ?? '').toString().toLowerCase();
      if (!locale.startsWith('en')) continue;
      // Skip explicitly male-marked voices unless the name also says
      // female (e.g. "Microsoft Aria" sometimes appears near "male").
      if (name.contains('male') && !name.contains('female')) continue;
      if (!femaleMarkers.any(name.contains)) continue;
      candidates.add({
        'name': voice['name']?.toString() ?? '',
        'locale': voice['locale'] ?? voice['lang'] ?? 'en-US',
      });
    }
    if (candidates.isEmpty) return null;
    // Natural/online machine voices sound like real people; prefer them.
    for (final voice in candidates) {
      final name = voice['name']!.toLowerCase();
      if (name.contains('natural') ||
          name.contains('online') ||
          name.contains('google')) {
        return voice;
      }
    }
    return candidates.first;
  }

  /// Converts a level character (line, shape, digit, letter or word) into
  /// a spoken phrase.
  Future<void> speakCharacter(String character, LevelType type) async {
    if (_muted) return;
    final phrase = phraseFor(character, type);
    if (phrase == null) return;
    await speakRaw(phrase);
  }

  /// Speaks a pre-composed phrase. Any failure to speak is swallowed
  /// silently — the voice is a nicety, never a blocker.
  Future<void> speakRaw(String phrase) async {
    if (_muted || phrase.isEmpty) return;
    try {
      await _ensureConfigured();
      if (_muted || phrase.isEmpty) return;
      await _tts.stop();
      for (var attempt = 0; attempt < 3; attempt++) {
        // Give the stop/cancel event time to settle before retrying; on
        // the very first call nothing is playing, so keep it short.
        await Future<void>.delayed(
          Duration(milliseconds: attempt == 0 ? 120 : 250),
        );
        final started = Completer<void>();
        _started = started;
        try {
          await _tts.speak(phrase);
        } catch (_) {
          _started = null;
          return;
        }
        await Future.any<void>([
          started.future,
          Future<void>.delayed(const Duration(milliseconds: 900)),
        ]);
        if (_started == null) {
          return; // The browser really is speaking now.
        }
        // Not heard: the engine was still busy and dropped this speak.
      }
    } catch (_) {
      // No engine available / speak not supported: stay silent.
    }
  }

  /// Map a single level character to the phrase the child should hear.
  static String? phraseFor(String character, LevelType type) {
    switch (type) {
      case LevelType.lines:
        return _lineNames[character];
      case LevelType.shapes:
        return _shapeNames[character];
      case LevelType.numbers:
        return _digitNames[character] ?? character;
      case LevelType.capitalLetters:
        return 'Capital $character';
      case LevelType.smallLetters:
        return 'Small $character';
      case LevelType.sentences:
        return character; // speak words as-is
    }
  }

  static const Map<String, String> _digitNames = {
    '0': 'zero',
    '1': 'one',
    '2': 'two',
    '3': 'three',
    '4': 'four',
    '5': 'five',
    '6': 'six',
    '7': 'seven',
    '8': 'eight',
    '9': 'nine',
  };

  static const Map<String, String> _lineNames = {
    '|': 'vertical line',
    '-': 'horizontal line',
    '/': 'diagonal line',
    '\\': 'backslash',
    'V': 'V shape',
    '^': 'caret',
    '~': 'wave',
    '⌒': 'arch',
  };

  static const Map<String, String> _shapeNames = {
    'O': 'circle',
    '□': 'square',
    '△': 'triangle',
    '☆': 'star',
    '♥': 'heart',
    '◇': 'diamond',
    '⬠': 'pentagon',
    '⬡': 'hexagon',
  };
}

final ttsServiceProvider = Provider<TtsService>((ref) => TtsService());
