import 'package:bideuchre/data/data_store.dart';
import 'package:bideuchre/data/game.dart';
import 'package:bideuchre/data/stat_item.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import '../util.dart';
import 'game_rounds.dart';

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
    data = DataStore.currentData;
    List<Game> games = data.statsDb.getGames(id, DataStore.displayArchivedStats);
    if (games.isEmpty) {
      return Container();
    }
    OverallRatingStatItem ovrRating =
        OverallRatingStatItem.fromRawStats(games.map((g) => g.rawStatsMap[id]).toList(), isTeam);
    BidderRatingStatItem bidderRating =
        BidderRatingStatItem.fromRawStats(games.map((g) => g.rawStatsMap[id]).toList(), isTeam);
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
      height: 114,
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
          OverallRatingStatItem gameRating = OverallRatingStatItem.fromRawStats([game.rawStatsMap[id]], isTeam);
          BidderRatingStatItem gameBidderRating = BidderRatingStatItem.fromRawStats([game.rawStatsMap[id]], isTeam);
          return Card(
            color: game.isArchived ? Colors.grey[50] : Colors.white,
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                constraints: BoxConstraints(
                  minWidth: 100,
                ),
                margin: EdgeInsets.all(8),
                child: Column(
                  children: <Widget>[
                    Container(
                      width: 100,
                      child: Row(
                        children: [
                          Icon(
                            gameRating.rating > ovrRating.rating ? MdiIcons.chevronUp : MdiIcons.chevronDown,
                            color: gameRating.rating > ovrRating.rating ? Colors.green : Colors.red,
                          ),
                          Text(gameStatuses[game.gameId], style: textTheme.bodyText1),
                          Icon(
                            gameBidderRating.rating > bidderRating.rating ? MdiIcons.chevronUp : MdiIcons.chevronDown,
                            color: gameBidderRating.rating > bidderRating.rating ? Colors.green : Colors.red,
                          ),
                        ],
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      ),
                    ),
                    Row(children: scoreChildren),
                    Text(dateString, style: textTheme.caption),
                    Text(game.isArchived ? 'Archived' : timeString, style: textTheme.caption),
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
                      return GameRounds(game, isSummary: true);
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
