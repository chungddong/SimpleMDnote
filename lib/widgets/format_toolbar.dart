import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';

class FormatToolbar extends StatelessWidget {
  final Function(String)? onFormatPressed;
  
  const FormatToolbar({super.key, this.onFormatPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppConstants.formatBarHeight,
      decoration: BoxDecoration(
        color: AppColors.tabBackground,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Center(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
            _FormatButton(
              icon: Icons.title,
              tooltip: '제목 1',
              onPressed: () => onFormatPressed?.call('h1'),
            ),
            _FormatButton(
              icon: Icons.title,
              tooltip: '제목 2',
              onPressed: () => onFormatPressed?.call('h2'),
              size: 14,
            ),
            _FormatButton(
              icon: Icons.title,
              tooltip: '제목 3',
              onPressed: () => onFormatPressed?.call('h3'),
              size: 12,
            ),
            const SizedBox(width: 8),
            _FormatButton(
              icon: Icons.format_bold,
              tooltip: '굵게',
              onPressed: () => onFormatPressed?.call('bold'),
            ),
            _FormatButton(
              icon: Icons.format_italic,
              tooltip: '기울임',
              onPressed: () => onFormatPressed?.call('italic'),
            ),
            _FormatButton(
              icon: Icons.format_strikethrough,
              tooltip: '취소선',
              onPressed: () => onFormatPressed?.call('strikethrough'),
            ),
            const SizedBox(width: 8),
            _FormatButton(
              icon: Icons.format_list_bulleted,
              tooltip: '불릿 목록',
              onPressed: () => onFormatPressed?.call('bullet'),
            ),
            _FormatButton(
              icon: Icons.format_list_numbered,
              tooltip: '번호 목록',
              onPressed: () => onFormatPressed?.call('numbered'),
            ),
            const SizedBox(width: 8),
            _FormatButton(
              icon: Icons.link,
              tooltip: '링크',
              onPressed: () => onFormatPressed?.call('link'),
            ),
            _FormatButton(
              icon: Icons.image,
              tooltip: '이미지',
              onPressed: () => onFormatPressed?.call('image'),
            ),
            _FormatButton(
              icon: Icons.code,
              tooltip: '코드',
              onPressed: () => onFormatPressed?.call('code'),
            ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FormatButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final double? size;

  const _FormatButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        icon: Icon(
          icon,
          color: AppColors.textPrimary,
          size: size ?? 16,
        ),
        onPressed: onPressed,
        splashRadius: 16,
        padding: const EdgeInsets.all(6),
        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      ),
    );
  }
}