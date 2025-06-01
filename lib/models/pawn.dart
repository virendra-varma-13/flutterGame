enum PawnState { home, onBoard, inHomeStretch, finished }

class Pawn {
  final int id; // Unique ID for the pawn (e.g., 0, 1, 2, 3 for each player)
  final String color; // Color of the pawn, matches player color
  int position; // -1 for home, 0-51 for board, 99 (or other value) for finished
  PawnState state;

  Pawn({
    required this.id,
    required this.color,
    this.position = -1, // Default to home
    this.state = PawnState.home,
  });

  // Optional: Method to move pawn, could also be in Game logic
  // This method is largely superseded by Game.movePawn for game progression.
  // If it were to be used, it would need to be updated to understand PawnState.inHomeStretch
  // and the specific position values for that state.
  // void moveTo(int newPosition) {
  //   position = newPosition;
  //   if (newPosition == -1) {
  //     state = PawnState.home;
  //   } else if (newPosition >= 0 && newPosition <= 51) { // Assuming 52 board positions (0-51)
  //     state = PawnState.onBoard;
  //   } else { // Assuming positions > 51 mean finished
  //     state = PawnState.finished;
  //     // Consider a specific value for finished, e.g., a constant
  //     // For now, any position > 51 is considered finished for simplicity
  //   }
  // }

  @override
  String toString() {
    return 'Pawn(id: $id, color: $color, position: $position, state: $state)';
  }
}
