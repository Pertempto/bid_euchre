import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import '../data/data_store.dart';
import '../data/game.dart';
import 'color_chooser.dart';
import 'new_game.dart';

class GameSettings extends StatefulWidget {
  final Game game;

  GameSettings(this.game);

  @override
  _GameSettingsState createState() => _GameSettingsState();
}

class _GameSettingsState extends State<GameSettings> {
  Game game;
  Data data;

  @override
  Widget build(BuildContext context) {
    game = widget.game;
    data = DataStore.lastData;

    TextTheme textTheme = Theme.of(context).textTheme;
    TextStyle leadingStyle = textTheme.headline6;
    TextStyle trailingStyle = textTheme.headline6.copyWith(fontWeight: FontWeight.w400);
    List<Widget> children = [
      SizedBox(height: 8), //balance out dividers whitespace
    ];
    for (int i = 0; i < 2; i++) {
      children.add(ListTile(
        title: Text('Team ${i + 1} Color', style: leadingStyle),
        trailing: Container(color: game.teamColors[i], height: 32, width: 32),
        dense: true,
        onTap: (game.userId != data.currentUser.userId)
            ? null
            : () {
                selectTeamColor(i);
              },
      ));
      children.add(Divider());
    }
    children.add(ListTile(
      title: Text('Game Over Score', style: leadingStyle),
      trailing: Text('${game.gameOverScore}', style: trailingStyle),
      dense: true,
      onTap: (game.userId != data.currentUser.userId)
          ? null
          : () {
              showDialog(
                context: context,
                builder: (context) {
                  int sliderValue = game.gameOverScore;
                  return StatefulBuilder(builder: (context, innerSetState) {
                    return AlertDialog(
                      title: Text('Game Over Score'),
                      contentPadding: EdgeInsets.fromLTRB(24, 16, 24, 0),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Text(
                            '$sliderValue',
                            style: textTheme.subtitle1,
                          ),
                          Slider.adaptive(
                            value: sliderValue.toDouble(),
                            min: 12,
                            max: 60,
                            onChanged: (value) {
                              innerSetState(() {
                                sliderValue = value.toInt();
                              });
                            },
                          ),
                        ],
                      ),
                      actions: <Widget>[
                        FlatButton(
                          child: Text('Cancel'),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                        FlatButton(
                          child: Text('Submit'),
                          onPressed: () {
                            setState(() {
                              game.gameOverScore = sliderValue;
                              game.updateFirestore();
                            });
                            Navigator.of(context).pop();
                          },
                        ),
                      ],
                    );
                  });
                },
              );
            },
    ));
    children.add(Divider());
    Color copyColor = Colors.blueGrey;
    children.add(ListTile(
      title: Text('Copy Game', style: leadingStyle.copyWith(color: copyColor)),
      trailing: Icon(Icons.content_copy, color: copyColor),
      dense: true,
      onTap: () {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => NewGame(copyGame: game)));
      },
    ));
    children.add(Divider());
    if (game.userId == data.currentUser.userId) {
      children.add(ListTile(
        title: Text('Delete Game', style: leadingStyle.copyWith(color: Colors.red)),
        trailing: Icon(Icons.delete, color: Colors.red),
        dense: true,
        onTap: () {
          showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: Text('Delete Game'),
                contentPadding: EdgeInsets.fromLTRB(24, 8, 24, 0),
                content: Text('Are you sure?'),
                actions: <Widget>[
                  FlatButton(
                    child: Text('Cancel'),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                  FlatButton(
                    textColor: Colors.red,
                    child: Text('Delete'),
                    onPressed: () {
                      DataStore.gamesCollection.document(game.gameId).delete();
                      Navigator.of(context).pop(); // close dialog
                      Navigator.of(context).pop(); // close game detail page
                    },
                  ),
                ],
              );
            },
          );
        },
      ));
      children.add(Divider());
    }
    return SingleChildScrollView(
      child: Column(children: children),
    );
  }

  selectTeamColor(int teamIndex) async {
    Color teamColor = await Navigator.push(
        context, MaterialPageRoute(builder: (context) => ColorChooser(game.teamColors[teamIndex])));
    if (teamColor != null) {
      setState(() {
        game.teamColors[teamIndex] = teamColor;
        game.updateFirestore();
      });
    }
  }
}
