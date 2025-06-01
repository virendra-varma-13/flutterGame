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
    super.key,
    this.pawnsToDisplay = const [],
    required this.boardDrawingSize,
  });

  @override
  Widget build(BuildContext context) {
    // Convert material.Size to ui.Size for LudoBoardCoordinates
    final uiBoardSize = ui.Size(boardDrawingSize.width, boardDrawingSize.height);
    final coordinates = LudoBoardCoordinates(boardSize: uiBoardSize);

    return SizedBox(
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

          // Pawns are rendered on top
          ...pawnsToDisplay,
        ],
      ),
    );
  }
}

// At the top of the LudoTracksPainter class or as a global constant
const List<int> _safeSpotIndices = [0, 8, 13, 21, 26, 34, 39, 47];

class LudoTracksPainter extends CustomPainter {
  final LudoBoardCoordinates coordinates;
  final double cellSize; // Derived from coordinates.cellSize for convenience

  LudoTracksPainter({required this.coordinates}) : cellSize = coordinates.cellSize;

  // Helper method to draw a star (simplified)
  void _drawStar(Canvas canvas, Offset center, double radius, Color color) {
    final Paint starPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill; // Or PaintingStyle.stroke

    // Simple asterisk-like star
    canvas.drawLine(Offset(center.dx - radius, center.dy), Offset(center.dx + radius, center.dy), starPaint..strokeWidth=1);
    canvas.drawLine(Offset(center.dx, center.dy - radius), Offset(center.dx, center.dy + radius), starPaint..strokeWidth=1);
    canvas.drawLine(Offset(center.dx - radius * 0.7, center.dy - radius * 0.7), Offset(center.dx + radius * 0.7, center.dy + radius * 0.7), starPaint..strokeWidth=1);
    canvas.drawLine(Offset(center.dx - radius * 0.7, center.dy + radius * 0.7), Offset(center.dx + radius * 0.7, center.dy - radius * 0.7), starPaint..strokeWidth=1);
  }

  // Helper method to draw an arrow on a cell
  void _drawArrowOnCell(Canvas canvas, Offset cellCenter, String direction, Paint paint, double size) {
    double arrowLength = size * 0.3; // Length of the arrow body
    double headSize = size * 0.15;   // Size of the arrowhead sides

    Offset startPoint;
    Offset endPoint;

    // Calculate start and end points based on direction
    switch (direction) {
      case 'right':
        startPoint = Offset(cellCenter.dx - arrowLength / 2, cellCenter.dy);
        endPoint = Offset(cellCenter.dx + arrowLength / 2, cellCenter.dy);
        break;
      case 'left':
        startPoint = Offset(cellCenter.dx + arrowLength / 2, cellCenter.dy);
        endPoint = Offset(cellCenter.dx - arrowLength / 2, cellCenter.dy);
        break;
      case 'up':
        startPoint = Offset(cellCenter.dx, cellCenter.dy + arrowLength / 2);
        endPoint = Offset(cellCenter.dx, cellCenter.dy - arrowLength / 2);
        break;
      case 'down':
        startPoint = Offset(cellCenter.dx, cellCenter.dy - arrowLength / 2);
        endPoint = Offset(cellCenter.dx, cellCenter.dy + arrowLength / 2);
        break;
      default:
        return; // Invalid direction
    }

    // Draw arrow body
    canvas.drawLine(startPoint, endPoint, paint);

    // Draw arrowhead
    Path arrowhead = Path();
    if (direction == 'right') {
      arrowhead.moveTo(endPoint.dx - headSize, endPoint.dy - headSize);
      arrowhead.lineTo(endPoint.dx, endPoint.dy);
      arrowhead.lineTo(endPoint.dx - headSize, endPoint.dy + headSize);
    } else if (direction == 'left') {
      arrowhead.moveTo(endPoint.dx + headSize, endPoint.dy - headSize);
      arrowhead.lineTo(endPoint.dx, endPoint.dy);
      arrowhead.lineTo(endPoint.dx + headSize, endPoint.dy + headSize);
    } else if (direction == 'up') {
      arrowhead.moveTo(endPoint.dx - headSize, endPoint.dy + headSize);
      arrowhead.lineTo(endPoint.dx, endPoint.dy);
      arrowhead.lineTo(endPoint.dx + headSize, endPoint.dy + headSize);
    } else if (direction == 'down') {
      arrowhead.moveTo(endPoint.dx - headSize, endPoint.dy - headSize);
      arrowhead.lineTo(endPoint.dx, endPoint.dy);
      arrowhead.lineTo(endPoint.dx + headSize, endPoint.dy - headSize);
    }
    canvas.drawPath(arrowhead, paint..style = PaintingStyle.stroke); // ensure arrowhead is stroked
  }

  @override
  void paint(Canvas canvas, Size size) {
    // size here is the CustomPaint's own size
    // 1. Board Background
    final Paint backgroundPaint = Paint()..color = Color(0xFFF5F5DC); // Beige
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), backgroundPaint);

    final Paint strokePaint = Paint()
      ..color = Colors.black87 // Slightly softer black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5; // Adjusted stroke width

    final Paint whiteFillPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    // 2. Home Base Appearance
    for (PlayerColor color in PlayerColor.values) {
      final baseColor = playerColorToMaterialColor[color]!.withOpacity(0.3);
      final Rect baseRect = Rect.fromLTWH(
        (color == PlayerColor.red || color == PlayerColor.blue ? 0 : 9 * cellSize),
        (color == PlayerColor.red || color == PlayerColor.green ? 0 : 9 * cellSize),
        6 * cellSize,
        6 * cellSize,
      );
      canvas.drawRect(baseRect, Paint()..color = baseColor);
      canvas.drawRect(baseRect, strokePaint);

      // Large white circle in home base
      final Offset homeBaseCenter = Offset(
          baseRect.left + 3 * cellSize, baseRect.top + 3 * cellSize);
      canvas.drawCircle(homeBaseCenter, cellSize * 2.2, whiteFillPaint); // Increased size
      canvas.drawCircle(homeBaseCenter, cellSize * 2.2, strokePaint);

      // 4 pawn resting spots (solid color)
      final spots = coordinates.homeBaseSpots[color]!;
      for (Offset spotOffset in spots) {
        // The spots from LudoBoardCoordinates are already well-positioned for the 2x2 grid
        canvas.drawCircle(spotOffset, cellSize * 0.7, Paint()..color = playerColorToMaterialColor[color]!); // Solid color
        canvas.drawCircle(spotOffset, cellSize * 0.7, strokePaint); // Border for the spot
      }
    }

    // 3. Main Track Spots & Safe Spots
    for (int i = 0; i < coordinates.mainTrackSpots.length; i++) {
      final Offset spot = coordinates.mainTrackSpots[i];
      final Rect cellRect = Rect.fromCenter(center: spot, width: cellSize * 0.95, height: cellSize * 0.95); // Slightly larger cells

      bool isActuallySafe = _safeSpotIndices.contains(i);
      // Starting spots are also considered safe and have special coloring.
      // The small colored circle marks the start, the cell itself can be marked if it's a star spot.

      Paint cellFill = whiteFillPaint;
      if (isActuallySafe && !coordinates.startingTrackSpots.containsValue(spot)) {
        // For non-starting safe spots (the "starred" ones)
        cellFill = Paint()..color = Colors.grey.shade300; // Light gray for starred spots
      }

      canvas.drawRect(cellRect, cellFill);
      canvas.drawRect(cellRect, strokePaint);

      if (isActuallySafe && !coordinates.startingTrackSpots.containsValue(spot)) {
        // Draw a simple star or asterisk for safe spots for now
        _drawStar(canvas, spot, cellSize * 0.3, Colors.black54);
      }

      // Mark starting spots with player color (small indicator) - current logic is good
      coordinates.startingTrackSpots.forEach((playerColor, startOffset) {
        if (startOffset == spot) {
          final Paint startSpotPaint = Paint()..color = playerColorToMaterialColor[playerColor]!;
          // Draw a filled rectangle as the starting cell's background color
          Rect startCellBgRect = Rect.fromCenter(center: spot, width: cellSize * 0.95, height: cellSize * 0.95);
          canvas.drawRect(startCellBgRect, startSpotPaint);
          canvas.drawRect(startCellBgRect, strokePaint); // Re-apply border on top
        }
      });
    }

    // 4. Movement Direction Arrows
    // Helper function to draw an arrow might be useful
    // void _drawArrow(Canvas canvas, Offset from, Offset to, Paint paint)
    // For now, direct drawing:
    final Paint arrowPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // Arrows for Red Path (example on cell index 2)
    if (coordinates.mainTrackSpots.length > 2) {
      _drawArrowOnCell(canvas, coordinates.mainTrackSpots[2], 'right', arrowPaint, cellSize);
    }
    if (coordinates.mainTrackSpots.length > 9) {
      _drawArrowOnCell(canvas, coordinates.mainTrackSpots[9], 'up', arrowPaint, cellSize);
    }
    // Arrows for Green Path (example on cell index 15)
    if (coordinates.mainTrackSpots.length > 15) {
      _drawArrowOnCell(canvas, coordinates.mainTrackSpots[15], 'down', arrowPaint, cellSize);
    }
    if (coordinates.mainTrackSpots.length > 22) {
      _drawArrowOnCell(canvas, coordinates.mainTrackSpots[22], 'right', arrowPaint, cellSize);
    }
    // Arrows for Yellow Path (example on cell index 28)
    if (coordinates.mainTrackSpots.length > 28) {
      _drawArrowOnCell(canvas, coordinates.mainTrackSpots[28], 'left', arrowPaint, cellSize);
    }
    if (coordinates.mainTrackSpots.length > 35) {
      _drawArrowOnCell(canvas, coordinates.mainTrackSpots[35], 'down', arrowPaint, cellSize);
    }
    // Arrows for Blue Path (example on cell index 41)
    if (coordinates.mainTrackSpots.length > 41) {
      _drawArrowOnCell(canvas, coordinates.mainTrackSpots[41], 'up', arrowPaint, cellSize);
    }
    if (coordinates.mainTrackSpots.length > 48) {
      _drawArrowOnCell(canvas, coordinates.mainTrackSpots[48], 'left', arrowPaint, cellSize);
    }


    // 5. Home Column Spots (current logic is good, ensure colors are solid)
    for (PlayerColor color in PlayerColor.values) {
      final spots = coordinates.homeColumnSpots[color]!;
      final columnColor = playerColorToMaterialColor[color]!;
      for (Offset spotOffset in spots) {
        final Rect cellRect = Rect.fromCenter(center: spotOffset, width: cellSize * 0.95, height: cellSize * 0.95);
        canvas.drawRect(cellRect, Paint()..color = columnColor);
        canvas.drawRect(cellRect, strokePaint);
      }
    }

    // 6. Center Finish Spot (Triangle) - current logic seems mostly fine, review strokes
    final Paint centerPaint = Paint()..style = PaintingStyle.fill;
    Path centerTriangle = Path();

    // Adjusted to meet at the exact center point (coordinates.centerFinishSpot)
    // And use the end of home columns as other vertices.
    final Offset finishCenter = coordinates.centerFinishSpot;
    final double halfCell = cellSize / 2;

    // Red Triangle
    Offset redHomeEnd = coordinates.homeColumnSpots[PlayerColor.red]!.last;
    centerTriangle.moveTo(redHomeEnd.dx + halfCell, redHomeEnd.dy); // Outer point
    centerTriangle.lineTo(finishCenter.dx, finishCenter.dy - halfCell); // Top-center of central square
    centerTriangle.lineTo(finishCenter.dx, finishCenter.dy + halfCell); // Bottom-center of central square
    centerTriangle.close();
    canvas.drawPath(centerTriangle, centerPaint..color = playerColorToMaterialColor[PlayerColor.red]!);
    canvas.drawPath(centerTriangle, strokePaint);

    // Green Triangle
    centerTriangle.reset();
    Offset greenHomeEnd = coordinates.homeColumnSpots[PlayerColor.green]!.last;
    centerTriangle.moveTo(greenHomeEnd.dx, greenHomeEnd.dy + halfCell); // Outer point
    centerTriangle.lineTo(finishCenter.dx + halfCell, finishCenter.dy); // Right-center
    centerTriangle.lineTo(finishCenter.dx - halfCell, finishCenter.dy); // Left-center
    centerTriangle.close();
    canvas.drawPath(centerTriangle, centerPaint..color = playerColorToMaterialColor[PlayerColor.green]!);
    canvas.drawPath(centerTriangle, strokePaint);

    // Yellow Triangle
    centerTriangle.reset();
    Offset yellowHomeEnd = coordinates.homeColumnSpots[PlayerColor.yellow]!.last;
    centerTriangle.moveTo(yellowHomeEnd.dx - halfCell, yellowHomeEnd.dy); // Outer point
    centerTriangle.lineTo(finishCenter.dx, finishCenter.dy + halfCell); // Bottom-center
    centerTriangle.lineTo(finishCenter.dx, finishCenter.dy - halfCell); // Top-center
    centerTriangle.close();
    canvas.drawPath(centerTriangle, centerPaint..color = playerColorToMaterialColor[PlayerColor.yellow]!);
    canvas.drawPath(centerTriangle, strokePaint);

    // Blue Triangle
    centerTriangle.reset();
    Offset blueHomeEnd = coordinates.homeColumnSpots[PlayerColor.blue]!.last;
    centerTriangle.moveTo(blueHomeEnd.dx, blueHomeEnd.dy - halfCell); // Outer point
    centerTriangle.lineTo(finishCenter.dx - halfCell, finishCenter.dy); // Left-center
    centerTriangle.lineTo(finishCenter.dx + halfCell, finishCenter.dy); // Right-center
    centerTriangle.close();
    canvas.drawPath(centerTriangle, centerPaint..color = playerColorToMaterialColor[PlayerColor.blue]!);
    canvas.drawPath(centerTriangle, strokePaint);

    // Border for the absolute center square (optional, if triangles don't perfectly align or for emphasis)
    // Rect centerSquareRect = Rect.fromCenter(center: finishCenter, width: cellSize, height: cellSize);
    // canvas.drawRect(centerSquareRect, strokePaint..strokeWidth = 1.0);
  }

  @override
  bool shouldRepaint(covariant LudoTracksPainter oldDelegate) {
    // Repaint if coordinates or cellSize change. For now, assume they don't after init.
    return oldDelegate.coordinates != coordinates || oldDelegate.cellSize != cellSize;
  }
}