import 'package:circle_nav_bar/circle_nav_bar.dart';
import 'package:flutter/material.dart';

class Navbar extends StatelessWidget {
  final int activeIndex;
  final Function(int)? onTap;

  const Navbar({super.key, this.activeIndex = 0, this.onTap});

  static final List<Icon> inActiveIcons = [
    Icon(Icons.home_outlined, color: Color.fromARGB(255, 254, 93, 104)),
    Icon(Icons.calendar_month_outlined, color: Color.fromARGB(255, 254, 93, 104)),
    Icon(Icons.speed_outlined, color: Color.fromARGB(255, 254, 93, 104)),
    Icon(Icons.search, color: Color.fromARGB(255, 254, 93, 104)),
  ];

  static final List<Icon> activeIcons = [
    Icon(Icons.home, color: Colors.white),
    Icon(Icons.calendar_month, color: Colors.white),
    Icon(Icons.speed, color: Colors.white),
    Icon(Icons.search, color: Colors.white),
  ];

  @override
  Widget build(BuildContext context) {
    return CircleNavBar(
      activeIcons: Navbar.activeIcons,
      inactiveIcons: Navbar.inActiveIcons,
      color: const Color.fromARGB(255, 255, 200, 204),
      circleColor: const Color.fromARGB(255, 253, 120, 129),
      height: 55,
      circleWidth: 55,
      activeIndex: activeIndex,
      onTap: onTap,
      tabDurationMillSec: 500,
      iconDurationMillSec: 500,
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 24),
      cornerRadius: const BorderRadius.all(Radius.circular(10)),
      shadowColor: const Color.fromARGB(255, 253, 120, 129),
      circleShadowColor: const Color.fromARGB(130, 253, 0, 129),
      elevation: 10,
    );
  }
}
