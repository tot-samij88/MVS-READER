import 'dart:convert';
import 'package:flutter/material.dart' hide Element;
import 'package:flutter/services.dart';
import 'package:html/dom.dart' hide Text ;
import 'package:provider/provider.dart';
import '../providers/notes_provider.dart';
import 'package:flutter_html/flutter_html.dart';

class ReaderScreen extends StatefulWidget {
  const ReaderScreen({super.key});

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  late NotesProvider notesProvider;
  final PageController _pageController = PageController();
  List<Html> _pages = [];
  List<Map<String, dynamic>> _chapters = [];
  bool _isLoading = true;

  String _searchQuery = '';
  List<int> _searchMatches = [];
  int _currentMatchIndex = 0;
  String _selectedText = '';

  @override
  void initState() {
    super.initState();
    _loadBook();
    _loadChapters();
  }

  Future<void> _loadBook() async {
    final document = HtmlParser.parseHTML(await rootBundle.loadString('assets/Оригінал/Original_Dovidnik_filtered.html'));
    final header = document.nodes.first.nodes.where((node) => node.nodeType == Node.ELEMENT_NODE).join('');
    var body = document.nodes.last;

    List<Html> pages = [];

    void processNode(String data) {
        pages.add(
            Html(
                data: data.replaceAll('(?:\n(?:\r|\n)?){1,2}', ' '),
                style: Style.fromCss(header, null),
                extensions: [
                  ImageExtension(),
                  TagExtension(
                      tagsToExtend: {"img"},
                      builder: (ctx) {
                        return Image.asset(
                          "assets/Оригінал/${ctx.attributes['src'] ?? ''}",
                          fit: BoxFit.fitWidth,
                        );
                      }
                  ),
                  TagExtension(
                    tagsToExtend: {"span"},
                    builder: (ctx) {
                      // Keep your existing span handling code
                      if (_searchQuery.isNotEmpty) {
                        final content = ctx.element!.innerHtml;
                        final children = content.replaceAll('(?:\n(?:\r|\n)?){1,2}', ' ').splitMapJoin(
                          RegExp(_searchQuery, multiLine: true, dotAll: true, caseSensitive: false),
                          onMatch: (match) => '<mark>${match[0]}</mark>',
                          onNonMatch: (nonMatch) => nonMatch,
                        );
                        if (children.contains('<mark>')) {
                          final originalStyle = ctx.element!.attributes['style'] ?? '';

                          return Html(
                            data: '<span style="$originalStyle">$children</span>',
                            style: {
                              "span": ctx.styledElement!.style,
                              "mark": Style(
                                backgroundColor: Colors.lightBlueAccent,
                              ),
                            },
                          );
                        }
                      }

                      return Html(
                        data: ctx.element!.outerHtml,
                        style: {
                          "span": ctx.styledElement!.style,
                        },
                      );
                    },
                  )
                ]
            )
        );

    }

    for (var node in body.nodes) {
      if (node.nodeType == Node.ELEMENT_NODE && node is Element && node.localName == 'div' && node.nodes.isNotEmpty) {
        if (node.nodes.any((n) => n.nodeType == Node.ELEMENT_NODE && n is Element && n.localName == 'div' && n.nodes.isNotEmpty)) {
          String data = '';
          for (var child in node.nodes.whereType<Element>().where((e) => e.text.trim().replaceAll('(?:\n(?:\r|\n)?){1,2}', ' ').isNotEmpty)) {
            data += child.innerHtml;
          }
          if (data.isNotEmpty) {
            processNode(data);
          }
        } else {
          processNode(node.innerHtml);
        }
      }
    }

    setState(() {
      _pages = pages;
      _isLoading = false;
    });
  }
  Future<void> _loadChapters() async {
    final jsonStr = await rootBundle.loadString('assets/chapters.json');
    final data = json.decode(jsonStr);
    setState(() {
      _chapters = List<Map<String, dynamic>>.from(data['chapters']);
    });
  }

  void _onSearch(String query) {
    setState(() {
      _searchQuery = query.toLowerCase().split(' ').join('.*');
      _searchMatches = [];
      _currentMatchIndex = 0;

      for (int i = 0; i < _pages.length; i++) {
        if (RegExp(_searchQuery, multiLine: true, dotAll: true, caseSensitive: false).hasMatch(_pages[i].data!.toLowerCase().replaceAll('(?:\n(?:\r|\n)?){1,2}', ' '))) {
          _searchMatches.add(i);
        }
      }
    });

    if (_searchMatches.isNotEmpty) {
      _pageController.jumpToPage(_searchMatches[_currentMatchIndex]);
    }
  }

  void _highlightAndSave(String text, NotesProvider provider) {
    provider.addNote(text);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Текст додано до нотаток")),
    );
  }

  void _gotoChapter(int page) {
    _pageController.jumpToPage(page);
    Navigator.pop(context);
  }

  final staticAnchorKey = GlobalKey();
  @override
  Widget build(BuildContext context) {
    notesProvider = Provider.of<NotesProvider>(context);
    return SelectionArea(
        onSelectionChanged: (selected) {
          setState(() {
            _selectedText = selected?.plainText ?? '';
          });
        },
        child: Scaffold(
          appBar: AppBar(
            title: const Text('EPUB Читалка'),
            actions: [
              IconButton(
                icon: const Icon(Icons.notes),
                onPressed: () => Navigator.pushNamed(context, '/notes'),
              )
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(60),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(
                          hintText: 'Пошук...',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(),
                        ),
                        onSubmitted: _onSearch,
                      ),
                    ),
                    if (_searchMatches.isNotEmpty) ...[
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () {
                          setState(() {
                            _currentMatchIndex =
                                (_currentMatchIndex - 1 +
                                    _searchMatches.length) %
                                    _searchMatches.length;
                          });
                          _pageController.jumpToPage(
                              _searchMatches[_currentMatchIndex]);
                        },
                      ),
                      Text(
                          '${_currentMatchIndex + 1}/${_searchMatches.length}'),
                      IconButton(
                        icon: const Icon(Icons.arrow_forward),
                        onPressed: () {
                          setState(() {
                            _currentMatchIndex =
                                (_currentMatchIndex + 1) %
                                    _searchMatches.length;
                          });
                          _pageController.jumpToPage(
                              _searchMatches[_currentMatchIndex]);
                        },
                      ),
                    ]
                  ],
                ),
              ),
            ),
          ),
          drawer: Drawer(
            child: ListView(
              padding: EdgeInsets.zero,
              children: _chapters.map((chapter) {
                return ListTile(
                  title: Text(chapter['title'] ?? ''),
                  onTap: () => _gotoChapter(chapter['page']),
                );
              }).toList(),
            ),
          ),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : PageView.builder(
              controller: _pageController,
              itemCount: _pages.length,
              itemBuilder: (_, index) {
                final pageContent = _pages[index];
                return Padding(
                    padding: const EdgeInsets.all(1),
                    child: SingleChildScrollView(
                        child: pageContent
                    )
                );
              }
          ),
          floatingActionButton: _selectedText.isNotEmpty
              ? FloatingActionButton.extended(
            label: const Text("Додати до нотаток"),
            icon: const Icon(Icons.save),
            onPressed: () {
              _highlightAndSave(_selectedText, notesProvider);
              setState(() {
                _selectedText = '';
              });
            },
          )
              : null,
        )
    );
  }
}
