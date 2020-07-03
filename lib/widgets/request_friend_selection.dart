import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../data/data_store.dart';
import '../data/user.dart';

class RequestFriendSelection extends StatefulWidget {
  final List<User> usersList;
  final Data data;

  RequestFriendSelection(this.usersList, this.data);

  @override
  _RequestFriendSelectionState createState() => _RequestFriendSelectionState();
}

class _RequestFriendSelectionState extends State<RequestFriendSelection> {
  List<User> usersList;
  List<User> _filteredUsersList;
  TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    usersList = widget.usersList;
    if (_filteredUsersList == null) {
      _filteredUsersList = List.from(usersList);
      _filteredUsersList.sort((a, b) => a.name.compareTo(b.name));
    }
    textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: Text('Request Friend'),
      ),
      body: ListView.builder(
          itemCount: _filteredUsersList.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Row(
                  children: <Widget>[
                    Flexible(
                      child: TextField(
                        decoration: InputDecoration(hintText: 'Filter', suffixIcon: Icon(Icons.search)),
                        onChanged: _onFilterTextChanged,
                      ),
                    ),
                  ],
                ),
              );
            } else {
              User user = _filteredUsersList[index - 1];
              return ListTile(
                dense: true,
                title: Text(user.name, style: textTheme.headline6.copyWith(fontWeight: FontWeight.normal)),
                trailing: Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pop(context, user.userId);
                },
              );
            }
          }),
    );
  }

  void _onFilterTextChanged(String text) async {
    _filteredUsersList.clear();
    usersList.forEach((user) {
      if (text.isEmpty || user.name.toLowerCase().contains(text.toLowerCase())) {
        _filteredUsersList.add(user);
      }
    });
    setState(() {});
  }
}
