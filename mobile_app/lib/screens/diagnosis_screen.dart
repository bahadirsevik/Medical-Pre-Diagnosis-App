import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../services/api_service.dart';
import '../services/audio_service.dart';

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
    // Initialize speech engine
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
      // Auto-stop after some time or silence could be implemented here
      // For now, user taps again to stop or we rely on manual stop
    }
  }

  void _analyze() async {
    if (_textController.text.isEmpty) return;

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
      
      // Speak the result
      if (data['predictions'] != null && data['predictions'].isNotEmpty) {
        String disease = data['predictions'][0]['disease'];
        String prob = data['predictions'][0]['probability_str'];
        _audioService.speak("Analiz tamamlandı. En yüksek ihtimalle $disease riski görünüyor. Olasılık $prob.");
      }
      
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hastalık Ön Tanı'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {},
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
            if (_result != null) ...[
              const Text("Sonuçlar", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                  itemCount: (_result!['predictions'] as List).length,
                  itemBuilder: (context, index) {
                    final item = _result!['predictions'][index];
                    return FadeInUp(
                      delay: Duration(milliseconds: index * 100),
                      child: Card(
                        elevation: 2,
                        margin: const EdgeInsets.only(bottom: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: index == 0 ? Colors.redAccent : Colors.blueAccent,
                            child: Text("${index + 1}", style: const TextStyle(color: Colors.white)),
                          ),
                          title: Text(item['disease'], style: const TextStyle(fontWeight: FontWeight.bold)),
                          trailing: Text(
                            item['probability_str'],
                            style: TextStyle(
                              color: index == 0 ? Colors.red : Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 16
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              )
            ]
          ],
        ),
      ),
    );
  }
}
