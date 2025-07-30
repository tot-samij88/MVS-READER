import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:provider/provider.dart';
import 'package:html/parser.dart' show parse;
import 'package:mvs_reader/providers/notes_provider.dart';

class ReaderScreen extends StatefulWidget {
  const ReaderScreen({super.key});

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

// ⬇️ Фабрика для рендерингу зображень із assets
class MyWidgetFactory extends WidgetFactory {
  @override
  String? get fileSchemeAsset => 'assets/Original_Dovidnik HTML Filter.files/';
}

class _ReaderScreenState extends State<ReaderScreen> {
  final PageController _pageController = PageController();
  List<String> _htmlPages = [];
  String _searchQuery = '';
  List<int> _searchMatches = [];
  int _currentMatchIndex = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHtml();
  }

  Future<void> _loadHtml() async {
    final htmlRaw = await rootBundle.loadString('assets/TEST_Filter.html');
    final document = parse(htmlRaw);
    final body = document.body?.innerHtml ?? '';

    // Пагінація по <p>
    final paragraphs = body.split(RegExp(r'<p[^>]*>'));
    const paragraphsPerPage = 20;
    List<String> pages = [];

    for (int i = 0; i < paragraphs.length; i += paragraphsPerPage) {
      final chunk = paragraphs.sublist(i, (i + paragraphsPerPage > paragraphs.length) ? paragraphs.length : i + paragraphsPerPage);
      pages.add(chunk.join('<p>'));
    }

    setState(() {
      _htmlPages = pages;
      _isLoading = false;
    });
  }

  void _onSearch(String query) {
    setState(() {
      _searchQuery = query;
      _searchMatches = [];
      _currentMatchIndex = 0;
    });

    for (int i = 0; i < _htmlPages.length; i++) {
      if (_htmlPages[i].toLowerCase().contains(query.toLowerCase())) {
        _searchMatches.add(i);
      }
    }

    if (_searchMatches.isNotEmpty) {
      _pageController.jumpToPage(_searchMatches[_currentMatchIndex]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final notesProvider = Provider.of<NotesProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('HTML Читалка'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Пошук...',
                      border: OutlineInputBorder(),
                      isDense: true,
                      contentPadding: EdgeInsets.all(8),
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : PageView.builder(
        controller: _pageController,
        itemCount: _htmlPages.length,
        itemBuilder: (_, index) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: HtmlWidget(
              _htmlPages[index],
              factoryBuilder: () => MyWidgetFactory(),
              textStyle: const TextStyle(fontSize: 16),
            ),
          );
        },
      ),
    );
  }
}
