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
          node.className == null ? TextSpan(text: node.value) : TextSpan(text: node.value, style: cbTheme[node.className!]),
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
  color: Colors.white,
  height: 1.5,
);

// Material Deep Ocean Theme - inspired by Material Design and oceanic colors
final materialDeepOceanTheme = {
  'root': fontFamily.copyWith(
    backgroundColor: Color(0xff222222),
    color: Color(0xff545454),
  ),
  'comment': fontFamily.copyWith(color: Color(0xff607D8B)), // Greyish/blue shade for comments
  'quote': fontFamily.copyWith(color: Color(0xff607D8B)), // Same as comments for consistency
  'variable': fontFamily.copyWith(color: Color(0xffB2CCD6)), // Lighter blue for variables
  'template-variable': fontFamily.copyWith(color: Color(0xffB2CCD6)), // Same as variables
  'tag': fontFamily.copyWith(color: Color(0xff7C4DFF)), // Deep purple for tags
  'regexp': fontFamily.copyWith(color: Color(0xffE53935)), // Red for regular expressions
  'meta': fontFamily.copyWith(color: Color(0xffE53935)), // Red for meta tags, similar to regexp for attention
  'number': fontFamily.copyWith(color: Color(0xffF76D47)), // Orange for numbers
  'built_in': fontFamily.copyWith(color: Color(0xff82B1FF)), // Soft blue for built-in functions
  'builtin-name': fontFamily.copyWith(color: Color(0xff82B1FF)), // Same as built_in
  'literal': fontFamily.copyWith(color: Color(0xffDECB6B)), // Yellow for literals
  'params': fontFamily.copyWith(color: Color(0xffB2CCD6)), // Light blue for parameters, less emphasis
  'symbol': fontFamily.copyWith(color: Color(0xffE91E63)), // Pink for symbols
  'bullet': fontFamily.copyWith(color: Color(0xff8D6E63)), // Brownish for bullets
  'link': fontFamily.copyWith(color: Color(0xff039BE5)), // Bright blue for links
  'deletion': fontFamily.copyWith(color: Color(0xffE53935)), // Red for deletions, indicating removal or danger
  'section': fontFamily.copyWith(color: Color(0xff00BFA5)), // Teal for sections
  'title': fontFamily.copyWith(color: Color(0xff00BFA5)), // Teal for titles, matching sections for consistency
  'name': fontFamily.copyWith(color: Color(0xff00BFA5)), // Teal for names, consistent with titles/sections
  'selector-id': fontFamily.copyWith(color: Color(0xff7C4DFF)), // Deep purple, same as tags for ID selectors
  'selector-class': fontFamily.copyWith(color: Color(0xff7C4DFF)), // Deep purple for class selectors, matching tags
  'type': fontFamily.copyWith(color: Color(0xff82B1FF)), // Soft blue for types, readability
  'attribute': fontFamily.copyWith(color: Color(0xffFFC107)), // Amber for attributes, standout
  'string': fontFamily.copyWith(color: Color(0xffC3E88D)), // Light green for strings
  'keyword': fontFamily.copyWith(color: Color(0xffC792EA)), // Light purple for keywords
  'selector-tag': fontFamily.copyWith(color: Color(0xff7C4DFF)), // Deep purple, consistency with tag selectors
  'addition': fontFamily.copyWith(color: Color(0xffC3E88D)), // Light green, for additions, positive action
  'emphasis': fontFamily.copyWith(fontStyle: FontStyle.italic), // Italic for emphasis
  'strong': fontFamily.copyWith(fontWeight: FontWeight.bold), // Bold for strong emphasis
};
