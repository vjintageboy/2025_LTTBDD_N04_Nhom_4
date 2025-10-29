import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionText;
  final VoidCallback? onAction;
  final Color? iconColor;

  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionText,
    this.onAction,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: (iconColor ?? AppColors.primary).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 56,
                color: iconColor ?? AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            
            // Title
            Text(
              title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                letterSpacing: -0.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            
            // Message
            Text(
              message,
              style: const TextStyle(
                fontSize: 15,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            
            // Action button
            if (actionText != null && onAction != null) ...[
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: onAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  actionText!,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Preset empty states
class NoMoodEntriesEmpty extends StatelessWidget {
  final VoidCallback? onAddEntry;

  const NoMoodEntriesEmpty({super.key, this.onAddEntry});

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      icon: Icons.mood,
      title: 'No Mood Entries',
      message: 'You haven\'t logged any moods yet.\nStart tracking your emotions today!',
      actionText: 'Log Your Mood',
      onAction: onAddEntry,
      iconColor: AppColors.primaryLight,
    );
  }
}

class NoMeditationsEmpty extends StatelessWidget {
  final VoidCallback? onExplore;

  const NoMeditationsEmpty({super.key, this.onExplore});

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      icon: Icons.self_improvement,
      title: 'No Meditations',
      message: 'Explore our collection of guided\nmeditations to get started.',
      actionText: 'Explore Meditations',
      onAction: onExplore,
      iconColor: AppColors.accent,
    );
  }
}

class NoSearchResultsEmpty extends StatelessWidget {
  final String searchQuery;

  const NoSearchResultsEmpty({super.key, required this.searchQuery});

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      icon: Icons.search_off,
      title: 'No Results Found',
      message: 'We couldn\'t find anything matching\n"$searchQuery"',
      iconColor: AppColors.textSecondary,
    );
  }
}

class NoDataEmpty extends StatelessWidget {
  final String title;
  final String message;

  const NoDataEmpty({
    super.key,
    this.title = 'No Data',
    this.message = 'There\'s nothing to show here yet.',
  });

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      icon: Icons.inbox,
      title: title,
      message: message,
      iconColor: AppColors.textSecondary,
    );
  }
}
