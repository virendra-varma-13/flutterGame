import 'package:flutter_test/flutter_test.dart';
import 'package:ludo/models/game.dart';
import 'package:ludo/models/player.dart';
import 'package:ludo/models/pawn.dart';
// Dice is implicitly tested via Game, but can be imported if direct manipulation is needed beyond game.dice
// import 'package:ludo/models/dice.dart';

void main() {
  group('Game Logic', () {
    late Game game; // Standard game for most tests
    late Player testPlayer; // Usually the first player from the standard game, e.g., Red

    // Default setup for most tests: 2 human players
    setUp(() {
      // Game constructor now uses numPlayersToCreate and playWithAI
      game = Game(numPlayersToCreate: 2, playWithAI: false);
      game.currentPlayerIndex = 0;
      testPlayer = game.getCurrentPlayer();
      expect(testPlayer.color, "Red"); // Assuming Red is the first color for 2 players
      expect(testPlayer.isAI, isFalse);
    });

    test('Game initializes with correct number of players and pawns (default human players)', () {
      expect(game.players.length, 2);
      for (var player in game.players) {
        expect(player.isAI, isFalse); // Explicitly check for this test setup
        expect(player.pawns.length, 4);
        for (var pawn in player.pawns) {
          expect(pawn.state, PawnState.home);
          expect(pawn.position, -1);
          expect(pawn.color, player.color);
        }
      }
      expect(game.dice.currentValue, isNotNull);
    });

    test('Game initializes with an AI player correctly (1 Human vs 1 AI)', () {
      // Specific setup for this test
      Game aiGame = Game(numPlayersToCreate: 1, playWithAI: true);
      // Game logic: if numPlayersToCreate is 1 and playWithAI is true, totalPlayers becomes 2.
      expect(aiGame.players.length, 2, reason: "Should create 2 players for 1 Human vs AI mode");

      expect(aiGame.players[0].isAI, isFalse, reason: "First player should be human");
      expect(aiGame.players[0].color, "Red"); // Assuming Red is the first color

      expect(aiGame.players[1].isAI, isTrue, reason: "Second player should be AI");
      expect(aiGame.players[1].color, "Green"); // Assuming Green is the second color
    });

    test('Game initializes with an AI player correctly (3 Humans, 1 AI)', () {
      Game aiGame = Game(numPlayersToCreate: 4, playWithAI: true);
      expect(aiGame.players.length, 4);
      expect(aiGame.players[0].isAI, isFalse);
      expect(aiGame.players[1].isAI, isFalse);
      expect(aiGame.players[2].isAI, isFalse);
      expect(aiGame.players[3].isAI, isTrue); // Last player should be AI
      expect(aiGame.players[3].color, "Blue");
    });


    test('Pawn can leave home on a 6', () {
      Pawn pawn = testPlayer.pawns[0];
      expect(pawn.state, PawnState.home);

      game.dice.currentValue = 6; // Manually set dice value for testing

      bool moveResult = game.movePawn(pawn, game.dice.currentValue);

      expect(moveResult, isTrue);
      expect(pawn.state, PawnState.onBoard);
      expect(pawn.position, Game.startPositions[testPlayer.color]);
    });

    test('Pawn cannot leave home on non-6', () {
      Pawn pawn = testPlayer.pawns[0];
      expect(pawn.state, PawnState.home);
      int initialPosition = pawn.position;

      game.dice.currentValue = 3; // Manually set dice value
      bool moveResult = game.movePawn(pawn, game.dice.currentValue);

      expect(moveResult, isFalse);
      expect(pawn.state, PawnState.home);
      expect(pawn.position, initialPosition); // Position should not change
    });

    test('Pawn moves on board correctly (simple path)', () {
      Pawn pawn = testPlayer.pawns[0];
      // Manually place pawn on board for this test
      pawn.state = PawnState.onBoard;
      pawn.position = Game.startPositions[testPlayer.color]!; // e.g., 0 for Red

      int steps = 4;
      game.dice.currentValue = steps;
      bool moveResult = game.movePawn(pawn, game.dice.currentValue);

      expect(moveResult, isTrue);
      expect(pawn.state, PawnState.onBoard); // Still on board
      // Basic modulo arithmetic for simplified circular path
      int expectedPosition = (Game.startPositions[testPlayer.color]! + steps) % (Game.maxBoardPosition + 1);
      expect(pawn.position, expectedPosition);
    });

    test('Pawn movement wraps around the board (simple path)', () {
      Pawn pawn = testPlayer.pawns[0];
      pawn.state = PawnState.onBoard;
      pawn.position = Game.maxBoardPosition - 2; // e.g., position 49 if max is 51

      int steps = 5; // Should wrap around from 49 -> 50 -> 51 -> 0 -> 1 -> 2
      game.dice.currentValue = steps;
      bool moveResult = game.movePawn(pawn, game.dice.currentValue);

      expect(moveResult, isTrue);
      int expectedPosition = (pawn.position - steps + steps) % (Game.maxBoardPosition + 1); // Original position was already updated
      // simpler: ( (maxBoardPosition - 2) + 5 ) % 52 = (51-2+5)%52 = 54 % 52 = 2
      expect(pawn.position, (Game.maxBoardPosition - 2 + steps) % (Game.maxBoardPosition + 1) );
    });


    test('nextTurn() cycles through players correctly', () {
      int numPlayers = game.players.length;
      int initialIndex = game.currentPlayerIndex;
      expect(initialIndex, 0);

      game.nextTurn();
      expect(game.currentPlayerIndex, (initialIndex + 1) % numPlayers);
      expect(game.getCurrentPlayer().color, "Green");

      game.nextTurn(); // Should cycle back to the first player (Red)
      expect(game.currentPlayerIndex, (initialIndex + 2) % numPlayers);
      expect(game.getCurrentPlayer().color, "Red");
    });

    test('Cannot move pawn of another player', () {
      game.currentPlayerIndex = 0; // Red's turn
      Player greenPlayer = game.players[1];
      Pawn greenPawn = greenPlayer.pawns[0];
      expect(greenPawn.state, PawnState.home);

      game.dice.currentValue = 6;
      bool moveResult = game.movePawn(greenPawn, game.dice.currentValue);

      expect(moveResult, isFalse, reason: "Should not be able to move Green's pawn on Red's turn");
      expect(greenPawn.state, PawnState.home); // State should not change
    });

    test('Finished pawn cannot be moved', () {
      Pawn pawn = testPlayer.pawns[0];
      pawn.state = PawnState.finished;
      pawn.position = 99; // Arbitrary finished position
      int initialPosition = pawn.position;

      game.dice.currentValue = 3;
      bool moveResult = game.movePawn(pawn, game.dice.currentValue);

      expect(moveResult, isFalse);
      expect(pawn.state, PawnState.finished);
      expect(pawn.position, initialPosition);
    });

  });

  group('GameState Auto Turn Pass Logic', () {
    late GameState gameState;
    late Player player1; // Typically Red, Human
    late Player player2; // Typically Green, Human

    // Helper to set up a standard 2-player human game
    void setupStandardHumanGame() {
      gameState = GameState(); // Calls resetGame with 2 players, no AI by default

      // Ensure Player 1 (Red) is the current player
      // The GameState.resetGame by default sets up players: Red, Green, Yellow, Blue
      // For a 2-player game, it will be Red, Green.
      // We need to ensure the game is set to the first player's turn.
      // resetGame should handle setting the initial player, but let's be sure.
      gameState.game.currentPlayerIndex = 0;

      player1 = gameState.players[0];
      player2 = gameState.players[1];

      // Verify initial setup assumptions
      expect(player1.color, "Red", reason: "Player 1 should be Red");
      expect(player1.isAI, isFalse, reason: "Player 1 should be Human in this setup");
      expect(player2.color, "Green", reason: "Player 2 should be Green");
      expect(player2.isAI, isFalse, reason: "Player 2 should be Human in this setup");
      expect(gameState.getCurrentPlayer(), player1, reason: "Current player should be Player 1 (Red) initially");

      // Ensure all pawns for player1 are at home
      for (var pawn in player1.pawns) {
        expect(pawn.state, PawnState.home, reason: "All Player 1 pawns should be home at start.");
      }
    }

    setUp(() {
      setupStandardHumanGame();
    });

    test('Human player, no pawns out, rolls < 6: turn passes', () {
      // Pre-conditions verified by setupStandardHumanGame and specific checks
      expect(player1.isAI, isFalse, reason: "Test requires Player 1 to be human.");
      expect(player1.getOnBoardPawns().isEmpty, isTrue, reason: "Player 1 must have no pawns on board.");

      // Force dice roll to a value less than 6
      gameState.game.dice.currentValue = 3;

      Player initialPlayer = gameState.getCurrentPlayer();
      expect(initialPlayer, player1, reason: "Player 1 should be the current player before rolling dice.");

      gameState.rollDice(); // Action: Roll the dice

      // Expectation: Current player should switch to Player 2
      expect(gameState.getCurrentPlayer(), player2, reason: "Turn should automatically pass to Player 2.");
    });

    test('Human player, no pawns out, rolls 6: turn does NOT pass automatically', () {
      expect(player1.isAI, isFalse);
      expect(player1.getOnBoardPawns().isEmpty, isTrue);

      gameState.game.dice.currentValue = 6; // Force dice roll = 6
      Player initialPlayer = gameState.getCurrentPlayer();
      expect(initialPlayer, player1);

      gameState.rollDice(); // Action: Roll the dice

      // Expectation: Current player should remain Player 1
      expect(gameState.getCurrentPlayer(), player1, reason: "Turn should not pass automatically when a 6 is rolled.");
    });

    test('Human player, one pawn out, rolls < 6: turn does NOT pass automatically', () {
      expect(player1.isAI, isFalse);

      // Setup: Manually put one pawn on board for Player 1
      // Ensure pawn is valid and belongs to player1
      expect(player1.pawns.isNotEmpty, isTrue, reason: "Player 1 should have pawns.");
      Pawn pawnToMove = player1.pawns[0];
      pawnToMove.state = PawnState.onBoard;
      pawnToMove.position = Game.startPositions[player1.color] ?? 0; // Place at start position
      expect(player1.getOnBoardPawns().isNotEmpty, isTrue, reason: "Player 1 should have one pawn on board after setup.");
      expect(player1.getOnBoardPawns().length, 1, reason: "Only one pawn should be on board.");


      gameState.game.dice.currentValue = 3; // Force dice roll < 6
      Player initialPlayer = gameState.getCurrentPlayer();
      expect(initialPlayer, player1);

      gameState.rollDice(); // Action: Roll the dice

      // Expectation: Current player should remain Player 1
      expect(gameState.getCurrentPlayer(), player1, reason: "Turn should not pass, player has a pawn on board and rolled < 6.");
    });

    // Optional Test Case 4: AI player, no pawns out, rolls < 6
    // As reasoned before, the specific logic `!currentPlayer.isAI && ...` means this exact path isn't for AI.
    // AI's turn passing would be handled by its own `_handleAITurn` logic after it rolls.
    // A test for AI turn passing would look different:
    // 1. Set up AI player's turn.
    // 2. AI rolls (e.g., < 6).
    // 3. AI has no movable pawns (e.g., all home, roll != 6).
    // 4. Verify _handleAITurn calls nextTurn().
    // This is out of scope for testing the *newly added* human-specific auto-pass logic.
  });
}
