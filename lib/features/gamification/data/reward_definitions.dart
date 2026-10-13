import '../models/reward.dart';

class RewardDefinitions {
  static const List<Reward> allRewards = [
    Reward(
      id: 'rainbow_pen',
      name: 'Rainbow Pen',
      description: 'A magical rainbow pen',
      type: RewardType.penStyle,
      cost: 50,
      assetPath: 'assets/rewards/pens/rainbow.json',
    ),
    Reward(
      id: 'glitter_pen',
      name: 'Glitter Pen',
      description: 'Sparkly glitter pen',
      type: RewardType.penStyle,
      cost: 75,
      assetPath: 'assets/rewards/pens/glitter.json',
    ),
    Reward(
      id: 'neon_pen',
      name: 'Neon Pen',
      description: 'Glowing neon pen',
      type: RewardType.penStyle,
      cost: 100,
      assetPath: 'assets/rewards/pens/neon.json',
    ),
    Reward(
      id: 'space_bg',
      name: 'Space Background',
      description: 'Practice in outer space',
      type: RewardType.background,
      cost: 100,
      assetPath: 'assets/rewards/backgrounds/space.json',
    ),
    Reward(
      id: 'underwater_bg',
      name: 'Underwater Background',
      description: 'Practice under the sea',
      type: RewardType.background,
      cost: 100,
      assetPath: 'assets/rewards/backgrounds/underwater.json',
    ),
    Reward(
      id: 'forest_bg',
      name: 'Forest Background',
      description: 'Practice in a magical forest',
      type: RewardType.background,
      cost: 150,
      assetPath: 'assets/rewards/backgrounds/forest.json',
    ),
    Reward(
      id: 'theme_pastel',
      name: 'Pastel Theme',
      description: 'Soft pastel colors',
      type: RewardType.theme,
      cost: 200,
      assetPath: 'assets/rewards/themes/pastel.json',
    ),
    Reward(
      id: 'theme_dark',
      name: 'Night Mode',
      description: 'Easy on the eyes',
      type: RewardType.theme,
      cost: 200,
      assetPath: 'assets/rewards/themes/dark.json',
    ),
  ];
}
