import 'dart:math';

import 'package:confetti/confetti.dart';
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

  static Widget confettiLayer(
      {Alignment alignment,
      ConfettiController controller,
      double direction,
      double amount,
      double maxForce,
      double gravityFactor,
      List<Color> colors,
      double sizeFactor}) {
    return Positioned.fill(
      child: Align(
        alignment: alignment,
        child: ConfettiWidget(
          confettiController: controller,
          blastDirection: direction,
          emissionFrequency: amount,
          numberOfParticles: 1,
          maxBlastForce: maxForce,
          minBlastForce: maxForce / 2,
          gravity: 0.1*gravityFactor,
          colors: colors,
          minimumSize: Size(20 * sizeFactor, 10 * sizeFactor),
          maximumSize: Size(30 * sizeFactor, 15 * sizeFactor),
          particleDrag: 0.05,
        ),
      ),
    );
  }

  static Widget confettiStack(
      {Widget child, ConfettiController controller, ConfettiSettings settings, List<Color> colors}) {
    return Stack(
      children: <Widget>[
        child,
        if (settings.locations['tl'])
          Util.confettiLayer(
            alignment: Alignment.topLeft,
            controller: controller,
            direction: pi / 4,
            amount: settings.amount,
            maxForce: 20 * settings.force,
            gravityFactor: settings.gravityFactor,
            colors: colors,
            sizeFactor: settings.sizeFactor,
          ),
        if (settings.locations['tc'])
          Util.confettiLayer(
            alignment: Alignment.topCenter,
            controller: controller,
            direction: pi / 2,
            amount: settings.amount,
            maxForce: 10 * settings.force,
            gravityFactor: settings.gravityFactor,
            colors: colors,
            sizeFactor: settings.sizeFactor,
          ),
        if (settings.locations['tr'])
          Util.confettiLayer(
            alignment: Alignment.topRight,
            controller: controller,
            direction: pi / 4 * 3,
            amount: settings.amount,
            maxForce: 20 * settings.force,
            gravityFactor: settings.gravityFactor,
            colors: colors,
            sizeFactor: settings.sizeFactor,
          ),
        if (settings.locations['bl'])
          Util.confettiLayer(
            alignment: Alignment.bottomLeft,
            controller: controller,
            direction: -pi / 8 * 3,
            amount: settings.amount,
            maxForce: 80 * settings.force,
            gravityFactor: settings.gravityFactor,
            colors: colors,
            sizeFactor: settings.sizeFactor,
          ),
        if (settings.locations['bc'])
          Util.confettiLayer(
            alignment: Alignment.bottomCenter,
            controller: controller,
            direction: -pi / 2,
            amount: settings.amount,
            maxForce: 80 * settings.force,
            gravityFactor: settings.gravityFactor,
            colors: colors,
            sizeFactor: settings.sizeFactor,
          ),
        if (settings.locations['br'])
          Util.confettiLayer(
            alignment: Alignment.bottomRight,
            controller: controller,
            direction: -pi / 8 * 5,
            amount: settings.amount,
            maxForce: 80 * settings.force,
            gravityFactor: settings.gravityFactor,
            colors: colors,
            sizeFactor: settings.sizeFactor,
          ),
      ],
    );
  }
}
