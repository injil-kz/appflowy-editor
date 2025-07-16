import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
          color: Color(0xff222222),
        ),
        alignment: alignment,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ColoredBox(
              color: Color(0xff545454),
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

    final cbTheme = darkThemeInCodeBlock;

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

const darkThemeInCodeBlock = {
  'root': TextStyle(
    backgroundColor: Color(0xff000000),
    color: Color(0xfff8f8f8),
  ),
  'comment': TextStyle(
    color: Color(0xffaeaeae),
    fontStyle: FontStyle.italic,
  ),
  'quote': TextStyle(
    color: Color(0xffaeaeae),
    fontStyle: FontStyle.italic,
  ),
  'keyword': TextStyle(color: Color(0xffe28964)),
  'selector-tag': TextStyle(color: Color(0xffe28964)),
  'type': TextStyle(color: Color(0xffe28964)),
  'string': TextStyle(color: Color(0xff65b042)),
  'subst': TextStyle(color: Color(0xffdaefa3)),
  'regexp': TextStyle(color: Color(0xffe9c062)),
  'link': TextStyle(color: Color(0xffe9c062)),
  'title': TextStyle(color: Color(0xff89bdff)),
  'section': TextStyle(color: Color(0xff89bdff)),
  'tag': TextStyle(color: Color(0xff89bdff)),
  'name': TextStyle(color: Color(0xff89bdff)),
  'symbol': TextStyle(color: Color(0xff3387cc)),
  'bullet': TextStyle(color: Color(0xff3387cc)),
  'number': TextStyle(color: Color(0xff3387cc)),
  'params': TextStyle(color: Color(0xff3e87e3)),
  'variable': TextStyle(color: Color(0xff3e87e3)),
  'template-variable': TextStyle(color: Color(0xff3e87e3)),
  'attribute': TextStyle(color: Color(0xffcda869)),
  'meta': TextStyle(color: Color(0xff8996a8)),
  'formula': TextStyle(
    backgroundColor: Color(0xff0e2231),
    color: Color(0xfff8f8f8),
    fontStyle: FontStyle.italic,
  ),
  'addition': TextStyle(
    backgroundColor: Color(0xff253b22),
    color: Color(0xfff8f8f8),
  ),
  'deletion': TextStyle(
    backgroundColor: Color(0xff420e09),
    color: Color(0xfff8f8f8),
  ),
  'selector-class': TextStyle(color: Color(0xff9b703f)),
  'selector-id': TextStyle(color: Color(0xff8b98ab)),
  'emphasis': TextStyle(fontStyle: FontStyle.italic),
  'strong': TextStyle(fontWeight: FontWeight.bold),
};
