import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';

class CustomTitleBar extends StatelessWidget {
  const CustomTitleBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primaryBackground,
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.defaultPadding),
      child: Row(
        children: [
          const Text(
            AppConstants.appName,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: AppConstants.titleFontSize,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Row(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.minimize,
                  color: AppColors.textPrimary,
                  size: AppConstants.iconSizeSmall,
                ),
                onPressed: () {},
                padding: const EdgeInsets.all(AppConstants.smallPadding),
                constraints: const BoxConstraints(
                  minWidth: AppConstants.iconButtonMinSize,
                  minHeight: AppConstants.iconButtonMinSize,
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.crop_square,
                  color: AppColors.textPrimary,
                  size: AppConstants.iconSizeSmall,
                ),
                onPressed: () {},
                padding: const EdgeInsets.all(AppConstants.smallPadding),
                constraints: const BoxConstraints(
                  minWidth: AppConstants.iconButtonMinSize,
                  minHeight: AppConstants.iconButtonMinSize,
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.close,
                  color: AppColors.textPrimary,
                  size: AppConstants.iconSizeSmall,
                ),
                onPressed: () => SystemNavigator.pop(),
                padding: const EdgeInsets.all(AppConstants.smallPadding),
                constraints: const BoxConstraints(
                  minWidth: AppConstants.iconButtonMinSize,
                  minHeight: AppConstants.iconButtonMinSize,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}