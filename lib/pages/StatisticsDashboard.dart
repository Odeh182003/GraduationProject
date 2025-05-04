import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

class StatisticsPage extends StatefulWidget {
  @override
  _StatisticsPageState createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  Map<String, dynamic>? data;

  @override
  void initState() {
    super.initState();
    fetchStats();
  }

  Future<void> fetchStats() async {
    final response = await http.get(Uri.parse("http://192.168.10.5/public_html/FlutterGrad/statistics.php"));
    if (response.statusCode == 200) {
      setState(() {
        data = json.decode(response.body);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (data == null) {
      return Scaffold(
backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
  backgroundColor: Colors.white,
  foregroundColor: Colors.green,
  elevation: 1,
  title: Row(
    children: [
      Image.asset(
        'assets/logo.png',
        height: 40, // Adjust height as needed
      ),
      const SizedBox(width: 8), // Space between image and text
      const Text(
        "University Statistics",
        style: TextStyle(
          color: Colors.green, // Ensure text color matches your theme
        ),
      ),
    ],
  ),
      ),        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text("University Statistics")),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(12),
        child: Column(
          children: [
            buildInfoGrid(),
            SizedBox(height: 20),
            buildActivityPieChart(),
            SizedBox(height: 20),
            buildFacultyPostChart(),
            SizedBox(height: 20),
            buildFacultyList(),
          ],
        ),
      ),
    );
  }

  Widget buildInfoGrid() {
    List<Map<String, String>> stats = [
      {"title": "Total Users", "value": data!["total_users"]},
      {"title": "Active Students", "value": data!["active_students"]},
      {"title": "Active Faculty", "value": data!["active_faculty"]},
      {"title": "Total Posts", "value": data!["total_posts"].toString()},
      {"title": "Public Posts", "value": data!["public_posts"]},
      {"title": "Private Posts", "value": data!["private_posts"]},
      {"title": "Total Activities", "value": data!["total_activities"]},
      {"title": "Messages Groups", "value": data!["messagesgroup"]},
    ];

    return StaggeredGrid.count(
      crossAxisCount: 4,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      children: stats.map((stat) {
        return Card(
          color: Colors.blue.shade100,
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(stat["title"]!, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text(stat["value"]!, style: TextStyle(fontSize: 24, color: Colors.blue.shade900)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget buildActivityPieChart() {
    final total = int.parse(data!["total_activities"]);
    if (total == 0) return Container();

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Text("Activity Status", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 12),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: [
                    PieChartSectionData(
                      value: double.parse(data!["done_activities"]),
                      title: 'Done',
                      color: Colors.green,
                    ),
                    PieChartSectionData(
                      value: double.parse(data!["pending_activities"]),
                      title: 'Pending',
                      color: Colors.orange,
                    ),
                    PieChartSectionData(
                      value: double.parse(data!["cancelled_activities"]),
                      title: 'Cancelled',
                      color: Colors.red,
                    ),
                  ],
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildFacultyPostChart() {
    List<dynamic> facultyPosts = data!["faculty_posts"];

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Text("Posts by Faculty", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(
              height: 250,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: true),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < facultyPosts.length) {
                            return RotatedBox(
                              quarterTurns: 1,
                              child: Text(facultyPosts[index]["facultyName"], style: TextStyle(fontSize: 10)),
                            );
                          }
                          return Text('');
                        },
                      ),
                    ),
                  ),
                  barGroups: facultyPosts.asMap().entries.map((entry) {
                    final i = entry.key;
                    final post = entry.value;
                    return BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: double.parse(post["count"]),
                          color: Colors.purpleAccent,
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildFacultyList() {
    final faculties = data!["faculties"] as List;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Faculties", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        SizedBox(height: 10),
        ...faculties.map((f) {
          return Card(
            child: ListTile(
              title: Text(f["facultyName"]),
              subtitle: Text("Academic Members: ${f["academic_count"]}"),
              trailing: Icon(Icons.school),
            ),
          );
        }).toList(),
      ],
    );
  }
}
