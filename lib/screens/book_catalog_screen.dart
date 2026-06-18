import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';

class BookCatalogScreen extends StatefulWidget {
  const BookCatalogScreen({super.key});

  @override
  State<BookCatalogScreen> createState() => _BookCatalogScreenState();
}

class _BookCatalogScreenState extends State<BookCatalogScreen> {
  final String apiUrl = 'https://lumina-library-ecas.onrender.com/api/books';
  final String borrowUrl = 'https://lumina-library-ecas.onrender.com/api/borrow';
  final String returnUrl = 'https://lumina-library-ecas.onrender.com/api/return';

  List<Map<String, dynamic>> allBooks = [];
  List<Map<String, dynamic>> filteredBooks = [];
  TextEditingController searchController = TextEditingController();
  bool isLoading = true;

  String currentUser = 'meghana';
  String? activeBookId;
  Timer? _returnTimer;
  int _secondsRemaining = 0;

  @override
  void initState() {
    super.initState();
    fetchBooks();
  }

  @override
  void dispose() {
    _returnTimer?.cancel();
    searchController.dispose();
    super.dispose();
  }

  Future<void> fetchBooks() async {
    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (!mounted) return;

      if (response.statusCode == 200) {
        final List<dynamic> decoded = json.decode(response.body);
        final List<Map<String, dynamic>> safeList = decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();

        Map<String, dynamic>? activeBook;
        for (var b in safeList) {
          final borrowers = b['activeBorrowers'] as List<dynamic>? ?? [];
          if (borrowers.contains(currentUser)) {
            activeBook = b;
            break;
          }
        }

        if (activeBook != null) {
          activeBookId = activeBook['id']?.toString();
          
        
          final prefs = await SharedPreferences.getInstance();
          int? endTime = prefs.getInt('endTime_$currentUser');

          if (endTime != null) {
            final now = DateTime.now().millisecondsSinceEpoch;
            final diffInSeconds = (endTime - now) ~/ 1000;
            
            if (diffInSeconds > 0) {
              setState(() {
                _secondsRemaining = diffInSeconds;
              });
              if (_returnTimer == null || !_returnTimer!.isActive) startTimer();
            } else {
              handleReturn(activeBookId!); 
            }
          } else {
            final newEndTime = DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch;
            await prefs.setInt('endTime_$currentUser', newEndTime);
            setState(() {
              _secondsRemaining = 3600;
            });
            if (_returnTimer == null || !_returnTimer!.isActive) startTimer();
          }
        } else {
          activeBookId = null;
          _returnTimer?.cancel();
        }

        setState(() {
          allBooks = safeList;
          filteredBooks = safeList;
          isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  void filterSearch(String query) {
    setState(() {
      filteredBooks = allBooks.where((book) {
        final title = (book['title'] ?? '').toString().toLowerCase();
        final subject = (book['subject'] ?? '').toString().toLowerCase();
        return title.contains(query.toLowerCase()) || subject.contains(query.toLowerCase());
      }).toList();
    });
  }

  void startTimer() {
    _returnTimer?.cancel();
    _returnTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        timer.cancel();
        if (activeBookId != null) handleReturn(activeBookId!);
      }
    });
  }

  String formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  Future<void> handleBorrow(String bookId) async {
    try {
      final response = await http.post(
        Uri.parse(borrowUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'bookId': bookId, 'username': currentUser}),
      );
      if (!mounted) return; 
      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        final endTime = DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch;
        await prefs.setInt('endTime_$currentUser', endTime);
        
        setState(() {
          _secondsRemaining = 3600;
        });
        startTimer();
      }
      fetchBooks();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error connecting to server')));
    }
  }

  Future<void> handleReturn(String bookId) async {
    try {
      final response = await http.post(
        Uri.parse(returnUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'bookId': bookId, 'username': currentUser}),
      );
      if (!mounted) return; 
      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('endTime_$currentUser');

        setState(() {
          activeBookId = null;
          _returnTimer?.cancel();
        });
      }
      fetchBooks();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error returning resource')));
    }
  }

  Future<void> _openMaterialUrl(String bookTitle) async {
    String link = 'https://en.wikipedia.org/wiki/Computer_science'; 

    if (bookTitle.contains('Natural Language')) {
      link = 'https://huggingface.co/learn/nlp-course/chapter1/1';
    } else if (bookTitle.contains('Compiler')) {
      link = 'https://www.geeksforgeeks.org/compiler-design-tutorials/';
    } else if (bookTitle.contains('MERN') || bookTitle.contains('Full-Stack')) {
      link = 'https://react.dev/learn';
    } else if (bookTitle.contains('Augmented') || bookTitle.contains('WebVR')) {
      link = 'https://aframe.io/docs/';
    } else if (bookTitle.contains('Algorithmic')) {
      link = 'https://leetcode.com/explore/learn/';
    } else if (bookTitle.contains('Cloud')) {
      link = 'https://aws.amazon.com/getting-started/';
    } else if (bookTitle.contains('Cyber')) {
      link = 'https://www.cybrary.it/';
    }

    final Uri url = Uri.parse(link);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication); 
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open material')));
    }
  }

  Drawer _buildAppDrawer() {
    return Drawer(
      backgroundColor: const Color(0xFFF0EFFF),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Color(0xFFF0EFFF)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.account_balance, size: 40, color: Color(0xFF5A4FCF)),
                SizedBox(height: 10),
                Text('Lumina Library', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF5A4FCF))),
                Text('Knowledge Allocation Network', style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.menu_book, color: Color(0xFF5A4FCF)),
            title: const Text('Book Catalog', style: TextStyle(fontWeight: FontWeight.bold)),
            onTap: () => Navigator.pop(context), 
          ),
          ListTile(
            leading: const Icon(Icons.info_outline, color: Colors.teal),
            title: const Text('How it Works'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const HowItWorksScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.history, color: Colors.orange),
            title: const Text('Session History'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const HistoryScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.headset_mic, color: Colors.blue),
            title: const Text('Help Desk & Contact'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const HelpDeskScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.person_pin, color: Colors.deepPurple),
            title: const Text('About Us'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const AboutScreen()));
            },
          ),
          const SizedBox(height: 100),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.redAccent, 
                side: const BorderSide(color: Colors.redAccent)
              ),
              onPressed: () {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
              },
              child: const Text('Exit Session', style: TextStyle(color: Colors.redAccent)),
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Color(0xFF5A4FCF)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16, top: 10, bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(color: const Color(0xFFE8E5FF), borderRadius: BorderRadius.circular(20)),
            child: Row(
              children: [
                const Icon(Icons.person, color: Color(0xFF5A4FCF), size: 16),
                const SizedBox(width: 8),
                Text('Reader: $currentUser', style: const TextStyle(color: Color(0xFF5A4FCF), fontWeight: FontWeight.bold)),
              ],
            ),
          )
        ],
      ),
      drawer: _buildAppDrawer(),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF5A4FCF)))
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Explore\nResources', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF333333))),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0EFFF),
                      borderRadius: BorderRadius.circular(8),
                      border: const Border(left: BorderSide(color: Color(0xFF5A4FCF), width: 4)),
                    ),
                    child: const Text(
                      '"The beautiful thing about learning is that no one can take it away from you."\n— B.B. King (Curated for Lumina Students)',
                      style: TextStyle(fontStyle: FontStyle.italic, color: Color(0xFF555555)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: searchController,
                    onChanged: filterSearch,
                    decoration: InputDecoration(
                      hintText: 'Search titles, subjects...',
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      itemCount: filteredBooks.length,
                      itemBuilder: (context, index) {
                        final book = filteredBooks[index];

                        final String bookId = book['id']?.toString() ?? '';
                        final String bookTitle = book['title']?.toString() ?? 'Unknown Title';
                        final String bookSubject = book['subject']?.toString() ?? 'Subject';
                        final String availableTokens = book['availableTokens']?.toString() ?? '0';
                        final String totalTokens = book['totalTokens']?.toString() ?? '0';

                        final bool isMyBook = activeBookId == bookId;
                        final bool isLocked = activeBookId != null && !isMyBook;

                        return Card(
                          color: Colors.white,
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          margin: const EdgeInsets.only(bottom: 16),
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(color: const Color(0xFFF0EFFF), borderRadius: BorderRadius.circular(4)),
                                  child: Text(bookSubject, style: const TextStyle(fontSize: 10, color: Color(0xFF5A4FCF), fontWeight: FontWeight.bold)),
                                ),
                                const SizedBox(height: 12),
                                Text(bookTitle, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                                const SizedBox(height: 12),
                                Text('Available Copies: $availableTokens / $totalTokens', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                const SizedBox(height: 8),
                                Container(height: 4, width: 100, color: const Color(0xFF5A4FCF)),
                                const SizedBox(height: 16),

                                if (isMyBook) ...[
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(color: const Color(0xFFE8FAF0), borderRadius: BorderRadius.circular(12)),
                                    child: Column(
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            const Icon(Icons.timer, color: Colors.orange, size: 16),
                                            const SizedBox(width: 8),
                                            Text('${formatTime(_secondsRemaining)} left', style: const TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.bold)),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        const Text('🔒 Material Access Unlocked!', style: TextStyle(color: Colors.teal, fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 12),
                                        SizedBox(
                                          width: double.infinity,
                                          child: ElevatedButton.icon(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(0xFF00C896), 
                                              padding: const EdgeInsets.symmetric(vertical: 12)
                                            ),
                                            onPressed: () => _openMaterialUrl(bookTitle), 
                                            icon: const Icon(Icons.menu_book, color: Colors.white),
                                            label: const Text('Read Online Content', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                                          ),
                                        ),
                                        TextButton(
                                          onPressed: () => handleReturn(bookId),
                                          child: const Text('Return Copy Now', style: TextStyle(color: Colors.redAccent)),
                                        )
                                      ],
                                    ),
                                  )
                                ] else if (isLocked) ...[
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.grey[300], 
                                        padding: const EdgeInsets.symmetric(vertical: 12)
                                      ),
                                      onPressed: null,
                                      icon: const Icon(Icons.lock, color: Colors.grey),
                                      label: const Text('Locked', style: TextStyle(color: Colors.grey)),
                                    ),
                                  )
                                ] else ...[
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF5A4FCF), 
                                        padding: const EdgeInsets.symmetric(vertical: 12)
                                      ),
                                      onPressed: () => handleBorrow(bookId),
                                      icon: const Icon(Icons.flash_on, color: Colors.amber),
                                      label: const Text('Borrow Book Copy', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                                    ),
                                  )
                                ]
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About Us', style: TextStyle(color: Colors.white)), backgroundColor: const Color(0xFF5A4FCF), iconTheme: const IconThemeData(color: Colors.white)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.auto_stories, size: 100, color: Color(0xFF5A4FCF)),
            const SizedBox(height: 20),
            const Text('Lumina Academic Library', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.black87)),
            const SizedBox(height: 10),
            const Text('Version 2.0 (Flutter Hybrid)', style: TextStyle(fontSize: 16, color: Colors.grey)),
            const SizedBox(height: 40),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: const Color(0xFFF0EFFF), borderRadius: BorderRadius.circular(16)),
              child: const Column(
                children: [
                  Text('Developed & Designed by', style: TextStyle(fontSize: 16, color: Colors.grey)),
                  SizedBox(height: 8),
                  Text('MEGHANA YELURI', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Color(0xFF5A4FCF), letterSpacing: 2)),
                  SizedBox(height: 8),
                  Text('Full-Stack Developer | Innovator', style: TextStyle(fontSize: 14, color: Colors.teal, fontWeight: FontWeight.bold)),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

class HowItWorksScreen extends StatelessWidget {
  const HowItWorksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('How It Works', style: TextStyle(color: Colors.white)), backgroundColor: Colors.teal, iconTheme: const IconThemeData(color: Colors.white)),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: const [
          ListTile(
            leading: CircleAvatar(backgroundColor: Colors.teal, child: Text('1', style: TextStyle(color: Colors.white))),
            title: Text('Browse Catalog', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Search and find your desired academic resource.'),
          ),
          Divider(),
          ListTile(
            leading: CircleAvatar(backgroundColor: Colors.teal, child: Text('2', style: TextStyle(color: Colors.white))),
            title: Text('Borrow Resource', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Click on Borrow to allocate a secure token to your account.'),
          ),
          Divider(),
          ListTile(
            leading: CircleAvatar(backgroundColor: Colors.teal, child: Text('3', style: TextStyle(color: Colors.white))),
            title: Text('1-Hour Lock System', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Read the content. Other books will be locked until you return the current one.'),
          ),
        ],
      ),
    );
  }
}

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Session History', style: TextStyle(color: Colors.white)), backgroundColor: Colors.orange, iconTheme: const IconThemeData(color: Colors.white)),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_toggle_off, size: 80, color: Colors.orange),
            SizedBox(height: 20),
            Text('No past sessions found.', style: TextStyle(fontSize: 18, color: Colors.grey)),
            Text('Start borrowing to build your history!', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

class HelpDeskScreen extends StatelessWidget {
  const HelpDeskScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Help Desk & Contact', style: TextStyle(color: Colors.white)), backgroundColor: Colors.blue, iconTheme: const IconThemeData(color: Colors.white)),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Need Assistance?', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.email, color: Colors.blue),
              title: const Text('Email Support'),
              subtitle: const Text('meghanayeluri0306@gmail.com'),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.phone, color: Colors.blue),
              title: const Text('Technical Hotline'),
              subtitle: const Text('+91 8919873965'),
              onTap: () {},
            ),
            const Spacer(),
            const Center(child: Text('Response time: Under 24 hours', style: TextStyle(color: Colors.grey))),
          ],
        ),
      ),
    );
  }
}