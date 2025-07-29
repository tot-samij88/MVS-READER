import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:epubx/epubx.dart';
import 'package:provider/provider.dart';
import 'package:html/parser.dart' show parse;
import '../providers/notes_provider.dart';

class ReaderScreen extends StatefulWidget {
  const ReaderScreen({super.key});

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  final PageController _pageController = PageController();
  List<String> _pages = [];
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
    final bytes = await rootBundle.load('assets/TEST.html');
    final book = await EpubReader.readBook(bytes.buffer.asUint8List());

    final textBuffer = StringBuffer();

    final htmlFiles = book.Content?.Html;
    if (htmlFiles != null && htmlFiles.isNotEmpty) {
      for (var htmlFile in htmlFiles.values) {
        final htmlContent = htmlFile.Content;
        final document = parse(htmlContent);
        final text = document.body?.text.trim() ?? '';
        textBuffer.writeln(text);
      }
    }

    final allText = textBuffer.toString();
    final lines = const LineSplitter().convert(allText);
    const linesPerPage = 30;
    List<String> pages = [];
    for (int i = 0; i < lines.length; i += linesPerPage) {
      pages.add(
        lines
            .sublist(i, (i + linesPerPage > lines.length) ? lines.length : i + linesPerPage)
            .join('\n'),
      );
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
      _searchQuery = query;
      _searchMatches = [];
      _currentMatchIndex = 0;

      for (int i = 0; i < _pages.length; i++) {
        if (_pages[i].toLowerCase().contains(query.toLowerCase())) {
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

  @override
  Widget build(BuildContext context) {
    final notesProvider = Provider.of<NotesProvider>(context);

    return Scaffold(
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
                    decoration: InputDecoration(
                      hintText: 'Пошук...',
                      prefixIcon: const Icon(Icons.search),
                      border: const OutlineInputBorder(),
                    ),
                    onSubmitted: _onSearch,
                  ),
                ),
                if (_searchMatches.isNotEmpty) ...[
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () {
                      setState(() {
                        _currentMatchIndex = (_currentMatchIndex - 1 + _searchMatches.length) % _searchMatches.length;
                      });
                      _pageController.jumpToPage(_searchMatches[_currentMatchIndex]);
                    },
                  ),
                  Text('${_currentMatchIndex + 1}/${_searchMatches.length}'),
                  IconButton(
                    icon: const Icon(Icons.arrow_forward),
                    onPressed: () {
                      setState(() {
                        _currentMatchIndex = (_currentMatchIndex + 1) % _searchMatches.length;
                      });
                      _pageController.jumpToPage(_searchMatches[_currentMatchIndex]);
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
          final pageText = _pages[index];
          final isMatch = _searchQuery.isNotEmpty && pageText.toLowerCase().contains(_searchQuery.toLowerCase());

          return Padding(
            padding: const EdgeInsets.all(16),
            child: GestureDetector(
              onLongPressStart: (details) {},
              child: SelectableText.rich(
                TextSpan(
                  children: [
                    for (final word in pageText.split(' '))
                      TextSpan(
                        text: '$word ',
                        style: TextStyle(
                          backgroundColor: notesProvider.isHighlighted(word)
                              ? Colors.yellow
                              : (isMatch && word.toLowerCase().contains(_searchQuery.toLowerCase())
                              ? Colors.lightBlueAccent
                              : null),
                        ),
                      ),
                  ],
                ),
                onSelectionChanged: (selection, cause) {
                  final safeStart = selection.start.clamp(0, pageText.length);
                  final safeEnd = selection.end.clamp(0, pageText.length);
                  final safeRange = TextRange(start: safeStart, end: safeEnd);
                  final selected = safeRange.textInside(pageText).trim();
                  setState(() {
                    _selectedText = selected;
                  });
                },
              ),
            ),
          );
        },
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
    );
  }
}
