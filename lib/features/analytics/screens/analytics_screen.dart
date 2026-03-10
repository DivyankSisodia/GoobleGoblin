import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../core/utils/date_utils.dart';
import '../../../data/repositories/payment_repository.dart';
import '../../../providers/analytics_provider.dart';
import '../widgets/category_flow_widget.dart';
import '../widgets/pulse_indicator.dart';
import '../widgets/spending_flow_card.dart';
import '../widgets/spending_heatmap.dart';
import '../widgets/spending_ring.dart';
import '../widgets/trend_timeline.dart';

/// Analytics screen with creative, modern visualizations
class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsState = ref.watch(analyticsProvider);
    final analytics = analyticsState.analytics;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(analyticsProvider.notifier).refresh();
        },
        color: AppColors.primaryNeon,
        backgroundColor: AppColors.surface,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            // Custom App Bar
            SliverAppBar(
              expandedHeight: 120,
              floating: true,
              pinned: true,
              backgroundColor: AppColors.background,
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
                title: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: AppColors.analyticsGradient,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.insights_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const Gap(12),
                    Text(
                      'Analytics',
                      style: GoogleFonts.montserrat(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                // Period selector chip
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: _buildPeriodSelector(context, ref, analyticsState),
                ),
              ],
            ),

            // Loading State
            if (analyticsState.isLoading)
              const SliverFillRemaining(child: Center(child: PulseIndicator()))
            // Error State
            else if (analyticsState.errorMessage != null)
              SliverFillRemaining(
                child: _buildErrorState(context, analyticsState.errorMessage!),
              )
            // Empty State
            else if (analytics == null || analytics.transactionCount == 0)
              SliverFillRemaining(child: _buildEmptyState(context))
            // Content
            else ...[
              // Spending Overview Card with Gradient
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: _buildSpendingOverview(
                    context,
                    analytics,
                    analyticsState,
                  ),
                ),
              ),

              // Spending Ring - Category Breakdown
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SpendingRingWidget(
                    categoryData: analyticsState.categoryData,
                    totalSpending: analytics.totalSpending,
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: Gap(24)),

              // Recurring Payments Ring (only shown when recurring data exists)
              if (analyticsState.recurringCategoryData.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: SpendingRingWidget(
                      categoryData: analyticsState.recurringCategoryData,
                      totalSpending: analyticsState.recurringCategoryData.fold(
                        0.0,
                        (s, d) => s + d.amount,
                      ),
                      title: 'Recurring Payments',
                      subtitle: 'Category breakdown of your recurring charges',
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: Gap(24)),
              ],

              // Spending Heatmap
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Spending Activity',
                        style: GoogleFonts.montserrat(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const Gap(8),
                      Text(
                        'Your spending intensity over the last 30 days',
                        style: GoogleFonts.montserrat(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const Gap(16),
                      const SpendingHeatmapWidget(),
                    ],
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: Gap(24)),

              // Trend Timeline
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TrendTimelineWidget(
                    dailyData: analyticsState.dailyData,
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: Gap(24)),

              // Category Flow
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: CategoryFlowWidget(
                    categoryData: analyticsState.categoryData,
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: Gap(24)),

              // Spending Insights Cards
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildInsightsSection(
                    context,
                    analytics,
                    analyticsState,
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: Gap(100)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodSelector(
    BuildContext context,
    WidgetRef ref,
    AnalyticsState state,
  ) {
    return PopupMenuButton<AnalyticsPeriod>(
      initialValue: state.selectedPeriod,
      onSelected: (period) {
        ref.read(analyticsProvider.notifier).setPeriod(period);
      },
      offset: const Offset(0, 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: AppColors.surface,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.primaryNeon.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              state.selectedPeriod.label,
              style: GoogleFonts.montserrat(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Gap(8),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: AppColors.primaryNeon,
              size: 18,
            ),
          ],
        ),
      ),
      itemBuilder: (context) => AnalyticsPeriod.values.map((period) {
        final isSelected = period == state.selectedPeriod;
        return PopupMenuItem(
          value: period,
          child: Row(
            children: [
              if (isSelected)
                const Icon(
                  Icons.check_circle,
                  color: AppColors.primaryNeon,
                  size: 18,
                )
              else
                const SizedBox(width: 18),
              const Gap(12),
              Text(
                period.label,
                style: GoogleFonts.montserrat(
                  color: isSelected ? AppColors.primaryNeon : Colors.white,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSpendingOverview(
    BuildContext context,
    SpendingAnalytics analytics,
    AnalyticsState state,
  ) {
    final trend = analytics.percentageChange;
    final isIncreasing = trend > 0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.surfaceLight,
            AppColors.surface.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.primaryNeon.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryNeon.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Spent',
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const Gap(8),
                  Text(
                    CurrencyUtils.format(analytics.totalSpending),
                    style: GoogleFonts.montserrat(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              // Trend indicator
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color:
                      (isIncreasing
                              ? AppColors.errorRed
                              : AppColors.successGreen)
                          .withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      isIncreasing
                          ? Icons.trending_up_rounded
                          : Icons.trending_down_rounded,
                      color: isIncreasing
                          ? AppColors.errorRed
                          : AppColors.successGreen,
                      size: 18,
                    ),
                    const Gap(6),
                    Text(
                      CurrencyUtils.formatPercentageChange(trend),
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isIncreasing
                            ? AppColors.errorRed
                            : AppColors.successGreen,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Gap(24),
          // Stats row
          Row(
            children: [
              _buildStatItem(
                'Transactions',
                analytics.transactionCount.toString(),
                Icons.receipt_long_rounded,
              ),
              const Gap(24),
              _buildStatItem(
                'Avg. Transaction',
                CurrencyUtils.formatCompact(analytics.averageTransaction),
                Icons.analytics_rounded,
              ),
              const Gap(24),
              _buildStatItem(
                'Top Category',
                analytics.topCategory ?? 'N/A',
                Icons.category_rounded,
              ),
            ],
          ),
          if (state.scheduledFutureTotal > 0 ||
              state.upcomingRecurringCount > 0) ...[
            const Gap(16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.accentCyan.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.accentCyan.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.upcoming_rounded,
                    color: AppColors.accentCyan,
                    size: 16,
                  ),
                  const Gap(8),
                  Expanded(
                    child: Text(
                      state.scheduledFutureTotal > 0
                          ? 'Upcoming: ${CurrencyUtils.formatCompact(state.scheduledFutureTotal)} scheduled'
                                '${state.upcomingRecurringCount > 0 ? '  ·  ${state.upcomingRecurringCount} recurring due' : ''}'
                          : '${state.upcomingRecurringCount} recurring payment${state.upcomingRecurringCount == 1 ? '' : 's'} due soon',
                      style: GoogleFonts.montserrat(
                        fontSize: 12,
                        color: AppColors.accentCyan,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primaryNeon, size: 14),
              const Gap(6),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.montserrat(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const Gap(4),
          Text(
            value,
            style: GoogleFonts.montserrat(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildInsightsSection(
    BuildContext context,
    SpendingAnalytics analytics,
    AnalyticsState state,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Insights',
          style: GoogleFonts.montserrat(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const Gap(16),
        // Insight cards
        Row(
          children: [
            Expanded(
              child: SpendingFlowCard(
                title: 'Daily Average',
                amount: state.averageDailySpending,
                icon: Icons.today_rounded,
                gradient: AppColors.createGradient(
                  AppColors.accentCyan,
                  AppColors.accentBlue,
                ),
              ),
            ),
            const Gap(16),
            Expanded(
              child: SpendingFlowCard(
                title: 'Peak Spending',
                amount: state.maxDailySpending,
                icon: Icons.trending_up_rounded,
                gradient: AppColors.createGradient(
                  AppColors.accentMagenta,
                  AppColors.accentPurple,
                ),
              ),
            ),
          ],
        ),
        const Gap(16),
        // Days remaining insight
        if (analytics.topCategory != null)
          _buildInsightRow(
            icon: Icons.lightbulb_rounded,
            title: 'Top Spending',
            description:
                'You spent ${CurrencyUtils.formatCompact(analytics.topCategoryAmount ?? 0)} on ${analytics.topCategory}',
            color: AppColors.warningYellow,
          ),
        const Gap(12),
        _buildInsightRow(
          icon: Icons.calendar_today_rounded,
          title: 'Days Remaining',
          description:
              '${AppDateUtils.getDaysRemainingInMonth()} days left in this month',
          color: AppColors.accentTeal,
        ),
        if (state.scheduledFutureTotal > 0) ...[
          const Gap(12),
          _buildInsightRow(
            icon: Icons.schedule_rounded,
            title: 'Scheduled Payments',
            description:
                '${CurrencyUtils.formatCompact(state.scheduledFutureTotal)} in upcoming one-time payments',
            color: AppColors.accentCyan,
          ),
        ],
        if (state.upcomingRecurringCount > 0) ...[
          const Gap(12),
          _buildInsightRow(
            icon: Icons.autorenew_rounded,
            title: 'Recurring Due Soon',
            description:
                '${state.upcomingRecurringCount} recurring payment${state.upcomingRecurringCount == 1 ? '' : 's'} due in the next 30 days',
            color: AppColors.accentMagenta,
          ),
        ],
      ],
    );
  }

  Widget _buildInsightRow({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const Gap(16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const Gap(4),
                Text(
                  description,
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.insights_rounded,
                size: 64,
                color: AppColors.primaryNeon,
              ),
            ),
            const Gap(24),
            Text(
              'No Data Yet',
              style: GoogleFonts.montserrat(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const Gap(12),
            Text(
              'Start adding transactions to see\nyour spending insights here',
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: AppColors.errorRed,
            ),
            const Gap(24),
            Text(
              'Something went wrong',
              style: GoogleFonts.montserrat(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const Gap(12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
