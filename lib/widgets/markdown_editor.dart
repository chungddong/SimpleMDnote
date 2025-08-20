import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';

class MarkdownEditor extends StatefulWidget {
  final TextEditingController? controller;
  final VoidCallback? onContentChanged;
  
  const MarkdownEditor({super.key, this.controller, this.onContentChanged});

  @override
  State<MarkdownEditor> createState() => MarkdownEditorState();
}

class MarkdownEditorState extends State<MarkdownEditor> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  final FocusNode _titleFocusNode = FocusNode();
  final FocusNode _contentFocusNode = FocusNode();
  bool _isUpdatingContent = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _contentController = widget.controller ?? TextEditingController();
    
    // 내용 변경 감지 리스너 추가
    _titleController.addListener(_onContentChanged);
    _contentController.addListener(_onContentChanged);
  }
  
  void _onContentChanged() {
    if (_isUpdatingContent) return;
    widget.onContentChanged?.call();
  }

  @override
  void dispose() {
    _titleController.dispose();
    if (widget.controller == null) {
      _contentController.dispose();
    }
    _titleFocusNode.dispose();
    _contentFocusNode.dispose();
    super.dispose();
  }

  void insertFormat(String format) {
    final selection = _contentController.selection;
    final text = _contentController.text;
    
    if (!selection.isValid) return;

    final selectedText = text.substring(selection.start, selection.end);
    String newText = '';
    int cursorOffset = 0;

    switch (format) {
      case 'bold':
        if (selectedText.isEmpty) {
          newText = '**텍스트**';
          cursorOffset = 2;
        } else {
          newText = '**$selectedText**';
          cursorOffset = newText.length;
        }
        break;
      case 'italic':
        if (selectedText.isEmpty) {
          newText = '*텍스트*';
          cursorOffset = 1;
        } else {
          newText = '*$selectedText*';
          cursorOffset = newText.length;
        }
        break;
      case 'h1':
        final lineStart = _getLineStart(text, selection.start);
        final lineEnd = _getLineEnd(text, selection.start);
        final currentLine = text.substring(lineStart, lineEnd);
        final cleanLine = currentLine.replaceFirst(RegExp(r'^#{1,3}\s*'), '');
        newText = '# $cleanLine';
        _contentController.value = TextEditingValue(
          text: text.replaceRange(lineStart, lineEnd, newText),
          selection: TextSelection.collapsed(offset: lineStart + newText.length),
        );
        return;
      case 'h2':
        final lineStart = _getLineStart(text, selection.start);
        final lineEnd = _getLineEnd(text, selection.start);
        final currentLine = text.substring(lineStart, lineEnd);
        final cleanLine = currentLine.replaceFirst(RegExp(r'^#{1,3}\s*'), '');
        newText = '## $cleanLine';
        _contentController.value = TextEditingValue(
          text: text.replaceRange(lineStart, lineEnd, newText),
          selection: TextSelection.collapsed(offset: lineStart + newText.length),
        );
        return;
      case 'h3':
        final lineStart = _getLineStart(text, selection.start);
        final lineEnd = _getLineEnd(text, selection.start);
        final currentLine = text.substring(lineStart, lineEnd);
        final cleanLine = currentLine.replaceFirst(RegExp(r'^#{1,3}\s*'), '');
        newText = '### $cleanLine';
        _contentController.value = TextEditingValue(
          text: text.replaceRange(lineStart, lineEnd, newText),
          selection: TextSelection.collapsed(offset: lineStart + newText.length),
        );
        return;
      default:
        return;
    }

    final newTextValue = text.replaceRange(selection.start, selection.end, newText);
    _contentController.value = TextEditingValue(
      text: newTextValue,
      selection: TextSelection.collapsed(offset: selection.start + cursorOffset),
    );
  }

  int _getLineStart(String text, int position) {
    int lineStart = position;
    while (lineStart > 0 && text[lineStart - 1] != '\n') {
      lineStart--;
    }
    return lineStart;
  }

  int _getLineEnd(String text, int position) {
    int lineEnd = position;
    while (lineEnd < text.length && text[lineEnd] != '\n') {
      lineEnd++;
    }
    return lineEnd;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.editorBackground,
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.editorBackground,
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 제목 입력
              TextField(
                controller: _titleController,
                focusNode: _titleFocusNode,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                ),
                decoration: const InputDecoration(
                  hintText: '제목 없음',
                  hintStyle: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
                maxLines: null,
                textInputAction: TextInputAction.next,
                onSubmitted: (_) => _contentFocusNode.requestFocus(),
              ),
              const SizedBox(height: 16),
              // 내용 입력
              Expanded(
                child: TextField(
                  controller: _contentController,
                  focusNode: _contentFocusNode,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: AppConstants.bodyFontSize,
                    height: 1.6,
                  ),
                  decoration: const InputDecoration(
                    hintText: '내용을 입력하세요...\n\n마크다운 문법을 사용할 수 있습니다.',
                    hintStyle: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: AppConstants.bodyFontSize,
                      height: 1.6,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  TextEditingController get titleController => _titleController;
  TextEditingController get contentController => _contentController;
  
  void setContent(String title, String content) {
    _isUpdatingContent = true;
    _titleController.text = title;
    _contentController.text = content;
    
    // 다음 프레임에서 플래그 해제
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _isUpdatingContent = false;
    });
  }
  
  void clearContent() {
    _titleController.clear();
    _contentController.clear();
  }
}