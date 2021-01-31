import 'dart:math';

import 'package:bideuchre/data/data_store.dart';
import 'package:bideuchre/data/entity_raw_game_stats.dart';
import 'package:bideuchre/data/game.dart';
import 'package:bideuchre/data/player.dart';
import 'package:bideuchre/data/round.dart';
import 'package:bideuchre/data/stat_item.dart';
import 'package:bideuchre/data/stat_type.dart';
import 'package:bideuchre/util.dart';
import 'package:bideuchre/widgets/player_profile.dart';
import 'package:bideuchre/widgets/player_selection.dart';
import 'package:bideuchre/widgets/team_profile.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';

class GameOverview extends StatefulWidget {
  final Game game;
  final bool isSummary;

  GameOverview(this.game, {this.isSummary = false});

  @override
  _GameOverviewState createState() => _GameOverviewState();
}

class _GameOverviewState extends State<GameOverview>
    with AutomaticKeepAliveClientMixin<GameOverview>, TickerProviderStateMixin {
  Game game;
  Data data;

  AnimationController confettiController;
  TextTheme textTheme;
  bool gameIsLocked = true;
  String selectedId;
  bool displayActions = true;

  @override
  bool get wantKeepAlive => true;

  bool get isSelectedTeam => selectedId.contains(" ");

  bool get isSmallScreen => MediaQuery.of(context).size.height <= 600;

  Color get selectedTeamColor {
    int teamIndex;
    if (isSelectedTeam) {
      teamIndex = game.teamIds.indexOf(selectedId);
    } else {
      teamIndex = game.currentPlayerIds.indexOf(selectedId) % 2;
    }
    return game.teamColors[teamIndex];
  }

  String get selectedFullName {
    if (isSelectedTeam) {
      return Util.teamName(selectedId, data);
    } else {
      return data.allPlayers[selectedId].fullName;
    }
  }

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
    data = DataStore.currentData;
    textTheme = Theme.of(context).textTheme;

    if (selectedId != null) {
      if (isSelectedTeam) {
        if (!game.teamIds.contains(selectedId)) {
          selectedId = null;
        }
      } else {
        if (!game.currentPlayerIds.contains(selectedId)) {
          selectedId = null;
        }
      }
    }
    Widget body = Container(
      width: double.infinity,
      color: Colors.white,
      child: Column(
        children: [
          scoreHeader(context),
          playerLayout(context),
          Divider(),
          Expanded(child: bottomPane(context)),
        ],
      ),
    );

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

  onUndoClick() {
    if (game.rounds.isNotEmpty) {
      game.undoLastAction();
      if (game.rounds.isEmpty) {
        game.newRound(0);
      }
      game.updateFirestore();
    }
  }

  Widget scoreHeader(BuildContext context) {
    List<String> scoreStrings = game.currentScore.map((score) => score.toString()).toList();

    double height = MediaQuery.of(context).size.height;
    TextStyle scoreTextStyle = GoogleFonts.sourceCodePro().copyWith(
      color: Colors.white,
      fontSize: height * 0.08,
      fontWeight: FontWeight.w700,
    );
    return Row(
        children: List.generate(2, (index) {
      String teamId = game.teamIds[index];
      return Expanded(
        child: Container(
          margin: EdgeInsets.fromLTRB(index == 0 ? 8 : 4, 8, index == 0 ? 4 : 8, 4),
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              backgroundColor: selectedId == teamId ? Colors.white : game.teamColors[index],
              side: BorderSide(
                width: 4,
                color: game.teamColors[index],
              ),
              padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 2 : 8),
            ),
            child: Text(
              scoreStrings[index],
              style: scoreTextStyle.copyWith(color: selectedId == teamId ? game.teamColors[index] : Colors.white),
            ),
            onPressed: () {
              setState(() {
                confettiController.stop();
                if (selectedId == teamId) {
                  selectedId = null;
                } else {
                  selectedId = teamId;
                  if (game.winningTeamIndex == index) {
                    confettiController.reset();
                    confettiController.forward();
                  }
                }
              });
            },
          ),
        ),
      );
    }));
  }

  Widget playerLayout(BuildContext context) {
    return Column(
      children: List.generate(2, (playerY) {
        return Row(
          children: List.generate(2, (playerX) {
            int playerIndex;
            if (playerY == 0) {
              playerIndex = playerX;
            } else {
              playerIndex = 3 - playerX;
            }
            String playerId = game.currentPlayerIds[playerIndex];
            Player player = data.allPlayers[playerId];
            Color teamColor = game.teamColors[playerIndex % 2];
            List<String> captionStrings = [];
            if (game.isFinished) {
              EntityRawGameStats rawStats = game.rawStatsMap[playerId];
              captionStrings.add('Bidding Gained: ${rawStats.gainedOnBids}');
            } else {
              Round lastRound = game.rounds.last;
              if (!lastRound.isFinished) {
                if (lastRound.dealerIndex == playerIndex) {
                  captionStrings.add('Dealer');
                } else if ((lastRound.dealerIndex + 1) % 4 == playerIndex) {
                  captionStrings.add('Lead');
                }
                if (lastRound.bidderIndex == playerIndex) {
                  captionStrings.add('Bidder (${Round.bidString(lastRound.bid)})');
                }
              }
            }
            return Expanded(
                child: Container(
              padding: EdgeInsets.fromLTRB(4, 4, 4, 0),
              alignment: Alignment.center,
              child: FlatButton(
                color: selectedId == playerId ? Colors.grey[200] : null,
                padding: EdgeInsets.fromLTRB(12, 4, 12, 4),
                child: Column(
                  children: [
                    Text(player.shortName,
                        style: textTheme.headline4.copyWith(color: teamColor, fontSize: isSmallScreen ? 24 : null)),
                    if (captionStrings.isNotEmpty)
                      Text(captionStrings.join(', '),
                          style: textTheme.bodyText1.copyWith(fontSize: isSmallScreen ? 12 : null)),
                  ],
                ),
                onPressed: () {
                  setState(() {
                    confettiController.stop();
                    if (selectedId == playerId) {
                      selectedId = null;
                    } else {
                      selectedId = playerId;
                    }
                  });
                },
              ),
            ));
          }),
        );
      }),
    );
  }

  Widget bottomPane(BuildContext context) {
    if (selectedId == null) {
      return Container(
          padding: EdgeInsets.all(32),
          alignment: Alignment.center,
          child: Text(
            'Select a team or player to view them here',
            style: textTheme.subtitle1,
            textAlign: TextAlign.center,
          ));
    }

    List<Widget> children = [
      if (isSelectedTeam)
        Container(
          height: 40,
          padding: EdgeInsets.fromLTRB(0, 4, 0, 8),
          child: Text(
            selectedFullName,
            style: textTheme.headline5.copyWith(color: selectedTeamColor),
          ),
        ),
      if (game.userId == data.currentUser.userId && !isSelectedTeam && !game.isFinished)
        Container(
          width: double.infinity,
          height: 40,
          padding: EdgeInsets.fromLTRB(0, 0, 0, 8),
          child: CupertinoSlidingSegmentedControl(
            children: Map.fromIterable(
              [true, false],
              key: (i) => i,
              value: (i) => Text(i ? 'Actions' : 'Info'),
            ),
            onValueChanged: (value) {
              setState(() {
                displayActions = value;
              });
            },
            groupValue: displayActions,
          ),
        ),
    ];
    Widget bodyWidget;
    if (game.userId != data.currentUser.userId || game.isFinished || isSelectedTeam || !displayActions) {
      bodyWidget = infoSection();
    } else {
      bodyWidget = actionsSection();
    }
    children.add(Expanded(child: bodyWidget));
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: Column(children: children),
    );
  }

  Widget infoSection() {
    EntityRawGameStats rawStats = game.rawStatsMap[selectedId];
    int numRounds = game.numRounds;
    double biddingGainedPercent = 0;
    if (numRounds != 0) {
      biddingGainedPercent = rawStats.gainedOnBids / numRounds;
      if (isSelectedTeam) {
        biddingGainedPercent /= 2;
      }
      biddingGainedPercent = max(0, min(1, biddingGainedPercent));
    }
    double madeBidPercent = MadeBidPercentageStatItem.fromRawStats([rawStats], isSelectedTeam).percentage;
    BidderRatingStatItem thisGameBidderRating = BidderRatingStatItem.fromRawStats([rawStats], isSelectedTeam);
    SetterRatingStatItem thisGameSetterRating = SetterRatingStatItem.fromRawStats([rawStats], isSelectedTeam);
    BidderRatingStatItem bidderRating = data.statsDb.getStat(selectedId, StatType.bidderRating, false);
    BiddingFrequencyStatItem biddingFrequency = data.statsDb.getStat(selectedId, StatType.biddingFrequency, false);
    GainedPerBidStatItem gainedPerBid = data.statsDb.getStat(selectedId, StatType.gainedPerBid, false);
    return SingleChildScrollView(
      child: Column(children: [
        Column(
          children: [
            Text('Game Stats', style: textTheme.subtitle2),
            statBar('Bidding Points Gained', rawStats.gainedOnBids.toString(), biddingGainedPercent, selectedTeamColor),
            statBar('Made Bids', '${rawStats.madeBids}/${rawStats.numBids}', madeBidPercent, selectedTeamColor),
            statBar(
                'Bidder Rating', thisGameBidderRating.toString(), thisGameBidderRating.rating / 100, selectedTeamColor),
            statBar(
                'Setter Rating', thisGameSetterRating.toString(), thisGameSetterRating.rating / 100, selectedTeamColor),
          ],
        ),
        SizedBox(height: isSmallScreen ? 4 : 16),
        Column(
          children: [
            Text('Bidder Profile', style: textTheme.subtitle2),
            statBar('Bidder Rating', bidderRating.toString(), bidderRating.rating / 100, selectedTeamColor),
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Text('Bidding Freq', style: textTheme.bodyText2.copyWith(fontSize: isSmallScreen ? 12 : null)),
                      Spacer(),
                      Text(biddingFrequency.toString(),
                          style: textTheme.subtitle2.copyWith(fontSize: isSmallScreen ? 12 : null)),
                    ],
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Row(
                    children: [
                      Text('Gained Per Bid', style: textTheme.bodyText2.copyWith(fontSize: isSmallScreen ? 12 : null)),
                      Spacer(),
                      Text(gainedPerBid.toString(),
                          style: textTheme.subtitle2.copyWith(fontSize: isSmallScreen ? 12 : null)),
                    ],
                  ),
                )
              ],
            )
          ],
        ),
        SizedBox(height: 16),
        TextButton.icon(
          onPressed: () {
            if (isSelectedTeam) {
              Navigator.push(context, MaterialPageRoute(builder: (context) => TeamProfile(selectedId)));
            } else {
              Navigator.push(
                  context, MaterialPageRoute(builder: (context) => PlayerProfile(data.allPlayers[selectedId])));
            }
          },
          icon: Icon(isSelectedTeam ? Icons.people : Icons.person),
          label: Text('View Profile'),
        ),
        SizedBox(height: 8),
      ]),
    );
  }

  Widget actionsSection() {
    Round lastRound = game.rounds.last;

    Widget createActionButton({Icon icon, String label, VoidCallback onPressed}) {
      if (isSmallScreen) {
        return IconButton(icon: icon, onPressed: onPressed, tooltip: label);
      } else {
        return TextButton.icon(onPressed: onPressed, icon: icon, label: Text(label));
      }
    }

    List<Widget> children = [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          createActionButton(
            icon: Icon(MdiIcons.undo),
            label: 'Undo',
            onPressed: onUndoClick,
          ),
          createActionButton(
            icon: Icon(MdiIcons.accountSwitch),
            label: 'Replace',
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => PlayerSelection())).then((value) {
                if (value != null) {
                  game.replacePlayer(game.currentPlayerIds.indexOf(selectedId), value.playerId);
                  selectedId = value.playerId;
                  int dealerIndex = 0;
                  for (Round round in game.rounds.reversed) {
                    if (!round.isPlayerSwitch) {
                      dealerIndex = (round.dealerIndex + 1) % 4;
                      break;
                    }
                  }
                  game.newRound(dealerIndex);
                  game.updateFirestore();
                }
              });
            },
          ),
          if (lastRound.bidderIndex == null)
            createActionButton(
              icon: Icon(MdiIcons.accountCowboyHat),
              label: 'Make Dealer',
              onPressed: () {
                game.rounds.last.dealerIndex = game.currentPlayerIds.indexOf(selectedId);
                game.updateFirestore();
              },
            ),
        ],
      ),
      Spacer(),
    ];

    if (!lastRound.isPlayerSwitch) {
      if (lastRound.bidderIndex == null) {
        int selectedBid = 3;
        children.add(
          StatefulBuilder(
            builder: (context, innerSetState) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Bid', style: textTheme.subtitle2),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.fromLTRB(0, 2, 0, 4),
                    child: CupertinoSlidingSegmentedControl(
                      children: Map.fromIterable(
                        Round.ALL_BIDS,
                        key: (i) => i,
                        value: (i) => Text(Round.bidString(i)),
                      ),
                      onValueChanged: (value) {
                        innerSetState(() {
                          selectedBid = value;
                        });
                      },
                      groupValue: selectedBid,
                    ),
                  ),
                  SizedBox(height: isSmallScreen ? 4 : 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      RaisedButton.icon(
                        icon: Icon(Icons.add),
                        label: Text('Add Bid'),
                        onPressed: () {
                          game.addBid(lastRound.dealerIndex, game.currentPlayerIds.indexOf(selectedId), selectedBid);
                          game.updateFirestore();
                        },
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        );
      } else if (lastRound.wonTricks == null && game.currentPlayerIds[lastRound.bidderIndex] == selectedId) {
        int selectedWonTricks = lastRound.bid > 6 ? 6 : lastRound.bid;
        children.add(StatefulBuilder(builder: (context, innerSetState) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('Won Tricks', style: textTheme.subtitle2),
              Container(
                width: double.infinity,
                child: CupertinoSlidingSegmentedControl(
                  children: Map.fromIterable([0, 1, 2, 3, 4, 5, 6], key: (i) => i, value: (i) => Text(i.toString())),
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
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  RaisedButton.icon(
                    icon: Icon(Icons.add),
                    label: Text('Add Result'),
                    onPressed: () {
                      game.addRoundResult(selectedWonTricks);
                      if (!game.isFinished) {
                        game.newRound((lastRound.dealerIndex + 1) % 4);
                      }
                      game.updateFirestore();
                    },
                  ),
                ],
              ),
            ],
          );
        }));
      }
    }
    return Column(children: children, crossAxisAlignment: CrossAxisAlignment.start);
  }

  Widget statBar(String title, String leftLabel, double percent, Color color) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(
        children: [
          Text(title, style: textTheme.bodyText2.copyWith(fontSize: isSmallScreen ? 12 : null)),
          Spacer(),
          Text(leftLabel, style: textTheme.subtitle2.copyWith(fontSize: isSmallScreen ? 12 : null)),
        ],
      ),
      Padding(
        padding: EdgeInsets.fromLTRB(0, 2, 0, 4),
        child: LinearPercentIndicator(
          percent: min(1, max(0, percent)),
          progressColor: color,
          lineHeight: isSmallScreen ? 4 : 6,
          linearStrokeCap: LinearStrokeCap.butt,
          padding: EdgeInsets.all(0),
        ),
      ),
    ]);
  }
}
