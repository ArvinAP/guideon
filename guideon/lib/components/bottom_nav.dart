import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

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

/// New pill-style bottom nav used on the Chatbot screen.
/// Icons: sheep (MDI), cross (MDI), head+lightbulb (MDI), clipboard+edit (MDI)
class GuideOnPillNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onItemSelected;

  const GuideOnPillNav({
    super.key,
    required this.currentIndex,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    const barColor = Color(0xFF3DB5A6);
    const iconColor = Color(0xFF154D71);
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(
            color: barColor,
            borderRadius: BorderRadius.circular(26),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _pillItem(
                index: 0,
                isActive: currentIndex == 0,
                onTap: () => onItemSelected(0),
                child: Icon(MdiIcons.sheep, color: iconColor, size: 26),
              ),
              _pillItem(
                index: 1,
                isActive: currentIndex == 1,
                onTap: () => onItemSelected(1),
                child: Icon(MdiIcons.cross, color: iconColor, size: 26),
              ),
              _pillItem(
                index: 2,
                isActive: currentIndex == 2,
                onTap: () => onItemSelected(2),
                child: Icon(MdiIcons.headLightbulbOutline, color: iconColor, size: 26),
              ),
              _pillItem(
                index: 3,
                isActive: currentIndex == 3,
                onTap: () => onItemSelected(3),
                child: Icon(MdiIcons.clipboardEditOutline, color: iconColor, size: 26),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pillItem({
    required int index,
    required bool isActive,
    required VoidCallback onTap,
    required Widget child,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? Colors.white.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: child,
      ),
    );
  }
}
