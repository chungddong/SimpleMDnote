import '../models/editor_tab.dart';

enum SplitDirection {
  horizontal, // 좌우 분할
  vertical,   // 상하 분할
}

class SplitView {
  final String id;
  final SplitDirection direction;
  final List<EditorPanel> panels;
  final List<double> weights; // 각 패널의 비율

  SplitView({
    required this.id,
    required this.direction,
    required this.panels,
    List<double>? weights,
  }) : weights = weights ?? List.filled(panels.length, 1.0 / panels.length);

  SplitView copyWith({
    String? id,
    SplitDirection? direction,
    List<EditorPanel>? panels,
    List<double>? weights,
  }) {
    return SplitView(
      id: id ?? this.id,
      direction: direction ?? this.direction,
      panels: panels ?? this.panels,
      weights: weights ?? this.weights,
    );
  }
}

class EditorPanel {
  final String id;
  final List<EditorTab> tabs;
  final EditorTab? activeTab;

  EditorPanel({
    required this.id,
    required this.tabs,
    this.activeTab,
  });

  EditorPanel copyWith({
    String? id,
    List<EditorTab>? tabs,
    EditorTab? activeTab,
  }) {
    return EditorPanel(
      id: id ?? this.id,
      tabs: tabs ?? this.tabs,
      activeTab: activeTab ?? this.activeTab,
    );
  }

  bool get hasTabs => tabs.isNotEmpty;
}