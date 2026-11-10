import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../shared/providers/app_providers.dart';

class _OnboardingPage {
  const _OnboardingPage({
    required this.image,
    required this.title,
    required this.description,
  });

  final String image;
  final String title;
  final String description;
}

const _imagePool = [
  'assets/onboarding/onboarding_pool_1.webp',
  'assets/onboarding/onboarding_pool_2.webp',
  'assets/onboarding/onboarding_pool_3.webp',
  'assets/onboarding/onboarding_pool_4.webp',
  'assets/onboarding/onboarding_pool_5.webp',
  'assets/onboarding/onboarding_pool_6.webp',
];

const _titles = [
  'Suivez vos finances en un coup d\'œil',
  'Léa, votre conseillère IA',
  'Fixez vos objectifs d\'épargne',
];

const _descriptions = [
  'Revenus, dépenses et budget du mois réunis sur un seul écran, sans complexité.',
  'Des conseils personnalisés basés sur vos vraies dépenses, comme un conseiller humain.',
  'Créez vos objectifs et suivez votre progression en temps réel.',
];

/// Écran d'accueil (3 pages), affiché une seule fois avant l'inscription.
/// Images tirées au hasard dans un pool de 6 à chaque affichage.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  int _index = 0;
  late final List<_OnboardingPage> _pages = _buildPages();

  List<_OnboardingPage> _buildPages() {
    final shuffled = List<String>.from(_imagePool)..shuffle(Random());
    final picked = shuffled.take(3).toList();
    return [
      for (var i = 0; i < 3; i++)
        _OnboardingPage(
          image: picked[i],
          title: _titles[i],
          description: _descriptions[i],
        ),
    ];
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await ref.read(authServiceProvider).markOnboardingSeen();
    if (!mounted) return;
    context.go('/signup');
  }

  void _next() {
    if (_index == _pages.length - 1) {
      _finish();
    } else {
      _controller.nextPage(
          duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: _pages.length,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (context, i) => _PageContent(page: _pages[i]),
          ),
          Positioned(
            top: 16,
            right: 16,
            child: SafeArea(
              child: TextButton(
                onPressed: _finish,
                style: TextButton.styleFrom(foregroundColor: Colors.white),
                child: const Text('Passer',
                    style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ),
          Positioned(
            left: 24,
            right: 24,
            bottom: 36,
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Row(
                    children: [
                      for (var i = 0; i < _pages.length; i++)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          margin: const EdgeInsets.only(right: 6),
                          width: i == _index ? 22 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: i == _index
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                    ],
                  ),
                  const Spacer(),
                  FilledButton(
                    onPressed: _next,
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.primaryDark,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 22, vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30)),
                    ),
                    child: Text(
                      _index == _pages.length - 1 ? 'Commencer' : 'Suivant',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PageContent extends StatelessWidget {
  const _PageContent({required this.page});
  final _OnboardingPage page;

  @override
  Widget build(BuildContext context) {
    // Décode l'image à la hauteur physique de l'écran (BoxFit.cover en
    // portrait : c'est la hauteur qui contraint) plutôt qu'en pleine
    // résolution — divise l'empreinte mémoire du décodage.
    final cacheHeight = (MediaQuery.sizeOf(context).height *
            MediaQuery.devicePixelRatioOf(context))
        .round();
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(page.image, fit: BoxFit.cover, cacheHeight: cacheHeight),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.primaryDark.withValues(alpha: 0.15),
                AppColors.primaryDark.withValues(alpha: 0.55),
                AppColors.primary.withValues(alpha: 0.92),
              ],
              stops: const [0.0, 0.55, 1.0],
            ),
          ),
        ),
        Align(
          alignment: Alignment.bottomLeft,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 110),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  page.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  page.description,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 15,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
