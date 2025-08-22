import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../models/editor_tab.dart';

class TabBarWidget extends StatefulWidget {
  final List<EditorTab> tabs;
  final Function(EditorTab) onTabSelected;
  final Function(String) onTabClosed;
  final Function(int, int) onTabReordered;
  final Function(EditorTab, TapDownDetails) onTabRightClick;

  const TabBarWidget({
    super.key,
    required this.tabs,
    required this.onTabSelected,
    required this.onTabClosed,
    required this.onTabReordered,
    required this.onTabRightClick,
  });

  @override
  State<TabBarWidget> createState() => _TabBarWidgetState();
}

class _TabBarWidgetState extends State<TabBarWidget> {
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

    return Container(
      height: 40,
      color: AppColors.tabBackground,
      child: Row(
        children: [
          Flexible(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: widget.tabs.asMap().entries.map((entry) {
                  final index = entry.key;
                  final tab = entry.value;
                  return Draggable<String>(
                    data: tab.id,
                    feedback: Material(
                      elevation: 4,
                      child: TabWidget(
                        tab: tab.copyWith(isActive: false),
                        onSelected: () {},
                        onClosed: () {},
                        onRightClick: (_) {},
                      ),
                    ),
                    childWhenDragging: Container(
                      width: 120,
                      height: 40,
                      color: AppColors.tabBackground.withValues(alpha: 0.5),
                    ),
                    child: DragTarget<String>(
                      onWillAcceptWithDetails: (details) => details.data != tab.id,
                      onAcceptWithDetails: (details) {
                        // 드래그된 탭의 인덱스 찾기
                        final draggedIndex = widget.tabs.indexWhere((t) => t.id == details.data);
                        if (draggedIndex != -1 && draggedIndex != index) {
                          widget.onTabReordered(draggedIndex, index);
                        }
                      },
                      builder: (context, candidateData, rejectedData) {
                        return TabWidget(
                          key: ValueKey(tab.id),
                          tab: tab,
                          onSelected: () => widget.onTabSelected(tab),
                          onClosed: () => widget.onTabClosed(tab.id),
                          onRightClick: (details) => widget.onTabRightClick(tab, details),
                        );
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          // 분할 영역을 위한 확장 가능한 공간
          const Expanded(child: SizedBox()),
        ],
      ),
    );
  }
}

class TabWidget extends StatefulWidget {
  final EditorTab tab;
  final VoidCallback onSelected;
  final VoidCallback onClosed;
  final Function(TapDownDetails) onRightClick;

  const TabWidget({
    super.key,
    required this.tab,
    required this.onSelected,
    required this.onClosed,
    required this.onRightClick,
  });

  @override
  State<TabWidget> createState() => _TabWidgetState();
}

class _TabWidgetState extends State<TabWidget> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isActive = widget.tab.isActive;
    
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onSelected,
        onSecondaryTapDown: widget.onRightClick,
        child: Container(
          constraints: const BoxConstraints(
            minWidth: 120,
            maxWidth: 200,
          ),
          decoration: BoxDecoration(
            color: isActive 
                ? AppColors.editorBackground 
                : _isHovered 
                    ? AppColors.tabBackground.withValues(alpha: 0.8)
                    : AppColors.tabBackground,
            border: Border(
              bottom: BorderSide(
                color: isActive 
                    ? AppColors.highlightColor 
                    : Colors.transparent,
                width: 2,
              ),
              right: BorderSide(
                color: AppColors.textSecondary.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 파일 아이콘
                Icon(
                  Icons.description,
                  size: 16,
                  color: isActive 
                      ? AppColors.textPrimary 
                      : AppColors.textSecondary,
                ),
                const SizedBox(width: 6),
                
                // 파일 이름
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
                if (widget.tab.isModified)
                  Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.only(left: 4),
                    decoration: BoxDecoration(
                      color: AppColors.highlightColor,
                      shape: BoxShape.circle,
                    ),
                  )
                else if (_isHovered || isActive)
                  GestureDetector(
                    onTap: widget.onClosed,
                    child: Container(
                      width: 16,
                      height: 16,
                      margin: const EdgeInsets.only(left: 4),
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Icon(
                        Icons.close,
                        size: 12,
                        color: isActive 
                            ? AppColors.textPrimary 
                            : AppColors.textSecondary,
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