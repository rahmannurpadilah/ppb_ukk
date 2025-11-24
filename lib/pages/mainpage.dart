import 'package:apiflutter/pages/homepage.dart';
import 'package:apiflutter/pages/productpage.dart';
import 'package:apiflutter/pages/mystorepage.dart';
import 'package:apiflutter/pages/profilpage.dart';
import 'package:flutter/material.dart';

class MainPage extends StatefulWidget {
  final int initialIndex;   // ⬅ TAMBAHAN

  const MainPage({super.key, this.initialIndex = 0});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  late int _currentIndex;

  // =========================== PAGES ===========================
  final List<Widget> _pages = const [
    HomePage(),       // 0
    ProductPage(),    // 1
    MyStorePage(),    // 2
    ProfilPage(),     // 3
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;   // ⬅ SET INDEX AWAL
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],

      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(20),
            topLeft: Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(0, -2),
            ),
          ],
        ),

        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: Colors.blue,
          unselectedItemColor: Colors.grey,
          showSelectedLabels: false,
          showUnselectedLabels: false,

          onTap: (index) {
            setState(() => _currentIndex = index);
          },

          items: [
            _navItem(Icons.home, 0),
            _navItem(Icons.storefront, 1),
            _navItem(Icons.business_center, 2),
            _navItem(Icons.person, 3),
          ],
        ),
      ),
    );
  }

  // =========================== NAV BAR ICON ===========================
  BottomNavigationBarItem _navItem(IconData icon, int index) {
    bool selected = _currentIndex == index;

    return BottomNavigationBarItem(
      icon: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: selected ? Colors.blue.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          size: selected ? 28 : 24,
          color: selected ? Colors.blue : Colors.grey,
        ),
      ),
      label: "",
    );
  }
}
