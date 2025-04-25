import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

/// A class that provides styled alerts and snackbars for consistent UI throughout the app.
class StyledAlerts {
  /// Shows a styled snackbar with the provided message.
  /// 
  /// Parameters:
  /// - context: The BuildContext
  /// - message: The message to display
  /// - type: The type of alert (success, error, info, warning)
  /// - action: Optional SnackBarAction to add to the snackbar
  static void showSnackBar(
    BuildContext context, 
    String message, 
    {AlertType type = AlertType.info, SnackBarAction? action}
  ) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDarkTheme = themeProvider.currentTheme.brightness == Brightness.dark;
    
    // Determine colors based on alert type
    final Color backgroundColor = _getBackgroundColor(type, isDarkTheme);
    final Color textColor = _getTextColor(type, isDarkTheme);
    final IconData icon = _getIcon(type);
    
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        backgroundColor: backgroundColor,
        content: Row(
          children: [
            Icon(icon, color: textColor),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: textColor,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
        action: action,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  /// Shows a styled dialog with the provided title and content.
  /// 
  /// Parameters:
  /// - context: The BuildContext
  /// - title: The title of the dialog
  /// - content: The content of the dialog
  /// - actions: Optional actions for the dialog (defaults to OK button)
  static Future<T?> showDialog<T>({
    required BuildContext context,
    required String title,
    required Widget content,
    List<Widget>? actions,
  }) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDarkTheme = themeProvider.currentTheme.brightness == Brightness.dark;
    final theme = themeProvider.currentTheme;
    
    return showGeneralDialog<T>(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, _, __) {
        return AlertDialog(
          backgroundColor: isDarkTheme ? const Color(0xFF212121) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: theme.primaryColor.withOpacity(0.2),
              width: 1,
            ),
          ),
          title: Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDarkTheme ? Colors.white : Colors.black87,
            ),
          ),
          content: content,
          actions: actions ?? [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                foregroundColor: theme.primaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: const Text('OK'),
            ),
          ],
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return ScaleTransition(
          scale: CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          ),
          child: FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeIn,
            ),
            child: child,
          ),
        );
      },
    );
  }

  /// Shows a confirmation dialog with the provided title and message.
  /// 
  /// Parameters:
  /// - context: The BuildContext
  /// - title: The title of the dialog
  /// - message: The message to display
  /// - confirmText: Text for the confirm button (defaults to "Confirm")
  /// - cancelText: Text for the cancel button (defaults to "Cancel")
  static Future<bool> showConfirmationDialog({
    required BuildContext context,
    required String title,
    required String message,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
  }) async {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final theme = themeProvider.currentTheme;
    final isDarkTheme = theme.brightness == Brightness.dark;
    
    final result = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, _, __) {
        return AlertDialog(
          backgroundColor: isDarkTheme ? const Color(0xFF212121) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: theme.primaryColor.withOpacity(0.2),
              width: 1,
            ),
          ),
          title: Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDarkTheme ? Colors.white : Colors.black87,
            ),
          ),
          content: Text(
            message,
            style: TextStyle(
              fontSize: 16,
              color: isDarkTheme ? Colors.white70 : Colors.black54,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              style: TextButton.styleFrom(
                foregroundColor: isDarkTheme ? Colors.white70 : Colors.black54,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: Text(cancelText),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(
                foregroundColor: theme.primaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: Text(confirmText),
            ),
          ],
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return ScaleTransition(
          scale: CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          ),
          child: FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeIn,
            ),
            child: child,
          ),
        );
      },
    );
    
    return result ?? false;
  }

  // Helper methods for colors and icons
  static Color _getBackgroundColor(AlertType type, bool isDarkTheme) {
    switch (type) {
      case AlertType.success:
        return isDarkTheme ? const Color(0xFF1B5E20) : const Color(0xFFE8F5E9);
      case AlertType.error:
        return isDarkTheme ? const Color(0xFF7F0000) : const Color(0xFFFFEBEE);
      case AlertType.warning:
        return isDarkTheme ? const Color(0xFF8F5000) : const Color(0xFFFFF8E1);
      case AlertType.info:
      default:
        return isDarkTheme ? const Color(0xFF01579B) : const Color(0xFFE1F5FE);
    }
  }

  static Color _getTextColor(AlertType type, bool isDarkTheme) {
    switch (type) {
      case AlertType.success:
        return isDarkTheme ? Colors.white : const Color(0xFF1B5E20);
      case AlertType.error:
        return isDarkTheme ? Colors.white : const Color(0xFFB71C1C);
      case AlertType.warning:
        return isDarkTheme ? Colors.white : const Color(0xFF8F5000);
      case AlertType.info:
      default:
        return isDarkTheme ? Colors.white : const Color(0xFF01579B);
    }
  }

  static IconData _getIcon(AlertType type) {
    switch (type) {
      case AlertType.success:
        return Icons.check_circle_outline;
      case AlertType.error:
        return Icons.error_outline;
      case AlertType.warning:
        return Icons.warning_amber_outlined;
      case AlertType.info:
      default:
        return Icons.info_outline;
    }
  }
}

/// Enum representing different types of alerts.
enum AlertType {
  success,
  error,
  warning,
  info,
} 