import 'package:bideuchre/data/data_store.dart';
import 'package:bideuchre/data/group.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class GroupSettings extends StatefulWidget {
  final Group group;

  GroupSettings(this.group);

  @override
  _GroupSettingsState createState() => _GroupSettingsState();
}

class _GroupSettingsState extends State<GroupSettings> {
  Group group;

  @override
  Widget build(BuildContext context) {
    group = widget.group;
    return DataStore.dataWrap(
      (data) {
        TextTheme textTheme = Theme.of(context).textTheme;
        TextStyle leadingStyle = textTheme.headline6;
        TextStyle trailingStyle = textTheme.headline6.copyWith(fontWeight: FontWeight.w400);
        List<Widget> children = [
          SizedBox(height: 8), // balance out dividers whitespace
          ListTile(
            title: Text('Admin', style: leadingStyle),
            trailing: Text(data.users[group.adminId].name, style: trailingStyle),
            dense: true,
          ),
          Divider(),
          ListTile(
            title: Text('Name', style: leadingStyle),
            trailing: Text('${group.name}', style: trailingStyle),
            dense: true,
            onTap: (group.adminId != data.currentUser.userId)
                ? null
                : () {
                    editName(context);
                  },
          ),
          Divider(),
        ];
        return SingleChildScrollView(
          child: Column(children: children),
        );
      },
    );
  }

  void editName(BuildContext context) {
    TextEditingController textFieldController = TextEditingController(text: group.name);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Name'),
          contentPadding: EdgeInsets.fromLTRB(24, 0, 24, 0),
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Padding(
                padding: EdgeInsets.only(right: 12),
                child: Text('Name:'),
              ),
              Expanded(
                child: TextField(controller: textFieldController),
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
                String name = textFieldController.value.text.trim();
                if (name.isNotEmpty) {
                  group.name = name;
                  group.updateFirestore();
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }
}
