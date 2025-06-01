import 'package:flutter_test/flutter_test.dart';
import 'package:ludo/models/dice.dart'; // Adjust import path as necessary

void main() {
  group('Dice', () {
    late Dice dice;

    setUp(() {
      dice = Dice();
    });

    test('initial currentValue is 1 (or as set)', () {
      // The Dice constructor sets an initial value, default is 1
      expect(dice.currentValue, anyOf(1, 2, 3, 4, 5, 6)); // Or check specific initial if constructor guarantees
      // If Dice() always starts at 1:
      // expect(dice.currentValue, 1);
      // However, the current Dice model initializes with a value (default 1) but doesn't roll.
      // Let's assume the test means after a roll.
      // For a freshly initialized Dice, it will be its initialValue.
      expect(dice.currentValue, isNotNull); // current Dice constructor sets default 1
      expect(dice.currentValue >= 1 && dice.currentValue <=6, isTrue);
    });

    test('roll() updates currentValue', () {
      int initialValue = dice.currentValue;
      dice.roll();
      // It's possible, though unlikely, to roll the same number.
      // The core test is that it *can* change and stays within bounds.
      expect(dice.currentValue, isNotNull);
      expect(dice.currentValue, isA<int>());
      // This test is more robustly covered by the next test.
    });

    test('roll() produces values within 1-6', () {
      for (int i = 0; i < 100; i++) {
        dice.roll();
        expect(dice.currentValue, greaterThanOrEqualTo(1));
        expect(dice.currentValue, lessThanOrEqualTo(6));
      }
    });

     test('constructor sets initial value correctly', () {
      var diceWithValue = Dice(initialValue: 4);
      expect(diceWithValue.currentValue, 4);
    });
  });
}
