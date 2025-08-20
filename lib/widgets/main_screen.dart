import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import 'sidebar.dart';
import 'editor_tab_bar.dart';
import 'markdown_editor.dart';
import 'format_toolbar.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final GlobalKey<MarkdownEditorState> _editorKey = GlobalKey<MarkdownEditorState>();

  void _onFormatPressed(String format) {
    _editorKey.currentState?.insertFormat(format);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          const SideBar(),
          Expanded(
            child: Container(
              color: AppColors.primaryBackground,
              child: Stack(
                children: [
                  Column(
                    children: [
                      const EditorTabBar(),
                      Expanded(
                        child: MarkdownEditor(key: _editorKey),
                      ),
                    ],
                  ),
                  Positioned(
                    bottom: 16,
                    left: 16,
                    right: 16,
                    child: FormatToolbar(
                      onFormatPressed: _onFormatPressed,
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