import 'package:flutter/material.dart';
import 'package:logbook_app_060/features/auth/login_view.dart';

class OnboardingView extends StatefulWidget {
  const OnboardingView({super.key});

  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView> {
  final PageController _pageController = PageController();
  int _pageIndex = 0;

  final List<String> _imageAssets = [
    "assets/Jade 1.png",
    "assets/Jade 3.png",
    "assets/Jade 4.png",
  ];

  final List<String> _descriptions = [
    "Aplikasi ini dibuat untuk memenuhi tugas mata kuliah Pengembangan Perangkat Lunak Berbasis Mobile.",
    "Dibuat dengan sepenuh hati oleh Rifky Hermawan dengan NIM akhir 060.",
    "Selamat mencoba!",
  ];

  void _nextPage() {
    if (_pageIndex < _imageAssets.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _startApp() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginView()),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Widget _buildDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_imageAssets.length, (index) {
        final bool isActive = index == _pageIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          height: 8,
          width: isActive ? 18 : 8,
          decoration: BoxDecoration(
            color: isActive ? Colors.blue : Colors.grey.shade400,
            borderRadius: BorderRadius.circular(8),
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _imageAssets.length,
                onPageChanged: (index) {
                  setState(() {
                    _pageIndex = index;
                  });
                },
                itemBuilder: (context, index) {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        _imageAssets[index],
                        height: 200,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        _descriptions[index],
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  );
                },
              ),
            ),
            _buildDots(),
            const SizedBox(height: 24),
            if (_pageIndex == _imageAssets.length - 1) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _startApp,
                  child: const Text("Masuk"),
                ),
              ),
            ] else
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _nextPage,
                  child: const Text("Lanjut"),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
