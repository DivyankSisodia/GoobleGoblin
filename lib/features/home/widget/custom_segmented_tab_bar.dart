import 'package:flutter/material.dart';

class CustomSegmentedTabBar extends StatelessWidget {
  final List<String> tabs;
  final int selectedIndex;
  final ValueChanged<int> onChanged;
  final Color? backgroundColor;
  final List<Color>? gradientColors;
  final Color? shadowColor;

  const CustomSegmentedTabBar({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onChanged,
    this.backgroundColor,
    this.gradientColors,
    this.shadowColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: backgroundColor ?? const Color(0xFF3A1D4E),
        borderRadius: BorderRadius.circular(30),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final tabWidth = constraints.maxWidth / tabs.length;

          return Stack(
            children: [
              /// Animated active tab
              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
                left: selectedIndex * tabWidth,
                child: Container(
                  width: tabWidth,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: gradientColors ?? [const Color(0xFFB0FF38), const Color(0xFF76CC00)],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: shadowColor ?? const Color(0xFFB0FF38).withOpacity(0.4),
                        blurRadius: 12,
                        spreadRadius: 1,
                      )
                    ],
                  ),
                ),
              ),

              /// Tabs
              Row(
                children: List.generate(tabs.length, (index) {
                  final isSelected = index == selectedIndex;

                  return Expanded(
                    child: GestureDetector(
                      onTap: () => onChanged(index),
                      child: Center(
                        child: Text(
                          tabs[index],
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? Colors.black : Colors.white70,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          );
        },
      ),
    );
  }
}
