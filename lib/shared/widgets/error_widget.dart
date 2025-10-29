import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class ErrorWidget extends StatelessWidget {
  final String title;
  final String message;
  final String? actionText;
  final VoidCallback? onRetry;
  final IconData icon;

  const ErrorWidget({
    super.key,
    this.title = 'Oops! Something went wrong',
    required this.message,
    this.actionText,
    this.onRetry,
    this.icon = Icons.error_outline,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Error icon
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 48,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 24),
            
            // Title
            Text(
              title,
              style: const TextStyle(
                fontSize: 22,
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
            
            // Retry button
            if (actionText != null && onRetry != null) ...[
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, size: 20),
                label: Text(
                  actionText!,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
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
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class NetworkErrorWidget extends StatelessWidget {
  final VoidCallback? onRetry;

  const NetworkErrorWidget({super.key, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return ErrorWidget(
      title: 'Connection Error',
      message: 'Please check your internet connection\nand try again.',
      actionText: 'Retry',
      onRetry: onRetry,
      icon: Icons.wifi_off,
    );
  }
}

class NotFoundErrorWidget extends StatelessWidget {
  final String? itemName;
  final VoidCallback? onGoBack;

  const NotFoundErrorWidget({
    super.key,
    this.itemName,
    this.onGoBack,
  });

  @override
  Widget build(BuildContext context) {
    return ErrorWidget(
      title: 'Not Found',
      message: itemName != null
          ? 'The $itemName you\'re looking for\ndoesn\'t exist or was removed.'
          : 'The page you\'re looking for\ndoesn\'t exist.',
      actionText: onGoBack != null ? 'Go Back' : null,
      onRetry: onGoBack,
      icon: Icons.search_off,
    );
  }
}

class PermissionErrorWidget extends StatelessWidget {
  final String permission;
  final VoidCallback? onRequestPermission;

  const PermissionErrorWidget({
    super.key,
    required this.permission,
    this.onRequestPermission,
  });

  @override
  Widget build(BuildContext context) {
    return ErrorWidget(
      title: 'Permission Required',
      message: 'We need $permission permission\nto continue.',
      actionText: 'Grant Permission',
      onRetry: onRequestPermission,
      icon: Icons.lock_outline,
    );
  }
}
