import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:mobile_app/providers/user_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _ageController = TextEditingController();
  final _conditionsController = TextEditingController();
  String? _selectedGender;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final user = Provider.of<UserProvider>(context, listen: false).user;
    if (user != null) {
      if (user['age'] != null) _ageController.text = user['age'].toString();
      if (user['gender'] != null) _selectedGender = user['gender'];
      if (user['chronic_conditions'] != null) _conditionsController.text = user['chronic_conditions'];
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profilim'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              userProvider.logout();
              Navigator.popUntil(context, (route) => route.isFirst);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Kişisel Bilgiler',
              style: GoogleFonts.outfit(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Analizlerinizi kişiselleştirmek için bilgilerinizi güncelleyin.',
              style: GoogleFonts.outfit(
                fontSize: 14,
                color: const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 32),
            TextFormField(
              controller: _ageController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Yaş',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.calendar_today),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedGender,
              decoration: InputDecoration(
                labelText: 'Cinsiyet',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.person),
              ),
              items: const [
                DropdownMenuItem(value: 'Erkek', child: Text('Erkek')),
                DropdownMenuItem(value: 'Kadın', child: Text('Kadın')),
              ],
              onChanged: (value) => setState(() => _selectedGender = value),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _conditionsController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Kronik Rahatsızlıklar',
                hintText: 'Örn: Diyabet, Tansiyon...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.medical_services),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: userProvider.isLoading
                  ? null
                  : () async {
                      final success = await userProvider.updateProfile({
                        'age': int.tryParse(_ageController.text),
                        'gender': _selectedGender,
                        'chronic_conditions': _conditionsController.text,
                      });
                      
                      if (context.mounted) {
                        if (success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Profil güncellendi!')),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Güncelleme başarısız.')),
                          );
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF006D5B),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: userProvider.isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(
                      'Kaydet',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
