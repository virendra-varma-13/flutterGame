import 'package:flutter/foundation.dart';
import 'package:ludo/models/game.dart';
import 'package:ludo/models/pawn.dart';
import 'package:ludo/models/player.dart'; // For type hinting if needed

class GameState extends ChangeNotifier {
  late Game _game;
  Pawn? _selectedPawn;

  // Initialize the game with default players, can be customized
  GameState({List<String>? playerColors}) {
    _game = Game(playerColors: playerColors ?? ["Red", "Green", "Yellow", "Blue"]);
  }

  // Getters to expose game data
  Game get game => _game; // Expose the whole game object if needed by UI
  Player getCurrentPlayer() => _game.getCurrentPlayer();
  int get diceValue => _game.dice.currentValue;
  List<Player> get players => _game.players;
  Pawn? get selectedPawn => _selectedPawn;
  // Potentially add more specific getters if the UI doesn't need the whole Game object.

  // Methods to modify game state
  void rollDice() {
    _game.rollDice();
    // Potentially add logic here: e.g., if no moves possible, call nextTurn()
    // For now, just roll and notify. UI will decide next steps.
    notifyListeners();
  }

  void nextTurn() {
    _game.nextTurn();
    _selectedPawn = null; // Clear selected pawn on turn change
    notifyListeners();
  }

  void selectPawn(Pawn pawn) {
    // Basic selection logic:
    // Only allow selection if it's the current player's pawn.
    if (pawn.color == getCurrentPlayer().color) {
      _selectedPawn = pawn;
      notifyListeners();
    } else {
      // Optionally, provide feedback that this pawn cannot be selected
      print("Cannot select pawn: Not current player's pawn.");
    }
  }

  // Attempts to move the currently selected pawn using the current dice value.
  void attemptMoveSelectedPawn() {
    if (_selectedPawn == null) {
      print("No pawn selected to move.");
      // Optionally, provide user feedback via a message
      return;
    }
    if (_selectedPawn!.color != getCurrentPlayer().color) {
      print("Selected pawn does not belong to the current player.");
      // This case should ideally be prevented by selectPawn logic
      return;
    }

    int currentDiceValue = _game.dice.currentValue;
    if (currentDiceValue == 0) { // Assuming 0 means dice not rolled or invalid state
        print("Dice has not been rolled or shows 0.");
        return;
    }

    // Call the game logic's movePawn
    // The Game model's movePawn now takes steps (dice value) directly.
    bool moveSuccessful = _game.movePawn(_selectedPawn!, currentDiceValue);

    if (moveSuccessful) {
      // Standard Ludo rule: if a 6 is rolled, player gets another turn.
      // Also, if a pawn moves out of home or captures (not yet implemented), player might get another turn.
      // For now, simplified: only a 6 grants another turn.
      if (currentDiceValue == 6) {
        print("Rolled a 6, player gets another turn.");
        // Player might want to roll again or move another pawn if applicable.
        // For now, we just don't switch turns.
      } else {
        // If not a 6, switch to the next player.
        _game.nextTurn();
      }
      _selectedPawn = null; // Clear selection after a successful move attempt.
    } else {
      // If the move was not successful (e.g., pawn at home and not a 6),
      // provide feedback to the user.
      // The turn might still pass if no other pawn can be moved with the current dice roll.
      // This part of logic (checking if any move is possible) is not yet implemented.
      // For now, if a move fails, the turn doesn't automatically switch, allowing player to select another pawn.
      print("Move for ${_selectedPawn!.id} of ${_selectedPawn!.color} was not successful with dice $currentDiceValue.");
    }
    notifyListeners();
  }

  // Method to re-initialize the game or start a new one
  void resetGame({List<String>? playerColors}) {
    _game = Game(playerColors: playerColors ?? ["Red", "Green", "Yellow", "Blue"]);
    _selectedPawn = null;
    notifyListeners();
  }
}
