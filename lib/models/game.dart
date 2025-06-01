import 'dart:math'; // For Random if generating gameId, though not strictly needed for this impl

import 'player.dart';
import 'pawn.dart';
import 'dice.dart';

class Game {
  String gameId;
  List<Player> players;
  int currentPlayerIndex;
  Dice dice;
  static const List<String> _defaultPlayerColors = ["Red", "Green", "Yellow", "Blue"];

  // Constructor for a new game
  Game({int numPlayersToCreate = 2, bool playWithAI = false, String? customGameId})
      : dice = Dice(),
        currentPlayerIndex = 0, // Start with the first player
        gameId = customGameId ?? 'game_${DateTime.now().millisecondsSinceEpoch}' {

    if (numPlayersToCreate < 1 || numPlayersToCreate > 4) {
      throw ArgumentError('Number of players must be between 1 and 4.');
    }
    if (playWithAI && numPlayersToCreate == 0) {
        throw ArgumentError('Cannot play with AI if there are no human players specified to determine total player count.');
    }
    // If playWithAI is true, and numPlayersToCreate is 1, we effectively have 2 players (1 human, 1 AI).
    // If playWithAI is true, and numPlayersToCreate > 1, one of the numPlayersToCreate will be AI.
    // The problem description: "the numHumanPlayers determines the count, and if playWithAI is true, the last player in the list of chosen colors becomes the AI."
    // This implies 'numPlayersToCreate' is the total number of active players (human + AI).
    // Let's rename numPlayersToCreate to totalPlayers for clarity based on this interpretation.

    int totalPlayers = numPlayersToCreate;
    if (playWithAI && totalPlayers == 1) {
      // If 1 player is selected and AI is on, it's a 1v1 game.
      // The setup screen logic already suggests this (1 player means vs AI).
      // So, if numPlayersToCreate from setup is 1 and playWithAI is true, we need 2 players.
      // However, the prompt says "numHumanPlayers determines the count".
      // If numPlayersToCreate was "number of human players", and it's 1, and playWithAI is true, then total players = 2.
      // Let's refine: numPlayersToCreate from setup *is* the total number of players in the game.
      // One of them will be AI if playWithAI is true.
       if (totalPlayers < 2 && playWithAI) {
         // This case implies 1 human vs AI, so we need to ensure totalPlayers is at least 2.
         // But if setup screen sends numPlayers = 1 and playWithAI = true, it means 1 Human player.
         // The Game model should then create 1 Human + 1 AI if playWithAI is true.
         // The prompt stated: "numHumanPlayers determines the count, and if playWithAI is true, the last player in the list of chosen colors becomes the AI."
         // This is slightly ambiguous. Let's stick to `numPlayersToCreate` being the *total* number of active player slots.
         // If `numPlayersToCreate` is 1 and `playWithAI` is true, it effectively means 1 Human vs 1 AI. So, 2 players.
         // The SetupScreen already handles the logic: if 1 player is selected, AI is true by default.
         // So, if SetupScreen sends numPlayers=1, playWithAI=true, this constructor receives that.
         // Game should create one human (Red) and one AI (Green).
         totalPlayers = 2; // Override totalPlayers for 1 Human vs AI.
       }
    }
     if (totalPlayers < 2) { // Minimum 2 players for a game (e.g. 1 human vs 1 AI, or 2 humans)
        throw ArgumentError('A game must have at least 2 active player slots (human or AI).');
    }


    players = [];
    List<String> colorsForThisGame = _defaultPlayerColors.sublist(0, totalPlayers);

    for (int i = 0; i < totalPlayers; i++) {
      String color = colorsForThisGame[i];
      String playerId = 'Player${i + 1}_$color';
      bool isPlayerAI = false;
      if (playWithAI && i == (totalPlayers - 1)) { // The last player is AI
        isPlayerAI = true;
      }
      players.add(Player(id: playerId, color: color, isAI: isPlayerAI));
    }
  }

  Player getCurrentPlayer() {
    return players[currentPlayerIndex];
  }

  void rollDice() {
    dice.roll();
    // Potentially add game logic here after dice roll,
    // like checking for valid moves, or delegate to another method.
  }

  void nextTurn() {
    currentPlayerIndex = (currentPlayerIndex + 1) % players.length;
  }

  // Example method to get a specific player's pawn (not in requirements but useful)
  Pawn? getPlayerPawn(String playerId, int pawnId) {
    try {
      Player player = players.firstWhere((p) => p.id == playerId);
      return player.pawns.firstWhere((pawn) => pawn.id == pawnId);
    } catch (e) {
      // Player or pawn not found
      return null;
    }
  }

  // Placeholder for game logic that would determine valid moves for a pawn
  // This would be a complex method in a real game
  List<int> getValidMoves(Pawn pawn, int diceValue) {
    // Basic logic:
    // - If pawn is home and dice is 6, can move to start position.
    // - If pawn is on board, can move diceValue steps forward.
    // - Handle board limits, opponent pawns, safe zones, finish line, etc.
    List<int> moves = [];
    if (pawn.state == PawnState.home) {
      if (diceValue == 6) {
        // Assuming start position is 0 for simplicity for now for each path
        // This needs to be color-specific in a real Ludo game.
        // For example, Red's start might be 0, Green's 13, Yellow's 26, Blue's 39.
        // This simplified version doesn't map to a global board position correctly without more info.
        moves.add(0); // Placeholder for start position
      }
    } else if (pawn.state == PawnState.onBoard) {
      // Simple move forward, does not handle board wrap-around or finish path yet
      moves.add(pawn.position + diceValue);
    }
    return moves;
  }

  // Define starting positions for each color
  static const Map<String, int> startPositions = {
    "Red": 0,
    "Green": 13,
    "Yellow": 26,
    "Blue": 39,
  };

  // Maximum position on the main board track
  static const int maxBoardPosition = 51; // 0-51 are 52 squares

  // Method to move a pawn based on dice steps
  bool movePawn(Pawn pawn, int steps) {
    if (pawn.color != getCurrentPlayer().color) {
      print("Attempted to move pawn of another player.");
      return false; // Cannot move other player's pawn
    }

    if (pawn.state == PawnState.home) {
      if (steps == 6) {
        int? startPos = startPositions[pawn.color];
        if (startPos == null) {
          print("Error: Start position not defined for color ${pawn.color}");
          return false;
        }
        pawn.position = startPos;
        pawn.state = PawnState.onBoard;
        // Potentially check if startPos is occupied by another pawn (capture logic here or later)
        print("Pawn ${pawn.id} of ${pawn.color} moved out of home to $startPos");
        return true;
      } else {
        print("Pawn ${pawn.id} of ${pawn.color} needs a 6 to move out of home.");
        return false; // Needs a 6 to move out of home
      }
    } else if (pawn.state == PawnState.onBoard) {
      // Basic movement on the board, wraps around.
      // Does not yet handle entering the home stretch or finishing.
      int newPosition = (pawn.position + steps);

      // TODO: Implement logic for home stretch and finishing
      // For now, if a pawn overshoots its home entry, it might just keep circling.
      // Or, for simplicity, let's say it cannot overshoot the max board position for now,
      // unless we implement the full path including home columns.
      // A true Ludo board path isn't a simple modulo 52 for all colors once they approach their home column.
      // Each color has a specific path. For now, we'll use a simplified modulo 52.

      pawn.position = newPosition % (maxBoardPosition + 1); // Simple circular path 0-51

      // If newPosition > maxBoardPosition, it means pawn is entering or in its home column.
      // This part needs more detailed logic per player color.
      // For example, if a Red pawn (starts at 0) is at position 50 and rolls 3,
      // it should go 50 -> 51 -> RedHome1 -> RedHome2.
      // The current (newPosition % 52) doesn't reflect this accurately.
      // This is a known simplification for this step.

      print("Pawn ${pawn.id} of ${pawn.color} moved from ${pawn.position-steps} to ${pawn.position}");
      // Potentially check for captures at newPosition
      return true;
    } else if (pawn.state == PawnState.finished) {
      print("Pawn ${pawn.id} of ${pawn.color} is already finished.");
      return false; // Cannot move a finished pawn
    }
    return false;
  }

  // Helper method to get a list of pawns a player can move with a given dice value
  List<Pawn> getMovablePawns(Player player, int diceValue) {
    List<Pawn> movable = [];
    if (player.id != getCurrentPlayer().id) {
      // Not this player's turn (should ideally be checked before calling)
      // Or, if called for hypothetical checks, ensure it's for the player passed in.
      // For AI, player will be getCurrentPlayer().
       if(player.id != getCurrentPlayer().id) return [];
    }

    for (Pawn pawn in player.pawns) {
      if (pawn.state == PawnState.home) {
        if (diceValue == 6) {
          movable.add(pawn);
        }
      } else if (pawn.state == PawnState.onBoard) {
        // Any pawn on board is considered movable for now.
        // More advanced logic would check if the move is blocked by own pawns,
        // or if it leads to a finish, etc.
        movable.add(pawn);
      }
      // Finished pawns are not movable
    }
    return movable;
  }


  @override
  String toString() {
    return 'Game(id: $gameId, players: ${players.length}, currentPlayer: ${getCurrentPlayer().id}, dice: ${dice.currentValue})';
  }
}
