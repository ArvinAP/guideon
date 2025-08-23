import 'package:flutter/material.dart';

/// A reusable bottom navigation bar with 4 items:
/// 0: Chatbot (sheep)
/// 1: Bible verses (cross)
/// 2: Motivational quotes (head + lightbulb)
/// 3: Journal (book)
///
/// Usage:
/// Scaffold(
///   bottomNavigationBar: GuideOnBottomNav(
///     currentIndex: 0,
///     onItemSelected: (i) { /* navigate */ },
///   ),
/// )
class GuideOnBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onItemSelected;

  const GuideOnBottomNav({
    super.key,
    required this.currentIndex,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF154D71),
            borderRadius: BorderRadius.circular(26),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _NavItem(
                isActive: currentIndex == 0,
                onTap: () => onItemSelected(0),
                child: const Text('🐑', style: TextStyle(fontSize: 22)),
                tooltip: 'Chatbot',
              ),
              _NavItem(
                isActive: currentIndex == 1,
                onTap: () => onItemSelected(1),
                child: const Text('✝', style: TextStyle(fontSize: 20, height: 1.2)),
                tooltip: 'Bible Verses',
              ),
              _NavItem(
                isActive: currentIndex == 2,
                onTap: () => onItemSelected(2),
                child: const Icon(Icons.psychology_alt, color: Colors.white),
                tooltip: 'Motivational Quotes',
              ),
              _NavItem(
                isActive: currentIndex == 3,
                onTap: () => onItemSelected(3),
                child: const Icon(Icons.menu_book, color: Colors.white),
                tooltip: 'Journal',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final bool isActive;
  final VoidCallback onTap;
  final Widget child;
  final String tooltip;

  const _NavItem({
    required this.isActive,
    required this.onTap,
    required this.child,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final activeBg = Colors.white.withOpacity(0.15);
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: isActive ? activeBg : Colors.transparent,
            borderRadius: BorderRadius.circular(22),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: DefaultTextStyle(
            style: const TextStyle(color: Colors.white),
            child: IconTheme(
              data: const IconThemeData(color: Colors.white),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
