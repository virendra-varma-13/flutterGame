import 'package:flutter/material.dart';

// Enum for player colors
enum PlayerColor { red, green, yellow, blue }

// Map PlayerColor enum to Flutter Material Colors
const Map<PlayerColor, Color> playerColorToMaterialColor = {
  PlayerColor.red: Colors.red,
  PlayerColor.green: Colors.green,
  PlayerColor.yellow: Colors.yellow, // Or Colors.amber for better visibility
  PlayerColor.blue: Colors.blue,
};

// Helper to convert string color from Game model to PlayerColor enum if needed
// This might be useful if your Game model stores colors as strings.
// For now, Game model uses strings, this can bridge that to the enum.
PlayerColor? playerColorFromString(String colorString) {
  switch (colorString.toLowerCase()) {
    case 'red':
      return PlayerColor.red;
    case 'green':
      return PlayerColor.green;
    case 'yellow':
      return PlayerColor.yellow;
    case 'blue':
      return PlayerColor.blue;
    default:
      return null; // Or throw an error
  }
}

// Mapping from PlayerColor enum to the string representation used in Game model
// This helps keep consistency if the Game model uses string colors.
String playerColorToString(PlayerColor playerColor) {
  switch (playerColor) {
    case PlayerColor.red:
      return "Red";
    case PlayerColor.green:
      return "Green";
    case PlayerColor.yellow:
      return "Yellow";
    case PlayerColor.blue:
      return "Blue";
  }
}
