import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';
import '../models/file_tree_item.dart';
import '../services/file_service.dart';
import '../services/settings_service.dart';
import 'sidebar.dart';
import 'editor_tab_bar.dart';
import 'markdown_editor.dart';
import 'format_toolbar.dart';
import 'dart:io';
import 'dart:async';
import 'package:path/path.dart' as path;

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
  FileTreeItem? _selectedFile;
  String _currentFileContent = '';
  String _currentFileTitle = '';
  Timer? _saveTimer;

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
    _saveTimer?.cancel();
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

  Future<void> _onFileSelected(FileTreeItem file) async {
    if (file.isFolder) return;
    
    try {
      // 노트 디렉토리 경로 가져오기
      final notesPath = await SettingsService.getNotesPath();
      if (notesPath == null) {
        print('노트 디렉토리를 찾을 수 없습니다');
        return;
      }
      
      // 절대 경로 생성
      final fullPath = path.join(notesPath, file.path);
      
      final content = await File(fullPath).readAsString();
      final lines = content.split('\n');
      String title = file.name.replaceAll('.md', '');
      String displayContent = content;
      
      // 첫 번째 줄이 # 헤더인지 확인
      if (lines.isNotEmpty && lines[0].trim().startsWith('# ')) {
        title = lines[0].substring(2).trim();
        // 제목 줄을 제거한 나머지 내용
        if (lines.length > 1) {
          displayContent = lines.skip(1).join('\n').trimLeft();
        } else {
          displayContent = '';
        }
      }
      
      setState(() {
        _selectedFile = file;
        _currentFileContent = displayContent;
        _currentFileTitle = title;
      });
      
      // 다음 프레임에서 에디터에 내용 설정
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _editorKey.currentState?.setContent(_currentFileTitle, _currentFileContent);
      });
    } catch (e) {
      print('파일 읽기 오류: $e');
      print('파일 경로: ${file.path}');
    }
  }

  Future<void> _saveCurrentFile() async {
    if (_selectedFile == null) return;
    
    try {
      // 노트 디렉토리 경로 가져오기
      final notesPath = await SettingsService.getNotesPath();
      if (notesPath == null) {
        print('노트 디렉토리를 찾을 수 없습니다');
        return;
      }
      
      final title = _editorKey.currentState?.titleController.text ?? '';
      final content = _editorKey.currentState?.contentController.text ?? '';
      
      String fullContent = '';
      if (title.isNotEmpty) {
        fullContent = '# $title\n\n$content';
      } else {
        fullContent = content;
      }
      
      // 절대 경로 생성
      final fullPath = path.join(notesPath, _selectedFile!.path);
      
      await File(fullPath).writeAsString(fullContent);
    } catch (e) {
      print('파일 저장 오류: $e');
    }
  }

  void _onEditorContentChanged() {
    if (_selectedFile == null) return;
    
    // 즉시 저장
    _saveCurrentFile();
  }

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: <LogicalKeySet, Intent>{
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyS): const _SaveIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          _SaveIntent: CallbackAction<_SaveIntent>(
            onInvoke: (_SaveIntent intent) {
              _saveCurrentFile();
              return null;
            },
          ),
        },
        child: Focus(
          autofocus: true,
          child: Scaffold(
            body: Row(
              children: [
                SideBar(
                  width: _currentWidth,
                  isCollapsed: _isSidebarCollapsed,
                  onToggle: _toggleSidebar,
                  onFileSelected: _onFileSelected,
                ),
                Expanded(
                  child: Container(
                    color: AppColors.primaryBackground,
                    child: Stack(
                      children: [
                        Column(
                          children: [
                            EditorTabBar(
                              fileName: _selectedFile?.name ?? '새 노트',
                            ),
                            Expanded(
                              child: MarkdownEditor(
                                key: _editorKey,
                                onContentChanged: _onEditorContentChanged,
                              ),
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
          ),
        ),
      ),
    );
  }
}

class _SaveIntent extends Intent {
  const _SaveIntent();
}