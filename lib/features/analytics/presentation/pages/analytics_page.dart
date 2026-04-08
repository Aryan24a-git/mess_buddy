import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/dimensions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/analytics_provider.dart';
import '../../../../features/monetization/presentation/providers/monetization_provider.dart';
import '../../../../features/monetization/services/unity_ads_service.dart';
import 'dart:math' as math;

class AnalyticsPage extends ConsumerStatefulWidget {
  const AnalyticsPage({super.key});

  @override
  ConsumerState<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends ConsumerState<AnalyticsPage> {
  final List<Color> chartColors = [
    AppColors.accent,
    Colors.lightBlueAccent,
    Colors.orangeAccent,
    Colors.pinkAccent,
    Colors.greenAccent,
    Colors.purpleAccent,
    Colors.redAccent,
    Colors.amberAccent,
    Colors.cyanAccent,
  ];

  @override
  void initState() {
    super.initState();
    // Delay ad shown until frame is built so read() works correctly
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final isPro = ref.read(monetizationProvider).isPro;
      if (!isPro) {
        UnityAdsService().showInterstitialAd();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final analyticsState = ref.watch(analyticsProvider);
    
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: analyticsState.when(
          loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
          error: (e, _) => Center(child: Text('Error loading analytics: $e', style: const TextStyle(color: Colors.red))),
          data: (data) => SingleChildScrollView(
            padding: const EdgeInsets.all(AppDimensions.pNormal),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: AppDimensions.s4),
                _buildMonthlySpending(data),
                const SizedBox(height: AppDimensions.s4),
                _buildCategoryBreakdownCard(data),
                const SizedBox(height: AppDimensions.s3),
                _buildBurnRateCard(data.burnRate),
                const SizedBox(height: AppDimensions.s3),
                _buildLast7DaysCard(data),
                const SizedBox(height: AppDimensions.s3),
                _buildSpendingFrequencyCard(data),
                const SizedBox(height: AppDimensions.s4),
                const Text(
                  'AI Insights',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppDimensions.s3),
                _buildInsightCard(
                  icon: Icons.restaurant,
                  title: 'Category Focus',
                  highlightText: 'Most spent on: ',
                  highlightValue: data.mostSpentCategory,
                  color: Colors.orangeAccent,
                ),
                const SizedBox(height: AppDimensions.s2),
                _buildInsightCard(
                  icon: Icons.calendar_today,
                  title: 'Time Analysis',
                  highlightText: 'Most expensive week: ',
                  highlightValue: data.mostExpensiveWeek,
                  color: AppColors.accent,
                ),
                const SizedBox(height: AppDimensions.s2),
                _buildInsightCard(
                  icon: Icons.pie_chart,
                  title: 'Mess vs Outside',
                  highlightText: 'Mess: ',
                  highlightValue: '₹${data.messSpending.toStringAsFixed(0)} | Outside: ₹${data.outsideSpending.toStringAsFixed(0)}',
                  color: Colors.greenAccent,
                ),
                const SizedBox(height: AppDimensions.pHuge * 2),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Image.asset(
              'assets/images/logo.png',
              height: 40,
              width: 40,
            ),
            const SizedBox(width: AppDimensions.s1),
            const Text(
              'Mess Buddy',
              style: TextStyle(
                fontFamily: 'PlusJakartaSans',
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMonthlySpending(AnalyticsData data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'MONTHLY SPENDING',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: AppDimensions.s1),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              '₹${data.monthlySpending.toStringAsFixed(2)}',
              style: const TextStyle(
                fontFamily: 'PlusJakartaSans',
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            GestureDetector(
              onTap: () {
                final message = data.dailyGrowth == 0 
                  ? "You haven't spent anything today! Starting at neutral."
                  : (data.dailyGrowth > 0 
                      ? "Spending increased by ₹${(-data.todayDifference).toStringAsFixed(2)} over your daily target."
                      : "Spending decreased by ₹${data.todayDifference.toStringAsFixed(2)} relative to your daily target.");
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      message,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    backgroundColor: data.dailyGrowth > 0.01 
                        ? Colors.redAccent.withValues(alpha: 0.9) 
                        : (data.dailyGrowth < -0.01 ? AppColors.success.withValues(alpha: 0.9) : AppColors.background),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppDimensions.rMax),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                ),
                child: Row(
                  children: [
                    Icon(
                      data.dailyGrowth > 0.01 
                          ? Icons.trending_up 
                          : (data.dailyGrowth < -0.01 ? Icons.trending_down : Icons.remove), 
                      color: data.dailyGrowth > 0.01 
                          ? Colors.redAccent 
                          : (data.dailyGrowth < -0.01 ? AppColors.success : AppColors.textMuted), 
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      data.dailyGrowth == 0 
                          ? 'Neutral' 
                          : '${data.dailyGrowth > 0 ? "+" : ""}${data.dailyGrowth.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: data.dailyGrowth > 0.01 
                            ? Colors.redAccent 
                            : (data.dailyGrowth < -0.01 ? AppColors.success : AppColors.textMuted),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.s2),
        _buildMonthlyTrend(data),
      ],
    );
  }

  Widget _buildMonthlyTrend(AnalyticsData data) {
    if (data.dailyCumulativeSpending.isEmpty) return const SizedBox();
    
    return Container(
      height: 80,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(AppDimensions.r2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppDimensions.r2),
        child: CustomPaint(
          painter: TrendChartPainter(
            data.dailyCumulativeSpending,
            DateTime.now().day,
          ),
        ),
      ),
    );
  }

  Widget _buildAxisLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.bold,
        color: AppColors.textMuted.withValues(alpha: 0.6),
      ),
    );
  }

  Widget _buildCategoryBreakdownCard(AnalyticsData data) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.pLarge),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.r3),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Category Breakdown',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: AppDimensions.s4),
          // Custom Donut Chart Placeholder
          SizedBox(
            height: 140,
            width: 140,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(140, 140),
                  painter: _DonutChartPainter(data.categoryBreakdown, chartColors),
                ),
                const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Total',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                    Text(
                      '100%',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.s4),
          // Dynamic Legend for all categories
          Wrap(
            spacing: 16,
            runSpacing: 12,
            children: data.categoryBreakdown.entries.toList().asMap().entries.map((entry) {
              final idx = entry.key;
              final catEntry = entry.value;
              return SizedBox(
                width: (MediaQuery.of(context).size.width - 80) / 2, // 2 items per row approx
                child: _buildLegendItem(
                  color: chartColors[idx % chartColors.length],
                  label: catEntry.key.toUpperCase(),
                  percentage: '${catEntry.value.toStringAsFixed(1)}%',
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem({required Color color, required String label, required String percentage}) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: AppDimensions.s1),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textMuted),
            ),
            Text(
              percentage,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
          ],
        )
      ],
    );
  }

  Widget _buildBurnRateCard(double burnRate) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.pLarge),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.r3),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.local_fire_department, color: Colors.lightBlueAccent, size: 20),
              SizedBox(width: AppDimensions.s1),
            ],
          ),
          const SizedBox(height: AppDimensions.s1),
          const Text(
            'Burn Rate',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const Text(
            'Average daily expense',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: AppDimensions.s2),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '₹${burnRate.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontFamily: 'PlusJakartaSans',
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const Text(
                '/day',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.s2),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppDimensions.r1),
            child: LinearProgressIndicator(
              value: 0.65,
              backgroundColor: Colors.white.withValues(alpha: 0.1),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.lightBlueAccent),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLast7DaysCard(AnalyticsData data) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.pLarge),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.r3),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          SizedBox(
            height: 100,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (index) {
                final amount = data.last7DaysSpending[index];
                final maxAmount = data.last7DaysSpending.reduce(math.max);
                final heightFactor = (maxAmount > 0 ? amount / maxAmount : 0.0);
                
                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      final dayLabel = index == 6 ? 'Today' : '${6 - index}d ago';
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('$dayLabel High: ${data.highestExpenseByDay[index]}\nTotal: ₹${amount.toStringAsFixed(0)}'),
                          duration: const Duration(seconds: 2),
                          backgroundColor: index == 6 ? AppColors.accent : AppColors.primary,
                        ),
                      );
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          width: 20,
                          height: (80 * heightFactor).clamp(4, 80),
                          decoration: BoxDecoration(
                            color: index == 6 ? AppColors.accent : AppColors.primary.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildAxisLabel('6d ago'),
              _buildAxisLabel('Today'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSpendingFrequencyCard(AnalyticsData data) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.pLarge),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.r3),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Spending Frequency',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'PAST 28 DAYS',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.s3),
          // Heatmap grid (4 weeks x 7 days = 28 slots)
          Column(
            children: List.generate(4, (rowIndex) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(7, (colIndex) {
                    final index = rowIndex * 7 + colIndex;
                    final count = data.spendingFrequency[index];
                    // Alpha: 0.05 (none), 0.2 (1), 0.5 (2), 0.8 (3+)
                    double alpha = 0.05;
                    if (count == 1) alpha = 0.3;
                    if (count == 2) alpha = 0.6;
                    if (count >= 3) alpha = 1.0;

                    return GestureDetector(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('$count transaction${count == 1 ? "" : "s"} on this day'),
                            duration: const Duration(seconds: 1),
                            backgroundColor: AppColors.accent,
                          ),
                        );
                      },
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: alpha),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    );
                  }),
                ),
              );
            }),
          ),
          const SizedBox(height: AppDimensions.s2),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const Text('Less ', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
              Row(
                children: [0.1, 0.3, 0.6, 1.0].map((alpha) {
                  return Container(
                    margin: const EdgeInsets.only(right: 2),
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: alpha),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(width: 4),
              const Text('More', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInsightCard({
    required IconData icon,
    required String title,
    required String highlightText,
    required String highlightValue,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.r3),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 80,
            decoration: BoxDecoration(
              color: color,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppDimensions.r3),
                bottomLeft: Radius.circular(AppDimensions.r3),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppDimensions.pNormal, vertical: AppDimensions.pNormal),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: color, size: 24),
                  ),
                  const SizedBox(width: AppDimensions.s2),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            highlightText,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            highlightValue,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DonutChartPainter extends CustomPainter {
  final Map<String, double> breakdown;
  final List<Color> colors;
  _DonutChartPainter(this.breakdown, this.colors);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    const strokeWidth = 14.0;
    
    final bgPaint = Paint()
      ..color = AppColors.surface
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;
    
    canvas.drawArc(rect, 0, math.pi * 2, false, bgPaint);

    if (breakdown.isEmpty) return;

    double currentAngle = -math.pi / 2;

    int colorIndex = 0;
    breakdown.forEach((cat, percentage) {
      if (percentage <= 0) return;
      
      final sweepAngle = (percentage / 100) * math.pi * 2;
      final paint = Paint()
        ..color = colors[colorIndex % colors.length]
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      
      canvas.drawArc(rect, currentAngle, sweepAngle, false, paint);
      currentAngle += sweepAngle;
      colorIndex++;
    });
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class TrendChartPainter extends CustomPainter {
  final List<double> cumulativeData;
  final int currentDay; // 1-based

  TrendChartPainter(this.cumulativeData, this.currentDay);

  @override
  void paint(Canvas canvas, Size size) {
    if (cumulativeData.isEmpty) return;

    final maxVal = cumulativeData.reduce(math.max);
    final referenceMax = maxVal > 0 ? maxVal * 1.2 : 1000.0;
    
    final paint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.primary.withValues(alpha: 0.3),
          AppColors.primary.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path();
    final fillPath = Path();

    final double stepX = size.width / (cumulativeData.length - 1);
    
    for (int i = 0; i < cumulativeData.length; i++) {
      // We only draw up to the current day for a real "progress" feel
      // or we can draw the whole month but only the data points we have
      double y = size.height - (cumulativeData[i] / referenceMax * size.height);
      double x = i * stepX;

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        // Curve approximation
        double prevX = (i - 1) * stepX;
        double prevY = size.height - (cumulativeData[i-1] / referenceMax * size.height);
        
        path.quadraticBezierTo(
          prevX + (x - prevX) / 2, 
          prevY, 
          x, 
          y
        );
        
        fillPath.quadraticBezierTo(
          prevX + (x - prevX) / 2, 
          prevY, 
          x, 
          y
        );
      }
      
      // Stop drawing the visible line if we exceed current day
      if (i + 1 >= currentDay) break;
    }

    // Close fill path
    double lastX = (currentDay - 1) * stepX;
    fillPath.lineTo(lastX, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);
    
    // Draw "today" dot
    final dotPaint = Paint()..color = Colors.white;
    final dotOuterPaint = Paint()..color = AppColors.primary;
    
    double todayY = size.height - (cumulativeData[currentDay - 1] / referenceMax * size.height);
    double todayX = (currentDay - 1) * stepX;
    
    canvas.drawCircle(Offset(todayX, todayY), 6, dotOuterPaint);
    canvas.drawCircle(Offset(todayX, todayY), 3, dotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
