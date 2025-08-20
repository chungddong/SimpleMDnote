class FileTreeItem {
  final String id;
  final String name;
  final bool isDirectory;
  final String path;
  final List<FileTreeItem> children;
  final int level;
  bool isExpanded;
  bool isSelected;

  FileTreeItem({
    required this.id,
    required this.name,
    required this.isDirectory,
    required this.path,
    this.children = const [],
    this.level = 0,
    this.isExpanded = false,
    this.isSelected = false,
  });

  bool get hasChildren => children.isNotEmpty;
  bool get isFolder => isDirectory;
  bool get isFile => !isDirectory;

  FileTreeItem copyWith({
    String? id,
    String? name,
    bool? isDirectory,
    String? path,
    List<FileTreeItem>? children,
    int? level,
    bool? isExpanded,
    bool? isSelected,
  }) {
    return FileTreeItem(
      id: id ?? this.id,
      name: name ?? this.name,
      isDirectory: isDirectory ?? this.isDirectory,
      path: path ?? this.path,
      children: children ?? this.children,
      level: level ?? this.level,
      isExpanded: isExpanded ?? this.isExpanded,
      isSelected: isSelected ?? this.isSelected,
    );
  }
}

