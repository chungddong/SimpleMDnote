import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';
import '../models/file_tree_item.dart';
import '../models/editor_tab.dart';
import '../services/settings_service.dart';
import '../services/split_view_manager.dart';
import '../utils/extensions.dart';
import 'sidebar.dart';
import 'tab_bar_widget.dart';
import 'markdown_editor.dart';
import 'format_toolbar.dart';
import 'split_drop_zone.dart';
import 'dart:io';
import 'dart:async';
import 'package:path/path.dart' as path;

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  final Map<String, GlobalKey<MarkdownEditorState>> _editorKeys = {};
  final Map<String, String> _tabContentCache = {}; // 탭별 내용 캐시
  final SplitViewManager _splitViewManager = SplitViewManager();
  bool _isSidebarCollapsed = false;
  late AnimationController _animationController;
  late Animation<double> _widthAnimation;
  double _currentWidth = 280.0;
  Timer? _saveTimer;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _splitViewManager.addListener(_onSplitViewChanged);
    // 메인 에디터 키 초기화
    _editorKeys['main'] = GlobalKey<MarkdownEditorState>();
  }

  void _onSplitViewChanged() {
    setState(() {
      // 새로운 패널에 대한 에디터 키 생성
      if (_splitViewManager.splitView != null) {
        for (final panel in _splitViewManager.splitView!.panels) {
          if (!_editorKeys.containsKey(panel.id)) {
            _editorKeys[panel.id] = GlobalKey<MarkdownEditorState>();
          }
        }
      }
    });
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
    _splitViewManager.removeListener(_onSplitViewChanged);
    _splitViewManager.dispose();
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

  void _onFormatPressed(String format, [String? panelId]) {
    final targetPanelId = panelId ?? _splitViewManager.activePanelId;
    final activeEditorKey = _editorKeys[targetPanelId];
    activeEditorKey?.currentState?.insertFormat(format);
  }

  Future<void> _onFileSelected(FileTreeItem file) async {
    if (file.isFolder) return;
    
    debugPrint('파일 선택: ${file.name}, 활성 패널: ${_splitViewManager.activePanelId}');
    
    // 활성 패널에 파일 열기
    final tab = _splitViewManager.openFile(file, targetPanelId: _splitViewManager.activePanelId);
    if (tab != null) {
      // 활성 패널에 내용 로드
      await _loadTabContentForPanel(_splitViewManager.activePanelId, tab);
      debugPrint('파일 오픈 완료: ${tab.title}');
    }
  }


  Future<void> _loadTabContentForPanel(String panelId, EditorTab tab) async {
    if (tab.file == null) return;
    
    try {
      // 노트 디렉토리 경로 가져오기
      final notesPath = await SettingsService.getNotesPath();
      if (notesPath == null) {
        debugPrint('노트 디렉토리를 찾을 수 없습니다');
        return;
      }
      
      // 절대 경로 생성
      final fullPath = path.join(notesPath, tab.file!.path);
      
      final content = await File(fullPath).readAsString();
      final lines = content.split('\n');
      String title = tab.file!.name.replaceAll('.md', '');
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
      
      // 탭별 내용 캐시 업데이트
      _tabContentCache[tab.id] = content;
      
      // 다음 프레임에서 해당 패널의 에디터에 내용 설정
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final editorKey = _editorKeys[panelId];
        if (editorKey?.currentState != null) {
          editorKey!.currentState!.setContent(title, displayContent);
          debugPrint('패널 $panelId 에디터에 내용 로드 완료: ${tab.title}');
        } else {
          debugPrint('패널 $panelId 에디터 키를 찾을 수 없음');
        }
      });
    } catch (e) {
      debugPrint('파일 읽기 오류: $e');
      debugPrint('파일 경로: ${tab.file?.path}');
    }
  }

  Future<void> _saveCurrentFile() async {
    final activeTab = _splitViewManager.activeTab;
    if (activeTab?.file == null) return;
    
    try {
      // 노트 디렉토리 경로 가져오기
      final notesPath = await SettingsService.getNotesPath();
      if (notesPath == null) {
        debugPrint('노트 디렉토리를 찾을 수 없습니다');
        return;
      }
      
      final activeEditorKey = _editorKeys[_splitViewManager.activePanelId];
      final title = activeEditorKey?.currentState?.titleController.text ?? '';
      final content = activeEditorKey?.currentState?.contentController.text ?? '';
      
      String fullContent = '';
      if (title.isNotEmpty) {
        fullContent = '# $title\n\n$content';
      } else {
        fullContent = content;
      }
      
      // 절대 경로 생성
      final fullPath = path.join(notesPath, activeTab!.file!.path);
      
      await File(fullPath).writeAsString(fullContent);
      
      // 탭의 수정 상태 업데이트
      _splitViewManager.setTabModified(activeTab.id, false);
    } catch (e) {
      debugPrint('파일 저장 오류: $e');
    }
  }

  void _onEditorContentChanged() {
    final activeTab = _splitViewManager.activeTab;
    if (activeTab == null) return;
    
    // 탭을 수정됨으로 표시
    _splitViewManager.setTabModified(activeTab.id, true);
    
    // 즉시 저장
    _saveCurrentFile();
  }

  void _onTabSelected(EditorTab tab) {
    debugPrint('탭 선택됨: ${tab.title} (ID: ${tab.id})');
    
    // 탭이 속한 패널 찾기
    String? panelId = _findPanelForTab(tab.id);
    
    if (panelId != null) {
      debugPrint('패널 ID 찾음: $panelId');
      _onPanelTabSelected(panelId, tab);
    } else {
      debugPrint('패널을 찾을 수 없음: ${tab.id}');
    }
  }

  String? _findPanelForTab(String tabId) {
    // 메인 패널에서 찾기
    if (_splitViewManager.activePanel.tabs.any((t) => t.id == tabId)) {
      return _splitViewManager.activePanelId;
    }
    
    // 분할된 패널들에서 찾기
    if (_splitViewManager.splitView != null) {
      for (final panel in _splitViewManager.splitView!.panels) {
        if (panel.tabs.any((t) => t.id == tabId)) {
          return panel.id;
        }
      }
    }
    
    return null;
  }

  void _onTabClosed(String tabId) {
    _splitViewManager.closeTab(tabId);
  }

  void _onTabReordered(int oldIndex, int newIndex) {
    // 현재 분할 뷰 매니저에서는 reorder 미지원, 추후 구현 가능
  }

  void _onTabRightClick(EditorTab tab, TapDownDetails details) {
    // 우클릭 컨텍스트 메뉴 표시 (나중에 구현)
  }

  void _onSplit(String direction, String tabId) {
    debugPrint('분할 요청: $direction, 탭 ID: $tabId');
    
    // 모든 패널에서 탭을 찾기
    EditorTab? draggedTab;
    
    // 메인 패널에서 찾기
    final mainTab = _splitViewManager.activePanel.tabs.where((t) => t.id == tabId).firstOrNull;
    if (mainTab != null) {
      draggedTab = mainTab;
    }
    
    // 분할된 패널들에서 찾기
    if (draggedTab == null && _splitViewManager.splitView != null) {
      for (final panel in _splitViewManager.splitView!.panels) {
        final tab = panel.tabs.where((t) => t.id == tabId).firstOrNull;
        if (tab != null) {
          draggedTab = tab;
          break;
        }
      }
    }

    if (draggedTab != null && direction == 'right') {
      debugPrint('수평 분할 실행 중...');
      _splitViewManager.splitHorizontally(draggedTab);
      
      // 새로 생성된 패널의 탭 내용 로드
      final newPanelId = _splitViewManager.activePanelId;
      _loadTabContentForPanel(newPanelId, draggedTab);
      
      debugPrint('분할 완료, 새 패널: $newPanelId');
    }
  }

  Widget _buildEditorArea() {
    if (_splitViewManager.isSplit) {
      return _buildSplitView();
    } else {
      return _buildSingleEditor();
    }
  }

  Widget _buildSingleEditor() {
    return Stack(
      children: [
        Column(
          children: [
            TabBarWidget(
              tabs: _splitViewManager.activeTabs,
              onTabSelected: _onTabSelected,
              onTabClosed: _onTabClosed,
              onTabReordered: _onTabReordered,
              onTabRightClick: _onTabRightClick,
            ),
            Expanded(
              child: DragTarget<FileTreeItem>(
                onWillAcceptWithDetails: (details) => !details.data.isFolder,
                onAcceptWithDetails: (details) {
                  debugPrint('파일 드롭: ${details.data.name}');
                  _onFileSelected(details.data);
                },
                builder: (context, candidateData, rejectedData) {
                  return Stack(
                    children: [
                      _splitViewManager.activeTab != null
                          ? MarkdownEditor(
                              key: _editorKeys['main']!,
                              onContentChanged: _onEditorContentChanged,
                            )
                          : Container(
                              color: AppColors.editorBackground,
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      candidateData.isNotEmpty ? Icons.file_copy : Icons.description_outlined,
                                      size: 48,
                                      color: candidateData.isNotEmpty 
                                          ? AppColors.highlightColor 
                                          : AppColors.textSecondary.withValues(alpha: 0.5),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      candidateData.isNotEmpty 
                                          ? '파일을 여기에 놓으세요' 
                                          : '파일을 선택하거나 드래그해주세요',
                                      style: TextStyle(
                                        color: candidateData.isNotEmpty 
                                            ? AppColors.highlightColor 
                                            : AppColors.textSecondary,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                      // 단일 에디터용 서식바
                      if (_splitViewManager.activeTab != null)
                        Positioned(
                          bottom: 16,
                          left: 16,
                          right: 16,
                          child: FormatToolbar(
                            onFormatPressed: (format) => _onFormatPressed(format, 'main'),
                          ),
                        ),
                      // 드롭 호버 효과
                      if (candidateData.isNotEmpty)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: AppColors.highlightColor,
                                width: 2,
                              ),
                              color: AppColors.highlightColor.withValues(alpha: 0.1),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
        // 분할을 위한 드롭 오버레이
        SplitDropOverlay(
          onSplit: _onSplit,
        ),
      ],
    );
  }

  Widget _buildSplitView() {
    final splitView = _splitViewManager.splitView!;
    
    if (splitView.panels.length == 2) {
      return Row(
        children: [
          Expanded(
            flex: (splitView.weights[0] * 100).round(),
            child: _buildPanelEditor(splitView.panels[0]),
          ),
          Container(
            width: 1,
            color: AppColors.textSecondary.withValues(alpha: 0.3),
          ),
          Expanded(
            flex: (splitView.weights[1] * 100).round(),
            child: _buildPanelEditor(splitView.panels[1]),
          ),
        ],
      );
    }
    
    return _buildSingleEditor(); // fallback
  }

  Widget _buildPanelEditor(panel) {
    final editorKey = _editorKeys[panel.id];
    if (editorKey == null) return Container();
    
    return GestureDetector(
      onTap: () {
        // 패널 클릭 시 해당 패널을 활성화
        if (_splitViewManager.activePanelId != panel.id) {
          _splitViewManager.setActivePanel(panel.id);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          border: _splitViewManager.activePanelId == panel.id 
              ? Border.all(color: AppColors.highlightColor.withValues(alpha: 0.3), width: 1)
              : null,
        ),
        child: Column(
          children: [
            TabBarWidget(
              tabs: panel.tabs,
              onTabSelected: (tab) => _onPanelTabSelected(panel.id, tab),
              onTabClosed: _onTabClosed,
              onTabReordered: _onTabReordered,
              onTabRightClick: _onTabRightClick,
            ),
            Expanded(
              child: DragTarget<FileTreeItem>(
                onWillAcceptWithDetails: (details) => !details.data.isFolder,
                onAcceptWithDetails: (details) {
                  debugPrint('파일 드롭 to 패널 ${panel.id}: ${details.data.name}');
                  // 해당 패널에 파일 열기
                  final tab = _splitViewManager.openFile(details.data, targetPanelId: panel.id);
                  if (tab != null) {
                    _loadTabContentForPanel(panel.id, tab);
                  }
                },
                builder: (context, candidateData, rejectedData) {
                  return Stack(
                    children: [
                      panel.activeTab != null
                          ? MarkdownEditor(
                              key: editorKey,
                              onContentChanged: _onEditorContentChanged,
                            )
                          : Container(
                              color: AppColors.editorBackground,
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      candidateData.isNotEmpty ? Icons.file_copy : Icons.description_outlined,
                                      size: 32,
                                      color: candidateData.isNotEmpty 
                                          ? AppColors.highlightColor 
                                          : AppColors.textSecondary.withValues(alpha: 0.5),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      candidateData.isNotEmpty 
                                          ? '파일을 여기에 놓으세요' 
                                          : '파일을 선택하세요',
                                      style: TextStyle(
                                        color: candidateData.isNotEmpty 
                                            ? AppColors.highlightColor 
                                            : AppColors.textSecondary,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                      // 각 패널별 서식바
                      if (panel.activeTab != null)
                        Positioned(
                          bottom: 16,
                          left: 16,
                          right: 16,
                          child: FormatToolbar(
                            onFormatPressed: (format) => _onFormatPressed(format, panel.id),
                          ),
                        ),
                      // 드롭 호버 효과
                      if (candidateData.isNotEmpty)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: AppColors.highlightColor,
                                width: 2,
                              ),
                              color: AppColors.highlightColor.withValues(alpha: 0.1),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onPanelTabSelected(String panelId, EditorTab tab) {
    debugPrint('패널 $panelId에서 탭 선택: ${tab.title}');
    
    // 패널과 탭을 즉시 활성화 (상태 변경 먼저)
    _splitViewManager.setActivePanel(panelId);
    _splitViewManager.setActiveTab(tab.id);
    
    // UI 즉시 업데이트 (선택 효과 즉시 반영)
    setState(() {});
    
    // 내용 로드는 비동기로 처리
    Future.microtask(() => _loadTabContentForPanel(panelId, tab));
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
                        _buildEditorArea(),
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