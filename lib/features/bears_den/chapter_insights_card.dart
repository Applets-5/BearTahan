import 'dart:async';
import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class ChapterInsightsCard extends StatefulWidget {
  const ChapterInsightsCard({super.key});

  @override
  State<ChapterInsightsCard> createState() => _ChapterInsightsCardState();
}

class _ChapterInsightsCardState extends State<ChapterInsightsCard> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _timer;

  static const List<Map<String, dynamic>> _subjectInsights = [
    {
      'subject': 'English',
      'color': AppColors.subjectEnglish,
      'insights': [
        {
          'name': 'Chapter 0 - Foundation',
          'stars': 3,
          'badge': 'Strong',
          'badgeColor': AppColors.accent,
          'badgeTextColor': Colors.white,
        },
        {
          'name': 'Chapter 1',
          'stars': 1,
          'badge': 'Needs Work',
          'badgeColor': AppColors.destructive,
          'badgeTextColor': Colors.white,
        },
        {
          'name': 'Chapter 2',
          'stars': 2,
          'badge': 'Average',
          'badgeColor': AppColors.secondary,
          'badgeTextColor': AppColors.foreground,
        },
      ]
    },
    {
      'subject': 'Bahasa Melayu',
      'color': AppColors.subjectBm,
      'insights': [
        {
          'name': 'Chapter 1 - Abjad',
          'stars': 3,
          'badge': 'Strong',
          'badgeColor': AppColors.accent,
          'badgeTextColor': Colors.white,
        },
        {
          'name': 'Chapter 2 - Suku Kata',
          'stars': 2,
          'badge': 'Average',
          'badgeColor': AppColors.secondary,
          'badgeTextColor': AppColors.foreground,
        },
        {
          'name': 'Chapter 3 - Perkataan',
          'stars': 1,
          'badge': 'Needs Work',
          'badgeColor': AppColors.destructive,
          'badgeTextColor': Colors.white,
        },
      ]
    },
    {
      'subject': 'Mandarin',
      'color': AppColors.subjectMandarin,
      'insights': [
        {
          'name': 'Chapter 1 - Basics',
          'stars': 2,
          'badge': 'Average',
          'badgeColor': AppColors.secondary,
          'badgeTextColor': AppColors.foreground,
        },
        {
          'name': 'Chapter 2 - Characters',
          'stars': 3,
          'badge': 'Strong',
          'badgeColor': AppColors.accent,
          'badgeTextColor': Colors.white,
        },
        {
          'name': 'Chapter 3 - Tones',
          'stars': 1,
          'badge': 'Needs Work',
          'badgeColor': AppColors.destructive,
          'badgeTextColor': Colors.white,
        },
      ]
    },
    {
      'subject': 'Mathematics',
      'color': AppColors.subjectMath,
      'insights': [
        {
          'name': 'Chapter 1 - Numbers',
          'stars': 3,
          'badge': 'Strong',
          'badgeColor': AppColors.accent,
          'badgeTextColor': Colors.white,
        },
        {
          'name': 'Chapter 2 - Addition',
          'stars': 2,
          'badge': 'Average',
          'badgeColor': AppColors.secondary,
          'badgeTextColor': AppColors.foreground,
        },
        {
          'name': 'Chapter 3 - Shapes',
          'stars': 2,
          'badge': 'Average',
          'badgeColor': AppColors.secondary,
          'badgeTextColor': AppColors.foreground,
        },
      ]
    },
    {
      'subject': 'Science',
      'color': AppColors.subjectScience,
      'insights': [
        {
          'name': 'Chapter 1 - Living Things',
          'stars': 3,
          'badge': 'Strong',
          'badgeColor': AppColors.accent,
          'badgeTextColor': Colors.white,
        },
        {
          'name': 'Chapter 2 - Our Senses',
          'stars': 2,
          'badge': 'Average',
          'badgeColor': AppColors.secondary,
          'badgeTextColor': AppColors.foreground,
        },
        {
          'name': 'Chapter 3 - Animals',
          'stars': 3,
          'badge': 'Strong',
          'badgeColor': AppColors.accent,
          'badgeTextColor': Colors.white,
        },
      ]
    },
  ];

  @override
  void initState() {
    super.initState();
    _startAutoSwipe();
  }

  void _startAutoSwipe() {
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_pageController.hasClients) {
        final nextPage = (_currentPage + 1) % _subjectInsights.length;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: AppRadius.r(AppRadius.xl),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Chapter Insights',
                    style: AppTextStyles.cardTitle,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _subjectInsights[_currentPage]['color'],
                    borderRadius: AppRadius.r(AppRadius.lg),
                  ),
                  child: Text(
                    _subjectInsights[_currentPage]['subject'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 150, // Reduced from 190 to bring info card closer
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              itemCount: _subjectInsights.length,
              itemBuilder: (context, index) {
                final data = _subjectInsights[index];
                final insights = data['insights'] as List<Map<String, dynamic>>;

                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ...insights.asMap().entries.map((entry) {
                        final i = entry.value;
                        final isLast = entry.key == insights.length - 1;
                        return Column(
                          children: [
                            _InsightRow(
                              name: i['name'],
                              stars: i['stars'],
                              badge: i['badge'],
                              badgeColor: i['badgeColor'],
                              badgeTextColor: i['badgeTextColor'],
                            ),
                            if (!isLast)
                              const Divider(height: 1, color: Color(0xFFEEEEEE)),
                          ],
                        );
                      }),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.xxs), // Reduced from sm
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E1),
                borderRadius: AppRadius.r(AppRadius.md),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.pets_rounded, color: Color(0xFFF59E0B), size: 18),
                  SizedBox(width: AppSpacing.xxs),
                  Expanded(
                    child: Text(
                      "Bear's Den questions are personalised to strengthen weaker chapters.",
                      style: AppTextStyles.small,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _subjectInsights.length,
              (index) => Container(
                width: 6,
                height: 6,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _currentPage == index
                      ? AppColors.primary
                      : AppColors.muted,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InsightRow extends StatelessWidget {
  const _InsightRow({
    required this.name,
    required this.stars,
    required this.badge,
    required this.badgeColor,
    required this.badgeTextColor,
  });

  final String name;
  final int stars;
  final String badge;
  final Color badgeColor;
  final Color badgeTextColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Row(
        children: [
          Expanded(child: Text(name, style: AppTextStyles.bodyBold)),
          Row(
            children: List.generate(
              3,
              (index) => Icon(
                index < stars ? Icons.star_rounded : Icons.star_border_rounded,
                color: AppColors.star,
                size: 15,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: badgeColor,
              borderRadius: AppRadius.r(AppRadius.sm),
            ),
            child: Text(
              badge,
              style: TextStyle(
                color: badgeTextColor,
                fontSize: 9,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
