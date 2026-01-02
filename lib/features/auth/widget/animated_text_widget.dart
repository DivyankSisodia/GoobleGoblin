import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';


class HindiScrambleText extends StatefulWidget {
  final String text;
  final TextStyle style;

  const HindiScrambleText({
    super.key,
    required this.text,
    required this.style,
  });

  @override
  State<HindiScrambleText> createState() => _HindiScrambleTextState();
}

class _HindiScrambleTextState extends State<HindiScrambleText> {
  static const _scrambleChars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  final _random = Random();

  late List<String> _chars;
  late String _display;
  int _revealIndex = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    _chars = widget.text.characters.toList();

    // ✅ IMPORTANT: initialize immediately
    _display = List.generate(
      _chars.length,
      (_) => _scrambleChars[_random.nextInt(_scrambleChars.length)],
    ).join();

    _startScramble();
  }

  void _startScramble() {
    _timer = Timer.periodic(const Duration(milliseconds: 200), (_) {
      if (!mounted) return;

      setState(() {
        _revealIndex++;

        if (_revealIndex > _chars.length) {
          _revealIndex = 0;
        }

        _display = _chars
            .asMap()
            .map((i, char) {
              if (i < _revealIndex) {
                return MapEntry(i, char);
              }
              return MapEntry(
                i,
                _scrambleChars[_random.nextInt(_scrambleChars.length)],
              );
            })
            .values
            .join();
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _display,
      style: widget.style,
      maxLines: 2,
      overflow: TextOverflow.clip,
    );
  }
}

class SlidingText extends StatefulWidget {
  final String text;
  final TextStyle style;

  const SlidingText({
    super.key,
    required this.text,
    required this.style,
  });

  @override
  State<SlidingText> createState() => _SlidingTextState();
}

class _SlidingTextState extends State<SlidingText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _animation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _animation = Tween<Offset>(
      begin: const Offset(1.2, 0),
      end: const Offset(-1.2, 0),
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.linear),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: SlideTransition(
        position: _animation,
        child: Text(widget.text, style: widget.style),
      ),
    );
  }
}
