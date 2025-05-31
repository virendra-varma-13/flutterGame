import 'dart:math'; // For Random if generating gameId, though not strictly needed for this impl

import 'package:flutter/cupertino.dart';

import 'player.dart';
import 'pawn.dart';
import 'dice.dart';

class Game {
  String gameId;
  List<Player> players = [];
  int currentPlayerIndex;
  Dice dice;

  // Constructor for a new game
  Game({required List<String> playerColors, String? customGameId})
      : dice = Dice(),
        currentPlayerIndex = 0, // Start with the first player
        gameId = customGameId ?? 'game_${DateTime.now().millisecondsSinceEpoch}' {
    if (playerColors.isEmpty || playerColors.length < 2) {
      throw ArgumentError('A game must have at least 2 players.');
    }
    if (playerColors.length > 4) {
      // Or handle more gracefully, e.g. Ludo King has up to 6. For now, limit to 4.
      throw ArgumentError('This Ludo implementation supports a maximum of 4 players.');
    }

    players = [];
    for (int i = 0; i < playerColors.length; i++) {
      String color = playerColors[i];
      // Simple player ID generation, could be more robust (e.g., UUID)
      String playerId = 'Player${i + 1}_$color';
      players.add(Player(id: playerId, color: color));
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
      debugPrint("Attempted to move pawn of another player.");
      return false; // Cannot move other player's pawn
    }

    if (pawn.state == PawnState.home) {
      if (steps == 6) {
        int? startPos = startPositions[pawn.color];
        if (startPos == null) {
          debugPrint("Error: Start position not defined for color ${pawn.color}");
          return false;
        }
        pawn.position = startPos;
        pawn.state = PawnState.onBoard;
        // Potentially check if startPos is occupied by another pawn (capture logic here or later)
        debugPrint("Pawn ${pawn.id} of ${pawn.color} moved out of home to $startPos");
        return true;
      } else {
        debugPrint("Pawn ${pawn.id} of ${pawn.color} needs a 6 to move out of home.");
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

      debugPrint("Pawn ${pawn.id} of ${pawn.color} moved from ${pawn.position-steps} to ${pawn.position}");
      // Potentially check for captures at newPosition
      return true;
    } else if (pawn.state == PawnState.finished) {
      debugPrint("Pawn ${pawn.id} of ${pawn.color} is already finished.");
      return false; // Cannot move a finished pawn
    }
    return false;
  }


  @override
  String toString() {
    return 'Game(id: $gameId, players: ${players.length}, currentPlayer: ${getCurrentPlayer().id}, dice: ${dice.currentValue})';
  }
}
