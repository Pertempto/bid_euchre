import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'data/data_store.dart';
import 'data/player.dart';
import 'data/user.dart';
import 'widgets/color_chooser.dart';

class Util {
  static Color checkColor(Color color, String id) {
    // replace the old generic blue and green
    if (color.value == 0xff007aff || color.value == 0xff34c759) {
      color = ColorChooser.generateRandomColor(seed: id.hashCode);
    }
    return color;
  }

  static String scoreString(int score) {
    return score < 0 ? '($score)' : '$score';
  }

  static String teamId(List<String> playerIds) {
    playerIds.sort();
    return playerIds.join(' ');
  }

  static String teamName(String teamId, Data data) {
    List<Player> players = teamId.split(' ').map((id) => data.allPlayers[id]).toList();
    if (players.contains(null)) {
      return '';
    }
    List<String> playerNames = players.map((p) => p.shortName).toList();
    playerNames.sort();
    if (playerNames.length > 3) {
      playerNames = playerNames.sublist(0, 4);
      playerNames.add('...');
    }
    return playerNames.join(' & ');
  }

  static Widget confettiStack(
      {Widget child,
      BuildContext context,
      AnimationController controller,
      ConfettiSettings settings,
      List<Color> colors}) {
    bool hasListener = false;
    Size screenSize = MediaQuery.of(context).size;
    Random rand = Random();
    List<Map> piecesData = [];
    for (int i = 0; i < settings.count; i++) {
      piecesData.add({
        'x': rand.nextDouble() * screenSize.width,
        'driftFactor': (rand.nextDouble() - 0.5) * 2,
        'spinFactor': (rand.nextDouble() - 0.5) * 5,
        'delay': 2 * pow(rand.nextDouble(), 2),
        'color': colors[rand.nextInt(colors.length)],
        'speedFactor': rand.nextDouble() / 2 + 0.75,
      });
    }
    return StatefulBuilder(builder: (context, innerSetState) {
      List<Widget> children = [child];
      if (controller != null) {
        double secs = controller.value / controller.velocity;
        for (Map pieceData in piecesData) {
          double y;
          if (secs >= pieceData['delay']) {
            y = (pow(secs - pieceData['delay'], 1.5)) * 200 * settings.gravityFactor * pieceData['speedFactor'] - 10;
          }
          if (controller.status == AnimationStatus.forward &&
              secs != double.infinity &&
              y != null &&
              y < screenSize.height) {
            children.add(Positioned(
              left: pieceData['x'] + pieceData['driftFactor'] * 50 * secs,
              top: y,
              child: Transform.rotate(
                angle: (2 * pi * (secs * pieceData['spinFactor'])) % (2 * pi),
                child: Container(
                  color: pieceData['color'],
                  width: 15 * settings.sizeFactor,
                  height: 10 * settings.sizeFactor,
                ),
              ),
            ));
          }
        }
      }
      if (!hasListener) {
        controller.addListener(() {
          innerSetState(() {});
        });
        hasListener = true;
      }
      return Stack(
        children: children,
      );
    });
  }

  static Widget winProbsBar(List<double> winProbs, List<Color> teamColors, BuildContext context) {
    TextTheme textTheme = Theme
        .of(context)
        .textTheme;
    return Stack(
      children: <Widget>[
        Row(
          children: List.generate(
            2,
                (index) =>
                Expanded(
                  child: Container(height: 16, color: teamColors[index]),
                  flex: ((winProbs[index]) * 1000).toInt(),
                ),
          ),
        ),
        Row(
          children: List.generate(
            2,
                (index) =>
                Expanded(
                  child: Container(
                    alignment: [Alignment.centerLeft, Alignment.centerRight][index],
                    height: 16,
                    padding: [EdgeInsets.only(left: 4), EdgeInsets.only(right: 4)][index],
                    child: Text((winProbs[index] * 100).toStringAsFixed(1) + '%',
                        style: textTheme.bodyText2.copyWith(color: Colors.white, fontSize: 12)),
                  ),
                ),
          ),
        ),
      ],
    );
  }
}