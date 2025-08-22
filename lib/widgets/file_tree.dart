import 'package:flutter/material.dart';
import '../models/file_tree_item.dart';
import '../constants/app_colors.dart';
import '../services/file_service.dart';
import 'create_item_dialog.dart';

class FileTree extends StatefulWidget {
  final List<FileTreeItem> items;
  final Function(FileTreeItem)? onItemTapped;
  final Function(FileTreeItem)? onItemToggled;
  final VoidCallback? onRefresh;

  const FileTree({
    super.key,
    required this.items,
    this.onItemTapped,
    this.onItemToggled,
    this.onRefresh,
  });

  @override
  State<FileTree> createState() => _FileTreeState();
}

class _FileTreeState extends State<FileTree> {
  List<FileTreeItem> _flattenedItems = [];

  @override
  void initState() {
    super.initState();
    _updateFlattenedItems();
  }

  @override
  void didUpdateWidget(FileTree oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.items != widget.items) {
      _updateFlattenedItems();
    }
  }

  void _updateFlattenedItems() {
    _flattenedItems = _flattenItems(widget.items);
  }

  List<FileTreeItem> _flattenItems(List<FileTreeItem> items, [int level = 0]) {
    final List<FileTreeItem> result = [];
    
    for (final item in items) {
      final updatedItem = item.copyWith(level: level);
      result.add(updatedItem);
      if (updatedItem.isFolder && updatedItem.isExpanded && updatedItem.hasChildren) {
        result.addAll(_flattenItems(updatedItem.children, level + 1));
      }
    }
    
    return result;
  }

  void _toggleItem(FileTreeItem item) {
    setState(() {
      _toggleItemRecursive(widget.items, item.id);
      _updateFlattenedItems();
    });
    widget.onItemToggled?.call(item);
  }

  bool _toggleItemRecursive(List<FileTreeItem> items, String targetId) {
    for (final item in items) {
      if (item.id == targetId) {
        item.isExpanded = !item.isExpanded;
        return true;
      }
      if (item.hasChildren) {
        if (_toggleItemRecursive(item.children, targetId)) {
          return true;
        }
      }
    }
    return false;
  }

  void _selectItem(FileTreeItem item) {
    setState(() {
      _clearSelectionRecursive(widget.items);
      _selectItemRecursive(widget.items, item.id);
      _updateFlattenedItems();
    });
    widget.onItemTapped?.call(item);
  }

  void _clearSelectionRecursive(List<FileTreeItem> items) {
    for (final item in items) {
      item.isSelected = false;
      if (item.hasChildren) {
        _clearSelectionRecursive(item.children);
      }
    }
  }

  bool _selectItemRecursive(List<FileTreeItem> items, String targetId) {
    for (final item in items) {
      if (item.id == targetId) {
        item.isSelected = true;
        return true;
      }
      if (item.hasChildren) {
        if (_selectItemRecursive(item.children, targetId)) {
          return true;
        }
      }
    }
    return false;
  }

  Future<void> _createItem(bool isFile, String? parentPath) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => CreateItemDialog(
        isFile: isFile,
        parentPath: parentPath,
      ),
    );

    if (result != null) {
      final success = isFile
          ? await FileService.createFile(result['name'], parentPath: parentPath)
          : await FileService.createFolder(result['name'], parentPath: parentPath);

      if (success) {
        widget.onRefresh?.call();
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success 
                ? '${isFile ? '파일' : '폴더'}이 생성되었습니다.'
                : '${isFile ? '파일' : '폴더'} 생성에 실패했습니다.'),
            backgroundColor: success ? AppColors.highlightColor : Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 루트 폴더가 있지만 내용이 비어있는 경우 체크
    final bool isEmpty = widget.items.isEmpty || 
        (widget.items.length == 1 && widget.items.first.children.isEmpty);
    
    if (isEmpty) {
      final rootPath = widget.items.isNotEmpty ? widget.items.first.path : '';
      return Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(
              Icons.folder_open,
              size: 48,
              color: AppColors.textSecondary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              '파일이 없습니다',
              style: TextStyle(
                color: AppColors.textSecondary.withValues(alpha: 0.7),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _CreateButton(
                  icon: Icons.note_add,
                  label: '파일 생성',
                  onPressed: () => _createItem(true, rootPath),
                ),
                const SizedBox(width: 8),
                _CreateButton(
                  icon: Icons.create_new_folder,
                  label: '폴더 생성',
                  onPressed: () => _createItem(false, rootPath),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return ClipRect(
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _flattenedItems.length,
        itemBuilder: (context, index) {
          final item = _flattenedItems[index];
          return FileTreeItemWidget(
            item: item,
            onTap: () => _selectItem(item),
            onToggle: item.isFolder ? () => _toggleItem(item) : null,
            onCreateFile: () => _createItem(true, item.path),
            onCreateFolder: () => _createItem(false, item.path),
          );
        },
      ),
    );
  }
}

class FileTreeItemWidget extends StatefulWidget {
  final FileTreeItem item;
  final VoidCallback? onTap;
  final VoidCallback? onToggle;
  final VoidCallback? onCreateFile;
  final VoidCallback? onCreateFolder;

  const FileTreeItemWidget({
    super.key,
    required this.item,
    this.onTap,
    this.onToggle,
    this.onCreateFile,
    this.onCreateFolder,
  });

  @override
  State<FileTreeItemWidget> createState() => _FileTreeItemWidgetState();
}

class _FileTreeItemWidgetState extends State<FileTreeItemWidget> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final indent = widget.item.level * 16.0;
    
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: widget.item.isFolder 
          ? GestureDetector(
              onTap: widget.onTap,
              child: Container(
                height: 32,
                margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                padding: EdgeInsets.only(left: 8 + indent),
                decoration: BoxDecoration(
                  color: widget.item.isSelected
                      ? AppColors.highlightColor.withValues(alpha: 0.2)
                      : _isHovered
                          ? AppColors.textSecondary.withValues(alpha: 0.1)
                          : null,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    // 폴더 토글 버튼
                    InkWell(
                      onTap: widget.onToggle,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        width: 20,
                        height: 20,
                        alignment: Alignment.center,
                        child: Icon(
                          widget.item.isExpanded 
                              ? Icons.keyboard_arrow_down 
                              : Icons.keyboard_arrow_right,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    
                    // 아이콘
                    Icon(
                      widget.item.isExpanded ? Icons.folder_open : Icons.folder,
                      size: 16,
                      color: AppColors.highlightColor,
                    ),
                    const SizedBox(width: 8),
                    
                    // 폴더 이름
                    Expanded(
                      flex: 1,
                      child: Text(
                        widget.item.name,
                        style: TextStyle(
                          color: widget.item.isSelected 
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
                          fontSize: 13,
                          fontWeight: widget.item.isSelected 
                              ? FontWeight.w500 
                              : FontWeight.normal,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    
                    // 호버 시 생성 버튼들
                    if (_isHovered) ...[
                      const SizedBox(width: 2),
                      Container(
                        constraints: const BoxConstraints(maxWidth: 40),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _HoverButton(
                              icon: Icons.note_add,
                              tooltip: '파일 생성',
                              onPressed: widget.onCreateFile,
                            ),
                            const SizedBox(width: 2),
                            _HoverButton(
                              icon: Icons.create_new_folder,
                              tooltip: '폴더 생성',
                              onPressed: widget.onCreateFolder,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            )
          : Draggable<FileTreeItem>(
              data: widget.item,
              feedback: Material(
                elevation: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.highlightColor.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.note,
                        size: 16,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        widget.item.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              childWhenDragging: Container(
                height: 32,
                margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                padding: EdgeInsets.only(left: 8 + indent),
                decoration: BoxDecoration(
                  color: AppColors.textSecondary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 20),
                    Icon(
                      Icons.note,
                      size: 16,
                      color: AppColors.textSecondary.withValues(alpha: 0.5),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.item.name,
                        style: TextStyle(
                          color: AppColors.textSecondary.withValues(alpha: 0.5),
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              child: GestureDetector(
                onTap: widget.onTap,
                child: Container(
                  height: 32,
                  margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  padding: EdgeInsets.only(left: 8 + indent),
                  decoration: BoxDecoration(
                    color: widget.item.isSelected
                        ? AppColors.highlightColor.withValues(alpha: 0.2)
                        : _isHovered
                            ? AppColors.textSecondary.withValues(alpha: 0.1)
                            : null,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 20),
                      
                      // 아이콘
                      Icon(
                        Icons.note,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 8),
                      
                      // 파일 이름
                      Expanded(
                        flex: 1,
                        child: Text(
                          widget.item.name,
                          style: TextStyle(
                            color: widget.item.isSelected 
                                ? AppColors.textPrimary
                                : AppColors.textSecondary,
                            fontSize: 13,
                            fontWeight: widget.item.isSelected 
                                ? FontWeight.w500 
                                : FontWeight.normal,
                          ),
                          overflow: TextOverflow.ellipsis,
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

class _HoverButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  const _HoverButton({
    required this.icon,
    required this.tooltip,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      waitDuration: const Duration(milliseconds: 500),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(2),
        child: Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2),
          ),
          child: Icon(
            icon,
            size: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _CreateButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  const _CreateButton({
    required this.icon,
    required this.label,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.textSecondary,
        side: BorderSide(color: AppColors.textSecondary.withValues(alpha: 0.3)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }
}