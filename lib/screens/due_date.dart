import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_datetime_picker/flutter_datetime_picker.dart';
import 'package:my_todo/screens/screens.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../functions/date_converter.dart';
import 'home_screen.dart';

///////////////////////////////
class MyDue extends StatefulWidget {
  const MyDue({Key? key}) : super(key: key);

  @override
  _MyDueState createState() => _MyDueState();
}

class _MyDueState extends State<MyHomePage> {
  @override
  void initState() {
    super.initState();
  }

  /// ---- ① 非同期にカードリストを生成する関数 ----
  Future<List<dynamic>> getCards() async {
    var prefs = await SharedPreferences.getInstance();
    List<TodoCardWidget> cards = [];
    List<TodoCardWidget> todayCards = [];
    List<TodoCardWidget> thisWeekCards = [];
    List<TodoCardWidget> futureCards = [];
    List<TodoCardWidget> overdueCards = [];
    var todo = prefs.getStringList("todo") ?? [];
    for (var jsonStr in todo) {
      // JSON形式の文字列から辞書形式のオブジェクトに変換し、各要素を取り出し
      var mapObj = jsonDecode(jsonStr);
      var title = mapObj['title']; //this is the cardtitle
      var date = mapObj['date']; // i want a due date
      var priority = mapObj['priority'];
      var priorityNo = mapObj['priorityNo'];
      var state = mapObj['state']; //this is the card done state
      cards.add(TodoCardWidget(
        label: title,
        date: date,
        priority: priority,
        state: state,
        priorityNo: priorityNo,
      ));
    }
    cards.sort((TodoCardWidget a, TodoCardWidget b) =>
        restoreDate.parse(a.date).compareTo(restoreDate.parse(b.date)));
    todayCards = cards
        .where((i) => calculateDifference(restoreDate.parse(i.date)) == 0)
        .toList();
    thisWeekCards = cards
        .where((i) =>
          restoreDate.parse(i.date).isAfter(DateTime.now()) &&
          calculateDifference(restoreDate.parse(i.date)) < 7 &&
          calculateDifference(restoreDate.parse(i.date)) > 0)
        .toList();
    futureCards = cards
        .where((i) =>
          restoreDate.parse(i.date).isAfter(DateTime.now()) &&
          calculateDifference(restoreDate.parse(i.date)) > 7)
        .toList();
    overdueCards = cards
      .where((i) =>
        restoreDate.parse(i.date).isBefore(DateTime.now()))
      .toList();   
    return [cards, todayCards, thisWeekCards, futureCards, overdueCards];
  }

  /// ------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("What's Due Soon?"),
        actions: [
          IconButton(
              onPressed: () {
                SharedPreferences.getInstance().then((prefs) async {
                  await prefs.setStringList("todo", []);
                  setState(() {});
                });
              },
              icon: const Icon(Icons.delete))
        ],
      ),
      body: Center(
        /// ---- ② 非同期にカードリストを更新するには、FutureBuilder を使います----
        child: FutureBuilder<List>(
          future: getCards(), // <--- getCards()メソッドの実行状態をモニタリングする
          builder: (BuildContext context, AsyncSnapshot<List> snapshot) {
            switch (snapshot.connectionState) {
              case ConnectionState.none:
                return const Text('Waiting to start');
              case ConnectionState.waiting:
                return const Text('Loading...');
              default:
                // getCards()メソッドの処理が完了すると、ここが呼ばれる。
                if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                } else if (snapshot.data![0].isEmpty) {
                  return const Text("Please add a todo!",
                      style: TextStyle(color: Colors.grey));
                } else {
                  return Container(
                      padding: const EdgeInsets.all(10.0),
                      child: Column(children: [
                        const Text("Today",
                            style: TextStyle(color: Colors.grey)),
                        (snapshot.data![1].length > 0) ?
                        ListView.builder(
                            scrollDirection: Axis.vertical,
                            shrinkWrap: true,
                            // リストの中身は、snapshot.dataの中に保存されているので、
                            // 取り出して活用する
                            itemCount: snapshot.data![1]!.length,
                            itemBuilder: (BuildContext context, int index) {
                              return snapshot.data![1][index];
                            }) 
                            : const Text("You are in the clear",
                            style: TextStyle(color: Colors.blue)),
                        const Text("This Week",
                            style: TextStyle(color: Colors.grey)),
                        (snapshot.data![2].length > 0) ?
                        ListView.builder(
                            // リストの中身は、snapshot.dataの中に保存されているので、
                            // 取り出して活用するss
                            scrollDirection: Axis.vertical,
                            shrinkWrap: true,
                            itemCount: snapshot.data![2]!.length,
                            itemBuilder: (BuildContext context, int index) {
                              return snapshot.data![2][index];
                            }) 
                            : const Text("You are in the clear",
                            style: TextStyle(color: Colors.blue)),
                        const Text("-These aren't due anytime soon-",
                            style: TextStyle(color: Colors.grey)),
                        ListView.builder(
                            // リストの中身は、snapshot.dataの中に保存されているので、
                            // 取り出して活用するss
                            scrollDirection: Axis.vertical,
                            shrinkWrap: true,
                            itemCount: snapshot.data![3]!.length,
                            itemBuilder: (BuildContext context, int index) {
                              return snapshot.data![3][index];
                            }),
                          const Text("-Overdue!!!!-",
                          style: TextStyle(color: Colors.red)),
                        ListView.builder(
                            // リストの中身は、snapshot.dataの中に保存されているので、
                            // 取り出して活用するss
                            scrollDirection: Axis.vertical,
                            shrinkWrap: true,
                            itemCount: snapshot.data![4]!.length,
                            itemBuilder: (BuildContext context, int index) {
                              return snapshot.data![4][index];
                            }),
                      ]));
                }
            }
          },
        ),

        /// ------------------------------------
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          var data = await _showTextInputDialog(context);
          var label = data[0];
          var date = data[1];
          var priority = data[2];
          var priorityNo = priority == 'One (低い）'
              ? 1
              : priority == 'Two'
                  ? 2
                  : 3;
          if (label != null && date != null && priority != null) {
            SharedPreferences prefs = await SharedPreferences.getInstance();
            var todo = prefs.getStringList("todo") ?? [];
            // 辞書型オブジェクトを生成し、JSON形式の文字列に変換して保存
            var mapObj = {
              "title": label,
              "date": date,
              "state": false,
              "priority": priority,
              "priorityNo": priorityNo,
            };
            var jsonStr = jsonEncode(mapObj);
            todo.add(jsonStr);
            await prefs.setStringList("todo", todo);

            setState(() {});
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<List<String?>> _showTextInputDialog(BuildContext context) async {
    final List<TextEditingController> _textFieldControllers =
        List.generate(3, (i) => TextEditingController());
    return await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Todo'),
            content: Column(
              // crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextField(
                  controller: _textFieldControllers[0],
                  decoration:
                      const InputDecoration(hintText: "タスクの名称を入力してください。"),
                ),
                TextField(
                  controller: _textFieldControllers[1],
                  decoration: InputDecoration(
                      hintText: "締め切りを選んでください。",
                      suffixIcon: IconButton(
                          onPressed: () {
                            DatePicker.showDatePicker(context,
                                showTitleActions: true,
                                minTime: DateTime(2022, 1, 1),
                                maxTime: DateTime(2030, 6, 7),
                                onConfirm: (date) {
                              _textFieldControllers[1].text =
                                  formatDate(date).toString();
                            },
                                currentTime: DateTime.now(),
                                locale: LocaleType.jp);
                          },
                          icon: const Icon(
                              IconData(0xe122, fontFamily: 'MaterialIcons')))),
                ),
                DropdownButtonFormField<String>(
                  value: 'One (低い）',
                  icon: const Icon(Icons.arrow_downward),
                  elevation: 16,
                  style: const TextStyle(color: Colors.blue),
                  onChanged: (String? newValue) {
                    setState(() {
                      _textFieldControllers[2].text = newValue!;
                    });
                  },
                  items: <String>['One (低い）', 'Two', 'Three（高い）']
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                )
              ],
            ),
            actions: <Widget>[
              ElevatedButton(
                child: const Text("キャンセル"),
                onPressed: () => Navigator.pop(context),
              ),
              ElevatedButton(
                child: const Text('OK'),
                onPressed: () => Navigator.pop(context, [
                  _textFieldControllers[0].text,
                  _textFieldControllers[1].text,
                  _textFieldControllers[2].text,
                ]),
              ),
            ],
          );
        });
  }
}
