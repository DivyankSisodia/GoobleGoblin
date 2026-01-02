import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class CustomTabWidget extends StatefulWidget {
  const CustomTabWidget({super.key});

  @override
  State<CustomTabWidget> createState() => _CustomTabWidgetState();
}

class _CustomTabWidgetState extends State<CustomTabWidget> {
  final List<String> tabs = ['Transactions', 'Cards', 'Categories'];
  int selectedIndex = 0;
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CustomSegmentedTabBar(
          tabs: tabs,
          selectedIndex: selectedIndex,
          onChanged: (index) {
            setState(() => selectedIndex = index);
          },
        ),
        const SizedBox(height: 40),

        /// Example content switching
        Text("Selected: ${tabs[selectedIndex]}", style: const TextStyle(fontSize: 22)),
      ],
    );
  }
}

class CustomSegmentedTabBar extends StatelessWidget {
  final List<String> tabs;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  const CustomSegmentedTabBar({super.key, required this.tabs, required this.selectedIndex, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(color: const Color(0xFF3A1D4E), borderRadius: BorderRadius.circular(30)),
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
                    gradient: const LinearGradient(colors: [Color(0xFFFF4FD8), Color(0xFFB83DFF)]),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [BoxShadow(color: Colors.pinkAccent.withOpacity(0.6), blurRadius: 12, spreadRadius: 1)],
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
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: isSelected ? Colors.white : Colors.white70),
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
