import 'package:bideuchre/data/data_store.dart';
import 'package:bideuchre/data/stats.dart';
import 'package:bideuchre/widgets/stat_selection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

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
  StatType displayStatType = StatType.record;
  bool showInfrequent = false;
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
        atScrollTop = scrollController.offset < 100;
      });
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    teams = widget.teams;
    textTheme = Theme.of(context).textTheme;
    return DataStore.dataWrap((data) {
      Map<String, Map<StatType, StatItem>> stats;
      if (teams) {
        stats = data.statsDb
            .getTeamStats({displayStatType, StatType.numGames, StatType.lastPlayed}, data.players.keys.toSet());
      } else {
        stats = data.statsDb
            .getPlayerStats({displayStatType, StatType.numGames, StatType.lastPlayed}, data.players.keys.toSet());
      }
      List<String> ids = stats.keys.toList();
      if (!showInfrequent) {
        ids = ids.where((id) {
          bool has5Games = stats[id][StatType.numGames].statValue >= 5;
          DateTime lastPlayed = DateTime.fromMillisecondsSinceEpoch(stats[id][StatType.lastPlayed].statValue);
          bool playedIn90Days = DateTime.now().subtract(Duration(days: 90)).isBefore(lastPlayed);
          return has5Games && playedIn90Days;
        }).toList();
      }
      Map<String, String> names = {};
      if (teams) {
        names = Map.fromIterable(ids, key: (id) => id, value: (id) => Util.getTeamName(id, data));
      } else {
        names = Map.fromIterable(ids, key: (id) => id, value: (id) => data.players[id].fullName);
      }
      ids.sort((a, b) {
        int statCmp = stats[a][displayStatType].sortValue.compareTo(stats[b][displayStatType].sortValue);
        if (statCmp != 0) {
          return statCmp;
        }
        return names[a].compareTo(names[b]);
      });

      List<Widget> children = [
        SizedBox(height: 8),
        ListTile(
          title: Text(StatsDb.statName(displayStatType), style: textTheme.headline6),
          trailing: Icon(MdiIcons.filter),
          dense: true,
          onTap: () {
            selectStat();
          },
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
        Divider(),
      ];
      int placeNum = 0;
      int playerNum = 0;
      double lastSortValue;
      for (String id in ids) {
        StatItem statItem = stats[id][displayStatType];
        playerNum++;
        if (statItem.sortValue != lastSortValue) {
          placeNum = playerNum;
          lastSortValue = statItem.sortValue;
        }
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
      children.add(SizedBox(height: 64));
      return Stack(
        children: <Widget>[
          SingleChildScrollView(
            controller: scrollController,
            child: Column(children: children),
          ),
          if (!atScrollTop)
            Align(
              alignment: Alignment.bottomRight,
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: FloatingActionButton(
                  heroTag: 'scrollToTopBtn$teams',
                  mini: true,
                  child: Icon(Icons.arrow_upward),
                  onPressed: () {
                    scrollController.animateTo(0, duration: Duration(milliseconds: 100), curve: Curves.linear);
                  },
                ),
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
