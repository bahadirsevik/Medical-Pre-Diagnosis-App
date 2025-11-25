import 'package:flutter/material.dart';
import '../../widgets/diagnosis_result_card.dart';

class HistoryDetailScreen extends StatelessWidget {
  final Map<String, dynamic> diagnosisData;

  const HistoryDetailScreen({super.key, required this.diagnosisData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analiz Detayı'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: DiagnosisResultCard(result: diagnosisData),
      ),
    );
  }
}
