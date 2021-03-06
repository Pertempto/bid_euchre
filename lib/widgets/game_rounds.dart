import 'package:bideuchre/data/data_store.dart';
import 'package:bideuchre/data/game.dart';
import 'package:bideuchre/data/player.dart';
import 'package:bideuchre/data/round.dart';
import 'package:bideuchre/widgets/player_selection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import '../util.dart';
import 'game_detail.dart';
import 'player_profile.dart';
import 'team_profile.dart';

class GameRounds extends StatefulWidget {
  final Game game;
  final bool isSummary;

  GameRounds(this.game, {this.isSummary = false});

  @override
  _GameRoundsState createState() => _GameRoundsState();
}

class _GameRoundsState extends State<GameRounds>
    with AutomaticKeepAliveClientMixin<GameRounds>, TickerProviderStateMixin {
  Game game;
  bool isSummary;
  Data data;

  AnimationController confettiController;
  TextTheme textTheme;
  bool gameIsLocked = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    confettiController = AnimationController(vsync: this, duration: Duration(seconds: 10));
    super.initState();
  }

  @override
  void dispose() {
    confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    game = widget.game;
    isSummary = widget.isSummary;
    data = DataStore.currentData;
    textTheme = Theme.of(context).textTheme;

    List<Widget> rows = [SizedBox(height: 8)];
    EdgeInsets rowPadding = EdgeInsets.fromLTRB(16, 0, 4, 0);
    for (Round round in game.rounds) {
      List<String> playerIds = game.getPlayerIdsAfterRound(round.roundIndex - 1);
      List<int> score = game.getScoreAfterRound(round.roundIndex);
      Widget scoreSection = Expanded(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(Util.scoreString(score[0]), style: textTheme.bodyText1.copyWith(color: game.teamColors[0])),
            Padding(padding: EdgeInsets.fromLTRB(1, 0, 1, 0), child: Text('-', style: textTheme.bodyText1)),
            Text(Util.scoreString(score[1]), style: textTheme.bodyText1.copyWith(color: game.teamColors[1])),
          ],
        ),
        flex: 8,
      );
      if (round.isPlayerSwitch) {
        String newPlayerName = data.allPlayers[round.newPlayerId].shortName;
        String oldPlayerName = data.allPlayers[playerIds[round.switchingPlayerIndex]].shortName;
        Color teamColor = game.teamColors[round.switchingPlayerIndex % 2];
        rows.add(
          Container(
            width: double.infinity,
            padding: rowPadding,
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text('$newPlayerName replaced $oldPlayerName',
                      style: textTheme.bodyText1
                          .copyWith(color: teamColor, fontWeight: FontWeight.w400, fontStyle: FontStyle.italic)),
                  flex: 24,
                ),
                scoreSection,
              ],
            ),
          ),
        );
      } else {
        String dealerName = '';
        Color dealerTeamColor = Colors.transparent;
        if (round.dealerIndex != null) {
          dealerName = data.allPlayers[playerIds[round.dealerIndex]].shortName;
          dealerTeamColor = game.teamColors[round.dealerIndex % 2];
        }
        String bidderName = '';
        Color bidderTeamColor = Colors.transparent;
        String bidString = '';
        if (round.bid != null) {
          bidderName = data.allPlayers[playerIds[round.bidderIndex]].shortName;
          bidderTeamColor = game.teamColors[round.bidderIndex % 2];
          bidString = round.bid.toString();
        }
        String madeString = '';
        if (round.wonTricks == null) {
          scoreSection = Expanded(child: Container(), flex: 8);
        } else {
          madeString = round.wonTricks.toString();
        }
        rows.add(
          Container(
            width: double.infinity,
            padding: rowPadding,
            child: Row(
              children: <Widget>[
                Expanded(
                  child: GestureDetector(
                    child: Text(dealerName, style: textTheme.bodyText1.copyWith(color: dealerTeamColor)),
                    onTap: dealerName == ''
                        ? null
                        : () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        PlayerProfile(data.allPlayers[playerIds[round.dealerIndex]])));
                          },
                  ),
                  flex: 8,
                ),
                Expanded(
                  child: GestureDetector(
                    child: Text(bidderName, style: textTheme.bodyText1.copyWith(color: bidderTeamColor)),
                    onTap: bidderName == ''
                        ? null
                        : () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        PlayerProfile(data.allPlayers[playerIds[round.bidderIndex]])));
                          },
                  ),
                  flex: 8,
                ),
                Expanded(
                  child: Text(
                    bidString,
                    style: textTheme.bodyText1.copyWith(fontWeight: FontWeight.w400),
                    textAlign: TextAlign.center,
                  ),
                  flex: 3,
                ),
                Expanded(
                  child: Text(
                    madeString,
                    style: textTheme.bodyText1.copyWith(fontWeight: FontWeight.w400),
                    textAlign: TextAlign.center,
                  ),
                  flex: 5,
                ),
                scoreSection,
              ],
            ),
          ),
        );
      }
      rows.add(Divider());
    }

    if (isSummary) {
      rows.add(Padding(
        padding: EdgeInsets.fromLTRB(8, 16, 8, 32),
        child: OutlineButton(
          child: Text('Open Game'),
          onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => GameDetail(game)));
          },
        ),
      ));
    } else {
      Color iconColor = Colors.blueGrey;
      if (game.isFinished && gameIsLocked) {
        int winningTeamIndex = game.winningTeamIndex;
        String winningTeamName = game.getTeamName(winningTeamIndex, data);
        rows.add(Padding(
          padding: EdgeInsets.fromLTRB(8, 16, 8, 32),
          child: Column(
            children: <Widget>[
              Text(
                '$winningTeamName won!!',
                style: textTheme.headline5.copyWith(color: game.teamColors[winningTeamIndex]),
              ),
              Stack(
                children: <Widget>[
                  Align(
                    alignment: Alignment.center,
                    child: OutlineButton(
                      child: Text('Celebrate!'),
                      onPressed: () {
                        confettiController.reset();
                        confettiController.forward();
                      },
                    ),
                  ),
                  if (game.userId == data.currentUser.userId)
                    Align(
                      alignment: Alignment.centerRight,
                      child: IconButton(
                        icon: Icon(MdiIcons.lockOpen),
                        color: iconColor,
                        onPressed: () {
                          setState(() {
                            gameIsLocked = false;
                          });
                        },
                      ),
                    ),
                ],
              ),
            ],
          ),
        ));
      } else {
        if (game.userId == data.currentUser.userId) {
          rows.add(Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(8, 0, 8, 0),
            child: Wrap(
              alignment: WrapAlignment.end,
              children: <Widget>[
                IconButton(
                  icon: Icon(Icons.undo),
                  color: iconColor,
                  onPressed: onUndoClick,
                ),
                IconButton(
                  icon: Icon(MdiIcons.accountSwitch),
                  color: iconColor,
                  onPressed: onSubstituteClick,
                ),
                IconButton(
                  icon: Icon(Icons.add),
                  color: iconColor,
                  onPressed: onAddClick,
                ),
              ],
            ),
          ));
          if (game.isFinished && !gameIsLocked) {
            rows.add(Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(8, 0, 8, 0),
              child: Row(
                children: <Widget>[
                  Spacer(),
                  IconButton(
                    icon: Icon(Icons.lock),
                    color: iconColor,
                    onPressed: () {
                      setState(() {
                        gameIsLocked = true;
                      });
                    },
                  ),
                ],
              ),
            ));
          }
          rows.add(SizedBox(height: 16));
        } else {
          rows.add(SizedBox(height: 32));
        }
      }
    }
    TextStyle headerStyle = textTheme.subtitle2;
    Widget body = Container(
      width: double.infinity,
      color: Colors.white,
      child: Column(
        children: <Widget>[
          Material(
            elevation: 1,
            color: Colors.white,
            child: Column(
              children: <Widget>[
                gameHeader(game, data, textTheme, context),
                Container(
                  width: double.infinity,
                  alignment: Alignment.center,
                  padding: EdgeInsets.fromLTRB(16, 0, 16, 0),
                  child: Text(game.dateString, style: textTheme.caption),
                ),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.fromLTRB(16, 4, 4, 4),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Text('Dealer', style: headerStyle),
                        flex: 8,
                      ),
                      Expanded(
                        child: Text('Bidder', style: headerStyle),
                        flex: 8,
                      ),
                      Expanded(
                        child: Text('Bid', style: headerStyle, textAlign: TextAlign.center),
                        flex: 3,
                      ),
                      Expanded(
                        child: Text('Won', style: headerStyle, textAlign: TextAlign.center),
                        flex: 5,
                      ),
                      Expanded(
                        child: Text('Score', style: headerStyle, textAlign: TextAlign.center),
                        flex: 8,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: rows,
              ),
            ),
          ),
        ],
      ),
    );
    if (isSummary) {
      return ClipRRect(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
        child: body,
      );
    }
    List<Color> confettiColors = [
      game.winningTeamIndex != null ? game.teamColors[game.winningTeamIndex] : Colors.white
    ];
    return Container(
      width: double.infinity,
      height: double.infinity,
      child: Util.confettiStack(
          child: body,
          context: context,
          controller: confettiController,
          settings: data.currentUser.confettiSettings,
          colors: confettiColors),
    );
  }

  onAddClick() {
    if (game.rounds.isEmpty) {
      setState(() {
        game.newRound(0);
      });
      return;
    }
    Round lastRound = game.rounds.last;
    if (lastRound.isPlayerSwitch) {
      int dealerIndex = 0;
      for (Round round in game.rounds.reversed) {
        if (!round.isPlayerSwitch) {
          dealerIndex = (round.dealerIndex + 1) % 4;
          break;
        }
      }
      setState(() {
        game.newRound(dealerIndex);
      });
    } else if (lastRound.bid == null) {
      selectBid();
    } else if (lastRound.wonTricks == null) {
      selectRoundResult();
    } else {
      setState(() {
        game.newRound((lastRound.dealerIndex + 1) % 4);
      });
    }
  }

  onSubstituteClick() {
    List<String> playerIds = game.getPlayerIdsAfterRound(game.rounds.length - 1);

    int selectedPlayerIndex = 0;
    String selectedPlayerId;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(builder: (context, innerSetState) {
          return Wrap(
            children: <Widget>[
              Container(
                padding: EdgeInsets.fromLTRB(12, 12, 12, 0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Container(
                        width: double.infinity,
                        child: Text(
                          'Replace Player',
                          style: textTheme.headline6,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      SizedBox(height: 16),
                      Text('Old Player', style: textTheme.subtitle1),
                      Container(
                        width: double.infinity,
                        child: CupertinoSlidingSegmentedControl(
                          children: Map.fromIterable(
                            [0, 1, 2, 3],
                            key: (i) => i,
                            value: (i) => Text(data.allPlayers[playerIds[i]].shortName),
                          ),
                          onValueChanged: (value) {
                            innerSetState(() {
                              selectedPlayerIndex = value;
                            });
                          },
                          groupValue: selectedPlayerIndex,
                        ),
                      ),
                      SizedBox(height: 16),
                      Text('New Player', style: textTheme.subtitle1),
                      Row(
                        children: <Widget>[
                          Text(
                            selectedPlayerId == null ? '' : data.allPlayers[selectedPlayerId].fullName,
                            style: textTheme.bodyText1,
                          ),
                          Spacer(),
                          OutlineButton(
                            child: Text('Select Player'),
                            onPressed: () {
                              Navigator.push(context, MaterialPageRoute(builder: (context) => PlayerSelection()))
                                  .then((value) {
                                if (value != null) {
                                  innerSetState(() {
                                    selectedPlayerId = value.playerId;
                                  });
                                }
                              });
                            },
                          ),
                        ],
                      ),
                      Row(
                        children: <Widget>[
                          FlatButton(
                            child: Text('Cancel'),
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                          ),
                          Spacer(),
                          FlatButton(
                            child: Text('Replace'),
                            onPressed: selectedPlayerId == null
                                ? null
                                : () {
                                    setState(() {
                                      Navigator.of(context).pop();
                                      game.replacePlayer(selectedPlayerIndex, selectedPlayerId);
                                      int dealerIndex = 0;
                                      for (Round round in game.rounds.reversed) {
                                        if (!round.isPlayerSwitch) {
                                          dealerIndex = (round.dealerIndex + 1) % 4;
                                          break;
                                        }
                                      }
                                      game.newRound(dealerIndex);
                                      game.updateFirestore();
                                    });
                                  },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        });
      },
    );
  }

  onUndoClick() {
    if (game.rounds.isNotEmpty) {
      game.undoLastAction();
      if (game.rounds.isEmpty) {
        game.newRound(0);
      }
      game.updateFirestore();
    }
  }

  selectBid() {
    Round lastRound = game.rounds.last;
    List<String> playerIds = game.getPlayerIdsAfterRound(lastRound.roundIndex - 1);
    int selectedDealerIndex = 0;
    if (lastRound.dealerIndex != null) {
      selectedDealerIndex = lastRound.dealerIndex;
    }
    int selectedBidderIndex = (selectedDealerIndex + 1) % 4;
    int selectedBid = 3;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(builder: (context, innerSetState) {
          return Wrap(
            children: <Widget>[
              Container(
                padding: EdgeInsets.fromLTRB(12, 12, 12, 0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Container(
                        width: double.infinity,
                        child: Text(
                          'Add Bid',
                          style: textTheme.headline6,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      SizedBox(height: 16),
                      Text('Dealer', style: textTheme.subtitle1),
                      Container(
                        width: double.infinity,
                        child: CupertinoSlidingSegmentedControl(
                          children: Map.fromIterable(
                            [0, 1, 2, 3],
                            key: (i) => i,
                            value: (i) => Text(data.allPlayers[playerIds[i]].shortName),
                          ),
                          onValueChanged: (value) {
                            innerSetState(() {
                              selectedDealerIndex = value;
                            });
                          },
                          groupValue: selectedDealerIndex,
                        ),
                      ),
                      SizedBox(height: 16),
                      Text('Bidder', style: textTheme.subtitle1),
                      Container(
                        width: double.infinity,
                        child: CupertinoSlidingSegmentedControl(
                          children: Map.fromIterable(
                            [0, 1, 2, 3],
                            key: (i) => i,
                            value: (i) => Text(data.allPlayers[playerIds[i]].shortName),
                          ),
                          onValueChanged: (value) {
                            innerSetState(() {
                              selectedBidderIndex = value;
                            });
                          },
                          groupValue: selectedBidderIndex,
                        ),
                      ),
                      SizedBox(height: 16),
                      Text('Bid', style: textTheme.subtitle1),
                      Container(
                        width: double.infinity,
                        child: CupertinoSlidingSegmentedControl(
                          children: Map.fromIterable(
                            Round.ALL_BIDS,
                            key: (i) => i,
                            value: (i) {
                              if (i == 24) {
                                return Text('Alone');
                              } else if (i == 12) {
                                return Text('Slide');
                              } else {
                                return Text(i.toString());
                              }
                            },
                          ),
                          onValueChanged: (value) {
                            innerSetState(() {
                              selectedBid = value;
                            });
                          },
                          groupValue: selectedBid,
                        ),
                      ),
                      SizedBox(height: 16),
                      Row(
                        children: <Widget>[
                          FlatButton(
                            child: Text('Cancel'),
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                          ),
                          Spacer(),
                          FlatButton(
                            child: Text('Add'),
                            onPressed: () {
                              setState(() {
                                Navigator.of(context).pop();
                                game.addBid(selectedDealerIndex, selectedBidderIndex, selectedBid);
                                game.updateFirestore();
                              });
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        });
      },
    );
  }

  selectRoundResult() {
    Round lastRound = game.rounds.last;
    int selectedWonTricks = lastRound.bid > 6 ? 6 : lastRound.bid;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(builder: (context, innerSetState) {
          return Wrap(
            children: <Widget>[
              Container(
                padding: EdgeInsets.fromLTRB(12, 12, 12, 0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Container(
                        width: double.infinity,
                        child: Text(
                          'Add Result',
                          style: textTheme.headline6,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      SizedBox(height: 16),
                      Text('Won Tricks', style: textTheme.subtitle1),
                      Container(
                        width: double.infinity,
                        child: CupertinoSlidingSegmentedControl(
                          children:
                              Map.fromIterable([0, 1, 2, 3, 4, 5, 6], key: (i) => i, value: (i) => Text(i.toString())),
                          onValueChanged: (value) {
                            innerSetState(() {
                              selectedWonTricks = value;
                            });
                          },
                          groupValue: selectedWonTricks,
                        ),
                      ),
                      SizedBox(height: 16),
                      Row(
                        children: <Widget>[
                          FlatButton(
                            child: Text('Cancel'),
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                          ),
                          Spacer(),
                          FlatButton(
                            child: Text('Add'),
                            onPressed: () {
                              setState(() {
                                Navigator.of(context).pop();
                                game.addRoundResult(selectedWonTricks);
                                if (!game.isFinished) {
                                  game.newRound((lastRound.dealerIndex + 1) % 4);
                                }
                                game.updateFirestore();
                              });
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        });
      },
    );
  }
}

Widget gameHeader(Game game, Data data, TextTheme textTheme, BuildContext context) {
  List<Player> players = game.currentPlayerIds.map((id) => data.allPlayers[id]).toList();
  List<String> scoreStrings = game.currentScore.map(Util.scoreString).toList();
  Widget playerTitle(int index) {
    return GestureDetector(
      child: Text(
        players[index].shortName,
        style: textTheme.headline5.copyWith(color: game.teamColors[index % 2], height: 1.1),
      ),
      onTap: () {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) =>
                    TeamProfile(Util.teamId([players[index].playerId, players[(index + 2) % 4].playerId]))));
      },
    );
  }

  return Column(
    children: [
      Container(
        padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  playerTitle(0),
                  playerTitle(2),
                ],
              ),
              flex: 7,
            ),
            Expanded(
              child: Text('vs', textAlign: TextAlign.center),
              flex: 1,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  playerTitle(1),
                  playerTitle(3),
                ],
              ),
              flex: 7,
            ),
          ],
        ),
      ),
      Container(
        width: double.infinity,
        alignment: Alignment.center,
        padding: EdgeInsets.fromLTRB(16, 0, 16, 0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Expanded(
              child: Text(
                scoreStrings[0],
                style:
                    textTheme.headline5.copyWith(fontWeight: FontWeight.w900, fontSize: 40, color: game.teamColors[0]),
                textAlign: TextAlign.end,
              ),
              flex: 7,
            ),
            Expanded(child: Text('-', style: textTheme.headline5, textAlign: TextAlign.center), flex: 1),
            Expanded(
              child: Text(
                scoreStrings[1],
                style:
                    textTheme.headline5.copyWith(fontWeight: FontWeight.w900, fontSize: 40, color: game.teamColors[1]),
                textAlign: TextAlign.start,
              ),
              flex: 7,
            ),
          ],
        ),
      ),
    ],
  );
}
