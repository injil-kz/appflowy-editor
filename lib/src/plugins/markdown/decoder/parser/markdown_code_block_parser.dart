import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:markdown/markdown.dart' as md;

class MarkdownCodeBlockParserV2 extends CustomMarkdownParser {
  const MarkdownCodeBlockParserV2();

  @override
  List<Node> transform(
    md.Node element,
    List<CustomMarkdownParser> parsers, {
    MarkdownListType listType = MarkdownListType.unknown,
    int? startNumber,
  }) {
    if (element is! md.Element) {
      return [];
    }

    // Parse <pre><code> structure for code blocks
    if (element.tag != 'pre') {
      return [];
    }

    final children = element.children;
    if (children == null || children.isEmpty) {
      return [];
    }

    final codeElement = children.first;
    if (codeElement is! md.Element || codeElement.tag != 'code') {
      return [];
    }

    // Extract language from class attribute (e.g., "language-dart")
    String? language;
    if (codeElement.attributes.containsKey('class')) {
      final classes = codeElement.attributes['class']!.split(' ');
      final languageClass = classes.firstWhere(
        (c) => c.startsWith('language-'),
        orElse: () => '',
      );
      if (languageClass.isNotEmpty) {
        language = languageClass.substring('language-'.length);
      }
    }

    // Extract the code content
    final codeContent = codeElement.textContent.trimRight();

    return [
      codeBlockNode(
        language: language,
        delta: Delta()..insert(codeContent),
      ),
    ];
  }
}
