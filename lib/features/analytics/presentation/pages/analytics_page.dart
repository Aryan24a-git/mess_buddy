import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/dimensions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/analytics_provider.dart';
import '../../../../features/monetization/presentation/providers/monetization_provider.dart';
import '../../../../features/monetization/services/ad_service.dart';
import 'dart:math' as math;

class AnalyticsPage extends ConsumerStatefulWidget {
  const AnalyticsPage({super.key});

  @override
  ConsumerState<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends ConsumerState<AnalyticsPage> {
  @override
  void initState() {
    super.initState();
    // Delay ad shown until frame is built so read() works correctly
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final isPro = ref.read(monetizationProvider).isPro;
      if (!isPro) {
        AdService().showInterstitialAd();
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
                _buildExpenseTrendsCard(),
                const SizedBox(height: AppDimensions.s3),
                _buildCategoryBreakdownCard(data),
                const SizedBox(height: AppDimensions.s3),
                _buildBurnRateCard(data.burnRate),
                const SizedBox(height: AppDimensions.s3),
                _buildLast7DaysCard(),
                const SizedBox(height: AppDimensions.s3),
                _buildSpendingFrequencyCard(),
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
            CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.primary.withValues(alpha: 0.2),
              child: const Icon(Icons.person, color: AppColors.primary),
            ),
            const SizedBox(width: AppDimensions.s2),
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
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.notifications_outlined, color: AppColors.textPrimary),
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
                color: AppColors.textPrimary, // With a slight purple glow in the design
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.surface, // Or deep green background
                borderRadius: BorderRadius.circular(AppDimensions.rMax),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.trending_up, color: AppColors.success, size: 14),
                  SizedBox(width: 4),
                  Text(
                    '+12.5%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildExpenseTrendsCard() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.pLarge),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.r3),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Expense Trends',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'Current Month',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 30),
          // Custom Line Chart Placeholder
          SizedBox(
            height: 100,
            child: CustomPaint(
              painter: _LineChartPainter(),
            ),
          ),
          const SizedBox(height: 16),
          // X-Axis
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildAxisLabel('WEEK 1'),
              _buildAxisLabel('WEEK 2'),
              _buildAxisLabel('WEEK 3'),
              _buildAxisLabel('WEEK 4'),
            ],
          ),
        ],
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
                  painter: _DonutChartPainter(),
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
          // Legend Options
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    _buildLegendItem(color: AppColors.accent, label: 'FOOD', percentage: '${(data.categoryBreakdown['Food'] ?? 0).toStringAsFixed(1)}%'),
                    const SizedBox(height: AppDimensions.s2),
                    _buildLegendItem(color: Colors.orangeAccent, label: 'MESS', percentage: '${(data.categoryBreakdown['Mess'] ?? 0).toStringAsFixed(1)}%'),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    _buildLegendItem(color: Colors.lightBlueAccent, label: 'RENT', percentage: '${(data.categoryBreakdown['Rent'] ?? 0).toStringAsFixed(1)}%'),
                    const SizedBox(height: AppDimensions.s2),
                    _buildLegendItem(color: Colors.white.withValues(alpha: 0.2), label: 'OTHER', percentage: '${(data.categoryBreakdown['Transport'] ?? 0 + (data.categoryBreakdown['Other'] ?? 0)).toStringAsFixed(1)}%'),
                  ],
                ),
              ),
            ],
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

  Widget _buildLast7DaysCard() {
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
          const Text(
            'Last 7 Days',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 100), // Height for bar chart
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildAxisLabel('M'),
              _buildAxisLabel('T'),
              _buildAxisLabel('W'),
              _buildAxisLabel('T'),
              _buildAxisLabel('F'),
              _buildAxisLabel('S'),
              _buildAxisLabel('S'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSpendingFrequencyCard() {
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
                  'PAST 30 DAYS',
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
          // Heatmap grid placeholder
          Column(
            children: List.generate(4, (rowIndex) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(7, (colIndex) {
                    final intensities = [0.1, 0.3, 0.5, 0.8, 0.1, 0.2, 0.4];
                    final intensity = intensities[(rowIndex * 7 + colIndex) % 7];
                    return Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: intensity),
                        borderRadius: BorderRadius.circular(6),
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

class _LineChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    
    // Gradient for line
    paint.shader = const LinearGradient(
      colors: [AppColors.accent, Colors.lightBlueAccent],
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    // Approximate the curve from the design
    path.moveTo(0, size.height * 0.8);
    path.cubicTo(
        size.width * 0.2, size.height * 0.9,
        size.width * 0.3, size.height * 0.7,
        size.width * 0.4, size.height * 0.4);
    path.cubicTo(
        size.width * 0.5, size.height * 0.1,
        size.width * 0.6, size.height * 0.9,
        size.width * 0.8, size.height * 0.6);
    path.cubicTo(
        size.width * 0.9, size.height * 0.3,
        size.width * 0.95, size.height * 0.1,
        size.width, size.height * 0.5);

    canvas.drawPath(path, paint);

    // Draw little dots on the line
    final dotPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    
    // Fake positions for dots
    canvas.drawCircle(Offset(size.width * 0.4, size.height * 0.4), 4, dotPaint);
    canvas.drawCircle(Offset(size.width * 0.8, size.height * 0.6), 4, dotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DonutChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    const strokeWidth = 14.0;
    
    final bgPaint = Paint()
      ..color = AppColors.background
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;
    
    canvas.drawArc(rect, 0, math.pi * 2, false, bgPaint);

    void drawSegment(double startAngle, double sweepAngle, Color color) {
      final paint = Paint()
        ..color = color
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
    }

    // Food 40% (Purple/Accent)
    drawSegment(-math.pi / 2, math.pi * 0.8, AppColors.accent);
    // Rent 30% (Blue)
    drawSegment(math.pi * 0.3 + 0.1, math.pi * 0.6, Colors.lightBlueAccent);
    // Mess 20% (Orange)
    drawSegment(math.pi * 0.9 + 0.2, math.pi * 0.4, Colors.orangeAccent);
    // Other 10% (Grey) is represented by background basically, or a small gap.
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
