import 'package:flutter/foundation.dart';
import '../models/editor_tab.dart';
import '../models/file_tree_item.dart';
import '../utils/extensions.dart';

class TabManager extends ChangeNotifier {
  final List<EditorTab> _tabs = [];
  EditorTab? _activeTab;

  List<EditorTab> get tabs => List.unmodifiable(_tabs);
  EditorTab? get activeTab => _activeTab;

  bool get hasTabs => _tabs.isNotEmpty;

  EditorTab? openFile(FileTreeItem file) {
    // 이미 열린 파일인지 확인
    final existingTab = _tabs.where((tab) => tab.file?.path == file.path).firstOrNull;
    
    if (existingTab != null) {
      // 이미 열린 탭을 활성화
      setActiveTab(existingTab);
      return existingTab;
    }

    // 새 탭 생성
    final newTab = EditorTab(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: file.name,
      file: file,
      isActive: true,
    );

    // 기존 탭들의 활성 상태 해제
    for (var tab in _tabs) {
      tab.isActive = false;
    }

    _tabs.add(newTab);
    _activeTab = newTab;
    
    notifyListeners();
    return newTab;
  }

  void closeTab(String tabId) {
    final tabIndex = _tabs.indexWhere((tab) => tab.id == tabId);
    if (tabIndex == -1) return;

    final tabToClose = _tabs[tabIndex];
    _tabs.removeAt(tabIndex);

    // 닫힌 탭이 활성 탭이었다면 다른 탭을 활성화
    if (tabToClose == _activeTab) {
      if (_tabs.isNotEmpty) {
        // 가능한 경우 오른쪽 탭, 없으면 왼쪽 탭 활성화
        final newActiveIndex = tabIndex < _tabs.length ? tabIndex : _tabs.length - 1;
        setActiveTab(_tabs[newActiveIndex]);
      } else {
        _activeTab = null;
      }
    }

    notifyListeners();
  }

  void setActiveTab(EditorTab tab) {
    if (!_tabs.contains(tab)) return;

    // 모든 탭 비활성화
    for (var t in _tabs) {
      t.isActive = false;
    }

    // 선택된 탭 활성화
    tab.isActive = true;
    _activeTab = tab;
    
    notifyListeners();
  }

  void setTabModified(String tabId, bool isModified) {
    final tab = _tabs.where((tab) => tab.id == tabId).firstOrNull;
    if (tab != null && tab.isModified != isModified) {
      tab.isModified = isModified;
      notifyListeners();
    }
  }

  void reorderTabs(int oldIndex, int newIndex) {
    if (oldIndex == newIndex) return;
    
    final tab = _tabs.removeAt(oldIndex);
    _tabs.insert(newIndex, tab);
    
    notifyListeners();
  }

  void closeAllTabs() {
    _tabs.clear();
    _activeTab = null;
    notifyListeners();
  }

  void closeOtherTabs(String keepTabId) {
    final tabToKeep = _tabs.where((tab) => tab.id == keepTabId).firstOrNull;
    if (tabToKeep == null) return;

    _tabs.clear();
    _tabs.add(tabToKeep);
    _activeTab = tabToKeep;
    tabToKeep.isActive = true;
    
    notifyListeners();
  }
}