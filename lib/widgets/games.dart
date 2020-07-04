import 'package:bideuchre/data/data_store.dart';
import 'package:bideuchre/data/game.dart';
import 'package:bideuchre/data/user.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'game_detail.dart';
import 'new_game.dart';

class GamesPage extends StatefulWidget {
  GamesPage();

  @override
  _GamesPageState createState() => _GamesPageState();
}

class _GamesPageState extends State<GamesPage> {
  bool showFriendsGames = false;
  Data data;
  List<Game> filteredGames;
  TextTheme textTheme;
  ScrollController scrollController;
  bool atScrollTop = true;

  @override
  void initState() {
    scrollController = ScrollController();
    scrollController.addListener(() {
      setState(() {
        atScrollTop = scrollController.offset < 50;
      });
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
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
      Widget header = Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: RaisedButton(
              child: Text(
                'Start New Game',
                style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.w500),
              ),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => NewGame()));
              },
            ),
          ),
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: CupertinoSlidingSegmentedControl(
              children: {
                false: Text('My Games'),
                true: Text('Friends\' Games'),
              },
              onValueChanged: (value) {
                setState(() {
                  showFriendsGames = value;
                });
              },
              groupValue: showFriendsGames,
            ),
          ),
        ],
      );

      return Scaffold(
        appBar: AppBar(title: Text('Games')),
        body: Column(
          // workaround for shadow https://github.com/flutter/flutter/issues/12206
          verticalDirection: VerticalDirection.up,
          children: <Widget>[
            Material(
              elevation: 1,
              child: Container(
                width: double.infinity,
                child: header,
              ),
            ),
            Expanded(
              child: Stack(
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
                    itemCount: (filteredGames.length + 1),
                    itemBuilder: (context, index) {
                      if (index == filteredGames.length) {
                        return SizedBox(height: 64);
                      }
                      return gameCard(filteredGames[index]);
                    },
                  ),
                  if (!atScrollTop)
                    Align(
                      alignment: Alignment.bottomRight,
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: FloatingActionButton(
                          mini: true,
                          child: Icon(Icons.arrow_upward),
                          onPressed: () {
                            scrollController.animateTo(0, duration: Duration(milliseconds: 500), curve: Curves.linear);
                          },
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ].reversed.toList(),
        ),
      );
    });
  }

  Widget gameCard(Game game) {
    List<Widget> children = [];
    for (int i = 0; i < 2; i++) {
      children.add(Row(
        children: <Widget>[
          Text(game.getTeamName(i, data), style: textTheme.headline5.copyWith(color: game.teamColors[i])),
          Spacer(),
          Text(game.currentScore[i].toString(),
              style: textTheme.headline6.copyWith(fontWeight: FontWeight.w300, color: game.teamColors[i])),
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
