import 'package:bideuchre/data/data_store.dart';
import 'package:bideuchre/data/user.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../util.dart';
import 'color_chooser.dart';

class ConfettiSetup extends StatefulWidget {
  ConfettiSetup();

  @override
  _ConfettiSetupState createState() => _ConfettiSetupState();
}

class _ConfettiSetupState extends State<ConfettiSetup> with TickerProviderStateMixin {
  AnimationController confettiController;
  TextTheme textTheme;
  ConfettiSettings settings;

  @override
  void initState() {
    super.initState();
    confettiController = AnimationController(vsync: this, duration: Duration(seconds: 20));
  }

  @override
  void dispose() {
    confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    textTheme = Theme.of(context).textTheme;
    return DataStore.dataWrap((data) {
      if (settings == null) {
        settings = data.currentUser.confettiSettings;
      }
      List<Widget> children = [
        SizedBox(height: 8),
        countSection(),
        sizeSection(),
        gravitySection(),
        OutlineButton(
          child: Text('Test Confetti!'),
          onPressed: () {
            confettiController.reset();
            confettiController.forward();
//            Navigator.of(context).push(MaterialPageRoute(builder: (context) => ConfettiTest(settings)));
          },
        ),
        SizedBox(height: 64),
      ];
      List<Color> colors = [];
      for (int i = 0; i < 10; i++) {
        colors.add(ColorChooser.generateRandomColor());
      }
      return Scaffold(
        appBar: AppBar(
          title: Text('Confetti Settings'),
          actions: <Widget>[
            IconButton(
              icon: Icon(Icons.save),
              onPressed: () {
                data.currentUser.confettiSettings = settings;
                data.currentUser.updateFirestore();
                Navigator.of(context).pop();
              },
            )
          ],
        ),
        body: Container(
          width: double.infinity,
          height: double.infinity,
          child: Util.confettiStack(
            child: SingleChildScrollView(
              child: Column(children: children),
            ),
            context: context,
            controller: confettiController,
            settings: settings,
            colors: colors,
          ),
        ),
      );
    });
  }

  Widget countSection() {
    List<Widget> children = [
      ListTile(
        title: Text('Count', style: textTheme.headline6),
        trailing: Text(settings.count.toString(), style: textTheme.headline6.copyWith(fontWeight: FontWeight.w400)),
        dense: true,
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
        child: Slider.adaptive(
          value: settings.count.toDouble(),
          min: 25,
          max: 1000,
          divisions: 39,
          onChanged: (value) {
            setState(() {
              confettiController.stop();
              settings.count = value.toInt();
            });
          },
        ),
      ),
      Divider(),
    ];
    return Column(children: children);
  }

  Widget sizeSection() {
    List<Widget> children = [
      ListTile(
        title: Text('Size', style: textTheme.headline6),
        trailing: Text(settings.sizeFactor.toStringAsFixed(1),
            style: textTheme.headline6.copyWith(fontWeight: FontWeight.w400)),
        dense: true,
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
        child: Slider.adaptive(
          value: settings.sizeFactor,
          min: 0.1,
          max: 2.0,
          divisions: 19,
          onChanged: (value) {
            setState(() {
              confettiController.stop();
              settings.sizeFactor = value;
            });
          },
        ),
      ),
      Divider(),
    ];
    return Column(children: children);
  }

  Widget gravitySection() {
    List<Widget> children = [
      ListTile(
        title: Text('Gravity', style: textTheme.headline6),
        trailing: Text(settings.gravityFactor.toStringAsFixed(1),
            style: textTheme.headline6.copyWith(fontWeight: FontWeight.w400)),
        dense: true,
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
        child: Slider.adaptive(
          value: settings.gravityFactor,
          min: 0.1,
          max: 2.0,
          divisions: 19,
          onChanged: (value) {
            setState(() {
              confettiController.stop();
              settings.gravityFactor = value;
            });
          },
        ),
      ),
      Divider(),
    ];
    return Column(children: children);
  }
}
