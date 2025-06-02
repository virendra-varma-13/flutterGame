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

  List<Pawn> highlightedPawnsForSelection = [];
  bool isAwaitingHumanSelection = false;

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
    debugPrint("Human player ${getCurrentPlayer().color} triggered rollDice().");
    Player currentPlayer = getCurrentPlayer();

    if (currentPlayer.isAI) {
        debugPrint("rollDice() called, but it's AI's turn (${currentPlayer.color}). Ignoring.");
        return;
    }
    if (isAwaitingHumanSelection) {
        debugPrint("rollDice() called for ${currentPlayer.color}, but awaiting pawn selection. Ignoring.");
        return;
    }
    // Check if player is rolling again after a 6.
    // If _stickyDiceValue is null, it means the previous 6 was consumed by a move, or this is the first roll.
    // If _stickyDiceValue is 6, it means they rolled 6, made no move (no valid moves), and are rolling again.
    if (_stickyDiceValue != null && _stickyDiceValue == 6) {
        debugPrint("Player ${currentPlayer.color} had a 6 (no move made or previous move was a 6), rolling again.");
        // Proceed to roll is fine. _stickyDiceValue will be overwritten.
    } else if (_stickyDiceValue != null && _stickyDiceValue != 6) {
        // This state should ideally not be reached if UI disables roll button until a non-6 roll is resolved.
        debugPrint("Warning: rollDice() called by ${currentPlayer.color} but a previous non-6 stickyDiceValue ($_stickyDiceValue) exists. Overwriting.");
    }

    // Perform the dice roll
    _game.dice.roll();
    _stickyDiceValue = _game.dice.currentValue;

    // Reset selection states for the new roll
    isAwaitingHumanSelection = false;
    highlightedPawnsForSelection = [];
    _selectedPawn = null; // Clear previous selection if any

    notifyListeners(); // UI shows the new dice roll
    debugPrint("Human player ${currentPlayer.color} rolled $_stickyDiceValue.");

    // Ensure stickyDiceValue is not null after roll (shouldn't be)
    if (_stickyDiceValue == null) {
        debugPrint("CRITICAL: _stickyDiceValue is null immediately after roll for ${currentPlayer.color}. Aborting further actions.");
        // This might indicate an issue with _game.dice.roll() or its assignment.
        return;
    }

    // Conditional Automation Logic
    bool allPawnsAtHome = currentPlayer.pawns.every((p) => p.state == PawnState.home);

    if (allPawnsAtHome) {
        if (_stickyDiceValue == 6) {
            debugPrint("Auto-move: Rolled 6, all pawns home for ${currentPlayer.color}.");
            List<Pawn> homePawns = currentPlayer.pawns.where((p) => p.state == PawnState.home).toList();
            if (homePawns.isNotEmpty) { // Should be true if allPawnsAtHome
                 Pawn pawnToMove = homePawns.first;
                _selectedPawn = pawnToMove;
                attemptMoveSelectedPawn(); // Handles 'another turn' internally by not calling nextTurn()
            } else {
                debugPrint("Error: All pawns reported home for ${currentPlayer.color}, but no home pawns found in list.");
                // Fall through to other logic, though this state is inconsistent.
            }
            return; // Action complete or another turn is set up by attemptMoveSelectedPawn
        } else { // Not a 6, all pawns home
            debugPrint("Auto-pass: Rolled $_stickyDiceValue (not 6), all pawns home for ${currentPlayer.color}.");
            nextTurn();
            return;
        }
    }

    // Some Pawns Are Out (Not All Home)
    List<Pawn> movablePawns = _game.getMovablePawns(currentPlayer, _stickyDiceValue!);
    debugPrint("Player ${currentPlayer.color} (not all pawns home) has ${movablePawns.length} movable pawns with dice $_stickyDiceValue.");

    if (movablePawns.isEmpty) {
        if (_stickyDiceValue == 6) {
            debugPrint("No moves available for ${currentPlayer.color} on a 6. Player gets another roll.");
            _stickyDiceValue = null; // Consume the 6 for this specific action attempt
            // Player remains current. UI should allow another roll.
            notifyListeners(); // Reflect that the dice action is done (sticky is null)
            return;
        } else { // Not a 6, no moves
            debugPrint("No moves available for ${currentPlayer.color} on $_stickyDiceValue. Passing turn.");
            nextTurn();
            return;
        }
    }

    if (movablePawns.length == 1) {
        debugPrint("Auto-move: Single move available for ${currentPlayer.color} with $_stickyDiceValue.");
        _selectedPawn = movablePawns.first;
        attemptMoveSelectedPawn(); // Handles 'another turn' or passes turn
        return;
    }

    // movablePawns.length > 1
    debugPrint("Multiple moves available for ${currentPlayer.color} with $_stickyDiceValue. Awaiting selection.");
    highlightedPawnsForSelection = List.from(movablePawns);
    isAwaitingHumanSelection = true;
    notifyListeners(); // UI highlights pawns
    // _stickyDiceValue is kept for when the player selects a pawn.
  }

  void nextTurn() {
    _stickyDiceValue = null;
    _game.nextTurn();
    _selectedPawn = null;

    highlightedPawnsForSelection = [];
    isAwaitingHumanSelection = false;

    notifyListeners();

    Player newCurrentPlayer = getCurrentPlayer();
    debugPrint("NextTurn: Changed to player ${newCurrentPlayer.color}, AI: ${newCurrentPlayer.isAI}");
    if (newCurrentPlayer.isAI) {
      _handleAITurn();
    }
    // If human, UI should enable their roll dice button. GameState waits for UI interaction.
  }

  void selectPawn(Pawn pawn) {
    if (isAwaitingHumanSelection) {
        // Check if the provided pawn instance is among the highlighted ones by ID and color
        bool isValidSelection = highlightedPawnsForSelection.any((p) => p.id == pawn.id && p.color == pawn.color);

        if (isValidSelection) {
            // To ensure we use the authoritative pawn object from the game model,
            // especially if 'pawn' comes directly from UI and might be a different instance.
            Player currentPlayer = getCurrentPlayer();
            Pawn? authoritativePawnFromList;
            try {
                authoritativePawnFromList = currentPlayer.pawns.firstWhere(
                    (p) => p.id == pawn.id && p.color == pawn.color
                );
            } catch (e) {
                debugPrint("SelectPawn: Error finding authoritative pawn for selected pawn ${pawn.id}-${pawn.color}. Error: $e");
                // Potentially reset selection state or provide feedback
                isAwaitingHumanSelection = false;
                highlightedPawnsForSelection = [];
                notifyListeners();
                return;
            }
            _selectedPawn = authoritativePawnFromList; // Use the instance from the player's list

            debugPrint("SelectPawn: Human selected highlighted pawn: ${_selectedPawn!.id}-${_selectedPawn!.color}. Attempting move.");
            isAwaitingHumanSelection = false;
            highlightedPawnsForSelection = [];
            // _stickyDiceValue should still be set from _initiateHumanTurnActions
            attemptMoveSelectedPawn();
            // If attemptMoveSelectedPawn results in another turn (e.g. rolled 6),
            // the game flow should re-trigger _initiateHumanTurnActions.
        } else {
            debugPrint("SelectPawn: Invalid selection. Pawn ${pawn.id}-${pawn.color} not in highlighted list: ${highlightedPawnsForSelection.map((p) => '${p.id}-${p.color}').join(', ')}");
            // Do not clear isAwaitingHumanSelection or highlightedPawns here, user might try again.
            // Optionally provide feedback to UI if needed.
        }
    } else {
        // This path handles pawn selection when not in 'isAwaitingHumanSelection' mode.
        // e.g., AI might use this, or future features.
        // For current human flow, selection should primarily occur via the above block.
        debugPrint("SelectPawn: Called when not awaiting human selection. Current player: ${getCurrentPlayer().color}, selected: ${pawn.id}-${pawn.color}");
        if (pawn.color == getCurrentPlayer().color) {
            _selectedPawn = pawn; // Allow selection if it's their pawn
            notifyListeners();
            debugPrint("SelectPawn (non-awaited): Selected pawn ${pawn.id}-${pawn.color}");
        } else {
            debugPrint("SelectPawn (non-awaited): Cannot select pawn ${pawn.id}-${pawn.color}. Not current player's ${getCurrentPlayer().color} pawn.");
        }
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
    highlightedPawnsForSelection = []; // Clear highlights
    isAwaitingHumanSelection = false; // Reset selection mode
    debugPrint("Game reset in GameState: Players: $_numPlayers, AI: $_playWithAI. Actual players in game: ${_game.players.length}");
    if (_playWithAI && _game.players.isNotEmpty && _game.players.last.isAI) {
      debugPrint("AI Player confirmed: ${_game.players.last.color}");
    }
    notifyListeners(); // Initial notification for game setup

    // Determine and initiate first player's turn
    Player firstPlayer = getCurrentPlayer();
    if (firstPlayer.isAI) {
        debugPrint("ResetGame: First player is AI (${firstPlayer.color}). Handling AI turn.");
        _handleAITurn();
    } else {
        debugPrint("ResetGame: First player is Human (${firstPlayer.color}). UI should enable roll dice.");
        // No direct action here, UI will enable rollDice for the human player.
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
