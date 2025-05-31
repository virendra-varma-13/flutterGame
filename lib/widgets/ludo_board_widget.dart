import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
// Assuming pawn_widget.dart is in the same directory, otherwise adjust path.
// import 'pawn_widget.dart'; // Not strictly needed if pawns are passed as generic Widgets

class LudoBoardWidget extends StatelessWidget {
  final List<Widget> pawnsToDisplay; // These will be positioned using Positioned widgets within the Stack
  final double boardSize;

  const LudoBoardWidget({
    Key? key,
    this.pawnsToDisplay = const [], // Default to an empty list
    this.boardSize = 300.0, // Default board size
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: boardSize,
      height: boardSize,
      child: Stack(
        children: <Widget>[
          // Ludo Board SVG Image
          SvgPicture.asset(
            'assets/images/ludo/ludo_board.svg',
            width: boardSize,
            height: boardSize,
            // You can add a placeholder if the SVG fails to load, though SvgPicture handles errors.
            // placeholderBuilder: (BuildContext context) => Container(
            //   padding: const EdgeInsets.all(30.0),
            //   child: const CircularProgressIndicator(),
            // ),
          ),
          // Pawns and other elements to overlay on the board
          // These should be wrapped in Positioned widgets to place them correctly.
          // Example:
          // Positioned(
          //   top: 50, // Example position
          //   left: 50, // Example position
          //   child: PawnWidget(pawnColor: Colors.red, pawnId: 1),
          // ),
          ...pawnsToDisplay,
        ],
      ),
    );
  }
}
