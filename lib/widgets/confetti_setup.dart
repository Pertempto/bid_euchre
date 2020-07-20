import 'package:bideuchre/data/data_store.dart';
import 'package:bideuchre/data/user.dart';
import 'package:bideuchre/widgets/confetti_test.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ConfettiSetup extends StatefulWidget {
  ConfettiSetup();

  @override
  _ConfettiSetupState createState() => _ConfettiSetupState();
}

class _ConfettiSetupState extends State<ConfettiSetup> {
  TextTheme textTheme;
  ConfettiSettings settings;

  @override
  Widget build(BuildContext context) {
    textTheme = Theme.of(context).textTheme;
    return DataStore.dataWrap((data) {
      if (settings == null) {
        settings = data.currentUser.confettiSettings;
      }
      List<Widget> children = [
        SizedBox(height: 8),
        locationsSection(),
        forceSection(),
        amountSection(),
        sizeSection(),
        gravitySection(),
        OutlineButton(
          child: Text('Test Confetti!'),
          onPressed: () {
            Navigator.of(context).push(MaterialPageRoute(builder: (context) => ConfettiTest(settings)));
          },
        ),
        SizedBox(height: 64),
      ];
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
        body: SingleChildScrollView(
          child: Column(children: children),
        ),
      );
    });
  }

  Widget locationsSection() {
    List<Widget> children = [
      ListTile(
        title: Text('Nozzle Locations', style: textTheme.headline6),
        dense: true,
      ),
    ];
    ConfettiSettings.LOCATION_NAMES.forEach((location, locationName) {
      children.add(CheckboxListTile(
        dense: true,
        title: Text(locationName),
        value: settings.locations[location],
        onChanged: (value) {
          setState(() {
            settings.locations[location] = !settings.locations[location];
          });
        },
      ));
    });
    children.add(Divider());
    return Column(children: children);
  }

  Widget forceSection() {
    List<Widget> children = [
      ListTile(
        title: Text('Ejection Force', style: textTheme.headline6),
        trailing:
            Text(settings.force.toStringAsFixed(1), style: textTheme.headline6.copyWith(fontWeight: FontWeight.w400)),
        dense: true,
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
        child: Slider.adaptive(
          value: settings.force,
          min: 0.1,
          max: 2.0,
          divisions: 19,
          onChanged: (value) {
            setState(() {
              settings.force = value;
            });
          },
        ),
      ),
      Divider(),
    ];
    return Column(children: children);
  }

  Widget amountSection() {
    List<Widget> children = [
      ListTile(
        title: Text('Amount', style: textTheme.headline6),
        trailing:
            Text(settings.amount.toStringAsFixed(2), style: textTheme.headline6.copyWith(fontWeight: FontWeight.w400)),
        dense: true,
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
        child: Slider.adaptive(
          value: settings.amount,
          min: 0.05,
          max: 1.0,
          divisions: 19,
          onChanged: (value) {
            setState(() {
              settings.amount = value;
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
        trailing:
            Text(settings.sizeFactor.toStringAsFixed(1), style: textTheme.headline6.copyWith(fontWeight: FontWeight.w400)),
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
        trailing:
            Text(settings.gravityFactor.toStringAsFixed(1), style: textTheme.headline6.copyWith(fontWeight: FontWeight.w400)),
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
