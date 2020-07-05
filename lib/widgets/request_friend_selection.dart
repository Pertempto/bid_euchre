import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../data/user.dart';

class RequestFriendSelection extends StatefulWidget {
  final List<User> usersList;

  RequestFriendSelection(this.usersList);

  @override
  _RequestFriendSelectionState createState() => _RequestFriendSelectionState();
}

class _RequestFriendSelectionState extends State<RequestFriendSelection> {
  List<User> usersList;
  List<User> filteredUsersList;
  TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    usersList = widget.usersList;
    if (filteredUsersList == null) {
      filteredUsersList = List.from(usersList);
      filteredUsersList.sort((a, b) => a.name.compareTo(b.name));
    }
    textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: Text('Request Friend'),
      ),
      body: ListView.builder(
          itemCount: filteredUsersList.length + 2,
          itemBuilder: (context, index) {
            if (index == 0) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Row(
                  children: <Widget>[
                    Flexible(
                      child: TextField(
                        decoration: InputDecoration(hintText: 'Filter', suffixIcon: Icon(Icons.search)),
                        onChanged: onFilterTextChanged,
                      ),
                    ),
                  ],
                ),
              );
            } else if (index == filteredUsersList.length + 1) {
              return SizedBox(height: 16);
            } else {
              User user = filteredUsersList[index - 1];
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

  void onFilterTextChanged(String text) async {
    filteredUsersList.clear();
    usersList.forEach((user) {
      if (text.isEmpty || user.name.toLowerCase().contains(text.toLowerCase())) {
        filteredUsersList.add(user);
      }
    });
    setState(() {});
  }
}
