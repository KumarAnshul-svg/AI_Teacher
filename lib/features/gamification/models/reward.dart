class Reward {
  final String id;
  final String name;
  final String description;
  final RewardType type;
  final int cost;
  final String assetPath;
  final bool isLocked;

  const Reward({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.cost,
    required this.assetPath,
    this.isLocked = false,
  });
}

enum RewardType {
  theme,
  penStyle,
  background,
  sticker,
  character,
}
