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
    notifyListeners(); // UI shows dice value

    Player currentPlayer = getCurrentPlayer(); // Get current player

    // Defensive check, though _stickyDiceValue should always be set above.
    if (_stickyDiceValue == null) {
        debugPrint("RollDice: Error - _stickyDiceValue is null immediately after roll and assignment. This indicates a critical issue.");
        // Potentially handle error, like ending turn or showing error to user.
        // For now, proceeding will likely fail in subsequent checks or actions.
        // If AI's turn, it might also fail.
    }

    // --- START: New Auto-move logic for human player with all pawns home on a 6 ---
    if (!currentPlayer.isAI && _stickyDiceValue == 6) {
        bool allPawnsAtHome = currentPlayer.pawns.every((p) => p.state == PawnState.home);
        if (allPawnsAtHome) {
            debugPrint("Auto-move: Player ${currentPlayer.color} rolled 6 with all pawns home.");
            // getHomePawns() might not exist, using direct filter.
            List<Pawn> homePawns = currentPlayer.pawns.where((p) => p.state == PawnState.home).toList();
            if (homePawns.isNotEmpty) { // Should always be true if allPawnsAtHome is true and pawns.length > 0
                Pawn pawnToMove = homePawns.first; // Select the first available home pawn
                _selectedPawn = pawnToMove; // Internal selection
                debugPrint("Auto-move: Selecting pawn ${pawnToMove.id}-${pawnToMove.color} for player ${currentPlayer.color}.");
                attemptMoveSelectedPawn(); // This handles 'another turn on 6' & clears sticky value if move is successful
                return; // Action for this roll is complete
            } else {
                debugPrint("Auto-move: Player ${currentPlayer.color} rolled 6, all pawns home, but no home pawns found in list. Skipping auto-move.");
            }
        }
    }
    // --- END: New Auto-move logic ---

    // Existing auto-pass logic for human (non-6 roll, no pawns out on board or in home stretch)
    // Added check for pawns in home stretch as well.
    if (!currentPlayer.isAI &&
        _stickyDiceValue != null &&
        _stickyDiceValue != 6 &&
        currentPlayer.getOnBoardPawns().isEmpty &&
        currentPlayer.pawns.where((p) => p.state == PawnState.inHomeStretch).toList().isEmpty) {
      debugPrint(
          "Auto-pass: Human player ${currentPlayer.color} rolled $_stickyDiceValue and has no pawns on board or in home stretch. Auto-passing turn.");
      nextTurn(); // nextTurn calls notifyListeners and clears _stickyDiceValue
      return;
    }

    // Existing AI turn check.
    // This will be reached if:
    // 1. It was AI's turn initially.
    // 2. It was Human's turn, they didn't trigger auto-move (e.g., not all pawns home, or not a 6).
    // 3. It was Human's turn, they didn't trigger auto-pass (e.g., rolled 6, or has pawns out).
    // If nextTurn() was called by auto-pass, and the new player is AI, _handleAITurn is called within nextTurn().
    // So, this check here primarily handles the case where it was AI's turn from the beginning of rollDice(),
    // or if a human player's turn continues (e.g. rolled 6, has pawns out, didn't auto-move).
    // If it's a human player's turn and they completed their action (auto-move or auto-pass), a 'return' was hit.
    if (getCurrentPlayer().isAI) { // Check the current player (could have changed if nextTurn was called)
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
    debugPrint("AttemptMove: Initiated for _selectedPawn: ${_selectedPawn?.id}-${_selectedPawn?.color} (State: ${_selectedPawn?.state.name}, Pos: ${_selectedPawn?.position})");

    if (_selectedPawn == null) {
      debugPrint("AttemptMove: No pawn selected to move. Aborting.");
      return;
    }

    Player currentPlayer = getCurrentPlayer();
    Pawn? originalSelectedPawn = _selectedPawn; // Keep a reference to the initially selected pawn

    // Retrieve the authoritative pawn instance from the current player's list
    Pawn? authoritativePawn;
    try {
      authoritativePawn = currentPlayer.pawns.firstWhere(
        (p) => p.id == originalSelectedPawn!.id && p.color == originalSelectedPawn.color
      );
      debugPrint("AttemptMove: Found authoritative pawn: ${authoritativePawn.id}-${authoritativePawn.color} (State: ${authoritativePawn.state.name}, Pos: ${authoritativePawn.position})");
    } catch (e) {
      debugPrint("AttemptMove: CRITICAL ERROR - Could not find authoritative pawn instance for initially selected pawn ${originalSelectedPawn?.id}-${originalSelectedPawn?.color}. Error: $e. Aborting move.");
      // _selectedPawn = null; // Consider clearing _selectedPawn as it's problematic
      // notifyListeners(); // If _selectedPawn is cleared
      return;
    }

    // This check should ideally always pass if current player is set correctly and pawn selection logic is sound.
    // And if the authoritativePawn was found from currentPlayer.pawns.
    if (authoritativePawn.color != currentPlayer.color) {
      debugPrint("AttemptMove: Authoritative pawn's color ${authoritativePawn.color} does not match current player's color ${currentPlayer.color}. This indicates a severe state inconsistency. Aborting.");
      return;
    }

    // Use the _stickyDiceValue for the move attempt
    int? moveDiceValue = _stickyDiceValue;
    debugPrint("AttemptMove: Using dice value: $moveDiceValue (from _stickyDiceValue)");

    if (moveDiceValue == null) {
      debugPrint("AttemptMove: Error - _stickyDiceValue is null. Player should roll dice first. Aborting.");
      return;
    }

    debugPrint("AttemptMove: Calling _game.movePawn with authoritative pawn ${authoritativePawn.id}-${authoritativePawn.color} and steps $moveDiceValue.");
    bool moveSuccessful = _game.movePawn(authoritativePawn, moveDiceValue);
    debugPrint("AttemptMove: _game.movePawn result for ${authoritativePawn.id}-${authoritativePawn.color}: $moveSuccessful. New state: ${authoritativePawn.state.name}, New pos: ${authoritativePawn.position}");

    if (moveSuccessful) {
      _stickyDiceValue = null; // Consume the dice value after a successful move
      _selectedPawn = null; // Clear selection after a successful move attempt.
      debugPrint("AttemptMove: Move successful. _stickyDiceValue cleared. _selectedPawn cleared.");

      if (moveDiceValue == 6) {
        debugPrint("AttemptMove: Rolled a 6, player ${currentPlayer.color} gets another turn. Roll dice again.");
        // Player gets another turn, they need to roll dice again.
        // _stickyDiceValue is now null, so they can't move again with the same 6.
        // No call to nextTurn() here.
      } else {
        debugPrint("AttemptMove: Rolled $moveDiceValue (not 6). Passing turn from ${currentPlayer.color}.");
        nextTurn(); // This will also clear _stickyDiceValue again, which is fine.
      }
    } else {
      // If the move was not successful, _stickyDiceValue remains unchanged.
      // This allows the player to select another pawn and try to move it with the same dice value.
      // _selectedPawn also remains unchanged, allowing UI to reflect the still-selected pawn.
      debugPrint("AttemptMove: Move for ${authoritativePawn.id}-${authoritativePawn.color} was NOT successful with dice $moveDiceValue. _stickyDiceValue ($moveDiceValue) is retained. _selectedPawn (${_selectedPawn?.id}) is retained.");
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
