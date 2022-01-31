import 'package:flutter/material.dart';
import 'package:my_todo/screens/screens.dart';

///////////////////////////////
void main() => runApp(const MyApp());

///////////////////////////////
class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(theme: ThemeData(), home: const BottomNavScreen());
  }
}
