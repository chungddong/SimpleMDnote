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

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  final GlobalKey<MarkdownEditorState> _editorKey = GlobalKey<MarkdownEditorState>();
  bool _isSidebarCollapsed = false;
  late AnimationController _animationController;
  late Animation<double> _widthAnimation;
  double _currentWidth = 280.0;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _widthAnimation = Tween<double>(
      begin: 280.0, // AppConstants.sidebarWidth
      end: 60.0,    // 접힌 상태의 너비
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _widthAnimation.addListener(() {
      setState(() {
        _currentWidth = _widthAnimation.value;
      });
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleSidebar() {
    setState(() {
      _isSidebarCollapsed = !_isSidebarCollapsed;
      if (_isSidebarCollapsed) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  void _onFormatPressed(String format) {
    _editorKey.currentState?.insertFormat(format);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          SideBar(
            width: _currentWidth,
            isCollapsed: _isSidebarCollapsed,
            onToggle: _toggleSidebar,
          ),
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