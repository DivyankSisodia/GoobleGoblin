import 'package:flutter/material.dart';
import 'package:gooble_goblin/core/models/card.dart';

import 'card_preview_widget.dart';

class StackedCardsView extends StatefulWidget {
  final List<BankCard> cards;
  final ValueChanged<int?> onCardTap;

  const StackedCardsView({
    super.key,
    required this.cards,
    required this.onCardTap,
  });

  @override
  State<StackedCardsView> createState() => _StackedCardsViewState();
}

class _StackedCardsViewState extends State<StackedCardsView> {
  int _currentIndex = 0;
  double _dragOffset = 0;

  void _onDragEnd(DragEndDetails details) {
    if (_dragOffset < -80) {
      _currentIndex =
          (_currentIndex + 1) % widget.cards.length;
    } else if (_dragOffset > 80) {
      _currentIndex =
          (_currentIndex - 1 + widget.cards.length) %
              widget.cards.length;
    }
    setState(() => _dragOffset = 0);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onVerticalDragUpdate: (d) {
        setState(() => _dragOffset += d.delta.dy);
      },
      onVerticalDragEnd: _onDragEnd,
      child: Center(
        child: SizedBox(
          height: 260,
          child: Stack(
            alignment: Alignment.topCenter,
            clipBehavior: Clip.none,
            children: _buildStack(),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildStack() {
    return List.generate(3, (i) {
      final index =
          (_currentIndex + i) % widget.cards.length;
      return _buildCard(i, widget.cards[index]);
    }).reversed.toList();
  }

  Widget _buildCard(int position, BankCard card) {
    final isTop = position == 0;

    final double top = position == 0
        ? _dragOffset
        : position == 1
            ? 18
            : 36;

    final scale = position == 0
        ? 1.0
        : position == 1
            ? 0.95
            : 0.9;

    final opacity = position == 0
        ? 1.0
        : position == 1
            ? 0.85
            : 0.65;

    return Positioned(
      top: top,
      child: Transform.scale(
        scale: scale,
        child: Opacity(
          opacity: opacity,
          child: CardPreviewWidget(
            bankName: card.bankName,
            balance: card.balance.toString(),
            isCredit: card.isCredit,
            isSelected: card.isSelected,
            onTap: isTop
                ? () => widget.onCardTap(card.id)
                : null,
          ),
        ),
      ),
    );
  }
}
