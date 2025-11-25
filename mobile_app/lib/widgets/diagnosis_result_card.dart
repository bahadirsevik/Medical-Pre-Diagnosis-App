import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';

class DiagnosisResultCard extends StatelessWidget {
  final Map<String, dynamic> result;

  const DiagnosisResultCard({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final predictions = result['predictions'] as List;
    if (predictions.isEmpty) {
      return const Center(child: Text('Sonuç bulunamadı.'));
    }

    final topDisease = predictions[0]['disease'];
    // Handle probability as double or string safely
    double probability = 0.0;
    if (predictions[0]['probability'] is double) {
      probability = predictions[0]['probability'];
    } else if (predictions[0]['probability'] is int) {
      probability = (predictions[0]['probability'] as int).toDouble();
    } else if (predictions[0]['probability_str'] != null) {
       // Try to parse string if double is missing
       try {
         probability = double.parse(predictions[0]['probability_str'].replaceAll('%', ''));
       } catch (e) {
         probability = 0.0;
       }
    }

    final alertLevel = result['alert_level'];
    final reasoning = result['reasoning'];
    final advice = result['advice'];

    Color alertColor = Colors.green;
    if (alertLevel == 'Medium') alertColor = Colors.orange;
    if (alertLevel == 'High') alertColor = Colors.red;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Gauge (Top Risk)
        SizedBox(
          height: 250,
          child: SfRadialGauge(
            axes: <RadialAxis>[
              RadialAxis(
                minimum: 0,
                maximum: 100,
                ranges: <GaugeRange>[
                  GaugeRange(startValue: 0, endValue: 50, color: Colors.green),
                  GaugeRange(startValue: 50, endValue: 80, color: Colors.orange),
                  GaugeRange(startValue: 80, endValue: 100, color: Colors.red),
                ],
                pointers: <GaugePointer>[
                  NeedlePointer(value: probability),
                ],
                annotations: <GaugeAnnotation>[
                  GaugeAnnotation(
                    widget: Text(
                      'Risk: %${probability.toStringAsFixed(1)}',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    angle: 90,
                    positionFactor: 0.5,
                  ),
                ],
              ),
            ],
          ),
        ),
        
        // 2. Top Disease Name
        Card(
          color: alertColor.withOpacity(0.1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Text(
                  'En Yüksek İhtimal',
                  style: GoogleFonts.outfit(fontSize: 14, color: Colors.grey[700]),
                ),
                const SizedBox(height: 4),
                Text(
                  topDisease,
                  style: GoogleFonts.outfit(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: alertColor,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // 3. Other Risks (New Section)
        if (predictions.length > 1) ...[
          Text(
            'Diğer Olasılıklar',
            style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...predictions.skip(1).take(3).map((p) {
            double prob = 0.0;
            if (p['probability'] is double) prob = p['probability'];
            else if (p['probability'] is int) prob = (p['probability'] as int).toDouble();

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text(p['disease'], style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                trailing: Text('%${prob.toStringAsFixed(1)}', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                leading: CircularProgressIndicator(
                  value: prob / 100,
                  backgroundColor: Colors.grey[200],
                  color: Colors.orange,
                ),
              ),
            );
          }).toList(),
          const SizedBox(height: 24),
        ],

        // 4. Reasoning
        if (reasoning != null) ...[
          Text(
            'Analiz Raporu',
            style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.analytics, color: Colors.teal),
                    const SizedBox(width: 8),
                    Text("Neden bu sonuç?", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.teal)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  reasoning,
                  style: GoogleFonts.outfit(fontSize: 15, height: 1.5, color: Colors.black87),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // 5. Advice
        if (advice != null) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFE3F2FD), // Light Blue
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade100),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.lightbulb, color: Colors.blue),
                    const SizedBox(width: 8),
                    Text(
                      'Tavsiyeler',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade900,
                      ),
                    ),
                  ],
                ),
                const Divider(color: Colors.blueAccent),
                Text(
                  advice,
                  style: GoogleFonts.outfit(fontSize: 15, height: 1.5, color: Colors.blue.shade900),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
