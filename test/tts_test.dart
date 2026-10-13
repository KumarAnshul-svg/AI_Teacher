import 'package:ai_tracer/core/services/tts_service.dart';
import 'package:ai_tracer/features/levels/models/level.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TtsService phrase mapping', () {
    test('lines speak their orientation names', () {
      expect(TtsService.phraseFor('|', LevelType.lines), 'vertical line');
      expect(TtsService.phraseFor('-', LevelType.lines), 'horizontal line');
      expect(TtsService.phraseFor('/', LevelType.lines), 'diagonal line');
      expect(TtsService.phraseFor('\\', LevelType.lines), 'backslash');
      expect(TtsService.phraseFor('V', LevelType.lines), 'V shape');
      expect(TtsService.phraseFor('^', LevelType.lines), 'caret');
      expect(TtsService.phraseFor('~', LevelType.lines), 'wave');
      expect(TtsService.phraseFor('⌒', LevelType.lines), 'arch');
    });

    test('shapes speak their names', () {
      expect(TtsService.phraseFor('O', LevelType.shapes), 'circle');
      expect(TtsService.phraseFor('□', LevelType.shapes), 'square');
      expect(TtsService.phraseFor('△', LevelType.shapes), 'triangle');
      expect(TtsService.phraseFor('☆', LevelType.shapes), 'star');
      expect(TtsService.phraseFor('♥', LevelType.shapes), 'heart');
      expect(TtsService.phraseFor('◇', LevelType.shapes), 'diamond');
      expect(TtsService.phraseFor('⬠', LevelType.shapes), 'pentagon');
      expect(TtsService.phraseFor('⬡', LevelType.shapes), 'hexagon');
    });

    test('numbers speak their digit names', () {
      expect(TtsService.phraseFor('0', LevelType.numbers), 'zero');
      expect(TtsService.phraseFor('5', LevelType.numbers), 'five');
      expect(TtsService.phraseFor('9', LevelType.numbers), 'nine');
    });

    test('letters are prefixed by case', () {
      expect(TtsService.phraseFor('A', LevelType.capitalLetters), 'Capital A');
      expect(TtsService.phraseFor('m', LevelType.smallLetters), 'Small m');
      // Same glyph, different segment, different phrase.
      expect(TtsService.phraseFor('V', LevelType.capitalLetters), 'Capital V');
    });

    test('sentences are spoken verbatim', () {
      expect(TtsService.phraseFor('Cat', LevelType.sentences), 'Cat');
      expect(TtsService.phraseFor('Sun', LevelType.sentences), 'Sun');
    });
  });

  group('TtsService feminine voice picker', () {
    test('prefers an explicitly female English voice', () {
      final voices = [
        {'name': 'Microsoft David', 'locale': 'en-US'},
        {'name': 'Microsoft Aria', 'locale': 'en-US'},
        {'name': 'Microsoft Zira', 'locale': 'en-US'},
      ];
      final picked = TtsService.pickFemaleVoice(voices);
      expect(picked, isNotNull);
      expect(picked!['name'], 'Microsoft Aria');
    });

    test('matches named female voices and skips male-marked ones', () {
      final voices = [
        {'name': 'Microsoft Guy', 'locale': 'en-US'},
        {'name': 'Google UK English Female', 'locale': 'en-GB'},
      ];
      final picked = TtsService.pickFemaleVoice(voices);
      expect(picked?['name'], 'Google UK English Female');
      expect(picked?['locale'], 'en-GB');
    });

    test('non-English voices are ignored', () {
      final voices = [
        {'name': 'Microsoft Ineka', 'locale': 'de-DE'},
        {'name': 'Aria', 'locale': 'fr-FR'},
      ];
      expect(TtsService.pickFemaleVoice(voices), isNull);
    });

    test('returns null for empty or malformed input', () {
      expect(TtsService.pickFemaleVoice([]), isNull);
      expect(TtsService.pickFemaleVoice('not a list'), isNull);
      expect(
        TtsService.pickFemaleVoice([
          'string entries are skipped',
          {'name': 'Samantha'}, // no locale -> not English -> skipped
        ]),
        isNull,
      );
    });

    test('prefers natural/online voices for a more human sound', () {
      final voices = [
        {'name': 'Microsoft Zira', 'locale': 'en-US'},
        {'name': 'Microsoft Aria Online (Natural)', 'locale': 'en-US'},
      ];
      final picked = TtsService.pickFemaleVoice(voices);
      expect(picked?['name'], 'Microsoft Aria Online (Natural)');
    });

    test('Google US English is feminine and skips Google male voices', () {
      final voices = [
        {'name': 'Google UK English Male', 'locale': 'en-GB'},
        {'name': 'Google US English', 'locale': 'en-US'},
      ];
      final picked = TtsService.pickFemaleVoice(voices);
      expect(picked?['name'], 'Google US English');
    });
  });
}
