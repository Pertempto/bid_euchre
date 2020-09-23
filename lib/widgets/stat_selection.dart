import 'package:bideuchre/data/stat_item.dart';
import 'package:bideuchre/data/stat_type.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class StatSelection extends StatefulWidget {
  StatSelection();

  @override
  _StatSelectionState createState() => _StatSelectionState();
}

class _StatSelectionState extends State<StatSelection> {
  TextTheme textTheme;
  List<StatType> statOptions;

  @override
  Widget build(BuildContext context) {
    if (statOptions == null) {
      statOptions = StatType.values.toList();
    }
    textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: Text('Select Stat'),
      ),
      body: ListView.builder(
          itemCount: statOptions.length + 1,
          itemBuilder: (context, index) {
            if (index == statOptions.length) {
              return SizedBox(height: 16);
            } else {
              StatType statType = statOptions[index];
              return InkWell(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Row(
                    children: <Widget>[
                      Text(StatItem.getStatName(statType),
                          style: textTheme.subtitle1.copyWith(fontWeight: FontWeight.w400)),
                      Spacer(),
                      Icon(Icons.chevron_right),
                    ],
                  ),
                ),
                onTap: () {
                  Navigator.pop(context, statType);
                },
              );
            }
          }),
    );
  }
}
