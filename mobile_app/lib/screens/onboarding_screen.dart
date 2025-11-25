import 'package:flutter/material.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile_app/main.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  Future<void> _onIntroEnd(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('showHome', true);

    if (context.mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AuthWrapper()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const bodyStyle = TextStyle(fontSize: 19.0);
    const pageDecoration = PageDecoration(
      titleTextStyle: TextStyle(fontSize: 28.0, fontWeight: FontWeight.w700),
      bodyTextStyle: bodyStyle,
      bodyPadding: EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 16.0),
      pageColor: Colors.white,
      imagePadding: EdgeInsets.zero,
    );

    return IntroductionScreen(
      globalBackgroundColor: Colors.white,
      allowImplicitScrolling: true,
      autoScrollDuration: 3000,
      infiniteAutoScroll: true,
      
      pages: [
        PageViewModel(
          title: "Hoş Geldiniz",
          body: "Yapay zeka destekli sağlık asistanınız ile tanışın. Semptomlarınızı analiz edin.",
          image: const Icon(Icons.health_and_safety, size: 100, color: Color(0xFF006D5B)),
          decoration: pageDecoration,
        ),
        PageViewModel(
          title: "Hızlı Analiz",
          body: "Şikayetlerinizi yazın veya söyleyin, saniyeler içinde olası nedenleri öğrenin.",
          image: const Icon(Icons.speed, size: 100, color: Color(0xFF006D5B)),
          decoration: pageDecoration,
        ),
        PageViewModel(
          title: "Detaylı Rapor",
          body: "Hastalık riskiniz, nedenleri ve evde uygulayabileceğiniz tavsiyeler cebinizde.",
          image: const Icon(Icons.analytics, size: 100, color: Color(0xFF006D5B)),
          decoration: pageDecoration,
        ),
      ],
      onDone: () => _onIntroEnd(context),
      onSkip: () => _onIntroEnd(context), // You can override onSkip callback
      showSkipButton: true,
      skipOrBackFlex: 0,
      nextFlex: 0,
      showBackButton: false,
      //rtl: true, // Display as right-to-left
      back: const Icon(Icons.arrow_back),
      skip: const Text('Atla', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF006D5B))),
      next: const Icon(Icons.arrow_forward, color: Color(0xFF006D5B)),
      done: const Text('Başla', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF006D5B))),
      curve: Curves.fastLinearToSlowEaseIn,
      controlsMargin: const EdgeInsets.all(16),
      controlsPadding: const EdgeInsets.fromLTRB(8.0, 4.0, 8.0, 4.0),
      dotsDecorator: const DotsDecorator(
        size: Size(10.0, 10.0),
        color: Color(0xFFBDBDBD),
        activeSize: Size(22.0, 10.0),
        activeShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(25.0)),
        ),
        activeColor: Color(0xFF006D5B),
      ),
    );
  }
}
