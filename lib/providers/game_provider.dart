import 'package:flutter/foundation.dart';
import 'package:ludo/models/game.dart';
import 'package:ludo/models/pawn.dart';
import 'package:ludo/models/player.dart'; // For type hinting if needed

class GameState extends ChangeNotifier {
  late Game _game;
  Pawn? _selectedPawn;
  int? _stickyDiceValue; // To hold the dice value for the current player's action
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
    _stickyDiceValue = _game.dice.currentValue; // Store the rolled value
    notifyListeners();

    // New logic for auto-passing human player's turn, using _stickyDiceValue
    Player currentPlayer = getCurrentPlayer();
    // Ensure _stickyDiceValue is not null here, as it's just been set.
    if (_stickyDiceValue == null) {
        debugPrint("Error: _stickyDiceValue is null immediately after roll. This should not happen.");
        // Fallback or error handling if necessary, though theoretically unreachable.
        // For safety, AI check might be skipped or handled.
        // However, the primary concern is the auto-pass logic.
        // If _stickyDiceValue is null, it cannot satisfy "!= 6".
        // To be safe, let's assume if it's null, we don't auto-pass.
        // This situation indicates a deeper issue if it occurs.
    }

    if (!currentPlayer.isAI &&
        _stickyDiceValue != null && // Added null check for safety
        _stickyDiceValue != 6 &&
        currentPlayer.getOnBoardPawns().isEmpty) {
      debugPrint(
          "Human player ${currentPlayer.color} rolled $_stickyDiceValue and has no pawns on board. Auto-passing turn.");
      nextTurn(); // nextTurn already calls notifyListeners and clears _stickyDiceValue
      return;
    }

    // Check for AI turn after dice roll
    if (getCurrentPlayer().isAI) {
      _handleAITurn();
    }
  }

  void nextTurn() {
    _stickyDiceValue = null; // Clear sticky dice value on any turn change
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
      debugPrint("Cannot select pawn: Not current player's pawn.");
    }
  }

  // Attempts to move the currently selected pawn using the current dice value.
  void attemptMoveSelectedPawn() {
    if (_selectedPawn == null) {
      debugPrint("No pawn selected to move.");
      // Optionally, provide user feedback via a message
      return;
    }
    if (_selectedPawn!.color != getCurrentPlayer().color) {
      debugPrint("Selected pawn does not belong to the current player.");
      // This case should ideally be prevented by selectPawn logic
      return;
    }

    // Use the _stickyDiceValue for the move attempt
    int? moveDiceValue = _stickyDiceValue;

    if (moveDiceValue == null) {
      debugPrint("Error: attemptMoveSelectedPawn called but _stickyDiceValue is null. Roll dice first.");
      // Optionally provide user feedback via a message
      return;
    }

    // The check for currentDiceValue == 0 is no longer needed here if _stickyDiceValue guarantees a valid roll.
    // However, if _stickyDiceValue could be 0 from a "bad roll" (if dice could roll 0), it might be relevant.
    // Assuming dice rolls 1-6.

    // Call the game logic's movePawn
    bool moveSuccessful = _game.movePawn(_selectedPawn!, moveDiceValue);

    if (moveSuccessful) {
      _stickyDiceValue = null; // Consume the dice value after a successful move
      _selectedPawn = null; // Clear selection after a successful move attempt.

      if (moveDiceValue == 6) {
        debugPrint("Rolled a 6, player gets another turn. Roll dice again.");
        // Player gets another turn, they need to roll dice again.
        // _stickyDiceValue is now null, so they can't move again with the same 6.
        // No call to nextTurn() here.
      } else {
        // If not a 6, switch to the next player.
        nextTurn(); // This will also clear _stickyDiceValue again, which is fine.
      }
    } else {
      // If the move was not successful, _stickyDiceValue remains unchanged.
      // This allows the player to select another pawn and try to move it with the same dice value.
      debugPrint("Move for ${_selectedPawn!.id} of ${_selectedPawn!.color} was not successful with dice $moveDiceValue.");
      // Do not clear _selectedPawn here, player might want to re-evaluate or it's cleared if they select another.
    }
    notifyListeners();
  }

  // Method to re-initialize the game or start a new one
  void resetGame({required int numPlayers, required bool playWithAI}) {
    _numPlayers = numPlayers;
    _playWithAI = playWithAI;
    _game = Game(numPlayersToCreate: _numPlayers, playWithAI: _playWithAI);
    _selectedPawn = null;
    _stickyDiceValue = null; // Clear sticky dice value on game reset
    debugPrint("Game reset in GameState: Players: $_numPlayers, AI: $_playWithAI. Actual players in game: ${_game.players.length}");
    if (_playWithAI && _game.players.isNotEmpty && _game.players.last.isAI) {
      debugPrint("AI Player confirmed: ${_game.players.last.color}");
    }
    notifyListeners();
    // Check if the first player is AI and trigger their turn
    if (getCurrentPlayer().isAI) {
        _handleAITurn();
    }
  }

  // --- AI Logic ---
  Future<void> _handleAITurn() async {
    debugPrint("AI Turn: ${getCurrentPlayer().color}");
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
    _stickyDiceValue = _game.dice.currentValue; // AI also uses sticky dice value for its turn.
    debugPrint("AI rolled: $_stickyDiceValue");
    notifyListeners(); // Notify UI about dice roll

    await Future.delayed(const Duration(milliseconds: 500)); // Short delay after showing dice roll

    // 2. Find a movable pawn
    Player aiPlayer = getCurrentPlayer();
    // AI needs to use _stickyDiceValue to find movable pawns.
    // Ensure _stickyDiceValue is not null for AI's decision process.
    if (_stickyDiceValue == null) {
      debugPrint("Error: AI turn, but _stickyDiceValue is null after roll. This should not happen.");
      nextTurn(); // Pass turn if AI cannot determine its move due to missing dice value
      return;
    }
    List<Pawn> movablePawns = _game.getMovablePawns(aiPlayer, _stickyDiceValue!);

    if (movablePawns.isNotEmpty) {
      Pawn pawnToMove = movablePawns.first; // Simplest strategy: pick the first movable pawn
      debugPrint("AI selected pawn: ${pawnToMove.id} at ${pawnToMove.position}");
      _selectedPawn = pawnToMove; // AI "selects" the pawn

      // AI calls attemptMoveSelectedPawn, which will use _stickyDiceValue
      attemptMoveSelectedPawn();
    } else {
      debugPrint("AI has no movable pawns with dice value $_stickyDiceValue.");
      // If no pawn is movable, the AI's turn ends.
      // attemptMoveSelectedPawn is not called, so _stickyDiceValue is not consumed by it.
      // nextTurn() will clear _stickyDiceValue.
      nextTurn();
    }
  }
}
