import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../data/repositories/payment_repository.dart';

/// Creative flow diagram showing category spending as animated cards
class CategoryFlowWidget extends StatelessWidget {
  final List<CategorySpendingData> categoryData;

  const CategoryFlowWidget({super.key, required this.categoryData});

  @override
  Widget build(BuildContext context) {
    if (categoryData.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Category Breakdown',
          style: GoogleFonts.montserrat(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),

        // Category flow cards
        ...categoryData.asMap().entries.map((entry) {
          return _CategoryFlowCard(
            data: entry.value,
            index: entry.key,
            maxAmount:
                categoryData.first.amount, // First item has highest amount
          );
        }),
      ],
    );
  }
}

class _CategoryFlowCard extends StatefulWidget {
  final CategorySpendingData data;
  final int index;
  final double maxAmount;

  const _CategoryFlowCard({
    required this.data,
    required this.index,
    required this.maxAmount,
  });

  @override
  State<_CategoryFlowCard> createState() => _CategoryFlowCardState();
}

class _CategoryFlowCardState extends State<_CategoryFlowCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 400 + (widget.index * 100)),
      vsync: this,
    );
    _slideAnimation = Tween<double>(
      begin: 50,
      end: 0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    // Stagger the animation
    Future.delayed(Duration(milliseconds: widget.index * 80), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = AppColors.getCategoryColor(widget.index);
    final percentage = widget.data.percentage;
    final progressWidth = widget.maxAmount > 0
        ? widget.data.amount / widget.maxAmount
        : 0.0;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_slideAnimation.value, 0),
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _isExpanded = !_isExpanded;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _isExpanded
                        ? color.withValues(alpha: 0.5)
                        : Colors.white.withValues(alpha: 0.05),
                  ),
                  boxShadow: _isExpanded
                      ? [
                          BoxShadow(
                            color: color.withValues(alpha: 0.2),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          // Category icon
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              _getCategoryIcon(widget.data.categoryIcon),
                              color: color,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),

                          // Category info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.data.categoryName,
                                  style: GoogleFonts.montserrat(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${widget.data.transactionCount} transaction${widget.data.transactionCount != 1 ? 's' : ''}',
                                  style: GoogleFonts.montserrat(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Amount and percentage
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                CurrencyUtils.formatCompact(widget.data.amount),
                                style: GoogleFonts.montserrat(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${percentage.toStringAsFixed(1)}%',
                                  style: GoogleFonts.montserrat(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: color,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Progress bar
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Stack(
                          children: [
                            Container(
                              height: 6,
                              decoration: BoxDecoration(
                                color: AppColors.surfaceLight,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 500),
                              curve: Curves.easeOutCubic,
                              height: 6,
                              width:
                                  MediaQuery.of(context).size.width *
                                  progressWidth *
                                  0.7 *
                                  _fadeAnimation.value,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [color.withValues(alpha: 0.6), color],
                                ),
                                borderRadius: BorderRadius.circular(4),
                                boxShadow: [
                                  BoxShadow(
                                    color: color.withValues(alpha: 0.4),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Expanded details
                    if (_isExpanded)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.05),
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(16),
                            bottomRight: Radius.circular(16),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildDetailItem(
                              'Avg per Transaction',
                              CurrencyUtils.formatCompact(
                                widget.data.transactionCount > 0
                                    ? widget.data.amount /
                                          widget.data.transactionCount
                                    : 0,
                              ),
                              color,
                            ),
                            Container(
                              width: 1,
                              height: 40,
                              color: color.withValues(alpha: 0.3),
                            ),
                            _buildDetailItem(
                              'Share of Total',
                              '${percentage.toStringAsFixed(1)}%',
                              color,
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.montserrat(
            fontSize: 10,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.montserrat(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  IconData _getCategoryIcon(String iconName) {
    final iconMap = {
      'restaurant': Icons.restaurant_rounded,
      'food': Icons.restaurant_rounded,
      'shopping_bag': Icons.shopping_bag_rounded,
      'shopping': Icons.shopping_bag_rounded,
      'directions_car': Icons.directions_car_rounded,
      'bike': Icons.two_wheeler_rounded,
      'movie': Icons.movie_rounded,
      'receipt_long': Icons.receipt_long_rounded,
      'home_utils': Icons.home_repair_service_rounded,
      'fitness_center': Icons.fitness_center_rounded,
      'flight': Icons.flight_rounded,
      'school': Icons.school_rounded,
      'subscriptions': Icons.subscriptions_rounded,
      'local_grocery_store': Icons.local_grocery_store_rounded,
      'grocery': Icons.local_grocery_store_rounded,
      'spa': Icons.spa_rounded,
      'category': Icons.category_rounded,
    };

    return iconMap[iconName] ?? Icons.category_rounded;
  }
}
