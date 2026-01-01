import 'package:flutter/material.dart';

class StackedCardsScreen extends StatefulWidget {
  const StackedCardsScreen({super.key});

  @override
  State<StackedCardsScreen> createState() => _StackedCardsScreenState();
}

class _StackedCardsScreenState extends State<StackedCardsScreen>
    with SingleTickerProviderStateMixin {
  final List<CardData> _cards = [
    CardData(
      title: 'AMIR KHORSANDI',
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFF6B6B), Color(0xFF8B5CF6)],
      ),
    ),
    CardData(
      title: 'JOHN SMITH',
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF4ECDC4), Color(0xFF44A08D)],
      ),
    ),
    CardData(
      title: 'SARAH WILSON',
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF9D50BB), Color(0xFF6E48AA)],
      ),
    ),
    CardData(
      title: 'DAVID BROWN',
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFf093fb), Color(0xFFf5576c)],
      ),
    ),
    CardData(
      title: 'EMMA DAVIS',
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF4facfe), Color(0xFF00f2fe)],
      ),
    ),
    CardData(
      title: 'MICHAEL JONES',
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFfa709a), Color(0xFFfee140)],
      ),
    ),
  ];

  int _currentIndex = 0;
  double _dragOffset = 0.0;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    if (_dragOffset < -80) {
      // Swipe up - go to next card
      setState(() {
        _currentIndex = (_currentIndex + 1) % _cards.length;
      });
      _animationController.forward(from: 0);
    } else if (_dragOffset > 80) {
      // Swipe down - go to previous card
      setState(() {
        _currentIndex = (_currentIndex - 1 + _cards.length) % _cards.length;
      });
      _animationController.forward(from: 0);
    }
    
    setState(() {
      _dragOffset = 0.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Stacked Cards Chain',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: GestureDetector(
        onVerticalDragUpdate: (details) {
          setState(() {
            _dragOffset += details.delta.dy;
          });
        },
        onVerticalDragEnd: _onVerticalDragEnd,
        child: Container(
          color: Colors.transparent,
          child: Center(
            child: SizedBox(
              height: 350,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.topCenter,
                children: _buildCardStack(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildCardStack() {
    List<Widget> stackedCards = [];
    
    // Build cards from back to front (bottom to top)
    for (int i = 2; i >= 0; i--) {
      final cardIndex = (_currentIndex + i) % _cards.length;
      stackedCards.add(_buildCard(i, cardIndex));
    }
    
    return stackedCards;
  }

  Widget _buildCard(int position, int cardIndex) {
    final card = _cards[cardIndex];
    final isTopCard = position == 0;
    final dragProgress = (_dragOffset / 200).clamp(-1.0, 1.0);

    double topOffset;
    double scale;
    double opacity;

    if (isTopCard) {
      // Top card (position 0) - can be dragged
      topOffset = _dragOffset;
      scale = 1.0 - (dragProgress.abs() * 0.08);
      opacity = 1.0 - (dragProgress.abs() * 0.6);
    } else if (position == 1) {
      // Middle card (position 1) - moves up when top card is swiped
      final stackOffset = 15.0;
      final moveUp = dragProgress < 0 ? dragProgress * -15 : 0.0;
      
      topOffset = stackOffset + moveUp;
      scale = 0.95 + (dragProgress < 0 ? -dragProgress * 0.05 : 0.0);
      opacity = 0.8 + (dragProgress < 0 ? -dragProgress * 0.2 : 0.0);
    } else {
      // Bottom card (position 2) - stays in place
      topOffset = 30.0;
      scale = 0.90;
      opacity = 0.6;
    }

    return Positioned(
      key: ValueKey('card_$cardIndex'),
      top: topOffset,
      child: Transform.scale(
        scale: scale,
        child: Opacity(
          opacity: opacity.clamp(0.0, 1.0),
          child: _buildCreditCard(card),
        ),
      ),
    );
  }

  Widget _buildCreditCard(CardData card) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = screenWidth * 0.85;
    final cardHeight = cardWidth / 1.586;

    return Container(
      width: cardWidth,
      height: cardHeight,
      decoration: BoxDecoration(
        gradient: card.gradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
            spreadRadius: -5,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Chip icon
                Container(
                  width: 48,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.amber.shade600,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Center(
                    child: Container(
                      width: 32,
                      height: 24,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.amber.shade800,
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
                // Card type
                const Text(
                  'VISA',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontStyle: FontStyle.italic,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
            const Spacer(),
            // Card number
            const Text(
              '1234  2489  2987  1084',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 16),
            // Card holder and expiry
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CARD HOLDER',
                      style: TextStyle(
                        fontSize: 9,
                        color: Colors.white.withOpacity(0.7),
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      card.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'EXPIRES',
                      style: TextStyle(
                        fontSize: 9,
                        color: Colors.white.withOpacity(0.7),
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '08/28',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class CardData {
  final String title;
  final LinearGradient gradient;

  CardData({
    required this.title,
    required this.gradient,
  });
}