import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';

class MarkdownEditor extends StatefulWidget {
  final TextEditingController? controller;
  
  const MarkdownEditor({super.key, this.controller});

  @override
  State<MarkdownEditor> createState() => MarkdownEditorState();
}

class MarkdownEditorState extends State<MarkdownEditor> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  final FocusNode _titleFocusNode = FocusNode();
  final FocusNode _contentFocusNode = FocusNode();
  bool _isPreviewMode = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _contentController = widget.controller ?? TextEditingController();
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

  void _insertFormat(String format) {
    final controller = _contentController;
    final selection = controller.selection;
    final text = controller.text;
    
    if (selection.isValid) {
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
        case 'strikethrough':
          if (selectedText.isEmpty) {
            newText = '~~텍스트~~';
            cursorOffset = 2;
          } else {
            newText = '~~$selectedText~~';
            cursorOffset = newText.length;
          }
          break;
        case 'code':
          if (selectedText.isEmpty) {
            newText = '`코드`';
            cursorOffset = 1;
          } else {
            newText = '`$selectedText`';
            cursorOffset = newText.length;
          }
          break;
        case 'link':
          newText = '[링크 텍스트](https://example.com)';
          cursorOffset = newText.length;
          break;
        case 'image':
          newText = '![이미지 설명](https://via.placeholder.com/150)';
          cursorOffset = newText.length;
          break;
        case 'bullet':
          final lineStart = _getLineStart(text, selection.start);
          if (selectedText.isEmpty) {
            newText = '- 목록 항목';
            cursorOffset = newText.length;
          } else {
            newText = '- $selectedText';
            cursorOffset = newText.length;
          }
          break;
        case 'numbered':
          if (selectedText.isEmpty) {
            newText = '1. 목록 항목';
            cursorOffset = newText.length;
          } else {
            newText = '1. $selectedText';
            cursorOffset = newText.length;
          }
          break;
        case 'h1':
          if (selectedText.isEmpty) {
            newText = '# 제목 1';
            cursorOffset = newText.length;
          } else {
            newText = '# $selectedText';
            cursorOffset = newText.length;
          }
          break;
        case 'h2':
          if (selectedText.isEmpty) {
            newText = '## 제목 2';
            cursorOffset = newText.length;
          } else {
            newText = '## $selectedText';
            cursorOffset = newText.length;
          }
          break;
        case 'h3':
          if (selectedText.isEmpty) {
            newText = '### 제목 3';
            cursorOffset = newText.length;
          } else {
            newText = '### $selectedText';
            cursorOffset = newText.length;
          }
          break;
      }
      
      final newTextValue = text.replaceRange(selection.start, selection.end, newText);
      controller.value = TextEditingValue(
        text: newTextValue,
        selection: TextSelection.collapsed(offset: selection.start + cursorOffset),
      );
    }
  }

  int _getLineStart(String text, int position) {
    int lineStart = position;
    while (lineStart > 0 && text[lineStart - 1] != '\n') {
      lineStart--;
    }
    return lineStart;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.editorBackground,
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 헤더 (제목 + 프리뷰 토글)
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _titleController,
                  focusNode: _titleFocusNode,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: const InputDecoration(
                    hintText: '제목을 입력하세요',
                    hintStyle: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 12),
                  ),
                  maxLines: null,
                  textInputAction: TextInputAction.next,
                  onSubmitted: (_) => _contentFocusNode.requestFocus(),
                ),
              ),
              IconButton(
                icon: Icon(
                  _isPreviewMode ? Icons.edit : Icons.preview,
                  color: AppColors.textPrimary,
                ),
                onPressed: () {
                  setState(() {
                    _isPreviewMode = !_isPreviewMode;
                  });
                },
                tooltip: _isPreviewMode ? '편집 모드' : '프리뷰 모드',
              ),
            ],
          ),
          const SizedBox(height: 20),
          // 내용 에디터/프리뷰
          Expanded(
            child: _isPreviewMode
                ? _buildPreview()
                : _buildEditor(),
          ),
        ],
      ),
    );
  }

  Widget _buildEditor() {
    return TextField(
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
    );
  }

  Widget _buildPreview() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.primaryBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.textSecondary.withOpacity(0.3)),
      ),
      child: Markdown(
        data: _contentController.text.isEmpty 
            ? '마크다운 내용이 여기에 표시됩니다...' 
            : _contentController.text,
        styleSheet: MarkdownStyleSheet(
          p: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: AppConstants.bodyFontSize,
            height: 1.6,
          ),
          h1: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
          h2: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          h3: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          code: TextStyle(
            backgroundColor: AppColors.tabBackground,
            color: AppColors.textPrimary,
            fontFamily: 'monospace',
          ),
          codeblockDecoration: BoxDecoration(
            color: AppColors.tabBackground,
            borderRadius: BorderRadius.circular(4),
          ),
          blockquoteDecoration: BoxDecoration(
            color: AppColors.tabBackground.withOpacity(0.5),
            border: const Border(
              left: BorderSide(
                color: AppColors.textSecondary,
                width: 4,
              ),
            ),
          ),
        ),
        selectable: true,
      ),
    );
  }

  TextEditingController get titleController => _titleController;
  TextEditingController get contentController => _contentController;

  void insertFormat(String format) => _insertFormat(format);
}