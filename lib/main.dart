import 'package:flutter/material.dart';

///////////////////////////////
// ① Main：Flutterアプリもmain()からコードが実行されます。
// `void main() => runApp(MyApp());` でも意味は同じです。
void main() {
  return runApp(MyApp());
}

///////////////////////////////
// ② アプリの基盤：アプリのテーマやスタイルを設定する。その上のページを追加していく。
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // MaterialAppという形式のアプリを作成
    return MaterialApp(
      theme: ThemeData(), // アプリのテーマカラーなど詳細を入力
      home: MyHomePage(), // メインページを作成
    );
  }
}

///////////////////////////////
// ⑦ MyHomePage本体
class MyHomePage extends StatefulWidget {

  // ⑦-1: TodoCardWidgetを一時的に保存する配列を作成
  List<Widget> cards = [];

  MyHomePage({Key? key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

// ⑧ MyHomePageの状態
class _MyHomePageState extends State<MyHomePage> {


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Menu Bar"),
      ),
      body: Center(
        // ⑧-3: ListViewのchildrenをwidget.cardsに変更
        child:  ListView.builder(
          itemCount: widget.cards.length,
          itemBuilder: (BuildContext context, int index) {
            return widget.cards[index];
          },
        ),
      ),
      // ⑧-1: 画面右下にボタンを追加
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Add your onPressed code here!
          setState(() {
            // ⑧-2: ボタンが押された時に、TodoCardWidgetをcardsに追加
            widget.cards.add(TodoCardWidget(label: "a"));
          });
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

////////////////////
/// ⑤ StatefulWidget本体
class TodoCardWidget extends StatefulWidget {
  final String label;
  var state = false;

  TodoCardWidget({Key? key, required this.label}) : super(key: key);

  @override
  _TodoCardWidgetState createState() => _TodoCardWidgetState();
}

/// ⑤ TodoCardWidgetの状態
class _TodoCardWidgetState extends State<TodoCardWidget> {
  void _changeState(value) {
    setState(() {
      widget.state = value ?? false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(10),
      child: Container(
        padding: EdgeInsets.all(10),
        child: Row(
          children: [
            Checkbox(onChanged: _changeState, value: widget.state),
            Text(widget.label),
          ],
        ),
      ),
    );
  }
}