import 'package:flutter/material.dart';
import 'dart:ui' as ui; // For Offset and Size, aliased to avoid conflict with material.Size

// Core imports
import 'package:ludo/core/constants.dart';
import 'package:ludo/core/ludo_board_coordinates.dart';

// Note: The SvgPicture.asset for 'ludo_board.svg' will be removed as we are custom painting the board.
// If you want to keep it as a background, it can be the first item in the Stack.

class LudoBoardWidget extends StatelessWidget {
  final List<Widget> pawnsToDisplay;
  final Size boardDrawingSize; // Use Flutter's material.Size for widget sizing

  const LudoBoardWidget({
    Key? key,
    this.pawnsToDisplay = const [],
    required this.boardDrawingSize,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Convert material.Size to ui.Size for LudoBoardCoordinates
    final uiBoardSize = ui.Size(boardDrawingSize.width, boardDrawingSize.height);
    final coordinates = LudoBoardCoordinates(boardSize: uiBoardSize);

    return Container(
      width: boardDrawingSize.width,
      height: boardDrawingSize.height,
      child: Stack(
        children: <Widget>[
          // Custom painter for tracks and cells
          CustomPaint(
            size: boardDrawingSize, // Ensure CustomPaint covers the area
            painter: LudoTracksPainter(
              coordinates: coordinates,
              // cellSize: coordinates.cellSize, // Pass cellSize or let painter use coordinates.cellSize
            ),
          ),

          // Optional: If you still want the SVG as a background (e.g., for complex imagery not drawn by painter)
          // Positioned.fill(
          //   child: SvgPicture.asset(
          //     'assets/images/ludo/ludo_board.svg',
          //     width: boardDrawingSize.width,
          //     height: boardDrawingSize.height,
          //     fit: BoxFit.fill,
          //   ),
          // ),

          // Pawns are rendered on top
          ...pawnsToDisplay,
        ],
      ),
    );
  }
}

class LudoTracksPainter extends CustomPainter {
  final LudoBoardCoordinates coordinates;
  final double cellSize; // Derived from coordinates.cellSize for convenience

  LudoTracksPainter({required this.coordinates}) : cellSize = coordinates.cellSize;

  @override
  void paint(Canvas canvas, Size size) { // size here is the CustomPaint's own size
    final Paint strokePaint = Paint()
      ..color = Colors.black54
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final Paint whiteFillPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    // Draw home base areas (large colored squares)
    for (PlayerColor color in PlayerColor.values) {
      final baseColor = playerColorToMaterialColor[color]!.withOpacity(0.3); // Lighter base color
      final Rect baseRect = Rect.fromLTWH(
        color == PlayerColor.red || color == PlayerColor.blue ? 0 : 9 * cellSize,
        color == PlayerColor.red || color == PlayerColor.green ? 0 : 9 * cellSize,
        6 * cellSize,
        6 * cellSize,
      );
      canvas.drawRect(baseRect, Paint()..color = baseColor);
      canvas.drawRect(baseRect, strokePaint); // Border for the base

      // Draw 4 pawn resting spots within each home base
      final spots = coordinates.homeBaseSpots[color]!;
      for (Offset spotOffset in spots) {
        canvas.drawCircle(spotOffset, cellSize * 0.6, whiteFillPaint); // White circle
        canvas.drawCircle(spotOffset, cellSize * 0.6, strokePaint);    // Border
         canvas.drawCircle(spotOffset, cellSize * 0.5, Paint()..color = playerColorToMaterialColor[color]!); // Inner color dot
      }
    }

    // Draw main track spots
    for (int i = 0; i < coordinates.mainTrackSpots.length; i++) {
      final Offset spot = coordinates.mainTrackSpots[i];
      final Rect cellRect = Rect.fromCenter(center: spot, width: cellSize * 0.9, height: cellSize * 0.9);

      // Basic safe spot indication (example: start spots and a few others)
      // A more detailed list of safe spots would be needed for accuracy.
      bool isSafeSpot = coordinates.startingTrackSpots.containsValue(spot) ||
                        i % 13 == 8; // Example: every 8th spot in a segment of 13 is safe

      final Paint cellFill = isSafeSpot ? (Paint()..color = Colors.grey.shade300) : whiteFillPaint;
      canvas.drawRect(cellRect, cellFill);
      canvas.drawRect(cellRect, strokePaint);

      // Mark starting spots with player color (small indicator)
      coordinates.startingTrackSpots.forEach((playerColor, startOffset) {
        if (startOffset == spot) {
          final Paint startSpotPaint = Paint()..color = playerColorToMaterialColor[playerColor]!;
          canvas.drawCircle(spot, cellSize * 0.25, startSpotPaint);
        }
      });
    }

    // Draw home column spots
    for (PlayerColor color in PlayerColor.values) {
      final spots = coordinates.homeColumnSpots[color]!;
      final columnColor = playerColorToMaterialColor[color]!;
      for (Offset spotOffset in spots) {
        final Rect cellRect = Rect.fromCenter(center: spotOffset, width: cellSize * 0.9, height: cellSize * 0.9);
        canvas.drawRect(cellRect, Paint()..color = columnColor);
        canvas.drawRect(cellRect, strokePaint);
      }
    }

    // Draw Center Finish Spot (Triangle)
    final Paint centerPaint = Paint()..style = PaintingStyle.fill;
    Path centerTriangle = Path();
    // Red side of triangle
    centerTriangle.moveTo(coordinates.homeColumnSpots[PlayerColor.red]!.last.dx + cellSize/2, coordinates.homeColumnSpots[PlayerColor.red]!.last.dy);
    centerTriangle.lineTo(coordinates.centerFinishSpot.dx, coordinates.centerFinishSpot.dy - cellSize/2);
    centerTriangle.lineTo(coordinates.centerFinishSpot.dx + cellSize/2, coordinates.centerFinishSpot.dy);
    canvas.drawPath(centerTriangle, centerPaint..color = playerColorToMaterialColor[PlayerColor.red]!);

    // Green side
    centerTriangle.reset();
    centerTriangle.moveTo(coordinates.homeColumnSpots[PlayerColor.green]!.last.dx, coordinates.homeColumnSpots[PlayerColor.green]!.last.dy + cellSize/2);
    centerTriangle.lineTo(coordinates.centerFinishSpot.dx + cellSize/2, coordinates.centerFinishSpot.dy);
    centerTriangle.lineTo(coordinates.centerFinishSpot.dx, coordinates.centerFinishSpot.dy + cellSize/2);
    canvas.drawPath(centerTriangle, centerPaint..color = playerColorToMaterialColor[PlayerColor.green]!);

    // Yellow side
    centerTriangle.reset();
    centerTriangle.moveTo(coordinates.homeColumnSpots[PlayerColor.yellow]!.last.dx - cellSize/2, coordinates.homeColumnSpots[PlayerColor.yellow]!.last.dy);
    centerTriangle.lineTo(coordinates.centerFinishSpot.dx, coordinates.centerFinishSpot.dy + cellSize/2);
    centerTriangle.lineTo(coordinates.centerFinishSpot.dx - cellSize/2, coordinates.centerFinishSpot.dy);
    canvas.drawPath(centerTriangle, centerPaint..color = playerColorToMaterialColor[PlayerColor.yellow]!);

    // Blue side
    centerTriangle.reset();
    centerTriangle.moveTo(coordinates.homeColumnSpots[PlayerColor.blue]!.last.dx, coordinates.homeColumnSpots[PlayerColor.blue]!.last.dy - cellSize/2);
    centerTriangle.lineTo(coordinates.centerFinishSpot.dx - cellSize/2, coordinates.centerFinishSpot.dy);
    centerTriangle.lineTo(coordinates.centerFinishSpot.dx, coordinates.centerFinishSpot.dy - cellSize/2);
    canvas.drawPath(centerTriangle, centerPaint..color = playerColorToMaterialColor[PlayerColor.blue]!);

    // Border for the center area
    Rect centerRect = Rect.fromCenter(center: coordinates.centerFinishSpot, width: cellSize*1.5, height: cellSize*1.5);
    canvas.drawRect(centerRect, strokePaint..strokeWidth=2.0);

  }

  @override
  bool shouldRepaint(covariant LudoTracksPainter oldDelegate) {
    // Repaint if coordinates or cellSize change. For now, assume they don't after init.
    return oldDelegate.coordinates != coordinates || oldDelegate.cellSize != cellSize;
  }
}
