import 'package:bideuchre/data/data_store.dart';
import 'package:bideuchre/data/game.dart';
import 'package:bideuchre/data/user.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'game_detail.dart';
import 'new_game.dart';

class GamesList extends StatefulWidget {
  final bool showSharedGames;

  GamesList(this.showSharedGames);

  @override
  _GamesListState createState() => _GamesListState();
}

class _GamesListState extends State<GamesList> with AutomaticKeepAliveClientMixin<GamesList> {
  bool showSharedGames;
  Data data;
  List<Game> filteredGames;
  TextTheme textTheme;

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    showSharedGames = widget.showSharedGames;
    textTheme = Theme.of(context).textTheme;
    return DataStore.dataWrap((data) {
      this.data = data;
      if (showSharedGames) {
        filteredGames = data.games
            .where((g) => (g.userId != data.currentUser.userId &&
                data.relationshipsDb.canShare(g.userId, data.currentUser.userId)))
            .toList();
      } else {
        filteredGames = data.games.where((g) => (g.userId == data.currentUser.userId)).toList();
      }
      // bring unfinished games to the top
      List<Game> finishedGames = filteredGames.where((g) => g.isFinished).toList();
      List<Game> unfinishedGames = filteredGames.where((g) => !g.isFinished).toList();
      filteredGames = unfinishedGames + finishedGames;

      return Stack(
        children: <Widget>[
          if (filteredGames.isEmpty)
            Container(
              alignment: Alignment.center,
              width: double.infinity,
              padding: EdgeInsets.all(16),
              child: Text(
                showSharedGames ? 'No shared games!' : 'Start a game to see it here!',
                textAlign: TextAlign.center,
                style: textTheme.bodyText1,
              ),
            ),
          ListView.builder(
            itemCount: showSharedGames ? (filteredGames.length + 1) : (filteredGames.length + 2),
            itemBuilder: (context, index) {
              if (!showSharedGames) {
                if (index == 0) {
                  return Container(
                    padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
                    width: double.infinity,
                    child: RaisedButton(
                      child: Text(
                        'Start New Game',
                        style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.w500),
                      ),
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => NewGame()));
                      },
                    ),
                  );
                }
                if (index == filteredGames.length + 1) {
                  return SizedBox(height: 64);
                }
                return gameCard(filteredGames[index - 1]);
              } else {
                if (index == filteredGames.length) {
                  return SizedBox(height: 64);
                }
                return gameCard(filteredGames[index]);
              }
            },
          ),
        ],
      );
    });
  }

  Widget gameCard(Game game) {
    List<Widget> children = [];
    for (int i = 0; i < 2; i++) {
      children.add(Row(
        children: <Widget>[
          Text(game.getTeamName(i, data), style: textTheme.headline6.copyWith(color: game.teamColors[i])),
          Spacer(),
          Text(game.currentScore[i].toString(),
              style: textTheme.headline6.copyWith(fontWeight: FontWeight.w900, color: game.teamColors[i])),
        ],
      ));
    }
    User owner = data.users[game.userId];
    String statusString;
    if (game.isFinished) {
      statusString = 'Finished';
    } else {
      statusString = 'In Progress';
    }
    children.add(Padding(
      padding: EdgeInsets.only(top: 4),
      child: Row(
        children: <Widget>[
          Text('${game.dateString} - ${owner.name}', style: textTheme.caption),
          Spacer(),
          Text(statusString,
              style: game.isFinished
                  ? textTheme.caption
                  : textTheme.subtitle2.copyWith(fontSize: textTheme.caption.fontSize)),
        ],
      ),
    ));
    return GestureDetector(
      child: Card(
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
      ),
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => GameDetail(game)));
      },
    );
  }
}
