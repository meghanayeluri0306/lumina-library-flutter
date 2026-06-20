import 'package:flutter/material.dart';
import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String currentUser = "Student";
  int minsToday = 0;
  String timeThisWeek = "0 Hrs";
  List<String> readBooks = [];

  Map<String, double> weeklyVelocity = {
    'Mon': 0.0, 'Tue': 0.0, 'Wed': 0.0, 'Thu': 0.0, 'Fri': 0.0, 'Sat': 0.0, 'Sun': 0.0,
  };

  @override
  void initState() {
    super.initState();
    _loadUserAnalytics();
  }

  void _loadUserAnalytics() {
    
    final loggedInUser = html.window.localStorage['username'] ?? 'Reader';

  
    final userStorageKey = 'analytics_db_${loggedInUser.toLowerCase()}';
    final rawData = html.window.localStorage[userStorageKey];

    if (rawData != null) {
      try {
        final data = json.decode(rawData) as Map<String, dynamic>;
        setState(() {
          currentUser = loggedInUser;
          minsToday = data['mins_today'] ?? 0;
          timeThisWeek = data['time_week'] ?? "0 Hrs";
          readBooks = List<String>.from(data['books'] ?? []);
          
          if (data['velocity'] != null) {
            Map<String, dynamic> vMap = data['velocity'];
            vMap.forEach((k, v) => weeklyVelocity[k] = (v as num).toDouble());
          }
        });
        return;
      } catch (e) {
        
      }
    }

  
    setState(() {
      currentUser = loggedInUser;
      minsToday = 0;
      timeThisWeek = "0 Hrs";
      readBooks = []; 
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$currentUser\'s Reading Log', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF5A4FCF),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Your Focus Stats', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            
            
            Row(
              children: [
                _buildStatBox('Today', '$minsToday Mins', Icons.today, Colors.orange),
                const SizedBox(width: 12),
                _buildStatBox('This Week', timeThisWeek, Icons.calendar_month, Colors.deepPurple),
                const SizedBox(width: 12),
                _buildStatBox('Completed', '${readBooks.length} Books', Icons.menu_book, Colors.green),
              ],
            ),

            const SizedBox(height: 28),

            
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, spreadRadius: 2)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Weekly Velocity Bar-Chart', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: weeklyVelocity.entries.map((entry) {
                      bool isToday = entry.key == 'Sun'; // డెమో కోసం సండే 'Today' అనుకుందాం
                      return _buildBar(entry.key, entry.value, isToday);
                    }).toList(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            
            const Text('Reading History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            
            readBooks.isEmpty
                ? Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(color: Colors.deepPurple.withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
                    child: const Column(
                      children: [
                        Icon(Icons.auto_stories, size: 48, color: Colors.grey),
                        SizedBox(height: 8),
                        Text("No reading history found for this account.", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                        Text("Borrow a resource from the catalog to start your streak!", style: TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: readBooks.length,
                    itemBuilder: (context, index) {
                      return Card(
                        elevation: 1,
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          leading: const CircleAvatar(backgroundColor: Color(0xFF5A4FCF), child: Icon(Icons.check, color: Colors.white)),
                          title: Text(readBooks[index], style: const TextStyle(fontWeight: FontWeight.bold)),
                          trailing: const Text('Completed', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatBox(String title, String val, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(16), border: Border.all(color: color.withOpacity(0.3))),
        child: Column(
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 8),
            Text(val, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: color)),
            Text(title, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildBar(String day, double fill, bool isToday) {
    return Column(
      children: [
        Container(
          height: 110, width: 18, alignment: Alignment.bottomCenter,
          decoration: BoxDecoration(color: Colors.grey.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
          child: FractionallySizedBox(
            heightFactor: fill, // 0.0 ఉంటే బార్ అస్సలు పైకి లేవదు (ఖాళీగా ఉంటుంది!)
            child: Container(decoration: BoxDecoration(color: isToday ? Colors.orange : const Color(0xFF5A4FCF), borderRadius: BorderRadius.circular(10))),
          ),
        ),
        const SizedBox(height: 8),
        Text(day, style: TextStyle(fontSize: 12, fontWeight: isToday ? FontWeight.bold : FontWeight.normal, color: isToday ? Colors.orange : Colors.grey)),
      ],
    );
  }
}