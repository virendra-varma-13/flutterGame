import 'pawn.dart';

class Player {
  final String id; // Could be a UUID or a simple identifier like "Player1"
  final String color; // e.g., "Red", "Green", "Blue", "Yellow"
  List<Pawn> pawns;

  Player({
    required this.id,
    required this.color,
    List<Pawn>? pawns,
  }) : pawns = pawns ?? List.generate(4, (i) => Pawn(id: i, color: color)); // Each player gets 4 pawns by default

  // Helper method to get pawns at home
  List<Pawn> getHomePawns() {
    return pawns.where((pawn) => pawn.state == PawnState.home).toList();
  }

  // Helper method to get pawns on board
  List<Pawn> getOnBoardPawns() {
    return pawns.where((pawn) => pawn.state == PawnState.onBoard).toList();
  }

  // Helper method to get finished pawns
  List<Pawn> getFinishedPawns() {
    return pawns.where((pawn) => pawn.state == PawnState.finished).toList();
  }

  // Check if all pawns are finished
  bool hasWon() {
    return pawns.every((pawn) => pawn.state == PawnState.finished);
  }

  @override
  String toString() {
    return 'Player(id: $id, color: $color, pawns: ${pawns.length})';
  }
}
