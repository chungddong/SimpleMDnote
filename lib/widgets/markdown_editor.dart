import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final ScrollController _scrollController = ScrollController();

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
    _scrollController.dispose();
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
          // 제목 입력
          TextField(
            controller: _titleController,
            focusNode: _titleFocusNode,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              height: 1.2,
            ),
            decoration: const InputDecoration(
              hintText: '제목 없음',
              hintStyle: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 8),
            ),
            maxLines: null,
            textInputAction: TextInputAction.next,
            onSubmitted: (_) => _contentFocusNode.requestFocus(),
          ),
          const SizedBox(height: 16),
          // 실시간 마크다운 에디터
          Expanded(
            child: NotionStyleEditor(
              controller: _contentController,
              focusNode: _contentFocusNode,
              scrollController: _scrollController,
            ),
          ),
        ],
      ),
    );
  }

  TextEditingController get titleController => _titleController;
  TextEditingController get contentController => _contentController;

  void insertFormat(String format) => _insertFormat(format);
}

class NotionStyleEditor extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ScrollController scrollController;

  const NotionStyleEditor({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.scrollController,
  });

  @override
  State<NotionStyleEditor> createState() => _NotionStyleEditorState();
}

class _NotionStyleEditorState extends State<NotionStyleEditor> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primaryBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.textSecondary.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Stack(
          children: [
            // 렌더링된 마크다운 (배경)
            if (widget.controller.text.isNotEmpty)
              SingleChildScrollView(
                controller: widget.scrollController,
                child: _buildRenderedMarkdown(),
              ),
            // 투명한 텍스트 에디터 (전경)
            TextField(
              controller: widget.controller,
              focusNode: widget.focusNode,
              scrollController: widget.scrollController,
              style: TextStyle(
                color: widget.controller.text.isEmpty 
                    ? AppColors.textPrimary 
                    : Colors.transparent,
                fontSize: AppConstants.bodyFontSize,
                height: 1.6,
              ),
              decoration: InputDecoration(
                hintText: '내용을 입력하세요...\n\n마크다운 문법을 사용할 수 있습니다.\n\n예시:\n# 제목 1\n## 제목 2\n**굵은 글씨**\n*기울임*\n- 목록\n1. 번호 목록',
                hintStyle: const TextStyle(
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
          ],
        ),
      ),
    );
  }

  Widget _buildRenderedMarkdown() {
    final lines = widget.controller.text.split('\n');
    final widgets = <Widget>[];
    
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      widgets.add(_buildLineWidget(line));
      if (i < lines.length - 1) {
        widgets.add(const SizedBox(height: 2));
      }
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  Widget _buildLineWidget(String line) {
    if (line.isEmpty) {
      return const SizedBox(height: AppConstants.bodyFontSize * 1.6);
    }

    // 헤딩 처리
    if (line.startsWith('# ')) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          line.substring(2),
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 24,
            fontWeight: FontWeight.bold,
            height: 1.3,
          ),
        ),
      );
    }
    if (line.startsWith('## ')) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Text(
          line.substring(3),
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            height: 1.3,
          ),
        ),
      );
    }
    if (line.startsWith('### ')) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text(
          line.substring(4),
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            height: 1.3,
          ),
        ),
      );
    }

    // 목록 처리
    if (line.startsWith('- ') || line.startsWith('* ')) {
      return Padding(
        padding: const EdgeInsets.only(left: 16, top: 2, bottom: 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '• ',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: AppConstants.bodyFontSize,
                height: 1.6,
              ),
            ),
            Expanded(
              child: _buildInlineText(line.substring(2)),
            ),
          ],
        ),
      );
    }

    // 번호 목록 처리
    final numberedMatch = RegExp(r'^(\d+)\. (.*)').firstMatch(line);
    if (numberedMatch != null) {
      return Padding(
        padding: const EdgeInsets.only(left: 16, top: 2, bottom: 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${numberedMatch.group(1)}. ',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: AppConstants.bodyFontSize,
                height: 1.6,
              ),
            ),
            Expanded(
              child: _buildInlineText(numberedMatch.group(2)!),
            ),
          ],
        ),
      );
    }

    // 일반 텍스트
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: _buildInlineText(line),
    );
  }

  Widget _buildInlineText(String text) {
    final spans = <TextSpan>[];
    final regex = RegExp(r'\*\*(.*?)\*\*|\*(.*?)\*|~~(.*?)~~|`(.*?)`');
    int lastIndex = 0;

    for (final match in regex.allMatches(text)) {
      // 매치 이전 텍스트 추가
      if (match.start > lastIndex) {
        spans.add(TextSpan(
          text: text.substring(lastIndex, match.start),
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: AppConstants.bodyFontSize,
            height: 1.6,
          ),
        ));
      }

      // 서식 적용된 텍스트 추가
      if (match.group(1) != null) {
        // 굵은 텍스트
        spans.add(TextSpan(
          text: match.group(1),
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: AppConstants.bodyFontSize,
            fontWeight: FontWeight.bold,
            height: 1.6,
          ),
        ));
      } else if (match.group(2) != null) {
        // 기울임 텍스트
        spans.add(TextSpan(
          text: match.group(2),
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: AppConstants.bodyFontSize,
            fontStyle: FontStyle.italic,
            height: 1.6,
          ),
        ));
      } else if (match.group(3) != null) {
        // 취소선 텍스트
        spans.add(TextSpan(
          text: match.group(3),
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: AppConstants.bodyFontSize,
            decoration: TextDecoration.lineThrough,
            height: 1.6,
          ),
        ));
      } else if (match.group(4) != null) {
        // 코드 텍스트
        spans.add(TextSpan(
          text: match.group(4),
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: AppConstants.bodyFontSize,
            fontFamily: 'monospace',
            backgroundColor: AppColors.tabBackground,
            height: 1.6,
          ),
        ));
      }

      lastIndex = match.end;
    }

    // 마지막 텍스트 추가
    if (lastIndex < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastIndex),
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: AppConstants.bodyFontSize,
          height: 1.6,
        ),
      ));
    }

    return RichText(
      text: TextSpan(children: spans),
    );
  }
}