import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:highlight/highlight.dart' as highlight;
import 'package:provider/provider.dart';

final programmingLanguages = [
  'text',
  'dart',
  'javascript',
  'typescript',
  'python',
  'java',
  'c',
  'c++',
  'csharp',
  'go',
  'kotlin',
  'swift',
  'ruby',
  'php',
  'rust',
  'scala',
  'shell',
  'sql',
  'html',
  'css',
  'json',
  'yaml',
  'markdown',
  'objectivec',
  'perl',
  'r',
  'lua',
  'powershell',
  'matlab',
  'groovy',
  'haskell',
  'elixir',
  'erlang',
  'clojure',
  'fsharp',
  'vbnet',
  'assembly',
];

class CodeBlockKeys {
  const CodeBlockKeys._();

  static const String type = 'code';

  static const String delta = 'delta';

  static const String language = 'language';
}

Node codeBlockNode({
  Delta? delta,
  String? language,
  Attributes? attributes,
  Iterable<Node>? children,
}) {
  attributes ??= {'delta': (delta ?? Delta()).toJson()};
  return Node(
    type: CodeBlockKeys.type,
    attributes: {
      ...attributes,
      CodeBlockKeys.delta: (delta ?? Delta()).toJson(),
    }..putIfAbsent(
        CodeBlockKeys.language,
        () => 'text',
      ),
    children: children ?? [],
  );
}

class CodeBlockComponentBuilder extends BlockComponentBuilder {
  CodeBlockComponentBuilder({
    super.configuration,
  });

  @override
  BlockComponentWidget build(BlockComponentContext blockComponentContext) {
    final node = blockComponentContext.node;
    return CodeBlockComponentWidget(
      key: node.key,
      node: node,
      configuration: configuration,
      showActions: showActions(node),
      actionBuilder: (context, state) => actionBuilder(
        blockComponentContext,
        state,
      ),
      actionTrailingBuilder: (context, state) => actionTrailingBuilder(
        blockComponentContext,
        state,
      ),
    );
  }

  @override
  BlockComponentValidate get validate => (node) => node.delta != null;
}

class CodeBlockComponentWidget extends BlockComponentStatefulWidget {
  const CodeBlockComponentWidget({
    super.key,
    required super.node,
    super.showActions,
    super.actionBuilder,
    super.actionTrailingBuilder,
    super.configuration = const BlockComponentConfiguration(),
  });

  @override
  State<CodeBlockComponentWidget> createState() => _CodeBlockComponentWidgetState();
}

class _CodeBlockComponentWidgetState extends State<CodeBlockComponentWidget>
    with
        SelectableMixin,
        DefaultSelectableMixin,
        BlockComponentConfigurable,
        BlockComponentBackgroundColorMixin,
        BlockComponentTextDirectionMixin,
        BlockComponentAlignMixin {
  @override
  final forwardKey = GlobalKey(debugLabel: 'inj_code_flowy_rich_text');

  @override
  GlobalKey<State<StatefulWidget>> get containerKey => widget.node.key;

  @override
  GlobalKey<State<StatefulWidget>> blockComponentKey = GlobalKey(
    debugLabel: CodeBlockKeys.type,
  );

  @override
  BlockComponentConfiguration get configuration => widget.configuration;

  @override
  Node get node => widget.node;

  @override
  late final editorState = Provider.of<EditorState>(context, listen: false);

  late Widget _switchWidget;
  bool hasCopied = false;

  @override
  void initState() {
    super.initState();
    _switchWidget = Icon(Icons.copy_rounded, key: UniqueKey());
  }

  String get programmingLanguageOfNode {
    final language = node.attributes[CodeBlockKeys.language];
    if (language is String && language.isNotEmpty) {
      return language;
    }
    return 'text';
  }

  @override
  Widget build(BuildContext context) {
    final textDirection = calculateTextDirection(
      layoutDirection: Directionality.maybeOf(context),
    );

    Widget child = ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Color(0xff0f111a), // Material Deep Ocean background
        ),
        alignment: alignment,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ColoredBox(
              color: Color(0xff1e2030), // Darker header background for Material Deep Ocean
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    editorState.editable
                        ? DropdownButton<String>(
                            value: programmingLanguageOfNode,
                            items: programmingLanguages.map((String language) {
                              return DropdownMenuItem<String>(
                                value: language,
                                child: Text(language.capitalize()),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              if (newValue != null && newValue != programmingLanguageOfNode) {
                                node.updateAttributes(node.attributes
                                  ..remove(CodeBlockKeys.language)
                                  ..putIfAbsent(CodeBlockKeys.language, () => newValue));
                                setState(() {});
                              }
                            },
                          )
                        : Text(
                            programmingLanguageOfNode.capitalize(),
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                    Spacer(),
                    InkWell(
                      onTap: () async {
                        if (hasCopied) return;
                        await Clipboard.setData(ClipboardData(text: node.delta?.toPlainText() ?? ''));
                        _switchWidget = Icon(Icons.check, key: UniqueKey());

                        if (mounted) setState(() {});
                        Future.delayed(Duration(seconds: 2), () {
                          hasCopied = false;
                          _switchWidget = Icon(Icons.copy_rounded, key: UniqueKey());
                          if (mounted) setState(() {});
                        });
                      },
                      child: AnimatedSwitcher(
                        duration: Duration(milliseconds: 200),
                        child: _switchWidget,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 12.0,
                vertical: 8.0,
              ),
              child: IntrinsicHeight(
                child: AppFlowyRichText(
                  key: forwardKey,
                  delegate: this,
                  node: widget.node,
                  editorState: editorState,
                  textAlign: alignment?.toTextAlign ?? textAlign,
                  placeholderText: placeholderText,
                  // textSpanDecorator: (textSpan) => textSpan,
                  textSpanDecorator: (textSpan) => TextSpan(
                    style: textSpan.style,
                    children: _codeTextSpans,
                  ),
                  placeholderTextSpanDecorator: (textSpan) =>
                      textSpan.updateTextStyle(placeholderTextStyleWithTextSpan(textSpan: textSpan)),
                  textDirection: textDirection,
                  cursorColor: editorState.editorStyle.cursorColor,
                  selectionColor: editorState.editorStyle.selectionColor,
                  cursorWidth: editorState.editorStyle.cursorWidth,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    child = Container(
      color: backgroundColor,
      child: Padding(
        key: blockComponentKey,
        padding: padding,
        child: child,
      ),
    );

    child = BlockSelectionContainer(
      node: node,
      delegate: this,
      listenable: editorState.selectionNotifier,
      remoteSelection: editorState.remoteSelections,
      blockColor: editorState.editorStyle.selectionColor,
      supportTypes: const [
        BlockSelectionType.block,
      ],
      child: child,
    );

    if (widget.showActions && widget.actionBuilder != null) {
      child = BlockComponentActionWrapper(
        node: node,
        actionBuilder: widget.actionBuilder!,
        actionTrailingBuilder: widget.actionTrailingBuilder,
        child: child,
      );
    }

    return child;
  }

  List<TextSpan> get _codeTextSpans {
    final delta = node.delta ?? Delta();
    final content = delta.toPlainText();

    final result = highlight.highlight.parse(
      content,
      language: programmingLanguageOfNode,
    );

    final codeNodes = result.nodes;
    if (codeNodes == null) {
      throw Exception('Code block parse error.');
    }

    final codeTextSpans = _convert(codeNodes);
    return codeTextSpans;
  }

  List<TextSpan> _convert(List<highlight.Node> nodes) {
    final List<TextSpan> spans = [];
    List<TextSpan> currentSpans = spans;
    final List<List<TextSpan>> stack = [];

    final cbTheme = materialDeepOceanTheme;

    void traverse(highlight.Node node) {
      if (node.value != null) {
        currentSpans.add(
          node.className == null
              ? TextSpan(text: node.value, style: fontFamily) // Use fontFamily for unstyled text
              : TextSpan(
                  text: node.value, style: cbTheme[node.className!] ?? fontFamily), // Fallback to fontFamily if class not found
        );
      } else if (node.children != null) {
        final List<TextSpan> tmp = [];
        currentSpans.add(
          TextSpan(children: tmp, style: cbTheme[node.className!]),
        );
        stack.add(currentSpans);
        currentSpans = tmp;

        for (final n in node.children!) {
          traverse(n);
          if (n == node.children!.last) {
            currentSpans = stack.isEmpty ? spans : stack.removeLast();
          }
        }
      }
    }

    for (final node in nodes) {
      traverse(node);
    }

    return spans;
  }
}

extension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}

final fontFamily = TextStyle(
  fontSize: 14.0,
  color: Color(0xffEEFFFF), // Light cyan instead of white for better ocean theme consistency
  height: 1.5,
);

// Material Deep Ocean Theme - inspired by Material Design and oceanic colors
final materialDeepOceanTheme = {
  // Base colors - soft oceanic tones
  'root': fontFamily.copyWith(color: Color(0xffEEFFFF)), // Very light cyan for default text

  // Comments and documentation
  'comment': fontFamily.copyWith(color: Color(0xff546E7A)), // Blue grey for comments
  'quote': fontFamily.copyWith(color: Color(0xff546E7A)), // Same as comments for consistency
  'doctag': fontFamily.copyWith(color: Color(0xff607D8B)), // Slightly lighter blue grey

  // Variables and identifiers
  'variable': fontFamily.copyWith(color: Color(0xff81D4FA)), // Light sky blue for variables
  'template-variable': fontFamily.copyWith(color: Color(0xff81D4FA)), // Same as variables
  'params': fontFamily.copyWith(color: Color(0xff81D4FA)), // Light blue for parameters
  'name': fontFamily.copyWith(color: Color(0xff4FC3F7)), // Slightly deeper blue for names

  // Keywords and language constructs
  'keyword': fontFamily.copyWith(color: Color(0xff7986CB)), // Indigo for keywords
  'built_in': fontFamily.copyWith(color: Color(0xff9575CD)), // Purple for built-ins
  'builtin-name': fontFamily.copyWith(color: Color(0xff9575CD)), // Same as built_in
  'type': fontFamily.copyWith(color: Color(0xffBA68C8)), // Light purple for types
  'meta': fontFamily.copyWith(color: Color(0xff7986CB)), // Indigo for meta
  'meta-keyword': fontFamily.copyWith(color: Color(0xff7986CB)), // Same as meta

  // Strings and literals
  'string': fontFamily.copyWith(color: Color(0xff66BB6A)), // Sea green for strings
  'literal': fontFamily.copyWith(color: Color(0xff81C784)), // Lighter green for literals
  'meta-string': fontFamily.copyWith(color: Color(0xff66BB6A)), // Same as strings
  'subst': fontFamily.copyWith(color: Color(0xff81C784)), // Light green for substitutions

  // Numbers and constants
  'number': fontFamily.copyWith(color: Color(0xffFFB74D)), // Warm orange for numbers
  'attr': fontFamily.copyWith(color: Color(0xffFFB74D)), // Same orange for attributes

  // Tags and selectors
  'tag': fontFamily.copyWith(color: Color(0xff42A5F5)), // Ocean blue for tags
  'selector-tag': fontFamily.copyWith(color: Color(0xff42A5F5)), // Same as tags
  'selector-id': fontFamily.copyWith(color: Color(0xff29B6F6)), // Lighter blue for IDs
  'selector-class': fontFamily.copyWith(color: Color(0xff29B6F6)), // Same as IDs
  'selector-attr': fontFamily.copyWith(color: Color(0xff26C6DA)), // Cyan for attribute selectors
  'selector-pseudo': fontFamily.copyWith(color: Color(0xff26C6DA)), // Same as attribute selectors

  // Functions and methods
  'function': fontFamily.copyWith(color: Color(0xff26A69A)), // Teal for functions
  'class': fontFamily.copyWith(color: Color(0xff4DB6AC)), // Lighter teal for classes

  // Special elements
  'title': fontFamily.copyWith(color: Color(0xff00BCD4)), // Dark cyan for titles
  'section': fontFamily.copyWith(color: Color(0xff00BCD4)), // Same as titles
  'attribute': fontFamily.copyWith(color: Color(0xffFFA726)), // Amber for attributes
  'template-tag': fontFamily.copyWith(color: Color(0xffFFA726)), // Same as attributes

  // Symbols and operators
  'symbol': fontFamily.copyWith(color: Color(0xffEC407A)), // Pink for symbols
  'bullet': fontFamily.copyWith(color: Color(0xffA1887F)), // Brown for bullets
  'link': fontFamily.copyWith(color: Color(0xff5DADE2)), // Light blue for links
  'link_label': fontFamily.copyWith(color: Color(0xff5DADE2)), // Same as links

  // Regular expressions and patterns
  'regexp': fontFamily.copyWith(color: Color(0xffEF5350)), // Coral red for regex

  // Diff colors
  'addition': fontFamily.copyWith(color: Color(0xff66BB6A)), // Green for additions
  'deletion': fontFamily.copyWith(color: Color(0xffEF5350)), // Red for deletions

  // Code blocks and formulas
  'code': fontFamily.copyWith(color: Color(0xffFFAB91)), // Light orange for inline code
  'formula': fontFamily.copyWith(
    backgroundColor: Color(0xff0E1621), // Darker background for formulas
    color: Color(0xffE0F7FA), // Very light cyan text
    fontStyle: FontStyle.italic,
  ),

  // Text formatting
  'emphasis': fontFamily.copyWith(fontStyle: FontStyle.italic), // Italic for emphasis
  'strong': fontFamily.copyWith(fontWeight: FontWeight.bold), // Bold for strong emphasis
};
