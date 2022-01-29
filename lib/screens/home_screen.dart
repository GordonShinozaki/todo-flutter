import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_datetime_picker/flutter_datetime_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../functions/dateConverter.dart';

///////////////////////////////
class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  void initState() {
    super.initState();
  }

  /// ---- ① 非同期にカードリストを生成する関数 ----
  Future<List<dynamic>> getCards() async {
    var prefs = await SharedPreferences.getInstance();
    List<TodoCardWidget> cards = [];
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
        priorityNo: priorityNo,
        state: state,
      ));
    }
    return cards;
  }

  /// ------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My TODO"),
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
                } else {
                  return ListView.builder(
                      // リストの中身は、snapshot.dataの中に保存されているので、
                      // 取り出して活用する
                      itemCount: snapshot.data!.length,
                      itemBuilder: (BuildContext context, int index) {
                        return snapshot.data![index];
                      });
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
            print(mapObj);
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
                          icon: Icon(
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

////////////////////
class TodoCardWidget extends StatefulWidget {
  String label;
  // 真偽値（Boolen）型のstateを外部からアクセスできるように修正
  String date;
  String priority;
  int priorityNo;
  var state = false;

  TodoCardWidget({
    Key? key,
    required this.label,
    required this.state,
    required this.date,
    required this.priority,
    required this.priorityNo,
  }) : super(key: key);

  @override
  _TodoCardWidgetState createState() => _TodoCardWidgetState();
}

class _TodoCardWidgetState extends State<TodoCardWidget> {
  void _changeState(value) async {
    setState(() {
      widget.state = value ?? false;
    });

    // --- ③ ボタンが押されたタイミング状態を更新し保存する ---
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var todo = prefs.getStringList("todo") ?? [];

    for (int i = 0; i < todo.length; i++) {
      var mapObj = jsonDecode(todo[i]);
      if (mapObj["title"] == widget.label) {
        mapObj["state"] = widget.state;
        todo[i] = jsonEncode(mapObj);
      }
    }

    prefs.setStringList("todo", todo);

    /// ------------------------------------
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(10),
      child: Container(
        padding: EdgeInsets.all(10),
        child: Column(
          children: [
            Row(
              children: [
                Checkbox(onChanged: _changeState, value: widget.state),
                Text(widget.label),
                Spacer(),
                IconButton(
                    onPressed: () async {
                      var data = await _showEditInputDialog(context);
                      var label = data[0];
                      var date = data[1];
                      var priority = data[2];
                      if (label != null && date != null) {
                        // 辞書型オブジェクトを生成し、JSON形式の文字列に変換して保存
                        widget.label = label;
                        widget.date = date.toString();
                        widget.priority = priority!;
                        setState(() {});
                      } else {
                        throw ("Null input");
                      }
                    },
                    icon: Icon(IconData(0xf67a, fontFamily: 'MaterialIcons')))
              ],
            ),
            Row(
              children: [
                Text(
                  "Due Date:" + widget.date,
                  textAlign: TextAlign.center,
                ),
                Spacer(),
                Chip(
                    backgroundColor: (widget.priority == 'Three（高い）')
                        ? Colors.red
                        : widget.priority == 'Two' ? Colors.amber : Colors.blue,
                    label: Text(widget.priority, style: TextStyle(color: Colors.white),)
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<List<String?>> _showEditInputDialog(BuildContext context) async {
    final List<TextEditingController> _textFieldControllers =
        List.generate(5, (i) => TextEditingController());
    _textFieldControllers[0].text = widget.label;
    _textFieldControllers[1].text = widget.date;
    return await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Edit'),
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextField(
                  controller: _textFieldControllers[0],
                  decoration:
                      const InputDecoration(hintText: "タスクの名称を変更してください。"),
                ),
                TextField(
                  controller: _textFieldControllers[1],
                  decoration: InputDecoration(
                      hintText: "締め切りを選更新してください。",
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
                          icon: Icon(
                              IconData(0xe122, fontFamily: 'MaterialIcons')))),
                ),
                DropdownButtonFormField<String>(
                  value: 'One (低い）',
                  icon: const Icon(Icons.arrow_downward),
                  elevation: 16,
                  style: const TextStyle(color: Colors.deepPurple),
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
