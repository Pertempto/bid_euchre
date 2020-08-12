import 'package:bideuchre/data/data_store.dart';
import 'package:bideuchre/data/stats.dart';
import 'package:bideuchre/widgets/stat_selection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../util.dart';
import 'player_profile.dart';
import 'team_profile.dart';

class StatsList extends StatefulWidget {
  final bool teams;

  StatsList(this.teams);

  @override
  _StatsListState createState() => _StatsListState();
}

class _StatsListState extends State<StatsList> with AutomaticKeepAliveClientMixin<StatsList> {
  bool teams;
  StatType displayStatType = StatType.overallRating;
  bool showInfrequent = false;
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
    teams = widget.teams;
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
      if (!showInfrequent) {
        ids = ids.where((id) {
          bool has5Games = data.statsDb.getStat(id, StatType.numGames).statValue >= 5;
          DateTime lastPlayed =
              DateTime.fromMillisecondsSinceEpoch(data.statsDb.getStat(id, StatType.lastPlayed).statValue);
          bool playedIn60Days = DateTime.now().subtract(Duration(days: 60)).isBefore(lastPlayed);
          return has5Games && playedIn60Days;
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
            .getStat(a, displayStatType)
            .sortValue
            .compareTo(data.statsDb.getStat(b, displayStatType).sortValue);
        if (statCmp != 0) {
          return statCmp;
        }
        return names[a].compareTo(names[b]);
      });

      List<Widget> children = [
        ExpansionTile(
          title: Text(StatsDb.statName(displayStatType), style: textTheme.headline6),
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
                      decoration: InputDecoration(
                          hintText: teams ? 'Team Search' : 'Player Search', prefixIcon: Icon(Icons.search)),
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
            Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 0),
              child: Row(
                children: <Widget>[
                  Text(teams ? 'Show Infrequent Teams:' : 'Show Infrequent Players:', style: textTheme.subtitle1),
                  Spacer(),
                  Switch.adaptive(
                    value: showInfrequent,
                    onChanged: (value) {
                      setState(() {
                        showInfrequent = value;
                      });
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
      ];
      int placeNum = 0;
      int playerNum = 0;
      double lastSortValue;
      for (String id in ids) {
        StatItem statItem = data.statsDb.getStat(id, displayStatType);
        playerNum++;
        if (statItem.sortValue != lastSortValue) {
          placeNum = playerNum;
          lastSortValue = statItem.sortValue;
        }
        if (filterText.isEmpty || names[id].toLowerCase().contains(filterText)) {
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
                    child: Text(names[id], style: textTheme.bodyText1.copyWith(fontWeight: FontWeight.w400)),
                    flex: 4,
                  ),
                  Expanded(
                    child: Text(
                      statItem.toString(),
                      style: textTheme.bodyText1.copyWith(fontWeight: FontWeight.w300),
                      textAlign: TextAlign.end,
                    ),
                    flex: 4,
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
      return SingleChildScrollView(
        child: Column(children: children),
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
