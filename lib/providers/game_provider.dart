import 'package:flutter/foundation.dart';
import 'package:ludo/models/game.dart';
import 'package:ludo/models/pawn.dart';
import 'package:ludo/models/player.dart'; // For type hinting if needed

class GameState extends ChangeNotifier {
  late Game _game;
  Pawn? _selectedPawn;
  int _numPlayers = 2; // Default, will be overridden by resetGame
  bool _playWithAI = false; // Default

  // Initialize the game with default settings or specified ones.
  // The main initialization will now happen via resetGame from MyHomePage.
  GameState() {
    // Initialize with default values. These will be immediately overridden
    // by the call to resetGame in MyHomePage's initState.
    resetGame(numPlayers: 2, playWithAI: false);
  }

  // Getters to expose game data
  // Expose numPlayers and playWithAI if UI needs them
  int get numPlayersConfig => _numPlayers;
  bool get playWithAIConfig => _playWithAI;
  Game get game => _game; // Expose the whole game object if needed by UI
  Player getCurrentPlayer() => _game.getCurrentPlayer();
  int get diceValue => _game.dice.currentValue;
  List<Player> get players => _game.players;
  Pawn? get selectedPawn => _selectedPawn;
  // Potentially add more specific getters if the UI doesn't need the whole Game object.

  // Methods to modify game state
  void rollDice() {
    _game.rollDice();
    notifyListeners();

    // Check for AI turn after dice roll
    if (getCurrentPlayer().isAI) {
      _handleAITurn();
    }
  }

  void nextTurn() {
    _game.nextTurn();
    _selectedPawn = null; // Clear selected pawn on turn change
    notifyListeners();

    // Check for AI turn after turn changes
    if (getCurrentPlayer().isAI) {
      _handleAITurn();
    }
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
  void resetGame({required int numPlayers, required bool playWithAI}) {
    _numPlayers = numPlayers;
    _playWithAI = playWithAI;
    _game = Game(numPlayersToCreate: _numPlayers, playWithAI: _playWithAI);
    _selectedPawn = null;
    print("Game reset in GameState: Players: $_numPlayers, AI: $_playWithAI. Actual players in game: ${_game.players.length}");
    if (_playWithAI && _game.players.isNotEmpty && _game.players.last.isAI) {
      print("AI Player confirmed: ${_game.players.last.color}");
    }
    notifyListeners();
    // Check if the first player is AI and trigger their turn
    if (getCurrentPlayer().isAI) {
        _handleAITurn();
    }
  }

  // --- AI Logic ---
  Future<void> _handleAITurn() async {
    print("AI Turn: ${getCurrentPlayer().color}");
    if (!getCurrentPlayer().isAI) return; // Should not happen if called correctly

    // 1. Add a short delay for UX
    await Future.delayed(const Duration(seconds: 1));

    // AI doesn't "roll" in the same way a human does via UI button.
    // The rollDice() method in GameState is for human players.
    // For AI, we can directly roll the game's dice object.
    // However, the current rollDice() in GameState also triggers AI check.
    // To avoid re-entrancy issues or complex conditions in rollDice(),
    // AI can have a slightly different flow for its first action (rolling).
    // OR, ensure rollDice() is safe for AI to call.
    // Current rollDice() calls notifyListeners() then _handleAITurn() if AI.
    // If AI calls rollDice(), it will notify, then it will call _handleAITurn() again. This is a loop.

    // Corrected AI dice roll:
    _game.dice.roll(); // AI rolls the dice internally
    print("AI rolled: ${diceValue}");
    notifyListeners(); // Notify UI about dice roll

    await Future.delayed(const Duration(milliseconds: 500)); // Short delay after showing dice roll

    // 2. Find a movable pawn
    Player aiPlayer = getCurrentPlayer();
    List<Pawn> movablePawns = _game.getMovablePawns(aiPlayer, diceValue);

    if (movablePawns.isNotEmpty) {
      Pawn pawnToMove = movablePawns.first; // Simplest strategy: pick the first movable pawn
      print("AI selected pawn: ${pawnToMove.id} at ${pawnToMove.position}");

      // We need to set this as the selectedPawn for attemptMoveSelectedPawn to work
      _selectedPawn = pawnToMove; // AI "selects" the pawn
      // No need to notifyListeners for pawn selection if it's an internal AI step before immediate move.
      // However, if we want UI to show AI's selection briefly, we could:
      // notifyListeners();
      // await Future.delayed(const Duration(milliseconds: 500));

      attemptMoveSelectedPawn(); // This method handles notifyListeners and nextTurn logic
    } else {
      print("AI has no movable pawns with dice value $diceValue.");
      // If no pawn is movable, the AI's turn ends.
      // attemptMoveSelectedPawn already calls nextTurn if move fails or not a 6.
      // But if no pawns are movable AT ALL, attemptMoveSelectedPawn is not called.
      // So, we need to call nextTurn here.
      nextTurn(); // This will also trigger _handleAITurn if the next player is AI.
    }
  }
}
