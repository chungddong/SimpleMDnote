import '../models/file_tree_item.dart';

class EditorTab {
  final String id;
  final String title;
  final FileTreeItem? file;
  bool isModified;
  bool isActive;

  EditorTab({
    required this.id,
    required this.title,
    this.file,
    this.isModified = false,
    this.isActive = false,
  });

  EditorTab copyWith({
    String? id,
    String? title,
    FileTreeItem? file,
    bool? isModified,
    bool? isActive,
  }) {
    return EditorTab(
      id: id ?? this.id,
      title: title ?? this.title,
      file: file ?? this.file,
      isModified: isModified ?? this.isModified,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EditorTab &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}