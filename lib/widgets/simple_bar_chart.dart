// lib/widgets/simple_bar_chart.dart
//
// Minimal bar chart: one Column per datum inside an Expanded slot, so
// equal-width bars regardless of count. Labels degrade gracefully when
// the available per-bar width is too small (e.g. 30 bars on a phone).

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

    return LayoutBuilder(
      builder: (context, constraints) {
        // Guard against unbounded width during early layout.
        final totalWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.of(context).size.width;

        // Per-bar slot width (padding excluded). If below ~14px, labels
        // can't fit; show bars only.
        final perBar = totalWidth / data.length;
        final showLabels = perBar >= 14.0;

        final maxVal =
        data.map((d) => d.value).reduce((a, b) => a > b ? a : b);
        final safeMax = maxVal <= 0 ? 1.0 : maxVal;

        return SizedBox(
          height: height,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: data.map((d) {
              final frac = (d.value / safeMax).clamp(0.0, 1.0);
              // Reserve 20px for the label row only if labels are shown.
              final barAreaHeight = height - (showLabels ? 20 : 4);
              return Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      height: (barAreaHeight * frac).clamp(0.0, barAreaHeight),
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    if (showLabels) ...[
                      const SizedBox(height: 4),
                      // No FittedBox — fixed-size text, clipped by the slot.
                      SizedBox(
                        height: 14,
                        child: Center(
                          child: Text(
                            d.label,
                            maxLines: 1,
                            overflow: TextOverflow.clip,
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ),
                    ] else
                      const SizedBox(height: 4),
                  ],
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}