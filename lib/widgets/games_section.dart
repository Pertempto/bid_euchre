import 'package:bideuchre/data/data_store.dart';
import 'package:bideuchre/data/game.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;

import '../util.dart';
import 'game_overview.dart';

class GamesSection extends StatefulWidget {
  final String id;

  GamesSection(this.id);

  @override
  _GamesSectionState createState() => _GamesSectionState();
}

class _GamesSectionState extends State<GamesSection>
    with AutomaticKeepAliveClientMixin<GamesSection>, SingleTickerProviderStateMixin {
  String id;
  Data data;

  bool get wantKeepAlive => true;

  bool get isTeam => id.contains(' ');

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    id = widget.id;
    data = DataStore.lastData;
    List<Game> games = data.statsDb.getEntityGames(id);
    if (games.isEmpty) {
      return Container();
    }

    Map<String, String> gameStatuses = {};
    Map<String, bool> flipScores = {};
    for (Game game in games) {
      List<String> teamsIds = game.teamIds;
      List<Set<String>> teamsPlayerIds = game.allTeamsPlayerIds;
      if (isTeam) {
        flipScores[game.gameId] = teamsIds[1] == id;
      } else {
        flipScores[game.gameId] = !teamsPlayerIds[0].contains(id);
      }
      if (!game.isFinished) {
        gameStatuses[game.gameId] = 'In Progress';
      } else {
        if (isTeam) {
          if (teamsIds[game.winningTeamIndex] == id) {
            gameStatuses[game.gameId] = 'Won';
          } else {
            gameStatuses[game.gameId] = 'Lost';
          }
        } else {
          if (game.fullGamePlayerIds.contains(id)) {
            if (teamsPlayerIds[game.winningTeamIndex].contains(id)) {
              gameStatuses[game.gameId] = 'Won';
            } else {
              gameStatuses[game.gameId] = 'Lost';
            }
          } else {
            gameStatuses[game.gameId] = 'Partial';
          }
        }
      }
    }
    TextTheme textTheme = Theme.of(context).textTheme;
    List<Widget> children = [
      ListTile(
        title: Text('Games', style: textTheme.headline6),
        dense: true,
      ),
    ];
    children.add(Container(
      height: 126,
      child: ListView.builder(
        itemBuilder: (context, index) {
          if (index == 0 || index == games.length + 1) {
            return Container(width: 16);
          }
          Game game = games[index - 1];
          List<int> score = game.currentScore;
          List<Widget> scoreChildren = [
            Text(Util.scoreString(score[0]), style: textTheme.headline4.copyWith(color: game.teamColors[0])),
            Padding(padding: EdgeInsets.fromLTRB(1, 0, 1, 0), child: Text('-', style: textTheme.headline5)),
            Text(Util.scoreString(score[1]), style: textTheme.headline4.copyWith(color: game.teamColors[1])),
          ];
          if (flipScores[game.gameId]) {
            scoreChildren = scoreChildren.reversed.toList();
          }
          DateTime date = DateTime.fromMillisecondsSinceEpoch(game.timestamp);
          String dateString = intl.DateFormat.yMd().format(date);
          String timeString = intl.DateFormat.jm().format(date);
          double rating = data.statsDb.getRatingAfterGame(id, game.gameId);
          String ratingString = 'OVR: ${rating.toStringAsFixed(1)}';
          return Card(
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                constraints: BoxConstraints(
                  minWidth: 100,
                ),
                margin: EdgeInsets.all(8),
                child: Column(
                  children: <Widget>[
                    Text(gameStatuses[game.gameId], style: textTheme.bodyText1),
                    Row(children: scoreChildren),
                    Text(ratingString, style: textTheme.bodyText2),
                    Text(dateString, style: textTheme.caption),
                    Text(timeString, style: textTheme.caption),
                  ],
                ),
              ),
              onTap: () {
                if (game.userId == data.currentUser.userId ||
                    data.relationshipsDb.canShare(game.userId, data.currentUser.userId)) {
                  showModalBottomSheet(
                    context: context,
                    backgroundColor: Colors.transparent,
                    builder: (context) {
                      return GameOverview(game, isSummary: true);
                    },
                  );
                } else {
                  print(game.gameId);
                  Scaffold.of(context).showSnackBar(SnackBar(
                    content: Text('You don\'t have permission to view this game!'),
                  ));
                }
              },
            ),
          );
        },
        scrollDirection: Axis.horizontal,
        itemCount: games.length + 2,
        shrinkWrap: true,
      ),
    ));
    children.add(Divider());
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: children);
  }
}
