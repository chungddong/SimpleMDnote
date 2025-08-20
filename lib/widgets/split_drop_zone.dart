import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class SplitDropZone extends StatefulWidget {
  final Widget child;
  final Function(String tabId) onTabDropped;
  final String direction; // 'left', 'right', 'top', 'bottom'

  const SplitDropZone({
    super.key,
    required this.child,
    required this.onTabDropped,
    required this.direction,
  });

  @override
  State<SplitDropZone> createState() => _SplitDropZoneState();
}

class _SplitDropZoneState extends State<SplitDropZone> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return DragTarget<String>(
      onWillAccept: (data) {
        setState(() => _isHovering = true);
        return data != null;
      },
      onLeave: (data) {
        setState(() => _isHovering = false);
      },
      onAccept: (tabId) {
        setState(() => _isHovering = false);
        widget.onTabDropped(tabId);
      },
      builder: (context, candidateData, rejectedData) {
        return Stack(
          children: [
            widget.child,
            if (_isHovering)
              _buildHoverOverlay(),
          ],
        );
      },
    );
  }

  Widget _buildHoverOverlay() {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.highlightColor.withOpacity(0.1),
          border: Border.all(
            color: AppColors.highlightColor,
            width: 2,
          ),
        ),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.highlightColor,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              _getDropMessage(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _getDropMessage() {
    switch (widget.direction) {
      case 'left':
        return '왼쪽에 분할';
      case 'right':
        return '오른쪽에 분할';
      case 'top':
        return '위쪽에 분할';
      case 'bottom':
        return '아래쪽에 분할';
      default:
        return '여기에 분할';
    }
  }
}

class SplitDropOverlay extends StatelessWidget {
  final bool showLeftZone;
  final bool showRightZone;
  final bool showTopZone;
  final bool showBottomZone;
  final Function(String direction, String tabId) onSplit;

  const SplitDropOverlay({
    super.key,
    this.showLeftZone = true,
    this.showRightZone = true,
    this.showTopZone = false,
    this.showBottomZone = false,
    required this.onSplit,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 왼쪽 드롭 영역
        if (showLeftZone)
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: 100,
            child: DragTarget<String>(
              onWillAccept: (data) => data != null,
              onAccept: (tabId) => onSplit('left', tabId),
              builder: (context, candidateData, rejectedData) {
                final isHovering = candidateData.isNotEmpty;
                return Container(
                  decoration: BoxDecoration(
                    color: isHovering 
                        ? AppColors.highlightColor.withOpacity(0.2)
                        : Colors.transparent,
                    border: isHovering
                        ? Border(right: BorderSide(color: AppColors.highlightColor, width: 2))
                        : null,
                  ),
                  child: isHovering
                      ? const Center(
                          child: Icon(
                            Icons.border_left,
                            color: AppColors.highlightColor,
                            size: 32,
                          ),
                        )
                      : null,
                );
              },
            ),
          ),

        // 오른쪽 드롭 영역
        if (showRightZone)
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            width: 100,
            child: DragTarget<String>(
              onWillAccept: (data) => data != null,
              onAccept: (tabId) => onSplit('right', tabId),
              builder: (context, candidateData, rejectedData) {
                final isHovering = candidateData.isNotEmpty;
                return Container(
                  decoration: BoxDecoration(
                    color: isHovering 
                        ? AppColors.highlightColor.withOpacity(0.2)
                        : Colors.transparent,
                    border: isHovering
                        ? Border(left: BorderSide(color: AppColors.highlightColor, width: 2))
                        : null,
                  ),
                  child: isHovering
                      ? const Center(
                          child: Icon(
                            Icons.border_right,
                            color: AppColors.highlightColor,
                            size: 32,
                          ),
                        )
                      : null,
                );
              },
            ),
          ),

        // 위쪽 드롭 영역
        if (showTopZone)
          Positioned(
            left: 100,
            right: 100,
            top: 0,
            height: 100,
            child: DragTarget<String>(
              onWillAccept: (data) => data != null,
              onAccept: (tabId) => onSplit('top', tabId),
              builder: (context, candidateData, rejectedData) {
                final isHovering = candidateData.isNotEmpty;
                return Container(
                  decoration: BoxDecoration(
                    color: isHovering 
                        ? AppColors.highlightColor.withOpacity(0.2)
                        : Colors.transparent,
                    border: isHovering
                        ? Border(bottom: BorderSide(color: AppColors.highlightColor, width: 2))
                        : null,
                  ),
                  child: isHovering
                      ? const Center(
                          child: Icon(
                            Icons.border_top,
                            color: AppColors.highlightColor,
                            size: 32,
                          ),
                        )
                      : null,
                );
              },
            ),
          ),

        // 아래쪽 드롭 영역
        if (showBottomZone)
          Positioned(
            left: 100,
            right: 100,
            bottom: 0,
            height: 100,
            child: DragTarget<String>(
              onWillAccept: (data) => data != null,
              onAccept: (tabId) => onSplit('bottom', tabId),
              builder: (context, candidateData, rejectedData) {
                final isHovering = candidateData.isNotEmpty;
                return Container(
                  decoration: BoxDecoration(
                    color: isHovering 
                        ? AppColors.highlightColor.withOpacity(0.2)
                        : Colors.transparent,
                    border: isHovering
                        ? Border(top: BorderSide(color: AppColors.highlightColor, width: 2))
                        : null,
                  ),
                  child: isHovering
                      ? const Center(
                          child: Icon(
                            Icons.border_bottom,
                            color: AppColors.highlightColor,
                            size: 32,
                          ),
                        )
                      : null,
                );
              },
            ),
          ),
      ],
    );
  }
}