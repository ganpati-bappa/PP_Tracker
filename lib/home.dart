import 'package:flutter/material.dart';
import 'package:pp_tracker/components/navbar.dart';
import 'package:pp_tracker/pages/calendar.dart';
import 'package:pp_tracker/pages/landing_page.dart';
import 'package:pp_tracker/pages/blog_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color.fromARGB(255, 255, 228, 244), Color.fromARGB(255, 254, 249, 223)],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        bottomNavigationBar: Navbar(
          activeIndex: index,
          onTap: (value) => setState(() {
            index = value;
          }),
        ),
        body: IndexedStack(
          index: index,
          children: const [
            LandingPage(),
            CalendarPage(),
            BlogPage(), // Replaced placeholder with the new Health Blog page
            Center(child: Text('Settings Page')),
          ],
        ),
      ),
    );
  }
}
