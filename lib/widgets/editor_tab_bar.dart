import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';

class EditorTabBar extends StatefulWidget {
  final String fileName;
  final VoidCallback? onSharePressed;

  const EditorTabBar({
    super.key,
    this.fileName = AppConstants.defaultFileName,
    this.onSharePressed,
  });

  @override
  State<EditorTabBar> createState() => _EditorTabBarState();
}

class _EditorTabBarState extends State<EditorTabBar> {
  bool _isSharePressed = false;
  bool _isMorePressed = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppConstants.tabBarHeight,
      color: AppColors.tabBackground,
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.defaultPadding),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.description,
                    color: AppColors.textPrimary,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.fileName,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: AppConstants.bodyFontSize,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            icon: Icon(
              Icons.share,
              color: _isSharePressed ? AppColors.highlightColor : AppColors.textPrimary,
              size: 20,
            ),
            onPressed: () {
              setState(() {
                _isSharePressed = !_isSharePressed;
                _isMorePressed = false;
              });
              widget.onSharePressed?.call();
            },
            padding: const EdgeInsets.all(8),
          ),
          IconButton(
            icon: Icon(
              Icons.more_vert,
              color: _isMorePressed ? AppColors.highlightColor : AppColors.textPrimary,
              size: 20,
            ),
            onPressed: () {
              setState(() {
                _isMorePressed = !_isMorePressed;
                _isSharePressed = false;
              });
            },
            padding: const EdgeInsets.all(8),
          ),
        ],
      ),
    );
  }
}