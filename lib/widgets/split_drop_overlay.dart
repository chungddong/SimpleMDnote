import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

enum DropZone {
  left,
  right, 
  top,
  bottom,
  center
}

class SplitDropOverlay extends StatefulWidget {
  final Widget child;
  final Function(String tabId, DropZone zone) onTabDropped;

  const SplitDropOverlay({
    super.key,
    required this.child,
    required this.onTabDropped,
  });

  @override
  State<SplitDropOverlay> createState() => _SplitDropOverlayState();
}

class _SplitDropOverlayState extends State<SplitDropOverlay> {
  DropZone? _hoveredZone;
  bool _isDragActive = false;

  @override
  void initState() {
    super.initState();
    // 주기적으로 드래그 상태 확인
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkDragState();
    });
  }

  void _checkDragState() {
    if (mounted) {
      final isDragging = DragStateManager().isDragging;
      if (_isDragActive != isDragging) {
        debugPrint('드롭존 상태 변경: $_isDragActive -> $isDragging');
        setState(() {
          _isDragActive = isDragging;
        });
      }
      // 100ms마다 상태 체크
      Future.delayed(const Duration(milliseconds: 100), _checkDragState);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        _buildDropZones(),
      ],
    );
  }

  Widget _buildDropZones() {
    return Positioned.fill(
      child: Stack(
        children: [
          // 왼쪽 드롭 존
          _buildDropZone(
            alignment: Alignment.centerLeft,
            zone: DropZone.left,
            child: Container(
              width: 100,
              height: double.infinity,
              margin: const EdgeInsets.all(20),
            ),
          ),
          
          // 오른쪽 드롭 존
          _buildDropZone(
            alignment: Alignment.centerRight,
            zone: DropZone.right,
            child: Container(
              width: 100,
              height: double.infinity,
              margin: const EdgeInsets.all(20),
            ),
          ),
          
          // 위쪽 드롭 존
          _buildDropZone(
            alignment: Alignment.topCenter,
            zone: DropZone.top,
            child: Container(
              width: double.infinity,
              height: 100,
              margin: const EdgeInsets.all(20),
            ),
          ),
          
          // 아래쪽 드롭 존
          _buildDropZone(
            alignment: Alignment.bottomCenter,
            zone: DropZone.bottom,
            child: Container(
              width: double.infinity,
              height: 100,
              margin: const EdgeInsets.all(20),
            ),
          ),
          
          // 중앙 드롭 존
          _buildDropZone(
            alignment: Alignment.center,
            zone: DropZone.center,
            child: Container(
              width: 200,
              height: 200,
              margin: const EdgeInsets.all(100),
            ),
          ),
          
          // 하이라이트 오버레이
          if (_hoveredZone != null) _buildHighlight(_hoveredZone!),
        ],
      ),
    );
  }

  Widget _buildDropZone({
    required Alignment alignment,
    required DropZone zone,
    required Widget child,
  }) {
    return Align(
      alignment: alignment,
      child: DragTarget<Map<String, dynamic>>(
        onWillAcceptWithDetails: (details) {
          setState(() {
            _hoveredZone = zone;
          });
          return details.data['tabId'] != null;
        },
        onLeave: (data) {
          setState(() {
            _hoveredZone = null;
          });
        },
        onAcceptWithDetails: (details) {
          setState(() {
            _hoveredZone = null;
          });
          final tabId = details.data['tabId'] as String;
          widget.onTabDropped(tabId, zone);
        },
        builder: (context, candidateData, rejectedData) {
          return child;
        },
      ),
    );
  }

  Widget _buildHighlight(DropZone zone) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.highlightColor.withValues(alpha: 0.1),
            border: Border.all(
              color: AppColors.highlightColor,
              width: 2,
            ),
          ),
          child: _getHighlightContent(zone),
        ),
      ),
    );
  }

  Widget _getHighlightContent(DropZone zone) {
    switch (zone) {
      case DropZone.left:
        return _buildSplitPreview(isVertical: true, position: 'left');
      case DropZone.right:
        return _buildSplitPreview(isVertical: true, position: 'right');
      case DropZone.top:
        return _buildSplitPreview(isVertical: false, position: 'top');
      case DropZone.bottom:
        return _buildSplitPreview(isVertical: false, position: 'bottom');
      case DropZone.center:
        return _buildCenterPreview();
    }
  }

  Widget _buildSplitPreview({required bool isVertical, required String position}) {
    return Container(
      margin: const EdgeInsets.all(20),
      child: isVertical
          ? Row(
              children: [
                if (position == 'right') const Expanded(child: SizedBox()),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.highlightColor.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.highlightColor,
                        width: 2,
                      ),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.tab,
                        size: 48,
                        color: AppColors.highlightColor,
                      ),
                    ),
                  ),
                ),
                if (position == 'left') const Expanded(child: SizedBox()),
              ],
            )
          : Column(
              children: [
                if (position == 'bottom') const Expanded(child: SizedBox()),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.highlightColor.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.highlightColor,
                        width: 2,
                      ),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.tab,
                        size: 48,
                        color: AppColors.highlightColor,
                      ),
                    ),
                  ),
                ),
                if (position == 'top') const Expanded(child: SizedBox()),
              ],
            ),
    );
  }

  Widget _buildCenterPreview() {
    return Center(
      child: Container(
        width: 200,
        height: 100,
        decoration: BoxDecoration(
          color: AppColors.highlightColor.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppColors.highlightColor,
            width: 2,
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add,
                size: 32,
                color: AppColors.highlightColor,
              ),
              SizedBox(height: 8),
              Text(
                '탭 추가',
                style: TextStyle(
                  color: AppColors.highlightColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 글로벌 드래그 상태 관리
class DragStateManager {
  static final DragStateManager _instance = DragStateManager._internal();
  factory DragStateManager() => _instance;
  DragStateManager._internal();

  bool _isDragging = false;
  String? _draggedTabId;

  bool get isDragging => _isDragging;
  String? get draggedTabId => _draggedTabId;

  void startDrag(String tabId) {
    _isDragging = true;
    _draggedTabId = tabId;
  }

  void endDrag() {
    _isDragging = false;
    _draggedTabId = null;
  }
}