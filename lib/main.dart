import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Import Provider

// Model imports (GameState will handle Game model directly)
import 'package:ludo/models/pawn.dart';   // Still needed for PawnState, and Pawn type in _buildPawnWidgets
import 'package:ludo/models/player.dart'; // For Player type in _buildPawnWidgets

// Provider import
import 'package:ludo/providers/game_provider.dart';

// Widget imports
import 'package:ludo/widgets/ludo_board_widget.dart';
import 'package:ludo/widgets/pawn_widget.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => GameState(), // Initialize GameState
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ludo Game',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueGrey),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Ludo Game Board'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  // Local game state (_game, _diceValue, initState, _rollDiceAndUpdate) is removed.
  // GameState provider will manage this.

  Color _mapPlayerColorToColor(String colorName) {
    switch (colorName.toLowerCase()) {
      case "red":
        return Colors.red.shade700;
      case "green":
        return Colors.green.shade700;
      case "yellow":
        return Colors.yellow.shade700;
      case "blue":
        return Colors.blue.shade700;
      default:
        return Colors.grey; // Default color
    }
  }

  List<Widget> _buildPawnWidgets(BuildContext context) {
    // Access GameState here. Listen: true is fine if this needs to rebuild on changes.
    // However, specific pawn movements might be better handled by Consumer widgets around individual pawns if performance becomes an issue.
    final gameState = Provider.of<GameState>(context);
    List<Widget> pawnWidgets = [];
    double boardSize = 300.0;
    double pawnSize = 24.0;

    Map<String, List<Offset>> playerHomeOffsets = {
      "Red": [Offset(pawnSize, pawnSize), Offset(pawnSize*2.5, pawnSize), Offset(pawnSize, pawnSize*2.5), Offset(pawnSize*2.5, pawnSize*2.5)],
      "Green": [Offset(boardSize - pawnSize*3.5, pawnSize), Offset(boardSize - pawnSize*2, pawnSize), Offset(boardSize - pawnSize*3.5, pawnSize*2.5), Offset(boardSize - pawnSize*2, pawnSize*2.5)],
      "Yellow": [Offset(boardSize - pawnSize*3.5, boardSize - pawnSize*3.5), Offset(boardSize - pawnSize*2, boardSize - pawnSize*3.5), Offset(boardSize - pawnSize*3.5, boardSize - pawnSize*2), Offset(boardSize - pawnSize*2, boardSize - pawnSize*2)],
      "Blue": [Offset(pawnSize, boardSize - pawnSize*3.5), Offset(pawnSize*2.5, boardSize - pawnSize*3.5), Offset(pawnSize, boardSize - pawnSize*2), Offset(pawnSize*2.5, boardSize - pawnSize*2)],
    };

    for (var player in gameState.players) { // Use players from GameState
      Color playerColor = _mapPlayerColorToColor(player.color);
      List<Offset> homeOffsets = playerHomeOffsets[player.color] ?? [];

      for (int i = 0; i < player.pawns.length; i++) {
        Pawn pawn = player.pawns[i];
        Widget pawnWidget = PawnWidget(
          pawnColor: playerColor,
          pawnId: pawn.id,
          size: pawnSize,
        );

        // Add a GestureDetector to each pawn for selection
        Widget interactivePawn = GestureDetector(
          onTap: () {
            // Use listen: false for actions
            Provider.of<GameState>(context, listen: false).selectPawn(pawn);
          },
          child: pawnWidget,
        );

        // Highlight selected pawn (optional visual feedback)
        if (gameState.selectedPawn != null && gameState.selectedPawn!.id == pawn.id && gameState.selectedPawn!.color == pawn.color) {
           interactivePawn = Container(
             decoration: BoxDecoration(
               shape: BoxShape.circle,
               border: Border.all(color: Colors.white, width: 3),
               boxShadow: [BoxShadow(color: playerColor.withOpacity(0.7), blurRadius: 10, spreadRadius: 2)],
             ),
             child: pawnWidget,
           );
        }


        if (pawn.state == PawnState.home && i < homeOffsets.length) {
          pawnWidgets.add(
            Positioned(
              top: homeOffsets[i].dy,
              left: homeOffsets[i].dx,
              child: interactivePawn,
            ),
          );
        } else if (pawn.state == PawnState.onBoard) {
          // Crude linear mapping for on-board pawns for visual feedback of movement
          // This is NOT a proper Ludo board path.
          // It just distributes pawns along 4 sides of a square.
          double x = 0, y = 0;
          // Using boardSize for path calculation, pawnSize for individual pawn rendering
          const double pathMargin = 30.0; // Margin from board edge to the path
          double effectiveBoardSide = boardSize - 2 * pathMargin; // Play area for path
          const int positionsPerSide = 13; // 52 total / 4 sides = 13
          double stepSize = effectiveBoardSide / (positionsPerSide -1); // Distance between pawn centers on a side

          int currentPosition = pawn.position; // 0-51

          // Determine which side and position on that side
          int side = currentPosition ~/ positionsPerSide; // 0: top, 1: right, 2: bottom, 3: left (for typical Ludo path starting Red)
          int posOnSide = currentPosition % positionsPerSide;

          // Player-specific offsets to make pawns of same player slightly offset if on same spot (rare with this crude mapping)
          // And to make different player pawns also not perfectly overlap if on same calculated spot.
          double pawnPlayerOffset = (gameState.players.indexOf(player) - 1.5) * pawnSize / 4;


          if (side == 0) { // Top row (e.g., Red's path part 1)
            x = pathMargin + posOnSide * stepSize;
            y = pathMargin + pawnPlayerOffset;
          } else if (side == 1) { // Right column (e.g., Green's path part 1)
            x = pathMargin + effectiveBoardSide - pawnPlayerOffset;
            y = pathMargin + posOnSide * stepSize;
          } else if (side == 2) { // Bottom row (e.g., Yellow's path part 1)
            x = pathMargin + effectiveBoardSide - posOnSide * stepSize;
            y = pathMargin + effectiveBoardSide - pawnPlayerOffset;
          } else { // Left column (e.g., Blue's path part 1, side == 3)
            x = pathMargin + pawnPlayerOffset;
            y = pathMargin + effectiveBoardSide - posOnSide * stepSize;
          }

          // Add small random jitter if multiple pawns land on the exact same calculated spot
          // This is more for visual debugging than proper game logic for stacking.
          // For real Ludo, you'd have specific rules for stacking or sending back.
          // x += Random().nextDouble() * pawnSize/4 - pawnSize/8;
          // y += Random().nextDouble() * pawnSize/4 - pawnSize/8;


          pawnWidgets.add(
            Positioned(
              top: y.clamp(0, boardSize - pawnSize),
              left: x.clamp(0, boardSize - pawnSize),
              child: interactivePawn,
            ),
          );
        }
      }
    }
    return pawnWidgets;
  }

  @override
  Widget build(BuildContext context) {
    double boardWidgetSize = 300.0;
    // Access GameState. For data that changes, listen: true (default)
    // For actions (like button presses), typically listen: false
    final gameState = Provider.of<GameState>(context);
    // For actions, you can also define it once:
    // final gameActions = Provider.of<GameState>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        actions: [ // Example: Reset button in AppBar
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              Provider.of<GameState>(context, listen: false).resetGame();
            },
          )
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              LudoBoardWidget(
                boardSize: boardWidgetSize,
                pawnsToDisplay: _buildPawnWidgets(context), // Pass context if needed by the method
              ),
              const SizedBox(height: 20),
              Text(
                'Dice: ${gameState.diceValue}', // Get diceValue from GameState
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 10),
              Text(
                'Current Player: ${gameState.getCurrentPlayer().color}', // Get current player from GameState
                style: Theme.of(context).textTheme.titleLarge,
              ),
               if (gameState.selectedPawn != null) // Display selected pawn info
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    'Selected: ${gameState.selectedPawn!.color} Pawn ${gameState.selectedPawn!.id}',
                    style: TextStyle(fontSize: 16, color: _mapPlayerColorToColor(gameState.selectedPawn!.color)),
                  ),
                ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Provider.of<GameState>(context, listen: false).rollDice();
                },
                child: const Text('Roll Dice'),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  Provider.of<GameState>(context, listen: false).nextTurn();
                },
                child: const Text('Next Turn'),
              ),
              // Button to attempt moving the selected pawn
              if (gameState.selectedPawn != null && gameState.diceValue > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 10.0),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _mapPlayerColorToColor(gameState.selectedPawn!.color).withOpacity(0.8),
                    ),
                    onPressed: () {
                      // Call the provider method to attempt the move
                      Provider.of<GameState>(context, listen: false).attemptMoveSelectedPawn();
                    },
                    child: Text(
                      'Move ${gameState.selectedPawn!.color} Pawn ${gameState.selectedPawn!.id} with ${gameState.diceValue}',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
