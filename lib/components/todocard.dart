import 'dart:convert';
import 'package:flutter/material.dart';
import '../functions/date_converter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_datetime_picker/flutter_datetime_picker.dart';

class TodoCardWidget extends StatefulWidget {
  String? label;
  // 真偽値（Boolen）型のstateを外部からアクセスできるように修正
  String date;
  String priority;
  int priorityNo;
  String doneDate;
  String hash;
  var state = false;

  TodoCardWidget({
    Key? key,
    required this.label,
    required this.state,
    required this.date,
    required this.priority,
    required this.priorityNo,
    this.doneDate = '202001',
    required this.hash,
  }) : super(key: key);

  @override
  _TodoCardWidgetState createState() => _TodoCardWidgetState();
}

class _TodoCardWidgetState extends State<TodoCardWidget> {
  void _changeState(value,
      {String? label, String? date, String? priority}) async {
    setState(() {
      widget.state = value ?? false;
      widget.doneDate = widget.state
          ? formatDate(DateTime.now())
          : formatDate(DateTime.now());
      if (label != null && date != null && priority != null) {
        widget.label = label;
        widget.date = date;
        widget.priority = priority;
      }
    });
    // --- ③ ボタンが押されたタイミング状態を更新し保存する ---
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var todo = prefs.getStringList("todo") ?? [];

    for (int i = 0; i < todo.length; i++) {
      var mapObj = jsonDecode(todo[i]);
      if (mapObj["hash"] == widget.hash) {
        if (widget.label == "will be removed") {
          todo.remove(todo[i]);
        } else {
          mapObj["state"] = widget.state;
          mapObj["date"] = widget.date;
          mapObj["title"] = widget.label;
          mapObj["priority"] = widget.priority;
          mapObj["doneDate"] = widget.doneDate;
          todo[i] = jsonEncode(mapObj);
        }
      }
    }

    prefs.setStringList("todo", todo);

    /// ------------------------------------
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(10),
      child: Container(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            Row(
              children: [
                Checkbox(onChanged: _changeState, value: widget.state),
                Text(widget.label.toString()),
                const Spacer(),
                IconButton(
                    onPressed: () {
                      _changeState(widget.state, label: "will be removed", date: widget.date, priority: widget.priority);
                    },
                    icon: const Icon(Icons.delete)),
                IconButton(
                    onPressed: () async {
                      var data = await _showEditInputDialog(context);
                      var label = data[0];
                      var date = data[1];
                      var priority = data[2];
                      _changeState(widget.state,
                          label: label.toString(),
                          date: date.toString(),
                          priority: priority.toString());
                    },
                    icon: const Icon(
                        IconData(0xf67a, fontFamily: 'MaterialIcons')))
              ],
            ),
            Row(
              children: [
                Text(
                  (widget.state)
                      ? "Done Date: " + widget.doneDate
                      : "Due Date: " + widget.date,
                  textAlign: TextAlign.center,
                ),
                const Spacer(),
                Chip(
                    backgroundColor: (widget.priority == 'Three（高い）')
                        ? Colors.red
                        : widget.priority == 'Two'
                            ? Colors.amber
                            : Colors.blue,
                    label: Text(
                      widget.priority,
                      style: const TextStyle(color: Colors.white),
                    )),
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
    _textFieldControllers[0].text = widget.label.toString();
    _textFieldControllers[1].text = widget.date;
    _textFieldControllers[2].text = widget.priority;
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
                          icon: const Icon(
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
                  onPressed: () => {
                        Navigator.pop(context, [
                          _textFieldControllers[0].text,
                          _textFieldControllers[1].text,
                          _textFieldControllers[2].text,
                        ])
                      }),
            ],
          );
        });
  }
}
