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
                  textSpanDecorator: (_) => TextSpan(children: _codeTextSpans),
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

  // Widget _buildCodeBlock(BuildContext context, TextDirection textDirection) {
  //   return AppFlowyRichText(
  //     key: forwardKey,
  //     delegate: this,
  //     node: widget.node,
  //     editorState: editorState,
  //     placeholderText: placeholderText,
  //     lineHeight: 1.5,
  //     placeholderTextSpanDecorator: (textSpan) => textSpan,
  //     textSpanDecorator: (_) => TextSpan(children: codeTextSpans),
  //     textDirection: textDirection,
  //     cursorColor: editorState.editorStyle.cursorColor,
  //     selectionColor: editorState.editorStyle.selectionColor,
  //   );
  // }

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

final fontFamily = GoogleFonts.robotoMono();

// Material Deep Ocean Theme - inspired by Material Design and oceanic colors
final materialDeepOceanTheme = {
  'root': fontFamily.copyWith(
    backgroundColor: Color(0xff0f111a), // Deep ocean background
    color: Color(0xff8f93a2), // Muted text color
  ),
  'comment': fontFamily.copyWith(color: Color(0xff464b5d)), // Dark blue-grey for comments
  'quote': fontFamily.copyWith(color: Color(0xff464b5d)), // Same as comments
  'variable': fontFamily.copyWith(color: Color(0xff82aaff)), // Bright ocean blue for variables
  'template-variable': fontFamily.copyWith(color: Color(0xff82aaff)), // Same as variables
  'tag': fontFamily.copyWith(color: Color(0xfff78c6c)), // Coral orange for tags
  'regexp': fontFamily.copyWith(color: Color(0xffff5370)), // Ocean red for regex
  'meta': fontFamily.copyWith(color: Color(0xffff5370)), // Same as regexp
  'number': fontFamily.copyWith(color: Color(0xfff78c6c)), // Coral orange for numbers
  'built_in': fontFamily.copyWith(color: Color(0xff82aaff)), // Ocean blue for built-ins
  'builtin-name': fontFamily.copyWith(color: Color(0xff82aaff)), // Same as built_in
  'literal': fontFamily.copyWith(color: Color(0xffc3e88d)), // Sea green for literals
  'params': fontFamily.copyWith(color: Color(0xffeeffff)), // Light text for parameters
  'symbol': fontFamily.copyWith(color: Color(0xffc792ea)), // Purple for symbols
  'bullet': fontFamily.copyWith(color: Color(0xff89ddff)), // Light blue for bullets
  'link': fontFamily.copyWith(color: Color(0xff89ddff)), // Light blue for links
  'deletion': fontFamily.copyWith(color: Color(0xffff5370)), // Ocean red for deletions
  'section': fontFamily.copyWith(color: Color(0xff89ddff)), // Light blue for sections
  'title': fontFamily.copyWith(color: Color(0xff89ddff)), // Light blue for titles
  'name': fontFamily.copyWith(color: Color(0xff89ddff)), // Light blue for names
  'selector-id': fontFamily.copyWith(color: Color(0xfff78c6c)), // Coral for ID selectors
  'selector-class': fontFamily.copyWith(color: Color(0xffff5370)), // Ocean red for class selectors
  'type': fontFamily.copyWith(color: Color(0xffff5370)), // Ocean red for types
  'attribute': fontFamily.copyWith(color: Color(0xffc3e88d)), // Sea green for attributes
  'string': fontFamily.copyWith(color: Color(0xffc3e88d)), // Sea green for strings
  'keyword': fontFamily.copyWith(color: Color(0xffc792ea)), // Purple for keywords
  'selector-tag': fontFamily.copyWith(color: Color(0xff82aaff)), // Ocean blue for tag selectors
  'addition': fontFamily.copyWith(color: Color(0xffc3e88d)), // Sea green for additions
  'emphasis': fontFamily.copyWith(fontStyle: FontStyle.italic), // Italic for emphasis
  'strong': fontFamily.copyWith(fontWeight: FontWeight.bold), // Bold for strong
  'subst': fontFamily.copyWith(color: Color(0xffeeffff)), // Light text for substitutions
  'formula': fontFamily.copyWith(
    backgroundColor: Color(0xff1e2030), // Darker background for formulas
    color: Color(0xffeeffff),
    fontStyle: FontStyle.italic,
  ),
};
