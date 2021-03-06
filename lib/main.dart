import 'dart:async';
import 'requester.dart';
import 'racerCard.dart';
import 'settingsView.dart';
import 'globals.dart';

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'dart:math';

var rng = Random();

void main() => runApp(new MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Thwack Timing',
      theme: new ThemeData(
        primaryColor: Colors.blueGrey[700],
        primaryColorDark: Color(0xFF455A64),
        primaryColorLight: Color(0xFFCFD8DC),
        accentColor: Colors.blue,
      ),
      home: new MyHomePage(title: 'Thwack Timing Gate'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _MyHomePageState createState() => new _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with SingleTickerProviderStateMixin{

  static const List<IconData> icons = const [ Icons.sort_by_alpha, Icons.access_time, Icons.timer ];
  AnimationController _controller;

  @override
  void initState() {
    _controller = new AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  void _sortCards(List cards){
    if(gSortType == 3){ //reverse list if sorting by finish time
      setState(() {
        cards.sort((a,b) => b[gSortType].compareTo(a[gSortType]));
      });
    }
    else if(gSortType == 2){
      List dnfs = [];
      for (var i = 0; i < cards.length; i++) {
        if (cards[i][2] == 0) {
          dnfs.add(cards[i]);
          cards.removeAt(i);
        }
      }
      cards.sort((a,b) => a[gSortType].compareTo(b[gSortType]));
      setState(() {
        cards.addAll(dnfs);
      });
    }
    else{
      setState(() {
        cards.sort((a,b) => a[gSortType].compareTo(b[gSortType]));
      });
    }
  }

  Future<Null> _updateCards() async {
    final jsonDB = await fetchTimes().
      timeout(
        Duration(seconds: 3),
        onTimeout: (){return [];}
      );

    //error message if request timeouts
    if (jsonDB.length == 0){
      // List<Widget> _errorMessage = [Column(
      //   mainAxisSize: MainAxisSize.min,
      //   mainAxisAlignment: MainAxisAlignment.center,
      //   children: <Widget>[
      //     Text("ERROR"),
      //     Text("An error occured"),
      //     Text("ensure all connections are valid")
      //   ],
      // )];

      // for (var i = 1; i < _card.length; i++) {
      //   _errorMessage.add(_card[i]);
      // }

      //error card
      // List errorCard = [RacerCard(racerID: -1, racerName: "Error", runDuration: -1.0, startTime: "Error")];
      // setState((){
      //   gCards = errorCard;
      // });

    }
    //if request is positive, update cards
    else{
      List _newCards = [];

      for(var i = jsonDB.length-1; i >= 0; i--){
        var entry = jsonDB[i];
        _newCards.add([entry.racerID, entry.runDuration, entry.startTime]);
      }

      setState(() {
        gCards = _newCards;
      });
    }

    return null;
  }

  Future<Null> _tempUpdateCards() async {

    List _tempCard = [
      [1, 54.0, "17:42"],
      [2, 51.2, "17:43"],
      [3, 0, "17:43"],
      [4, 55, "17:44"],
      [5, 51.2, "17:46"],
      [6, 57, "17:50"],
      [7, 0, "18:00"],
      [3, 49, "18:01"],
      [4, 53.3, "18:01"],
      [5, 57.3, "18:06"],
      [6, 51, "18:10"],
    ];

    setState(() {
      gCards = _tempCard;
    });

    return null;
  }
 

  @override
  Widget build(BuildContext context) {
    Color backgroundColor = Theme.of(context).cardColor;
    Color foregroundColor = Theme.of(context).accentColor;

    return new Scaffold(
      appBar: new AppBar(

        title: new Text(widget.title),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: (){
              Navigator.push(
                context, 
                MaterialPageRoute(builder: (context) => SettingsView())
              );

            },
          )
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: new List.generate(icons.length, (int index) {
          Widget child = new Container(
            height: 70.0,
            width: 56.0,
            alignment: FractionalOffset.topCenter,
            child: new ScaleTransition(
              scale: new CurvedAnimation(
                parent: _controller,
                curve: new Interval(
                  0.0,
                  1.0 - index / icons.length / 2.0,
                  curve: Curves.easeOut
                ),
              ),
              child: new FloatingActionButton(
                heroTag: null,
                backgroundColor: backgroundColor,
                mini: true,
                child: new Icon(icons[index], color: foregroundColor),
                onPressed: (){
                  gSortType = ((index == 0 ? 1 : index == 1 ? 3 : index == 2 ? 2 : -1));
                  _sortCards(gCards);
                  _controller.reverse();
                },
              ),
            ),
          );
          return child;
        }).toList()..add(
          new FloatingActionButton(
            heroTag: null,
            child: new AnimatedBuilder(
              animation: _controller,
              builder: (BuildContext context, Widget child) {
                return new Transform(
                  transform: new Matrix4.rotationZ(_controller.value * 0.5 * 3.14159),
                  alignment: FractionalOffset.center,
                  child: AnimatedCrossFade(
                    alignment: Alignment.center,
                    duration: const Duration(milliseconds: 300),
                    firstChild: Icon(Icons.sort),
                    secondChild: Icon(Icons.close),
                    crossFadeState: _controller.isDismissed ? CrossFadeState.showFirst : CrossFadeState.showSecond,
                  )
                );
              },
            ),
            onPressed: () {
              if (_controller.isDismissed) {
                _controller.forward();
              } else {
                _controller.reverse();
              }
            },
          ),
        ),
      ),

      body: Container(
        child: RefreshIndicator(
          onRefresh: (useTestData ? _tempUpdateCards : _updateCards),
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: gCards.length,
            itemBuilder: (context, index) {
              final item = gCards[index];
              return RacerCard(racerID: item[0], racerName: resolveIdToName(item[0]), runDuration: item[1], startTime: item[2]);
            },
          )
        ),
      )
    );
  }
}