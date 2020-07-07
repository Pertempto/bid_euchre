import 'package:bideuchre/data/data_store.dart';
import 'package:bideuchre/data/game.dart';
import 'package:bideuchre/data/user.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'game_detail.dart';
import 'new_game.dart';

class GamesList extends StatefulWidget {
  final bool showFriendsGames;

  GamesList(this.showFriendsGames);

  @override
  _GamesListState createState() => _GamesListState();
}

class _GamesListState extends State<GamesList> with AutomaticKeepAliveClientMixin<GamesList> {
  bool showFriendsGames;
  Data data;
  List<Game> filteredGames;
  TextTheme textTheme;
  ScrollController scrollController;
  bool atScrollTop = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    scrollController = ScrollController();
    scrollController.addListener(() {
      setState(() {
        atScrollTop = scrollController.offset < 8;
      });
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    showFriendsGames = widget.showFriendsGames;
    textTheme = Theme.of(context).textTheme;
    return DataStore.dataWrap((data) {
      this.data = data;
      if (showFriendsGames) {
        filteredGames =
            data.games.where((g) => (data.friendsDb.areFriends(g.userId, data.currentUser.userId))).toList();
      } else {
        filteredGames = data.games.where((g) => (g.userId == data.currentUser.userId)).toList();
      }
      // bring unfinished games to the top
      List<Game> finishedGames = filteredGames.where((g) => g.isFinished).toList();
      List<Game> unfinishedGames = filteredGames.where((g) => !g.isFinished).toList();
      filteredGames = unfinishedGames + finishedGames;

      return Stack(
        children: <Widget>[
          if (filteredGames.isEmpty && !showFriendsGames)
            Container(
              alignment: Alignment.center,
              width: double.infinity,
              padding: EdgeInsets.all(16),
              child: Text(
                'Start a game to see it here!',
                textAlign: TextAlign.center,
                style: textTheme.bodyText1,
              ),
            ),
          ListView.builder(
            controller: scrollController,
            itemCount: showFriendsGames ? (filteredGames.length + 1) : (filteredGames.length + 2),
            itemBuilder: (context, index) {
              if (!showFriendsGames) {
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
          if (!atScrollTop)
            Container(
              alignment: Alignment.bottomRight,
              padding: EdgeInsets.all(16.0),
              child: FloatingActionButton(
                heroTag: 'scrollToTopBtn$showFriendsGames',
                mini: true,
                child: Icon(Icons.arrow_upward),
                onPressed: () {
                  scrollController.animateTo(0, duration: Duration(milliseconds: 500), curve: Curves.linear);
                },
              ),
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
