import 'package:flutter/material.dart';

class PawnWidget extends StatelessWidget {
  final Color pawnColor;
  final int pawnId; // Or String, if preferred
  final double size;

  const PawnWidget({
    Key? key,
    required this.pawnColor,
    required this.pawnId,
    this.size = 24.0, // Default size for the pawn
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: pawnColor,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.black87, width: 1.5), // Changed to a more solid black
        boxShadow: [ // Adding a subtle shadow for a bit of depth
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            spreadRadius: 0.5,
            blurRadius: 1.5,
            offset: const Offset(0, 1),
          ),
        ]
      ),
      child: Center(
        child: Text(
          pawnId.toString(),
          style: TextStyle(
            color: Colors.white, // Text color that contrasts with most pawn colors
            fontWeight: FontWeight.bold,
            fontSize: size * 0.5,
          ),
        ),
      ),
    );
  }
}
