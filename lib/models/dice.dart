import 'dart:math';

class Dice {
  int currentValue;
  final Random _random;

  Dice({int initialValue = 1})
    : currentValue = initialValue,
      _random = Random();

  void roll() {
    currentValue = _random.nextInt(6) + 1; // Generates a random number between 1 and 6
  }

  @override
  String toString() {
    return 'Dice(currentValue: $currentValue)';
  }
}
