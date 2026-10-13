// Helper test: writes tool/templates.json (strokes of every template) so the
// PowerShell rasterizer can draw them alongside Arial reference glyphs.
import 'dart:convert';
import 'dart:io';

import 'package:ai_tracer/features/levels/screens/levels_screen.dart';
import 'package:ai_tracer/features/tracing/models/tracing_template.dart';
import 'package:ai_tracer/features/tracing/services/template_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('export all templates to json', () {
    final all = <Map<String, Object>>[];
    for (final level in LevelsScreen.levels) {
      for (final character in level.templates) {
        final TracingTemplate t =
            TemplateService.generateTemplate(character, level.type);
        all.add({
          'level': level.name,
          'type': level.type.name,
          'character': character,
          'strokes': t.strokes.isNotEmpty
              ? t.strokes
                  .map(
                    (s) => s.map((p) => {'x': p.x, 'y': p.y}).toList(),
                  )
                  .toList()
              : [
                  t.points
                      .map((p) => {'x': p.x, 'y': p.y})
                      .toList(),
                ],
        });
      }
    }
    File('tool/templates.json').writeAsStringSync(
      const JsonEncoder.withIndent(' ').convert(all),
    );
  });
}
