import 'dart:math';

import 'package:color_run/authentication/authentication.dart';
import 'package:color_run/constants/inputs_decorations.dart';
import 'package:color_run/firestore/database.dart';
import 'package:color_run/models/user.dart';
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';

import './loss.dart';

import './points.dart';
import './user_interface.dart';

import './colors.dart';
import 'package:flutter/material.dart';

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final Database _database = Database();
  final _nickController = TextEditingController();

  int points = 0;

  bool isStart =
      false; //bool which check if user start game using play icon button

  bool isLoss =
      false; //bool which check if user loss the game (show loss screen)

  //generage random color
  Color drawColor() => Color.fromRGBO(
      Random().nextInt(255), Random().nextInt(255), Random().nextInt(255), 1);

  //start the game
  void startGame() => setState(() => isStart = true);

  //play again (show again ui and play button (called in loss screen))
  void playAgain() => setState(() {
        points = 0;
        isStart = false;
        isLoss = false;
      });

  //calculate the points by time difference between clicked
  void calculatePoints(int timeDifference) => setState(() {
        if (timeDifference >= 5000 && timeDifference < 8000) {
          points += 500;
        } else if (timeDifference >= 8000) {
          points++;
        } else {
          points += (5000 - timeDifference);
        }
      });

  //loss the game (show loss screen on screen and stop clicked on containers)
  void loss() async {
    dynamic uid = await Authentication().getUserId();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if ((prefs.getInt(uid) ?? 0) < points) {
      prefs.setInt(uid, points);
    }
    setState(() {
      isLoss = true;
      isStart = false;
      //save points to firestore
    });
    await _database.updateHighScore(points, uid);
  }

  //----------------check if user is arleady in firestore if not ask about nick and save him into database---------------

  Future checkContains() async {
    dynamic uid = await Authentication().getUserId();
    dynamic result = await _database.checkUserContains(uid);

    if (uid is String && result != null) {
      if (result == false) {
        //show dialog to provide user nick
        await showDialog(
            barrierDismissible: false,
            context: context,
            builder: (context) => WillPopScope(
                  onWillPop: () {},
                  child: AlertDialog(
                    backgroundColor: Color.fromRGBO(34, 12, 44, 1),
                    title: Text(" Nickname",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 18.0,
                            fontWeight: FontWeight.w700)),
                    content: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(" Enter Nickname",
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 15.0,
                                fontWeight: FontWeight.w600)),
                        SizedBox(
                          height: 5.0,
                        ),
                        TextField(
                          controller: _nickController,
                          style: TextStyle(color: Colors.white),
                          cursorColor: Colors.white,
                          decoration: InputLoginTextDecoration.copyWith(
                            hintText: "Enter Nick",
                            hintStyle: TextStyle(color: Colors.grey[400]),
                          ),
                        ),
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.only(top: 15.0),
                          child: FlatButton(
                            padding: EdgeInsets.symmetric(vertical: 20.0),
                            color: Color.fromRGBO(244, 13, 193, 1),
                            onPressed: () async {
                              Navigator.pop(context);
                              await _database.insertUser(User(
                                      nickName: _nickController.text,
                                      uid: uid,
                                      highScore: 0)
                                  .userMap());
                              SharedPreferences prefs =
                                  await SharedPreferences.getInstance();
                              prefs.setInt(uid, 0);
                            },
                            child: Text(
                              "Save",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ));
      } else {
        int highScore = (await _database.getUserInfo(uid)).highScore;
        SharedPreferences preferences = await SharedPreferences.getInstance();
        if (highScore != preferences.getInt(uid)) {
          print("WYKONALO SIE");
          setState(() {
            preferences.setInt(uid, highScore);
          });
        }
      }
    }
  }



  @override
  Widget build(BuildContext context) {
    //get user info object
    Future getHighScore() async {
      final String uid = await Authentication().getUserId();
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      return prefs.getInt(uid) ?? 0;
    }
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          !isStart
              ? GameColors(
                  color: drawColor(),
                  calculatePoints: () {},
                  loss: () {} /*dont play game (cannot get points)*/)
              : GameColors(
                  color: drawColor(),
                  calculatePoints: calculatePoints,
                  loss: loss, /* play game (can get points)*/
                ),
          !isLoss
              ? /*check if loss to show loss screen*/
              Column(
                  mainAxisAlignment: !isStart
                      ? MainAxisAlignment.center
                      : MainAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(
                          top: !isStart
                              ? 0.0
                              : MediaQuery.of(context).size.height * 0.12),
                    ),
                    Points(points),
                    if (!isStart) UserInterface(startGame, getHighScore)
                  ],
                )
              : Loss(
                  playAgain: playAgain,
                  points: points,
                  getHighScore: getHighScore) /*loss game*/
        ],
      ),
    );
  }

  @override
  void initState() {
       super.initState();
       checkContains();
  }
}
