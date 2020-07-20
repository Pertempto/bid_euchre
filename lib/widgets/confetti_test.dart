import 'package:bideuchre/data/user.dart';
import 'package:bideuchre/widgets/color_chooser.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../util.dart';

class ConfettiTest extends StatefulWidget {
  final ConfettiSettings settings;

  ConfettiTest(this.settings);

  @override
  _ConfettiTestState createState() => _ConfettiTestState();
}

class _ConfettiTestState extends State<ConfettiTest> {
  ConfettiController confettiController;
  ConfettiSettings settings;

  @override
  void initState() {
    confettiController = ConfettiController(duration: Duration(seconds: 20));
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    settings = widget.settings;
    confettiController.play();
    List<Color> colors = [];
    for (int i = 0; i < 10; i++) {
      colors.add(ColorChooser.generateRandomColor());
    }
    return Scaffold(
      appBar: AppBar(title: Text('Confetti Test')),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        child: Util.confettiStack(
          child: Center(
            child: OutlineButton(
              child: Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ),
          controller: confettiController,
          settings: settings,
          colors: colors,
        ),
      ),
    );
  }
}
