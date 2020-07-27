import 'package:bideuchre/data/data_store.dart';
import 'package:bideuchre/data/game.dart';
import 'package:bideuchre/data/player.dart';
import 'package:bideuchre/data/stats.dart';
import 'package:bideuchre/widgets/color_chooser.dart';
import 'package:bideuchre/widgets/player_selection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import '../util.dart';
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
      this.data = data;
      if (initialPlayerIds == null) {
        Game copyGame = widget.copyGame;
        if (copyGame == null) {
          initialPlayerIds = [null, null, null, null];
          teamColors = [ColorChooser.generateRandomColor(), ColorChooser.generateRandomColor()];
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
        String playerId = initialPlayerIds[i];
        String playerName = 'Select';
        if (playerId != null) {
          if (data.players[playerId] == null) {
            playerName = '';
          } else {
            playerName = data.players[playerId].fullName;
          }
        }
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
      if (!initialPlayerIds.contains(null)) {
        children.add(ListTile(
          title: Text('Automatic Teams', style: leadingStyle),
          trailing: Icon(MdiIcons.shuffleVariant),
          dense: true,
          onTap: () {
            autoTeams();
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

  autoTeams() async {
    setState(() {
      initialPlayerIds.sort((a, b) {
        double sa = data.statsDb.getStat(a, StatType.rating).sortValue;
        double sb = data.statsDb.getStat(b, StatType.rating).sortValue;
        return sa.compareTo(sb);
      });
      int fairestPartnerIndex = 0;
      double smallestDiff = double.infinity;
      for (int i = 1; i < 4; i++) {
        List<String> oTeam = [];
        for (int j = 1; j < 4; j++) {
          if (j != i) {
            oTeam.add(initialPlayerIds[j]);
          }
        }
        List<double> chances = data.statsDb
            .getWinChances([initialPlayerIds[0], oTeam[0], initialPlayerIds[i], oTeam[1]], [0, 0], gameOverScore);
        double diff = (chances[0] - chances[1]).abs();
        print('$i, $chances');
        if (diff < smallestDiff) {
          smallestDiff = diff;
          fairestPartnerIndex = i;
        }
      }
      // switch two players
      String tempId = initialPlayerIds[2];
      initialPlayerIds[2] = initialPlayerIds[fairestPartnerIndex];
      initialPlayerIds[fairestPartnerIndex] = tempId;
      for (int i = 0; i < 2; i++) {
        String teamId = Util.teamId([initialPlayerIds[i], initialPlayerIds[i + 2]]);
        for (Game g in data.games) {
          if (g.teamIds.contains(teamId)) {
            int teamIndex = g.teamIds.indexOf(teamId);
            teamColors[i] = g.teamColors[teamIndex];
            break;
          }
        }
      }
    });
  }

  selectPlayer(int playerIndex) async {
    Player player = await Navigator.push(context, MaterialPageRoute(builder: (context) => PlayerSelection()));
    if (player != null) {
      setState(() {
        print('player: $player');
        initialPlayerIds[playerIndex] = player.playerId;
        String partnerId = initialPlayerIds[(playerIndex + 2) % 4];
        if (partnerId != null) {
          String teamId = Util.teamId([player.playerId, partnerId]);
          for (Game g in data.games) {
            if (g.teamIds.contains(teamId)) {
              int teamIndex = g.teamIds.indexOf(teamId);
              teamColors[playerIndex % 2] = g.teamColors[teamIndex];
              break;
            }
          }
        }
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
