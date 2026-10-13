// Renders templates to PNG files so the shapes can be inspected visually.
// Run with: flutter test test/render_templates_test.dart
// Outputs to build/template_previews/
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ai_tracer/features/levels/screens/levels_screen.dart';
import 'package:ai_tracer/features/tracing/services/template_service.dart';
import 'package:ai_tracer/features/tracing/widgets/template_painter.dart';

Future<void> _render(
  WidgetTester tester,
  String prefix,
  List<String> chars,
  dynamic level,
) async {
  final dir = Directory('build/template_previews');
  dir.createSync(recursive: true);
  for (final c in chars) {
    final template = TemplateService.generateTemplate(c, level.type);
    final key = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        home: ColoredBox(
          color: Colors.white,
          child: Center(
            child: RepaintBoundary(
              key: key,
              child: CustomPaint(
                painter: TemplatePainter(template: template),
                size: const Size(300, 300),
              ),
            ),
          ),
        ),
      ),
    );
    final boundary = key.currentContext!.findRenderObject()
        as RenderRepaintBoundary;
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      File('${dir.path}/$prefix${c.codeUnitAt(0)}.png')
          .writeAsBytesSync(bytes!.buffer.asUint8List());
    });
  }
}

void main() {
  testWidgets('render templates to PNGs', (tester) async {
    await _render(tester, 'num_', LevelsScreen.levels[2].templates, LevelsScreen.levels[2]);
    await _render(tester, 'cap_', LevelsScreen.levels[3].templates, LevelsScreen.levels[3]);
    await _render(tester, 'small_', LevelsScreen.levels[4].templates, LevelsScreen.levels[4]);
    await _render(tester, 'line_', LevelsScreen.levels[0].templates, LevelsScreen.levels[0]);
  });
}
