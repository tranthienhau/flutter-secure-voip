import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/providers.dart';
import '../../widgets/security_gauge.dart';

class FraudScoreScreen extends ConsumerStatefulWidget {
  const FraudScoreScreen({super.key});

  @override
  ConsumerState<FraudScoreScreen> createState() => _FraudScoreScreenState();
}

class _FraudScoreScreenState extends ConsumerState<FraudScoreScreen> {
  bool _isComputing = false;

  Future<void> _computeDemo() async {
    setState(() => _isComputing = true);

    // Demo: compute fraud score with simulated data
    await ref.read(fraudScoreProvider.notifier).computeScore(
          measuredRttMs: 45,
          jitterMs: 12,
          callerLat: 40.7128,
          callerLon: -74.006,
          calleeLat: 51.5074,
          calleeLon: -0.1278,
        );

    setState(() => _isComputing = false);
  }

  @override
  Widget build(BuildContext context) {
    final fraudState = ref.watch(fraudScoreProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF161B22),
        title: const Text('Anti-Fraud Analysis'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Gauge
            fraudState.when(
              data: (score) {
                if (score == null) {
                  return Column(
                    children: [
                      const SecurityGauge(score: 0),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: _isComputing ? null : _computeDemo,
                          icon: _isComputing
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.analytics),
                          label: Text(
                            _isComputing ? 'Analyzing...' : 'Run Fraud Analysis',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                }

                return Column(
                  children: [
                    SecurityGauge(score: score.score),
                    const SizedBox(height: 24),

                    // Factor breakdown chart
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF161B22),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[800]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Factor Breakdown',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 200,
                            child: BarChart(
                              BarChartData(
                                barGroups: [
                                  _barGroup(0, score.factors.rttAnomaly.toDouble(), Colors.orange),
                                  _barGroup(1, score.factors.gpsSpoof.toDouble(), Colors.red),
                                  _barGroup(2, score.factors.jitterAnomaly.toDouble(), Colors.purple),
                                  _barGroup(3, score.factors.vpnProxy.toDouble(), Colors.blue),
                                ],
                                titlesData: FlTitlesData(
                                  leftTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                  topTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                  rightTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      getTitlesWidget: (value, meta) {
                                        const labels = ['RTT', 'GPS', 'Jitter', 'VPN'];
                                        if (value.toInt() >= 0 && value.toInt() < labels.length) {
                                          return Padding(
                                            padding: const EdgeInsets.only(top: 8),
                                            child: Text(
                                              labels[value.toInt()],
                                              style: TextStyle(
                                                color: Colors.grey[400],
                                                fontSize: 11,
                                              ),
                                            ),
                                          );
                                        }
                                        return const SizedBox.shrink();
                                      },
                                    ),
                                  ),
                                ),
                                gridData: const FlGridData(show: false),
                                borderData: FlBorderData(show: false),
                                maxY: 50,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Flags
                    if (score.flags.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF161B22),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[800]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Detection Flags',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ...score.flags.map(
                              (flag) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(
                                      Icons.flag,
                                      color: Colors.orange,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        flag,
                                        style: TextStyle(
                                          color: Colors.grey[300],
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 16),

                    // Re-analyze button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton.icon(
                        onPressed: _isComputing ? null : _computeDemo,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Re-analyze'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.blue,
                          side: BorderSide(color: Colors.blue.withOpacity(0.5)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
              loading: () => const Center(
                child: Column(
                  children: [
                    SecurityGauge(score: 0),
                    SizedBox(height: 24),
                    CircularProgressIndicator(color: Colors.blue),
                    SizedBox(height: 12),
                    Text(
                      'Computing fraud score...',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
              error: (e, _) => Center(
                child: Column(
                  children: [
                    const SecurityGauge(score: 0),
                    const SizedBox(height: 24),
                    Text(
                      'Error: $e',
                      style: const TextStyle(color: Colors.red),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _computeDemo,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  BarChartGroupData _barGroup(int x, double y, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: color,
          width: 28,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
        ),
      ],
    );
  }
}
