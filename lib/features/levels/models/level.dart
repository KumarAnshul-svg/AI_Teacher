import 'package:flutter/material.dart';

enum LevelType {
  lines,
  shapes,
  numbers,
  capitalLetters,
  smallLetters,
  sentences,
}

class Level {
  final int id;
  final String name;
  final LevelType type;
  final IconData icon;
  final Color color;
  final bool isUnlocked;
  final int starsEarned;
  final List<String> templates;

  const Level({
    required this.id,
    required this.name,
    required this.type,
    required this.icon,
    required this.color,
    this.isUnlocked = false,
    this.starsEarned = 0,
    required this.templates,
  });

  Level copyWith({
    bool? isUnlocked,
    int? starsEarned,
  }) {
    return Level(
      id: id,
      name: name,
      type: type,
      icon: icon,
      color: color,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      starsEarned: starsEarned ?? this.starsEarned,
      templates: templates,
    );
  }
}
