import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_app/services/api_service.dart';
import 'history_detail_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<dynamic>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _historyFuture = _apiService.getHistory();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Geçmiş Analizler'),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _historyFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Hata: ${snapshot.error}'));
          }

          final history = snapshot.data ?? [];

          if (history.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(
                    'Henüz geçmiş kaydı yok',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: history.length,
            itemBuilder: (context, index) {
              final item = history[index];
              final predictions = item['predictions'] as List;
              final topDisease = predictions.isNotEmpty ? predictions[0]['disease'] : 'Bilinmiyor';
              final probability = predictions.isNotEmpty ? predictions[0]['probability_str'] : '';
              final alertLevel = item['alert_level'];

              Color alertColor = Colors.green;
              if (alertLevel == 'Medium') alertColor = Colors.orange;
              if (alertLevel == 'High') alertColor = Colors.red;



              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => HistoryDetailScreen(diagnosisData: item),
                      ),
                    );
                  },
                  leading: CircleAvatar(
                    backgroundColor: alertColor.withOpacity(0.2),
                    child: Icon(Icons.medical_services, color: alertColor),
                  ),
                  title: Text(
                    topDisease,
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(probability),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: alertColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      alertLevel,
                      style: TextStyle(color: alertColor, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
