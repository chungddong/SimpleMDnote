import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';
import '../models/file_tree_item.dart';
import '../services/file_service.dart';
import 'file_tree.dart';

class SideBar extends StatefulWidget {
  final double? width;
  final bool isCollapsed;
  final VoidCallback? onToggle;
  final Function(FileTreeItem)? onFileSelected;

  const SideBar({
    super.key,
    this.width,
    this.isCollapsed = false,
    this.onToggle,
    this.onFileSelected,
  });

  @override
  State<SideBar> createState() => _SideBarState();
}

class _SideBarState extends State<SideBar> {
  List<FileTreeItem> _fileTreeItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFileTree();
  }

  Future<void> _loadFileTree() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final items = await FileService.loadFileTree();
      setState(() {
        _fileTreeItems = items;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading file tree: $e');
      setState(() {
        _fileTreeItems = [];
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshFileTree() async {
    await _loadFileTree();
  }

  void _onItemTapped(FileTreeItem item) {
    if (!item.isFolder) {
      widget.onFileSelected?.call(item);
    }
  }

  void _onItemToggled(FileTreeItem item) {
    print('폴더 토글: ${item.name} (${item.isExpanded ? '펼침' : '접힘'})');
  }

  @override
  Widget build(BuildContext context) {
    final currentWidth = widget.width ?? AppConstants.sidebarWidth;
    final isAnimating = currentWidth > 60 && currentWidth < 280;
    
    return ClipRect(
      child: Container(
        width: currentWidth,
        color: AppColors.sidebarBackground,
        child: OverflowBox(
          maxWidth: currentWidth,
          child: currentWidth <= 100 
              ? _buildCollapsedSidebar() 
              : _buildExpandedSidebar(isAnimating: isAnimating),
        ),
      ),
    );
  }

  Widget _buildExpandedSidebar({bool isAnimating = false}) {
    return Column(
      children: [
        // 헤더
        Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.sidebarBackground,
            border: Border(
              bottom: BorderSide(
                color: AppColors.textSecondary.withOpacity(0.2),
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: widget.onToggle,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  child: const Icon(
                    Icons.menu,
                    color: AppColors.textSecondary,
                    size: 18,
                  ),
                ),
              ),
              if (!isAnimating) ...[
                const SizedBox(width: 8),
                Icon(
                  Icons.note_alt_outlined,
                  color: AppColors.highlightColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    '내 노트',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.clip,
                    maxLines: 1,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    print('새 노트 추가');
                  },
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    child: const Icon(
                      Icons.add,
                      color: AppColors.textSecondary,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        // 파일 트리
        if (!isAnimating)
          Expanded(
            child: ClipRect(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.highlightColor),
                        ),
                      )
                    : FileTree(
                        items: _fileTreeItems,
                        onItemTapped: _onItemTapped,
                        onItemToggled: _onItemToggled,
                        onRefresh: _refreshFileTree,
                      ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCollapsedSidebar() {
    return Column(
      children: [
        // 접힌 상태 헤더
        Container(
          height: 60,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.sidebarBackground,
            border: Border(
              bottom: BorderSide(
                color: AppColors.textSecondary.withOpacity(0.2),
                width: 1,
              ),
            ),
          ),
          child: Center(
            child: GestureDetector(
              onTap: widget.onToggle,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.tabBackground,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.menu,
                  color: AppColors.textPrimary,
                  size: 18,
                ),
              ),
            ),
          ),
        ),
        // 접힌 상태에서는 파일 아이콘들만 표시
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              children: _fileTreeItems.take(5).map((item) {
                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 2),
                  child: Material(
                    color: item.isSelected 
                        ? AppColors.highlightColor.withOpacity(0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    child: InkWell(
                      onTap: () => _onItemTapped(item),
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        child: Icon(
                          item.isFolder 
                              ? (item.isExpanded ? Icons.folder_open : Icons.folder)
                              : Icons.description_outlined,
                          size: 18,
                          color: item.isFolder 
                              ? AppColors.highlightColor.withOpacity(0.8)
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}