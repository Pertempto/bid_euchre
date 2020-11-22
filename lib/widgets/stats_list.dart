import 'package:bideuchre/data/data_store.dart';
import 'package:bideuchre/data/game.dart';
import 'package:bideuchre/data/stat_item.dart';
import 'package:bideuchre/data/stat_type.dart';
import 'package:bideuchre/widgets/stat_selection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../util.dart';
import 'player_profile.dart';
import 'team_profile.dart';

class StatsList extends StatefulWidget {
  StatsList();

  @override
  _StatsListState createState() => _StatsListState();
}

class _StatsListState extends State<StatsList> with AutomaticKeepAliveClientMixin<StatsList> {
  StatType displayStatType = StatType.overallRating;
  bool teams = false;
  bool showAll = false;
  String filterText;
  TextEditingController searchController;
  TextTheme textTheme;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    searchController = TextEditingController();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    textTheme = Theme.of(context).textTheme;
    if (filterText == null) {
      filterText = '';
    }
    return DataStore.dataWrap((data) {
      List<String> ids;
      if (teams) {
        ids = data.statsDb.getTeamIds(data.players.keys.toSet());
      } else {
        ids = data.players.keys.toList();
      }
      if (!showAll) {
        ids = ids.where((id) {
          return (data.statsDb.getStat(id, StatType.numRounds, false) as IntStatItem).value >= 36;
        }).toList();
      }
      Map<String, String> names = {};
      if (teams) {
        names = Map.fromIterable(ids, key: (id) => id, value: (id) => Util.teamName(id, data));
      } else {
        names = Map.fromIterable(ids,
            key: (id) => id,
            value: (id) {
              return data.players[id].fullName;
            });
      }
      ids.sort((a, b) {
        int statCmp = data.statsDb
            .getStat(a, displayStatType, DataStore.displayArchivedStats)
            .sortValue
            .compareTo(data.statsDb.getStat(b, displayStatType, DataStore.displayArchivedStats).sortValue);
        if (statCmp != 0) {
          return statCmp;
        }
        return names[a].compareTo(names[b]);
      });

      List<Widget> children = [SizedBox(height: 8)];
      int placeNum = 0;
      int playerNum = 0;
      double lastSortValue;
      for (String id in ids) {
        StatItem statItem = data.statsDb.getStat(id, displayStatType, DataStore.displayArchivedStats);
        playerNum++;
        if (statItem.sortValue != lastSortValue) {
          placeNum = playerNum;
          lastSortValue = statItem.sortValue;
        }
        if (filterText.isEmpty || names[id].toLowerCase().contains(filterText)) {
          Icon trendIcon;
          if ((displayStatType == StatType.overallRating || displayStatType == StatType.bidderRating)) {
            double recentRating = data.statsDb.getRecentRating(id, displayStatType).rating;
            double rating = (statItem as RatingStatItem).rating;
            if (recentRating > rating + 20) {
              trendIcon = Icon(Icons.trending_up, color: Colors.green);
            } else if (recentRating < rating - 20) {
              trendIcon = Icon(Icons.trending_down, color: Colors.red);
            }
          }
          Color color = data.statsDb.getColor(id);
          children.add(GestureDetector(
            child: Padding(
              padding: EdgeInsets.fromLTRB(0, 4, 16, 4),
              child: Row(
                children: <Widget>[
                  SizedBox(
                    width: 40,
                    child: Padding(
                      padding: EdgeInsets.only(right: 4),
                      child: Text(
                        '$placeNum.',
                        style: textTheme.bodyText1.copyWith(fontWeight: FontWeight.w600),
                        textAlign: TextAlign.end,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Row(
                      children: [
                        Text(names[id], style: textTheme.bodyText1.copyWith(color: color)),
                        if (trendIcon != null) Padding(child: trendIcon, padding: EdgeInsets.only(left: 4)),
                      ],
                    ),
                    flex: 6,
                  ),
                  Expanded(
                    child: Text(
                      statItem.toString(),
                      style: textTheme.bodyText1.copyWith(fontWeight: FontWeight.w300),
                      textAlign: TextAlign.end,
                    ),
                    flex: 2,
                  ),
                ],
              ),
            ),
            onTap: () {
              if (teams) {
                Navigator.push(context, MaterialPageRoute(builder: (context) => TeamProfile(id)));
              } else {
                Navigator.push(context, MaterialPageRoute(builder: (context) => PlayerProfile(data.players[id])));
              }
            },
          ));
          children.add(Divider());
        }
      }
      children.add(SizedBox(height: 32));
      return Column(
        children: [
          Material(
            elevation: 1,
            child: Column(
              children: [
                Container(
                    width: double.infinity,
                    padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: CupertinoSlidingSegmentedControl(
                      children: Map.fromIterable(
                        [false, true],
                        key: (i) => i,
                        value: (i) => Text(i ? 'Teams' : 'Players'),
                      ),
                      onValueChanged: (value) {
                        setState(() {
                          teams = value;
                        });
                      },
                      groupValue: teams,
                    )),
                ExpansionTile(
                  title: Text(StatItem.getStatName(displayStatType), style: textTheme.headline6),
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                      child: Row(
                        children: <Widget>[
                          OutlineButton(
                            child: Text('Select Stat'),
                            onPressed: selectStat,
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: TextField(
                              controller: searchController,
                              decoration: InputDecoration(hintText: 'Search', prefixIcon: Icon(Icons.search)),
                              onChanged: (value) {
                                setState(() {
                                  filterText = value.trim().toLowerCase();
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                        width: double.infinity,
                        padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
                        child: CupertinoSlidingSegmentedControl(
                          children: Map.fromIterable(
                            [false, true],
                            key: (i) => i,
                            value: (i) => Text(i ? 'All Time' : 'Last ${Game.ARCHIVE_AGE} Days'),
                          ),
                          onValueChanged: (value) {
                            setState(() {
                              DataStore.displayArchivedStats = value;
                            });
                          },
                          groupValue: DataStore.displayArchivedStats,
                        )),
                    Container(
                        width: double.infinity,
                        padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
                        child: CupertinoSlidingSegmentedControl(
                          children: Map.fromIterable(
                            [false, true],
                            key: (i) => i,
                            value: (i) => Text(i ? 'All' : 'Active'),
                          ),
                          onValueChanged: (value) {
                            setState(() {
                              showAll = value;
                            });
                          },
                          groupValue: showAll,
                        )),
                    SizedBox(height: 8)
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(children: children),
            ),
          ),
        ],
      );
    });
  }

  selectStat() async {
    StatType stat = await Navigator.push(context, MaterialPageRoute(builder: (context) => StatSelection()));
    if (stat != null) {
      setState(() {
        displayStatType = stat;
      });
    }
  }
}
