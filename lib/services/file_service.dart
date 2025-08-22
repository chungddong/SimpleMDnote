import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import '../models/file_tree_item.dart';
import 'settings_service.dart';

class FileService {
  static Future<String?> getNotesDirectory() async {
    return await SettingsService.getNotesPath();
  }

  static Future<List<FileTreeItem>> loadFileTree() async {
    // 웹 환경에서는 테스트 데이터 제공
    if (kIsWeb) {
      debugPrint('Web environment detected, using mock data');
      return _getMockFileTree();
    }

    final notesPath = await getNotesDirectory();
    if (notesPath == null) return [];

    try {
      final directory = Directory(notesPath);
      if (!directory.existsSync()) {
        directory.createSync(recursive: true);
        return [];
      }

      final children = _buildFileTree(directory, notesPath);
      final rootName = path.basename(notesPath);
      final result = [
        FileTreeItem(
          id: 'root',
          name: rootName.isEmpty ? '내 노트' : rootName,
          isDirectory: true,
          path: '',
          isExpanded: true,
          children: children,
        ),
      ];
      debugPrint('Loaded ${children.length} items in root folder from $notesPath');
      return result;
    } catch (e) {
      debugPrint('Error loading file tree: $e');
      return [];
    }
  }

  static List<FileTreeItem> _getMockFileTree() {
    return [
      FileTreeItem(
        id: 'root',
        name: '내 노트',
        isDirectory: true,
        path: '',
        isExpanded: true,
        children: [
          FileTreeItem(
            id: 'sample-folder',
            name: '샘플 폴더',
            isDirectory: true,
            path: 'sample-folder',
            isExpanded: true,
            children: [
              FileTreeItem(
                id: 'sample-folder/note1.md',
                name: '노트1.md',
                isDirectory: false,
                path: 'sample-folder/note1.md',
              ),
              FileTreeItem(
                id: 'sample-folder/note2.md',
                name: '노트2.md',
                isDirectory: false,
                path: 'sample-folder/note2.md',
              ),
            ],
          ),
          FileTreeItem(
            id: 'welcome.md',
            name: '환영합니다.md',
            isDirectory: false,
            path: 'welcome.md',
          ),
        ],
      ),
    ];
  }

  static List<FileTreeItem> _buildFileTree(Directory directory, String basePath) {
    final items = <FileTreeItem>[];
    
    try {
      final entities = directory.listSync()
        ..sort((a, b) {
          if (a is Directory && b is File) return -1;
          if (a is File && b is Directory) return 1;
          return a.path.toLowerCase().compareTo(b.path.toLowerCase());
        });

      for (final entity in entities) {
        final name = path.basename(entity.path);
        final relativePath = path.relative(entity.path, from: basePath);
        
        if (entity is Directory) {
          final children = _buildFileTree(entity, basePath);
          items.add(FileTreeItem(
            id: relativePath,
            name: name,
            isDirectory: true,
            path: relativePath,
            children: children,
            isExpanded: true, // 새로 생성된 폴더는 자동으로 펼치기
          ));
        } else if (entity is File && name.endsWith('.md')) {
          items.add(FileTreeItem(
            id: relativePath,
            name: name,
            isDirectory: false,
            path: relativePath,
          ));
        }
      }
    } catch (e) {
      debugPrint('Error reading directory: $e');
    }

    return items;
  }

  static Future<bool> createFile(String fileName, {String? parentPath}) async {
    // 웹 환경에서는 시뮬레이션
    if (kIsWeb) {
      debugPrint('Mock: Creating file $fileName in ${parentPath ?? 'root'}');
      await Future.delayed(const Duration(milliseconds: 500));
      return true;
    }

    final notesPath = await getNotesDirectory();
    if (notesPath == null) return false;

    try {
      String filePath;
      if (parentPath != null && parentPath.isNotEmpty) {
        filePath = path.join(notesPath, parentPath, fileName);
      } else {
        filePath = path.join(notesPath, fileName);
      }

      if (!fileName.endsWith('.md')) {
        filePath += '.md';
      }

      final file = File(filePath);
      if (file.existsSync()) {
        return false; // File already exists
      }

      // Create parent directory if it doesn't exist
      final parentDir = Directory(path.dirname(filePath));
      if (!parentDir.existsSync()) {
        parentDir.createSync(recursive: true);
      }

      await file.writeAsString('# $fileName\n\n');
      debugPrint('Successfully created file: $filePath');
      return true;
    } catch (e) {
      debugPrint('Error creating file: $e');
      return false;
    }
  }

  static Future<bool> createFolder(String folderName, {String? parentPath}) async {
    // 웹 환경에서는 시뮬레이션
    if (kIsWeb) {
      debugPrint('Mock: Creating folder $folderName in ${parentPath ?? 'root'}');
      await Future.delayed(const Duration(milliseconds: 500));
      return true;
    }

    final notesPath = await getNotesDirectory();
    if (notesPath == null) return false;

    try {
      String folderPath;
      if (parentPath != null && parentPath.isNotEmpty) {
        folderPath = path.join(notesPath, parentPath, folderName);
      } else {
        folderPath = path.join(notesPath, folderName);
      }

      final directory = Directory(folderPath);
      if (directory.existsSync()) {
        return false; // Folder already exists
      }

      directory.createSync(recursive: true);
      debugPrint('Successfully created folder: $folderPath');
      return true;
    } catch (e) {
      debugPrint('Error creating folder: $e');
      return false;
    }
  }

  static Future<String?> readFile(String filePath) async {
    final notesPath = await getNotesDirectory();
    if (notesPath == null) return null;

    try {
      final file = File(path.join(notesPath, filePath));
      if (!file.existsSync()) return null;

      return await file.readAsString();
    } catch (e) {
      debugPrint('Error reading file: $e');
      return null;
    }
  }

  static Future<bool> writeFile(String filePath, String content) async {
    final notesPath = await getNotesDirectory();
    if (notesPath == null) return false;

    try {
      final file = File(path.join(notesPath, filePath));
      
      // Create parent directory if it doesn't exist
      final parentDir = Directory(path.dirname(file.path));
      if (!parentDir.existsSync()) {
        parentDir.createSync(recursive: true);
      }

      await file.writeAsString(content);
      return true;
    } catch (e) {
      debugPrint('Error writing file: $e');
      return false;
    }
  }

  static Future<bool> deleteFile(String filePath) async {
    final notesPath = await getNotesDirectory();
    if (notesPath == null) return false;

    try {
      final file = File(path.join(notesPath, filePath));
      if (!file.existsSync()) return false;

      await file.delete();
      return true;
    } catch (e) {
      debugPrint('Error deleting file: $e');
      return false;
    }
  }

  static Future<bool> deleteFolder(String folderPath) async {
    final notesPath = await getNotesDirectory();
    if (notesPath == null) return false;

    try {
      final directory = Directory(path.join(notesPath, folderPath));
      if (!directory.existsSync()) return false;

      await directory.delete(recursive: true);
      return true;
    } catch (e) {
      debugPrint('Error deleting folder: $e');
      return false;
    }
  }
}