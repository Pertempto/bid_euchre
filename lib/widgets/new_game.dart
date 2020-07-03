import 'package:bideuchre/data/data_store.dart';
import 'package:bideuchre/data/game.dart';
import 'package:bideuchre/widgets/color_chooser.dart';
import 'package:bideuchre/widgets/player_selection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'game_detail.dart';

class NewGame extends StatefulWidget {
  final Game copyGame;

  NewGame({this.copyGame});

  @override
  _NewGameState createState() => _NewGameState();
}

class _NewGameState extends State<NewGame> {
  Data data;
  List<String> initialPlayerIds;
  List<Color> teamColors;
  int gameOverScore;

  @override
  Widget build(BuildContext context) {
    return DataStore.dataWrap((data) {
      if (initialPlayerIds == null) {
        Game copyGame = widget.copyGame;
        if (copyGame == null) {
          initialPlayerIds = [null, null, null, null];
          teamColors = [Colors.blue, Colors.green];
          gameOverScore = 42;
        } else {
          initialPlayerIds = copyGame.currentPlayerIds;
          for (int i = 0; i < 4; i++) {
            // don't copy over players that the current user doesn't have permission to use
            if (!data.players.containsKey(initialPlayerIds[i])) {
              initialPlayerIds[i] = null;
            }
          }
          teamColors = copyGame.teamColors;
          gameOverScore = copyGame.gameOverScore;
        }
      }
      TextTheme textTheme = Theme.of(context).textTheme;
      TextStyle leadingStyle = textTheme.headline6;
      TextStyle trailingStyle = textTheme.headline6.copyWith(fontWeight: FontWeight.w400);

      List<Widget> children = [
        SizedBox(height: 8), //balance out dividers whitespace
      ];
      for (int i = 0; i < 4; i++) {
        String playerName = initialPlayerIds[i] == null ? 'Select' : data.players[initialPlayerIds[i]].fullName;
        children.add(ListTile(
          title: Text('Player ${i + 1}', style: leadingStyle),
          trailing: Text(playerName, style: trailingStyle.copyWith(color: teamColors[i % 2])),
          dense: true,
          onTap: () {
            selectPlayer(i);
          },
        ));
        children.add(Divider());
      }
      for (int i = 0; i < 2; i++) {
        children.add(ListTile(
          title: Text('Team ${i + 1} Color', style: leadingStyle),
          trailing: Container(color: teamColors[i], height: 32, width: 32),
          dense: true,
          onTap: () {
            selectTeamColor(i);
          },
        ));
        children.add(Divider());
      }
      children.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Column(
            children: <Widget>[
              Row(
                children: <Widget>[
                  Text('Game Over Score', style: leadingStyle),
                  Spacer(),
                  Text('$gameOverScore', style: trailingStyle),
                ],
              ),
              Slider.adaptive(
                value: gameOverScore.toDouble(),
                min: 12,
                max: 60,
                onChanged: (value) {
                  setState(() {
                    gameOverScore = value.toInt();
                  });
                },
              ),
            ],
          ),
        ),
      );
      children.add(Divider());
      return Scaffold(
        appBar: AppBar(
          title: Text('New Game'),
          actions: <Widget>[
            if (!initialPlayerIds.contains(null))
              IconButton(
                icon: Icon(Icons.check),
                onPressed: () {
                  Game game = Game.newGame(data.currentUser, initialPlayerIds, teamColors, gameOverScore);
                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => GameDetail(game)));
                },
              ),
          ],
        ),
        body: SingleChildScrollView(
          child: Column(
            children: children,
          ),
        ),
      );
    });
  }

  selectPlayer(int playerIndex) async {
    String playerId = await Navigator.push(context, MaterialPageRoute(builder: (context) => PlayerSelection()));
    if (playerId != null) {
      setState(() {
        initialPlayerIds[playerIndex] = playerId;
      });
    }
  }

  selectTeamColor(int teamIndex) async {
    Color teamColor =
        await Navigator.push(context, MaterialPageRoute(builder: (context) => ColorChooser(teamColors[teamIndex])));
    if (teamColor != null) {
      setState(() {
        teamColors[teamIndex] = teamColor;
      });
    }
  }
}
