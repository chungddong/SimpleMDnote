import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';
import 'custom_title_bar.dart';
import 'sidebar.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          const SideBar(),
          Expanded(
            child: Container(
              color: AppColors.primaryBackground,
              child: const Center(
                child: Text(
                  '메인 콘텐츠 영역',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: AppConstants.headerFontSize,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}