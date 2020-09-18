import 'package:bideuchre/data/data_store.dart';
import 'package:bideuchre/data/game.dart';
import 'package:bideuchre/data/player.dart';
import 'package:bideuchre/data/stats.dart';
import 'package:bideuchre/widgets/player_selection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

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
          gameOverScore = 42;
        } else {
          initialPlayerIds = copyGame.currentPlayerIds;
          for (int i = 0; i < 4; i++) {
            // don't copy over players that the current user doesn't have permission to use
            if (!data.players.containsKey(initialPlayerIds[i])) {
              initialPlayerIds[i] = null;
            }
          }
          gameOverScore = copyGame.gameOverScore;
        }
        updateTeamColors();
      }
      List<List<String>> teamCombos = [];
      if (!initialPlayerIds.contains(null)) {
        teamCombos = getTeamCombos();
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
          title: Text('Team Combos', style: leadingStyle),
          dense: true,
        ));
        List<Widget> comboWidgets = [];
        for (List<String> playerIds in teamCombos) {
          String team1Id = Util.teamId([playerIds[0], playerIds[2]]);
          String team2Id = Util.teamId([playerIds[1], playerIds[3]]);
          List<Color> teamColors = [data.statsDb.getEntityColor(team1Id), data.statsDb.getEntityColor(team2Id)];
          List<double> winProbs = data.statsDb.calculateWinChances(playerIds, [0, 0], gameOverScore);
          comboWidgets.add(InkWell(
            onTap: () {
              setState(() {
                initialPlayerIds = playerIds;
                updateTeamColors();
              });
            },
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(Util.teamName(team1Id, data),
                            style: textTheme.bodyText1.copyWith(color: teamColors[0])),
                        flex: 4,
                      ),
                      Expanded(
                        child: Text(
                          'vs',
                          style: textTheme.bodyText1,
                          textAlign: TextAlign.center,
                        ),
                        flex: 1,
                      ),
                      Expanded(
                        child: Text(
                          Util.teamName(team2Id, data),
                          style: textTheme.bodyText1.copyWith(color: teamColors[1]),
                          textAlign: TextAlign.end,
                        ),
                        flex: 4,
                      ),
                    ],
                  ),
                  Util.winProbsBar(winProbs, teamColors, context),
                ],
              ),
            ),
          ));
        }
        children.add(Column(children: comboWidgets));
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

  List<List<String>> getTeamCombos() {
    List<List<String>> combos = [];
    List<String> sortedPlayerIds = initialPlayerIds.toList();
    sortedPlayerIds.sort((a, b) {
      double sa = data.statsDb.getStat(a, StatType.overallRating).sortValue;
      double sb = data.statsDb.getStat(b, StatType.overallRating).sortValue;
      return sa.compareTo(sb);
    });
    Map<String, double> diffMap = {};
    for (int i = 0; i < 3; i++) {
      List<String> playerIds = [];
      switch (i) {
        case 0:
          playerIds = [sortedPlayerIds[0], sortedPlayerIds[2], sortedPlayerIds[1], sortedPlayerIds[3]];
          break;
        case 1:
          playerIds = [sortedPlayerIds[0], sortedPlayerIds[1], sortedPlayerIds[2], sortedPlayerIds[3]];
          break;
        case 2:
          playerIds = [sortedPlayerIds[0], sortedPlayerIds[1], sortedPlayerIds[3], sortedPlayerIds[2]];
          break;
      }
      List<double> chances = data.statsDb.calculateWinChances(playerIds, [0, 0], gameOverScore);
      // put the team with the better chances first
      if (chances[0] < chances[1]) {
        String tempId = playerIds[0];
        playerIds[0] = playerIds[1];
        playerIds[1] = tempId;
        tempId = playerIds[2];
        playerIds[2] = playerIds[3];
        playerIds[3] = tempId;
      }
      combos.add(playerIds);
      diffMap[playerIds.toString()] = (chances[0] - chances[1]).abs();
    }
    combos.sort((a, b) => diffMap[a.toString()].compareTo(diffMap[b.toString()]));
    return combos;
  }

  selectPlayer(int playerIndex) async {
    Player player = await Navigator.push(context, MaterialPageRoute(builder: (context) => PlayerSelection()));
    if (player != null) {
      setState(() {
        print('player name: ${player.fullName}');
        initialPlayerIds[playerIndex] = player.playerId;
        updateTeamColors();
      });
    }
  }

  updateTeamColors() {
    teamColors = [Colors.black, Colors.black];
    for (int i = 0; i < 2; i++) {
      if (initialPlayerIds[i] != null && initialPlayerIds[i + 2] != null) {
        String teamId = Util.teamId([initialPlayerIds[i], initialPlayerIds[i + 2]]);
        Color teamColor = data.statsDb.getEntityColor(teamId);
        teamColors[i] = teamColor;
      }
    }
  }
}
