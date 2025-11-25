import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import '../services/api_service.dart';
import '../services/audio_service.dart';
import 'home/profile_screen.dart';
import 'home/history_screen.dart';
import '../widgets/diagnosis_result_card.dart';

class DiagnosisScreen extends StatefulWidget {
  const DiagnosisScreen({super.key});

  @override
  State<DiagnosisScreen> createState() => _DiagnosisScreenState();
}

class _DiagnosisScreenState extends State<DiagnosisScreen> {
  final TextEditingController _textController = TextEditingController();
  final ApiService _apiService = ApiService();
  final AudioService _audioService = AudioService();
  
  bool _isLoading = false;
  Map<String, dynamic>? _result;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _audioService.initSpeech();
  }

  void _toggleListening() async {
    if (_isListening) {
      await _audioService.stopListening();
      setState(() => _isListening = false);
    } else {
      setState(() => _isListening = true);
      await _audioService.startListening((text) {
        setState(() {
          _textController.text = text;
        });
      });
    }
  }

  void _analyze() async {
    if (_textController.text.isEmpty) return;

    // Hide keyboard
    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
      _result = null;
    });

    try {
      final data = await _apiService.diagnose(_textController.text);
      setState(() {
        _result = data;
        _isLoading = false;
      });
      
      if (data['predictions'] != null && data['predictions'].isNotEmpty) {
        String disease = data['predictions'][0]['disease'];
        String prob = data['predictions'][0]['probability_str'];
        _audioService.speak("Analiz tamamlandı. En yüksek ihtimalle $disease riski görünüyor. Olasılık $prob.");
      }
      
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (e.toString().contains('UNAUTHORIZED')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Oturum süresi doldu. Lütfen tekrar giriş yapın.')),
        );
        // Navigate to login or logout
        // Ideally call UserProvider.logout but we need context access
        // For now, just show message. The user will manually logout.
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
      }
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hastalık Ön Tanı'),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Color(0xFF009688)),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.health_and_safety, size: 60, color: Colors.white),
                  SizedBox(height: 10),
                  Text('Medical AI', style: TextStyle(color: Colors.white, fontSize: 24)),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Profilim'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('Geçmiş Analizler'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => const HistoryScreen()));
              },
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ... input fields
            FadeInDown(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.medical_services_outlined, size: 50, color: Colors.teal),
                    const SizedBox(height: 10),
                    const Text(
                      "Şikayetlerinizi anlatın",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      "Örn: 'Başım çok ağrıyor ve midem bulanıyor'",
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _textController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: "Buraya yazın veya mikrofonu kullanın...",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                filled: true,
                fillColor: Colors.white,
                suffixIcon: IconButton(
                  icon: Icon(_isListening ? Icons.mic : Icons.mic_none, 
                    color: _isListening ? Colors.red : Colors.grey),
                  onPressed: _toggleListening,
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _analyze,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
              child: _isLoading 
                ? const SpinKitThreeBounce(color: Colors.white, size: 20)
                : const Text("ANALİZ ET", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 30),
            if (_result != null) DiagnosisResultCard(result: _result!),
          ],
        ),
      ),
    );
  }
}
