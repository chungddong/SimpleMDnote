import 'package:flutter/foundation.dart';
import '../models/split_view.dart';
import '../models/editor_tab.dart';
import '../models/file_tree_item.dart';
import '../utils/extensions.dart';

class SplitViewManager extends ChangeNotifier {
  SplitView? _splitView;
  String _activePanelId = 'main';

  SplitView? get splitView => _splitView;
  String get activePanelId => _activePanelId;
  
  bool get isSplit => _splitView != null && _splitView!.panels.length > 1;

  // 메인 패널 (분할되지 않은 상태)
  EditorPanel _mainPanel = EditorPanel(
    id: 'main',
    tabs: [],
  );

  EditorPanel get activePanel {
    if (_splitView != null) {
      return _splitView!.panels.where((p) => p.id == _activePanelId).firstOrNull ?? _mainPanel;
    }
    return _mainPanel;
  }

  List<EditorTab> get activeTabs => activePanel.tabs;
  EditorTab? get activeTab => activePanel.activeTab;

  EditorTab? openFile(FileTreeItem file, {String? targetPanelId}) {
    final panelId = targetPanelId ?? _activePanelId;
    final panel = _getPanel(panelId);
    
    if (panel == null) return null;

    // 이미 열린 파일인지 확인
    final existingTab = panel.tabs.where((tab) => tab.file?.path == file.path).firstOrNull;
    
    if (existingTab != null) {
      // 이미 열린 탭을 활성화
      _setActiveTabInPanel(panelId, existingTab);
      return existingTab;
    }

    // 새 탭 생성
    final newTab = EditorTab(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: file.name,
      file: file,
      isActive: true,
    );

    _addTabToPanel(panelId, newTab);
    _setActiveTabInPanel(panelId, newTab);
    
    notifyListeners();
    return newTab;
  }

  void closeTab(String tabId) {
    for (final panel in _getAllPanels()) {
      final tabIndex = panel.tabs.indexWhere((tab) => tab.id == tabId);
      if (tabIndex != -1) {
        _removeTabFromPanel(panel.id, tabIndex);
        break;
      }
    }
    
    // 패널에 탭이 없으면 분할 해제
    _cleanupEmptyPanels();
    notifyListeners();
  }

  void setActiveTab(String tabId) {
    for (final panel in _getAllPanels()) {
      final tab = panel.tabs.where((t) => t.id == tabId).firstOrNull;
      if (tab != null) {
        _setActiveTabInPanel(panel.id, tab);
        _activePanelId = panel.id;
        break;
      }
    }
    notifyListeners();
  }

  void setActivePanel(String panelId) {
    if (_getPanel(panelId) != null) {
      _activePanelId = panelId;
      notifyListeners();
    }
  }

  void splitHorizontally(EditorTab draggedTab) {
    // 먼저 드래그된 탭을 원래 위치에서 제거
    _removeTabFromAnyPanel(draggedTab.id);
    
    if (_splitView == null) {
      // 처음 분할하는 경우
      final rightPanel = EditorPanel(
        id: 'right',
        tabs: [draggedTab.copyWith(isActive: true)],
        activeTab: draggedTab.copyWith(isActive: true),
      );

      _splitView = SplitView(
        id: 'main_split',
        direction: SplitDirection.horizontal,
        panels: [_mainPanel, rightPanel],
        weights: [0.5, 0.5],
      );
    } else {
      // 이미 분할된 경우 새 패널 추가
      final newPanel = EditorPanel(
        id: 'panel_${DateTime.now().millisecondsSinceEpoch}',
        tabs: [draggedTab.copyWith(isActive: true)],
        activeTab: draggedTab.copyWith(isActive: true),
      );

      final updatedPanels = List<EditorPanel>.from(_splitView!.panels)..add(newPanel);
      final newWeights = List.generate(updatedPanels.length, (index) => 1.0 / updatedPanels.length);

      _splitView = _splitView!.copyWith(
        panels: updatedPanels,
        weights: newWeights,
      );
    }

    _activePanelId = _splitView!.panels.last.id;
    notifyListeners();
  }

  void closeSplit() {
    if (_splitView == null) return;

    // 모든 탭을 메인 패널로 이동
    for (final panel in _splitView!.panels) {
      if (panel.id != 'main') {
        _mainPanel = _mainPanel.copyWith(
          tabs: [..._mainPanel.tabs, ...panel.tabs],
        );
      }
    }

    // 활성 탭 설정
    if (_mainPanel.tabs.isNotEmpty) {
      _mainPanel = _mainPanel.copyWith(activeTab: _mainPanel.tabs.first);
    }

    _splitView = null;
    _activePanelId = 'main';
    notifyListeners();
  }

  void setTabModified(String tabId, bool isModified) {
    for (final panel in _getAllPanels()) {
      final tab = panel.tabs.where((tab) => tab.id == tabId).firstOrNull;
      if (tab != null && tab.isModified != isModified) {
        final updatedTab = tab.copyWith(isModified: isModified);
        final tabIndex = panel.tabs.indexOf(tab);
        final updatedTabs = List<EditorTab>.from(panel.tabs);
        updatedTabs[tabIndex] = updatedTab;
        
        _updatePanel(panel.id, panel.copyWith(tabs: updatedTabs));
        notifyListeners();
        break;
      }
    }
  }

  // Private helper methods
  EditorPanel? _getPanel(String panelId) {
    if (panelId == 'main') return _mainPanel;
    if (_splitView == null) return null;
    return _splitView!.panels.where((p) => p.id == panelId).firstOrNull;
  }

  List<EditorPanel> _getAllPanels() {
    if (_splitView == null) return [_mainPanel];
    return _splitView!.panels;
  }

  void _addTabToPanel(String panelId, EditorTab tab) {
    if (panelId == 'main') {
      _mainPanel = _mainPanel.copyWith(tabs: [..._mainPanel.tabs, tab]);
    } else if (_splitView != null) {
      final panelIndex = _splitView!.panels.indexWhere((p) => p.id == panelId);
      if (panelIndex != -1) {
        final panel = _splitView!.panels[panelIndex];
        final updatedPanel = panel.copyWith(tabs: [...panel.tabs, tab]);
        final updatedPanels = List<EditorPanel>.from(_splitView!.panels);
        updatedPanels[panelIndex] = updatedPanel;
        _splitView = _splitView!.copyWith(panels: updatedPanels);
      }
    }
  }

  void _removeTabFromPanel(String panelId, int tabIndex) {
    if (panelId == 'main') {
      if (tabIndex >= 0 && tabIndex < _mainPanel.tabs.length) {
        final updatedTabs = List<EditorTab>.from(_mainPanel.tabs);
        updatedTabs.removeAt(tabIndex);
        _mainPanel = _mainPanel.copyWith(
          tabs: updatedTabs,
          activeTab: updatedTabs.isNotEmpty ? updatedTabs.first : null,
        );
      }
    } else if (_splitView != null) {
      final panelIndex = _splitView!.panels.indexWhere((p) => p.id == panelId);
      if (panelIndex != -1) {
        final panel = _splitView!.panels[panelIndex];
        if (tabIndex >= 0 && tabIndex < panel.tabs.length) {
          final updatedTabs = List<EditorTab>.from(panel.tabs);
          updatedTabs.removeAt(tabIndex);
          
          final updatedPanel = panel.copyWith(
            tabs: updatedTabs,
            activeTab: updatedTabs.isNotEmpty ? updatedTabs.first : null,
          );
          
          final updatedPanels = List<EditorPanel>.from(_splitView!.panels);
          updatedPanels[panelIndex] = updatedPanel;
          _splitView = _splitView!.copyWith(panels: updatedPanels);
        }
      }
    }
  }


  void _removeTabFromAnyPanel(String tabId) {
    for (final panel in _getAllPanels()) {
      final tabIndex = panel.tabs.indexWhere((tab) => tab.id == tabId);
      if (tabIndex != -1) {
        _removeTabFromPanel(panel.id, tabIndex);
        break;
      }
    }
  }

  void _setActiveTabInPanel(String panelId, EditorTab tab) {
    // 모든 패널의 모든 탭을 비활성화
    _deactivateAllTabs();
    
    if (panelId == 'main') {
      final updatedTabs = List<EditorTab>.from(_mainPanel.tabs);
      final tabIndex = updatedTabs.indexWhere((t) => t.id == tab.id);
      if (tabIndex != -1) {
        updatedTabs[tabIndex] = updatedTabs[tabIndex].copyWith(isActive: true);
        _mainPanel = _mainPanel.copyWith(tabs: updatedTabs, activeTab: updatedTabs[tabIndex]);
      }
    } else if (_splitView != null) {
      final panelIndex = _splitView!.panels.indexWhere((p) => p.id == panelId);
      if (panelIndex != -1) {
        final panel = _splitView!.panels[panelIndex];
        final updatedTabs = List<EditorTab>.from(panel.tabs);
        final tabIndex = updatedTabs.indexWhere((t) => t.id == tab.id);
        
        if (tabIndex != -1) {
          updatedTabs[tabIndex] = updatedTabs[tabIndex].copyWith(isActive: true);
          final updatedPanel = panel.copyWith(tabs: updatedTabs, activeTab: updatedTabs[tabIndex]);
          final updatedPanels = List<EditorPanel>.from(_splitView!.panels);
          updatedPanels[panelIndex] = updatedPanel;
          _splitView = _splitView!.copyWith(panels: updatedPanels);
        }
      }
    }
  }

  void _deactivateAllTabs() {
    // 메인 패널의 모든 탭 비활성화
    final mainTabs = _mainPanel.tabs.map((t) => t.copyWith(isActive: false)).toList();
    _mainPanel = _mainPanel.copyWith(tabs: mainTabs);
    
    // 분할된 패널들의 모든 탭 비활성화
    if (_splitView != null) {
      final updatedPanels = <EditorPanel>[];
      for (final panel in _splitView!.panels) {
        final updatedTabs = panel.tabs.map((t) => t.copyWith(isActive: false)).toList();
        updatedPanels.add(panel.copyWith(tabs: updatedTabs));
      }
      _splitView = _splitView!.copyWith(panels: updatedPanels);
    }
  }

  void _updatePanel(String panelId, EditorPanel updatedPanel) {
    if (panelId == 'main') {
      _mainPanel = updatedPanel;
    } else if (_splitView != null) {
      final panelIndex = _splitView!.panels.indexWhere((p) => p.id == panelId);
      if (panelIndex != -1) {
        final updatedPanels = List<EditorPanel>.from(_splitView!.panels);
        updatedPanels[panelIndex] = updatedPanel;
        _splitView = _splitView!.copyWith(panels: updatedPanels);
      }
    }
  }

  void _cleanupEmptyPanels() {
    if (_splitView == null) return;

    final nonEmptyPanels = _splitView!.panels.where((panel) => panel.hasTabs).toList();
    
    if (nonEmptyPanels.length <= 1) {
      // 분할 해제
      if (nonEmptyPanels.isNotEmpty) {
        _mainPanel = nonEmptyPanels.first.copyWith(id: 'main');
      }
      _splitView = null;
      _activePanelId = 'main';
    } else {
      // 빈 패널만 제거
      final newWeights = List.generate(nonEmptyPanels.length, (index) => 1.0 / nonEmptyPanels.length);
      _splitView = _splitView!.copyWith(panels: nonEmptyPanels, weights: newWeights);
      
      // 활성 패널이 제거되었으면 첫 번째 패널로 변경
      if (!nonEmptyPanels.any((p) => p.id == _activePanelId)) {
        _activePanelId = nonEmptyPanels.first.id;
      }
    }
  }
}