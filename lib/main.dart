import 'package:flutter/material.dart';
import 'package:ludo/screens/setup_screen.dart';
import 'package:provider/provider.dart'; // Import Provider

// Model imports (GameState will handle Game model directly)
import 'package:ludo/models/pawn.dart';   // Still needed for PawnState, and Pawn type in _buildPawnWidgets
import 'package:ludo/models/player.dart'; // For Player type in _buildPawnWidgets

// Provider import
import 'package:ludo/providers/game_provider.dart';

// Widget imports
import 'package:ludo/widgets/ludo_board_widget.dart';
import 'package:ludo/widgets/pawn_widget.dart';

// Core imports for LudoBoardCoordinates and PlayerColor enum
import 'package:ludo/core/constants.dart' as ludo_constants;
import 'package:ludo/core/ludo_board_coordinates.dart';
import 'dart:ui' as ui;

import 'models/game.dart';

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
      home: const SetupScreen(), // Changed home to SetupScreen
    );
  }
}

class MyHomePage extends StatefulWidget {
  // Added parameters to receive setup data
  final int numPlayers;
  final bool playWithAI;
  final String title; // Kept title for now, can be removed if not used

  const MyHomePage({
    super.key,
    required this.title,
    required this.numPlayers,
    required this.playWithAI,
  });

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  late LudoBoardCoordinates _boardCoordinates;
  // Store the board drawing size. This should ideally match what's passed to LudoBoardWidget.
  // For now, fixed. Could be dynamic based on MediaQuery.
  final Size _boardDrawingActualSize = Size(360, 360);

  @override
  void initState() {
    super.initState();

    _boardCoordinates = LudoBoardCoordinates(boardSize: ui.Size(_boardDrawingActualSize.width, _boardDrawingActualSize.height));

    debugPrint("MyHomePage initState: Number of Players: ${widget.numPlayers}, Play with AI: ${widget.playWithAI}");
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<GameState>(context, listen: false).resetGame(
          numPlayers: widget.numPlayers,
          playWithAI: widget.playWithAI
      );
    });
  }

  Color _mapPlayerColorStringToMaterialColor(String colorName) {
    ludo_constants.PlayerColor? enumColor = ludo_constants.playerColorFromString(colorName);
    if (enumColor != null) {
      return ludo_constants.playerColorToMaterialColor[enumColor] ?? Colors.grey;
    }
    return Colors.grey;
  }

  List<Widget> _buildPawnWidgets(BuildContext context) {
    final gameState = Provider.of<GameState>(context);
    List<Widget> pawnWidgets = [];
    // boardSize is now _boardDrawingActualSize.width (or height)
    double pawnSize = _boardCoordinates.cellSize * 0.8; // Make pawn size relative to cell size

    for (var player in gameState.players) {
      Color materialPlayerColor = _mapPlayerColorStringToMaterialColor(player.color);
      ludo_constants.PlayerColor playerEnumColor = ludo_constants.playerColorFromString(player.color) ?? ludo_constants.PlayerColor.red; // Fallback

      for (int i = 0; i < player.pawns.length; i++) {
        Pawn pawn = player.pawns[i];
        Widget pawnWidget = PawnWidget(
          pawnColor: materialPlayerColor,
          pawnId: pawn.id,
          size: pawnSize,
        );

        Widget interactivePawn = GestureDetector(
          onTap: () {
            if (player.isAI) return; // Prevent selecting AI pawns by click
            Provider.of<GameState>(context, listen: false).selectPawn(pawn);
          },
          child: pawnWidget,
        );

        if (gameState.selectedPawn != null && gameState.selectedPawn!.id == pawn.id && gameState.selectedPawn!.color == pawn.color) {
           interactivePawn = Container(
             alignment: Alignment.center,
             decoration: BoxDecoration(
               shape: BoxShape.circle,
               border: Border.all(color: Colors.yellowAccent, width: 1), // Brighter selection
               boxShadow: [BoxShadow(color: materialPlayerColor.withOpacity(1), blurRadius: 6, spreadRadius: 2)],
             ),
             child: pawnWidget,
           );
        }

        Offset position;
        if (pawn.state == PawnState.home) {
          // Use LudoBoardCoordinates for home spots. i is pawn's index (0-3)
          if(widget.numPlayers == 1){
            position = Offset(_boardCoordinates.homeBaseSpots[playerEnumColor]![i].dx + 12, _boardCoordinates.homeBaseSpots[playerEnumColor]![i].dy + 12);
          }else{
            position = _boardCoordinates.homeBaseSpots[playerEnumColor]![i];
          }
        } else if (pawn.state == PawnState.onBoard) {
          // Use LudoBoardCoordinates for main track spots
          // The pawn.position from game model (0-51) is the index for mainTrackSpots
          if (pawn.position >= 0 && pawn.position < _boardCoordinates.mainTrackSpots.length) {
            position = _boardCoordinates.mainTrackSpots[pawn.position];
          } else {
            // This case should ideally not happen if pawn.position is always valid for onBoard state
            debugPrint("Error: Pawn ${pawn.id} has invalid onBoard position: ${pawn.position}");
            position = Offset(-1000, -1000); // Hide if invalid
          }
        } else { // PawnState.finished
          // Use LudoBoardCoordinates for home column spots or center
          // For simplicity, let's place finished pawns near their home column's end or center.
          // This needs mapping pawn.position (if it indicates progress in home column) to homeColumnSpots.
          // If pawn.position for finished pawns is, e.g. 99, we need another way.
          // Assume pawn.position for finished state means progress into home column (e.g., 52-57 for Red)
          int homeColumnProgress = (pawn.position - (Game.maxBoardPosition + 1)); // e.g. 52 becomes 0, 57 becomes 5
          if (homeColumnProgress >=0 && homeColumnProgress < _boardCoordinates.homeColumnSpots[playerEnumColor]!.length) {
             position = _boardCoordinates.homeColumnSpots[playerEnumColor]![homeColumnProgress];
          } else {
             // If truly finished (at the absolute center)
             position = _boardCoordinates.centerFinishSpot;
          }
        }

        pawnWidgets.add(
          Positioned(
            // LudoBoardCoordinates provides center points, adjust for top-left if PawnWidget origin is top-left
            top: position.dy - pawnSize / 2,
            left: position.dx - pawnSize / 2,
              child: interactivePawn,
            ),
          );
        }
      }
    return pawnWidgets;
  }

  @override
  Widget build(BuildContext context) {
    // boardWidgetSize is now _boardDrawingActualSize
    // final gameState object is already obtained in _buildPawnWidgets if needed there,
    // or can be obtained here again if other parts of build need it.
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
              // When resetting from UI, use the currently configured numPlayers and playWithAI from GameState
              // or re-navigate to SetupScreen if you want to allow changing these.
              // For now, let's assume it resets with the *initial* setup parameters.
              // This might require storing initialNumPlayers and initialPlayWithAI in _MyHomePageState if they can't be derived.
              // Or, GameState's resetGame could be changed to have a no-arg version that reuses its stored _numPlayers, _playWithAI.
              // For simplicity, let's make the AppBar reset use the currently configured game settings.
              final gameState = Provider.of<GameState>(context, listen: false);
              gameState.resetGame(numPlayers: gameState.numPlayersConfig, playWithAI: gameState.playWithAIConfig);
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
                boardDrawingSize: _boardDrawingActualSize, // Pass the defined size
                pawnsToDisplay: _buildPawnWidgets(context),
              ),
              const SizedBox(height: 20),
              Consumer<GameState>( // Use Consumer for parts of UI that depend on GameState
                builder: (context, gameState, child) {
                  return Text(
                    'Dice: ${gameState.diceValue}',
                    style: Theme.of(context).textTheme.headlineMedium,
                  );
                }
              ),
              const SizedBox(height: 10),
              Consumer<GameState>(
                builder: (context, gameState, child) {
                  if (gameState.players.isEmpty) return const Text("Loading players..."); // Handle empty players list
                  return Text(
                    'Current Player: ${gameState.getCurrentPlayer().color} ${gameState.getCurrentPlayer().isAI ? "(AI)" : ""}',
                    style: Theme.of(context).textTheme.titleLarge,
                  );
                }
              ),
               Consumer<GameState>( // Consumer for selected pawn info
                 builder: (context, gameState, child) {
                   if (gameState.selectedPawn == null) return const SizedBox.shrink();
                   return Padding(
                     padding: const EdgeInsets.all(8.0),
                     child: Text(
                       'Selected: ${gameState.selectedPawn!.color} Pawn ${gameState.selectedPawn!.id}',
                       style: TextStyle(fontSize: 16, color: _mapPlayerColorStringToMaterialColor(gameState.selectedPawn!.color)),
                     ),
                   );
                 }
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
                      backgroundColor: gameState.selectedPawn != null ? _mapPlayerColorStringToMaterialColor(gameState.selectedPawn!.color).withOpacity(0.8) : Colors.grey,
                    ),
                    onPressed: (gameState.selectedPawn != null && !gameState.getCurrentPlayer().isAI) // Disable for AI or if no pawn selected
                      ? () {
                          Provider.of<GameState>(context, listen: false).attemptMoveSelectedPawn();
                        }
                      : null, // Disable button
                    child: Text(
                      gameState.selectedPawn != null
                        ? 'Move ${gameState.selectedPawn!.color} Pawn ${gameState.selectedPawn!.id} with ${gameState.diceValue}'
                        : 'Select a Pawn to Move',
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
