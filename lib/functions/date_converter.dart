import 'package:intl/intl.dart';

String formatDate(DateTime date) => DateFormat("yyyy MMMM d").format(date);
DateFormat restoreDate = DateFormat("yyyy MMMM d");

int calculateDifference(DateTime date) {
  DateTime now = DateTime.now();
  return DateTime(date.year, date.month, date.day).difference(DateTime(now.year, now.month, now.day)).inDays;
}