import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';
import '../models/editor_tab.dart';
import 'split_drop_overlay.dart';

class TabBarWidget extends StatefulWidget {
  final List<EditorTab> tabs;
  final Function(EditorTab) onTabSelected;
  final Function(String) onTabClosed;
  final Function(int, int) onTabReordered;
  final Function(EditorTab, TapDownDetails) onTabRightClick;
  final Function(String)? onTabPinToggle;
  final bool isSplitView;

  const TabBarWidget({
    super.key,
    required this.tabs,
    required this.onTabSelected,
    required this.onTabClosed,
    required this.onTabReordered,
    required this.onTabRightClick,
    this.onTabPinToggle,
    this.isSplitView = false,
  });

  @override
  State<TabBarWidget> createState() => _TabBarWidgetState();
}

class _TabBarWidgetState extends State<TabBarWidget> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _tabBarKey = GlobalKey();
  
  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // 키보드 단축키 처리를 위한 포커스 설정
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _scrollToActiveTab();
      }
    });
  }

  @override
  void didUpdateWidget(TabBarWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.tabs.length != oldWidget.tabs.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _scrollToActiveTab();
        }
      });
    }
  }

  void _scrollToActiveTab() {
    final activeIndex = widget.tabs.indexWhere((tab) => tab.isActive);
    if (activeIndex != -1 && _scrollController.hasClients) {
      const tabWidth = 180.0; // 고정 탭 너비
      final scrollPosition = activeIndex * tabWidth;
      final viewportWidth = _scrollController.position.viewportDimension;
      
      if (scrollPosition < _scrollController.offset || 
          scrollPosition > _scrollController.offset + viewportWidth - tabWidth) {
        _scrollController.animateTo(
          scrollPosition - viewportWidth / 2 + tabWidth / 2,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      // Ctrl+Tab: 다음 탭
      if (event.logicalKey == LogicalKeyboardKey.tab && 
          HardwareKeyboard.instance.isControlPressed) {
        _switchToNextTab();
      }
      // Ctrl+Shift+Tab: 이전 탭
      else if (event.logicalKey == LogicalKeyboardKey.tab && 
               HardwareKeyboard.instance.isControlPressed &&
               HardwareKeyboard.instance.isShiftPressed) {
        _switchToPreviousTab();
      }
    }
  }

  void _switchToNextTab() {
    if (widget.tabs.isEmpty) return;
    final currentIndex = widget.tabs.indexWhere((tab) => tab.isActive);
    final nextIndex = (currentIndex + 1) % widget.tabs.length;
    widget.onTabSelected(widget.tabs[nextIndex]);
  }

  void _switchToPreviousTab() {
    if (widget.tabs.isEmpty) return;
    final currentIndex = widget.tabs.indexWhere((tab) => tab.isActive);
    final prevIndex = currentIndex > 0 ? currentIndex - 1 : widget.tabs.length - 1;
    widget.onTabSelected(widget.tabs[prevIndex]);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.tabs.isEmpty) {
      return Container(
        height: 40,
        color: AppColors.tabBackground,
        child: const Row(
          children: [
            Expanded(
              child: Center(
                child: Text(
                  '열린 파일이 없습니다',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        _handleKeyEvent(event);
        return KeyEventResult.handled;
      },
      child: Container(
        key: _tabBarKey,
        height: 40,
        color: AppColors.tabBackground,
        child: Row(
          children: [
            Expanded(
              child: Listener(
                onPointerSignal: (pointerSignal) {
                  // PointerScrollEvent 타입 체크를 위한 dynamic 접근
                  final scrollDelta = (pointerSignal as dynamic).scrollDelta;
                  if (scrollDelta != null) {
                    final delta = scrollDelta.dx != 0 ? scrollDelta.dx : scrollDelta.dy;
                    
                    if (_scrollController.hasClients) {
                      final newOffset = (_scrollController.offset + delta * 2)
                          .clamp(0.0, _scrollController.position.maxScrollExtent);
                      _scrollController.animateTo(
                        newOffset,
                        duration: const Duration(milliseconds: 100),
                        curve: Curves.easeOut,
                      );
                    }
                  }
                },
                child: SingleChildScrollView(
                  controller: _scrollController,
                  scrollDirection: Axis.horizontal,
                  physics: const NeverScrollableScrollPhysics(),
                  child: Row(
                    children: widget.tabs.asMap().entries.map((entry) {
                      final index = entry.key;
                      final tab = entry.value;
                      return _buildTabItem(tab, index);
                    }).toList(),
                  ),
                ),
              ),
            ),
            // 분할 화면에서는 여분의 공간 추가
            if (widget.isSplitView) const SizedBox(width: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildTabItem(EditorTab tab, int index) {
    return Draggable<Map<String, dynamic>>(
      data: {
        'tabId': tab.id,
        'sourceIndex': index,
      },
      onDragStarted: () {
        // 글로벌 드래그 상태 시작
        debugPrint('드래그 시작: ${tab.id}');
        DragStateManager().startDrag(tab.id);
      },
      onDragEnd: (details) {
        // 글로벌 드래그 상태 종료
        debugPrint('드래그 종료: ${tab.id}');
        DragStateManager().endDrag();
      },
      feedback: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(4),
        child: SizedBox(
          width: 180,
          height: 40,
          child: TabWidget(
            tab: tab.copyWith(isActive: false),
            onSelected: () {},
            onClosed: () {},
            onRightClick: (_) {},
            onDoubleClick: () {},
            onPinToggle: () {},
            showCloseButton: false,
          ),
        ),
      ),
      childWhenDragging: Container(
        width: 180,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.tabBackground.withValues(alpha: 0.5),
          border: Border.all(
            color: AppColors.textSecondary.withValues(alpha: 0.3),
            style: BorderStyle.solid,
          ),
        ),
      ),
      child: DragTarget<Map<String, dynamic>>(
        onWillAcceptWithDetails: (details) {
          final data = details.data;
          return data['tabId'] != tab.id;
        },
        onAcceptWithDetails: (details) {
          final data = details.data;
          final draggedIndex = data['sourceIndex'] as int;
          if (draggedIndex != index) {
            widget.onTabReordered(draggedIndex, index);
          }
        },
        builder: (context, candidateData, rejectedData) {
          final isDropTarget = candidateData.isNotEmpty;
          return Container(
            decoration: isDropTarget
                ? BoxDecoration(
                    border: Border.all(
                      color: AppColors.highlightColor,
                      width: 2,
                    ),
                  )
                : null,
            child: TabWidget(
              key: ValueKey(tab.id),
              tab: tab,
              onSelected: () => widget.onTabSelected(tab),
              onClosed: () => widget.onTabClosed(tab.id),
              onRightClick: (details) => widget.onTabRightClick(tab, details),
              onDoubleClick: () => widget.onTabPinToggle?.call(tab.id),
              onPinToggle: () => widget.onTabPinToggle?.call(tab.id),
            ),
          );
        },
      ),
    );
  }
}

class TabWidget extends StatefulWidget {
  final EditorTab tab;
  final VoidCallback onSelected;
  final VoidCallback onClosed;
  final Function(TapDownDetails) onRightClick;
  final VoidCallback onDoubleClick;
  final VoidCallback onPinToggle;
  final bool showCloseButton;

  const TabWidget({
    super.key,
    required this.tab,
    required this.onSelected,
    required this.onClosed,
    required this.onRightClick,
    required this.onDoubleClick,
    required this.onPinToggle,
    this.showCloseButton = true,
  });

  @override
  State<TabWidget> createState() => _TabWidgetState();
}

class _TabWidgetState extends State<TabWidget> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isActive = widget.tab.isActive;
    final isPinned = widget.tab.isPinned ?? false;
    
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onSelected,
        onSecondaryTapDown: widget.onRightClick,
        onDoubleTap: widget.onDoubleClick,
        child: Container(
          width: 180, // VS Code 스타일 고정 너비
          height: 40,
          decoration: BoxDecoration(
            color: _getTabBackgroundColor(isActive),
            border: Border(
              bottom: BorderSide(
                color: isActive 
                    ? AppColors.highlightColor 
                    : Colors.transparent,
                width: 2,
              ),
              right: BorderSide(
                color: AppColors.textSecondary.withValues(alpha: 0.15),
                width: 1,
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                // 고정 표시 아이콘
                if (isPinned)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Icon(
                      Icons.push_pin,
                      size: 14,
                      color: isActive 
                          ? AppColors.textPrimary 
                          : AppColors.textSecondary,
                    ),
                  ),
                
                // 파일 아이콘
                Icon(
                  _getFileIcon(),
                  size: 16,
                  color: isActive 
                      ? AppColors.textPrimary 
                      : AppColors.textSecondary,
                ),
                const SizedBox(width: 8),
                
                // 파일 이름 (확장 가능)
                Expanded(
                  child: Text(
                    widget.tab.title,
                    style: TextStyle(
                      color: isActive 
                          ? AppColors.textPrimary 
                          : AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: isActive ? FontWeight.w500 : FontWeight.normal,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                
                // 수정됨 표시 또는 닫기 버튼
                _buildRightWidget(isActive, isPinned),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getTabBackgroundColor(bool isActive) {
    if (isActive) {
      return AppColors.editorBackground;
    } else if (_isHovered) {
      return AppColors.textSecondary.withValues(alpha: 0.1);
    }
    return AppColors.tabBackground;
  }

  IconData _getFileIcon() {
    final extension = widget.tab.title.split('.').lastOrNull?.toLowerCase();
    switch (extension) {
      case 'md':
      case 'markdown':
        return Icons.description;
      case 'txt':
        return Icons.text_snippet;
      default:
        return Icons.insert_drive_file;
    }
  }

  Widget _buildRightWidget(bool isActive, bool isPinned) {
    // 수정된 파일 표시
    if (widget.tab.isModified) {
      return Container(
        width: 8,
        height: 8,
        margin: const EdgeInsets.only(left: 8),
        decoration: BoxDecoration(
          color: AppColors.highlightColor,
          shape: BoxShape.circle,
        ),
      );
    }
    
    // Hover 또는 활성 탭에서 닫기 버튼 표시 (단, 고정된 탭은 제외)
    if (widget.showCloseButton && (_isHovered || isActive) && !isPinned) {
      return GestureDetector(
        onTap: widget.onClosed,
        child: Container(
          width: 20,
          height: 20,
          margin: const EdgeInsets.only(left: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: _isHovered 
                ? AppColors.textSecondary.withValues(alpha: 0.1)
                : Colors.transparent,
          ),
          child: Icon(
            Icons.close,
            size: 14,
            color: isActive 
                ? AppColors.textPrimary 
                : AppColors.textSecondary,
          ),
        ),
      );
    }
    
    return const SizedBox(width: 20); // 일관된 레이아웃을 위한 공간
  }
}