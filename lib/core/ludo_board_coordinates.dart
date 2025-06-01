import 'dart:ui'; // For Offset and Size
import 'package:ludo/core/constants.dart'; // For PlayerColor

class LudoBoardCoordinates {
  final Size boardSize;
  final double cellSize;

  // Main track spots (52 total)
  late final List<Offset> mainTrackSpots;

  // Home base spots (4 per player)
  late final Map<PlayerColor, List<Offset>> homeBaseSpots;

  // Starting squares on the main track (1 per player)
  late final Map<PlayerColor, Offset> startingTrackSpots;

  // Home column spots (6 per player, leading to center)
  late final Map<PlayerColor, List<Offset>> homeColumnSpots;

  // Center finish spot (1 total)
  late final Offset centerFinishSpot;

  LudoBoardCoordinates({required this.boardSize})
      : cellSize = boardSize.width / 15.0 { // Assuming a 15x15 grid
    _calculateAllCoordinates();
  }

  void _calculateAllCoordinates() {
    _calculateHomeBaseSpots();
    _calculateMainTrackAndStartingSpots();
    _calculateHomeColumnSpots();
    _calculateCenterFinishSpot();
  }

  void _calculateHomeBaseSpots() {
    homeBaseSpots = {};
    // Red Home Base (Top-Left Quadrant)
    // Cells are typically (1.5, 1.5), (1.5, 3.5), (3.5, 1.5), (3.5, 3.5) in a 6x6 base grid
    homeBaseSpots[PlayerColor.red] = [
      Offset(1.5 * cellSize, 1.5 * cellSize), Offset(1.5 * cellSize, 3.5 * cellSize),
      Offset(3.5 * cellSize, 1.5 * cellSize), Offset(3.5 * cellSize, 3.5 * cellSize),
    ];
    // Green Home Base (Top-Right Quadrant)
    homeBaseSpots[PlayerColor.green] = [
      Offset(10.5 * cellSize, 1.5 * cellSize), Offset(10.5 * cellSize, 3.5 * cellSize),
      Offset(12.5 * cellSize, 1.5 * cellSize), Offset(12.5 * cellSize, 3.5 * cellSize),
    ];
    // Yellow Home Base (Bottom-Right Quadrant)
    homeBaseSpots[PlayerColor.yellow] = [
      Offset(10.5 * cellSize, 10.5 * cellSize), Offset(10.5 * cellSize, 12.5 * cellSize),
      Offset(12.5 * cellSize, 10.5 * cellSize), Offset(12.5 * cellSize, 12.5 * cellSize),
    ];
    // Blue Home Base (Bottom-Left Quadrant)
    homeBaseSpots[PlayerColor.blue] = [
      Offset(1.5 * cellSize, 10.5 * cellSize), Offset(1.5 * cellSize, 12.5 * cellSize),
      Offset(3.5 * cellSize, 10.5 * cellSize), Offset(3.5 * cellSize, 12.5 * cellSize),
    ];
  }

  void _calculateMainTrackAndStartingSpots() {
    mainTrackSpots = List.filled(52, Offset.zero);
    startingTrackSpots = {};

    // Path for Red (starts at board index 0)
    // Column 6, Rows 0 to 4 (5 spots)
    for (int i = 0; i < 5; i++) { mainTrackSpots[i] = Offset((6.5 + i) * cellSize, 1.5 * cellSize); } // Corrected: Red path moves right from (6,1) up to (1,1) then turns
    // Path for Red (index 0 is at (1,6) in typical grid representation (0-indexed) or (2,7) in 1-indexed cell notation)
    // Let's use a common Ludo diagram where Red starts at the square just outside its home arm.
    // The board has 3 rows of 6 squares on each arm extension.
    // Grid: (0,0) top-left.
    // Red arm: cells (0,6) to (5,6) are red path, (0,7) center red home, (0,8) to (5,8) red path
    // Green arm: cells (6,0) to (6,5) green path, (7,0) center green home, (8,0) to (8,5) green path
    // Yellow arm: cells (9,6) to (14,6) yellow path, (14,7) center yellow home, (9,8) to (14,8) yellow path
    // Blue arm: cells (6,9) to (6,14) blue path, (7,14) center blue home, (8,9) to (8,14) blue path

    // Red starting spot (index 0 for game logic, visual position)
    mainTrackSpots[0]  = Offset(1.5 * cellSize, 6.5 * cellSize); startingTrackSpots[PlayerColor.red] = mainTrackSpots[0];
    for (int i = 1; i <= 5; i++) { mainTrackSpots[i] = Offset((1.5 + i) * cellSize, 6.5 * cellSize); } // Path along Red's bottom row
    mainTrackSpots[6]  = Offset(6.5 * cellSize, 5.5 * cellSize); // Turn up
    for (int i = 1; i <= 5; i++) { mainTrackSpots[6+i] = Offset(6.5 * cellSize, (5.5 - i) * cellSize); } // Up Red's right column
    mainTrackSpots[12] = Offset(7.5 * cellSize, 0.5 * cellSize); // Top-middle square before Green's arm

    // Green starting spot (index 13)
    mainTrackSpots[13] = Offset(8.5 * cellSize, 1.5 * cellSize); startingTrackSpots[PlayerColor.green] = mainTrackSpots[13];
    for (int i = 1; i <= 5; i++) { mainTrackSpots[13+i] = Offset(8.5 * cellSize, (1.5 + i) * cellSize); } // Path along Green's left column
    mainTrackSpots[19] = Offset(9.5 * cellSize, 6.5 * cellSize); // Turn right
    for (int i = 1; i <= 5; i++) { mainTrackSpots[19+i] = Offset((9.5 + i) * cellSize, 6.5 * cellSize); } // Across Green's bottom row
    mainTrackSpots[25] = Offset(14.5 * cellSize, 7.5 * cellSize); // Right-middle square before Yellow's arm

    // Yellow starting spot (index 26)
    mainTrackSpots[26] = Offset(13.5 * cellSize, 8.5 * cellSize); startingTrackSpots[PlayerColor.yellow] = mainTrackSpots[26];
    for (int i = 1; i <= 5; i++) { mainTrackSpots[26+i] = Offset((13.5 - i) * cellSize, 8.5 * cellSize); } // Path along Yellow's top row
    mainTrackSpots[32] = Offset(8.5 * cellSize, 9.5 * cellSize); // Turn down
    for (int i = 1; i <= 5; i++) { mainTrackSpots[32+i] = Offset(8.5 * cellSize, (9.5 + i) * cellSize); } // Down Yellow's left column
    mainTrackSpots[38] = Offset(7.5 * cellSize, 14.5 * cellSize); // Bottom-middle square before Blue's arm

    // Blue starting spot (index 39)
    mainTrackSpots[39] = Offset(6.5 * cellSize, 13.5 * cellSize); startingTrackSpots[PlayerColor.blue] = mainTrackSpots[39];
    for (int i = 1; i <= 5; i++) { mainTrackSpots[39+i] = Offset(6.5 * cellSize, (13.5 - i) * cellSize); } // Path along Blue's right column
    mainTrackSpots[45] = Offset(5.5 * cellSize, 8.5 * cellSize); // Turn left
    for (int i = 1; i <= 5; i++) { mainTrackSpots[45+i] = Offset((5.5 - i) * cellSize, 8.5 * cellSize); } // Across Blue's top row
    mainTrackSpots[51] = Offset(0.5 * cellSize, 7.5 * cellSize); // Left-middle square, completing the loop for Red.
  }

  void _calculateHomeColumnSpots() {
    homeColumnSpots = {};
    // Red Home Column (goes right from mainTrack[51] vicinity)
    homeColumnSpots[PlayerColor.red] = List.generate(6, (i) => Offset((1.5 + i) * cellSize, 7.5 * cellSize));
    // Green Home Column (goes down from mainTrack[12] vicinity)
    homeColumnSpots[PlayerColor.green] = List.generate(6, (i) => Offset(7.5 * cellSize, (1.5 + i) * cellSize));
    // Yellow Home Column (goes left from mainTrack[25] vicinity)
    homeColumnSpots[PlayerColor.yellow] = List.generate(6, (i) => Offset((13.5 - i) * cellSize, 7.5 * cellSize));
    // Blue Home Column (goes up from mainTrack[38] vicinity)
    homeColumnSpots[PlayerColor.blue] = List.generate(6, (i) => Offset(7.5 * cellSize, (13.5 - i) * cellSize));
  }

  void _calculateCenterFinishSpot() {
    // Center of the 15x15 grid
    centerFinishSpot = Offset(7.5 * cellSize, 7.5 * cellSize);
  }

  // Helper to get position for a pawn based on its state and board position
  // This is a conceptual helper; actual usage might be more direct in the UI layer.
  Offset getPawnScreenPosition(PlayerColor color, int pawnModelPosition, PawnState state) {
    if (state == PawnState.home) {
      // This needs more info: which home spot? Assume pawnModelPosition is 0-3 for home spots.
      if (pawnModelPosition >= 0 && pawnModelPosition < 4) {
        return homeBaseSpots[color]![pawnModelPosition];
      }
      return Offset(-100, -100); // Should not happen / off-screen
    } else if (state == PawnState.onBoard) {
      if (pawnModelPosition >= 0 && pawnModelPosition < mainTrackSpots.length) {
        return mainTrackSpots[pawnModelPosition];
      }
      // If pawnModelPosition is > 51, it might be in a home column.
      // This logic needs to map game model's pawn.position to these coordinate lists.
      // For now, assume pawn.position < 52 for onBoard means mainTrack.
      // A more robust system would have pawn.position represent a global unique ID for each spot.
      return Offset(-100,-100); // Invalid board position
    } else if (state == PawnState.finished) {
      return centerFinishSpot; // Or specific spot in home column if not yet at absolute center
    }
    return Offset(-100,-100); // Default off-screen
  }
}

// Enum PawnState needs to be accessible here or defined if not already.
// Assuming it's in 'package:ludo/models/pawn.dart'
// We might need to import it if this file were to be used independently for testing coordinates with pawn states.
// For now, PlayerColor is imported, and PawnState is used conceptually in getPawnScreenPosition.
// If PawnState is needed for constructor or other logic, it must be imported.
// import 'package:ludo/models/pawn.dart'; // If PawnState enum is needed directly
