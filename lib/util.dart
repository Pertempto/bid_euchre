import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'data/data_store.dart';
import 'data/player.dart';
import 'data/user.dart';

class Util {
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
      return null;
    }
    List<String> playerNames = players.map((p) => p.shortName).toList();
    playerNames.sort();
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
}
