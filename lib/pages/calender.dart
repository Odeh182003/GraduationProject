import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
class Calender extends StatefulWidget {
  const Calender({super.key});

  @override
  _Calender createState() => _Calender();
}


class _Calender extends State<Calender> {
  int displayedYear = DateTime.now().year;
  DateTime? selectedDate;
  Map<int, bool> expandedMonths = {};
  Map<String, String> notes = {};

  void _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;
        displayedYear = picked.year;
        expandedMonths = {picked.month: true};
      });
    }
  }

  void _changeYear(int offset) {
    setState(() {
      displayedYear += offset;
      expandedMonths.clear();
    });
  }

  Future<void> _addNoteForDay(DateTime date) async {
    String dateKey = DateFormat('yyyy-MM-dd').format(date);
    String? existingNote = notes[dateKey];

    TextEditingController controller = TextEditingController(
      text: existingNote,
    );

    String? result = await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Add Note for ${DateFormat.yMMMd().format(date)}'),
            content: TextField(
              controller: controller,
              decoration: InputDecoration(hintText: 'Enter note...'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, controller.text.trim()),
                child: Text('Save'),
              ),
            ],
          ),
    );

    if (result != null) {
      setState(() {
        notes[dateKey] = result;
      });
    }
  }

  Widget _buildMonth(int month) {
    DateTime firstDay = DateTime(displayedYear, month, 1);
    int daysInMonth = DateUtils.getDaysInMonth(displayedYear, month);
    int startWeekday = firstDay.weekday % 7;

    List<Widget> dayWidgets = [];

    List<String> weekdays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    dayWidgets.addAll(
      weekdays
          .map(
            (day) => Center(
              child: Text(
                day,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
          )
          .toList(),
    );

    for (int i = 0; i < startWeekday; i++) {
      dayWidgets.add(Container());
    }

    for (int day = 1; day <= daysInMonth; day++) {
      DateTime current = DateTime(displayedYear, month, day);
      bool isSelected =
          selectedDate != null &&
          selectedDate!.year == displayedYear &&
          selectedDate!.month == month &&
          selectedDate!.day == day;

      String dateKey = DateFormat('yyyy-MM-dd').format(current);
      bool hasNote = notes.containsKey(dateKey);

      bool isWeekend =
          current.weekday == DateTime.saturday ||
          current.weekday == DateTime.sunday;

      dayWidgets.add(
        GestureDetector(
          onTap: () async {
            setState(() {
              selectedDate = current;
            });
            await _addNoteForDay(current);
          },
          child: Container(
            margin: EdgeInsets.all(4),
            decoration: BoxDecoration(
              color:
                  isSelected
                      ? Colors.blueAccent
                      : isWeekend
                      ? Colors.red.shade100
                      : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(6),
              border:
                  hasNote
                      ? Border.all(color: Colors.green, width: 2)
                      : Border.all(color: Colors.transparent),
            ),
            alignment: Alignment.center,
            child: Text('$day'),
          ),
        ),
      );
    }

    return ExpansionTile(
      title: Text(
        DateFormat.MMMM().format(firstDay),
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      initiallyExpanded: expandedMonths[month] ?? false,
      onExpansionChanged: (expanded) {
        setState(() {
          expandedMonths[month] = expanded;
        });
      },
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            children: dayWidgets,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Year Calendar - $displayedYear'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: () => _changeYear(-1),
                icon: Icon(Icons.arrow_back),
                label: Text("Previous Year"),
              ),
              SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: _pickDate,
                icon: Icon(Icons.calendar_today),
                label: Text("Pick Date"),
              ),
              SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () => _changeYear(1),
                icon: Icon(Icons.arrow_forward),
                label: Text("Next Year"),
              ),
            ],
          ),
          SizedBox(height: 10),
          Expanded(
            child: ListView.builder(
              itemCount: 12,
              itemBuilder: (context, index) {
                return _buildMonth(index + 1);
              },
            ),
          ),
        ],
      ),
    );
  }
}
