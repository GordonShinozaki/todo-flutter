import 'package:flutter/material.dart';
import 'package:my_todo/screens/screens.dart';

///////////////////////////////
void main() => runApp(MyApp());

///////////////////////////////
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(theme: ThemeData(), home: BottomNavScreen());
  }
}
