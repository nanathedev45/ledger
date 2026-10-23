// lib/widgets/simple_bar_chart.dart
//
// Minimal bar chart: one Container per datum, height proportional to value.
// Zero dependencies. Bars equal width, varying height. Labels below bars.

import 'package:flutter/material.dart';

class BarDatum {
  final String label;
  final double value;

  const BarDatum({required this.label, required this.value});
}

class SimpleBarChart extends StatelessWidget {
  final List<BarDatum> data;
  final Color color;
  final double height;

  const SimpleBarChart({
    Key? key,
    required this.data,
    this.color = Colors.blue,
    this.height = 160,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return SizedBox(height: height);

    final maxVal = data.map((d) => d.value).reduce((a, b) => a > b ? a : b);
    final safeMax = maxVal <= 0 ? 1.0 : maxVal;

    return SizedBox(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: data.map((d) {
          final frac = (d.value / safeMax).clamp(0.0, 1.0);
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    height: (height - 24) * frac,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 4),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      d.label,
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}