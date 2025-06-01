import 'package:flutter/material.dart';
import 'package:ludo/main.dart'; // Import MyHomePage

class SetupScreen extends StatefulWidget {
  const SetupScreen({Key? key}) : super(key: key);

  @override
  _SetupScreenState createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  int _selectedNumberOfPlayers = 2; // Default to 2 players
  bool _playWithAI = false;

  @override
  Widget build(BuildContext context) {
    // Determine if AI switch should be enabled
    bool aiSwitchEnabled = _selectedNumberOfPlayers == 1;

    // If more than 1 player is selected, AI must be off
    if (_selectedNumberOfPlayers != 1 && _playWithAI) {
      // This should ideally not happen if logic in onChanged is correct,
      // but as a safeguard, update state during build (though not recommended, better in onChanged)
      // A cleaner way is to ensure _playWithAI is set to false in Dropdown's onChanged
      // when _selectedNumberOfPlayers is not 1.
      // Forcing it here for robustness, but it might cause a rebuild loop if not careful.
      // Future: schedule a post-frame callback if direct modification during build is problematic.
      // WidgetsBinding.instance.addPostFrameCallback((_) {
      //   setState(() {
      //     _playWithAI = false;
      //   });
      // });
    }


    return Scaffold(
      appBar: AppBar(
        title: const Text('Ludo Game Setup'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Select Number of Players:',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8.0),
            DropdownButtonFormField<int>(
              value: _selectedNumberOfPlayers,
              items: const [
                DropdownMenuItem(value: 1, child: Text('1 Player (vs AI)')),
                DropdownMenuItem(value: 2, child: Text('2 Players')),
                DropdownMenuItem(value: 3, child: Text('3 Players')),
                DropdownMenuItem(value: 4, child: Text('4 Players')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedNumberOfPlayers = value;
                    if (_selectedNumberOfPlayers != 1) {
                      _playWithAI = false; // Disable AI if not 1 player
                    } else {
                       _playWithAI = true; // Default to AI if 1 player is selected
                    }
                  });
                }
              },
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
              ),
            ),
            const SizedBox(height: 24.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text(
                  'Play with System (AI)',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Switch(
                  value: _playWithAI,
                  onChanged: aiSwitchEnabled
                    ? (value) {
                        setState(() {
                          _playWithAI = value;
                        });
                      }
                    : null, // Disabled if not 1 player
                  activeColor: Theme.of(context).primaryColor,
                ),
              ],
            ),
            const SizedBox(height: 8.0),
            Text(
              aiSwitchEnabled
                ? (_playWithAI ? 'You will play against the AI.' : 'You will play locally (pass and play).')
                : 'AI opponent is only available for 1 Player mode.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const Spacer(), // Pushes the button to the bottom
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 48.0, vertical: 16.0),
                  textStyle: Theme.of(context).textTheme.titleMedium,
                ),
                onPressed: () {
                  // Logic to start the game with selected settings
                  print('Selected Number of Players: $_selectedNumberOfPlayers');
                  print('Play with AI: $_playWithAI');

                  // Navigate to MyHomePage and pass the settings
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MyHomePage(
                        title: 'Ludo Game', // You can make title dynamic if needed
                        numPlayers: _selectedNumberOfPlayers,
                        playWithAI: _playWithAI,
                      ),
                    ),
                  );
                },
                child: const Text('Start Game'),
              ),
            ),
            const SizedBox(height: 20), // Some padding at the bottom
          ],
        ),
      ),
    );
  }
}
