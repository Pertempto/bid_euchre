import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import 'data/authentication.dart';
import 'data/data_store.dart';
import 'data/root_page.dart';
import 'widgets/games.dart';
import 'widgets/home.dart';
import 'widgets/login_signup.dart';
import 'widgets/stats.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bid Euchre',
      theme: ThemeData(
        primaryColor: Colors.blueGrey[800],
        primarySwatch: Colors.blueGrey,
        accentColor: Colors.red[800],
        buttonTheme: ButtonThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textTheme: ButtonTextTheme.primary,
        ),
        cardTheme: CardTheme(
          elevation: 0,
          shape: RoundedRectangleBorder(
            side: BorderSide(width: 1, color: Colors.grey[300]),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        dialogTheme: DialogTheme(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
        ),
        textTheme: TextTheme(
          headline4: TextStyle(fontSize: 32.0, fontWeight: FontWeight.w400, color: Colors.black),
          subtitle1: TextStyle(fontSize: 16.0, fontWeight: FontWeight.w300),
          bodyText1: TextStyle(fontSize: 16.0),
        ),
      ),
      home: Root(),
    );
  }
}

class Root extends StatefulWidget {
  Root();

  @override
  _RootState createState() => _RootState();
}

class _RootState extends State<Root> {
  AuthStatus authStatus = AuthStatus.NOT_DETERMINED;
  bool inited = false;
  Auth auth;
  final List<RootPage> pages = [
    RootPage('Home', Icons.home, HomePage()),
    RootPage('Games', MdiIcons.cardsPlayingOutline, GamesPage()),
    RootPage('Stats', MdiIcons.chartLine, StatsPage()),
  ];
  int _currentIndex = 0;

  void initializeFlutterFire() async {
    await Firebase.initializeApp();
    setState(() {
      inited = true;
      auth = Auth();
      DataStore.auth = auth;
      auth.onStateChanged((user) {
        if (user == null) {
          DataStore.currentUserId = null;
        } else {
          DataStore.currentUserId = user.uid;
        }
        setState(() {
          authStatus = user?.uid == null ? AuthStatus.NOT_LOGGED_IN : AuthStatus.LOGGED_IN;
        });
      });
    });
  }

  @override
  void initState() {
    initializeFlutterFire();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (!inited) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Loading'),
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }
    switch (authStatus) {
      case AuthStatus.NOT_LOGGED_IN:
        return LoginSignup();
      case AuthStatus.LOGGED_IN:
        return Scaffold(
          body: IndexedStack(
            children: pages.map((p) => p.widget).toList(),
            index: _currentIndex,
          ),
          bottomNavigationBar: BottomNavigationBar(
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            currentIndex: _currentIndex,
            items: pages.map((page) => _buildNavBarItem(page.iconData, page.title)).toList(),
          ),
        );
      default:
      // loading for a fraction of second, show blank screen
        return Scaffold(
          body: Container(),
        );
    }
  }

  BottomNavigationBarItem _buildNavBarItem(IconData iconData, String title) {
    return BottomNavigationBarItem(
      icon: Icon(iconData),
      label: title,
      backgroundColor: Theme.of(context).primaryColor,
    );
  }
}

enum AuthStatus {
  NOT_DETERMINED,
  NOT_LOGGED_IN,
  LOGGED_IN,
}
