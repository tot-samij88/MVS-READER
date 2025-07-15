// import 'dart:convert';
// import 'dart:io';
//
// import 'package:flutter/material.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
//
// void main() {
//   runApp(const MyApp());
// }
//
// class MyApp extends StatelessWidget {
//   const MyApp({super.key});
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'MVS Reader',
//       theme: ThemeData(useMaterial3: true, brightness: Brightness.light),
//       darkTheme: ThemeData(brightness: Brightness.dark, useMaterial3: true),
//       home: const HomePage(),
//     );
//   }
// }
//
// class HomePage extends StatefulWidget {
//   const HomePage({super.key});
//   @override
//   State<HomePage> createState() => _HomePageState();
// }
//
// class _HomePageState extends State<HomePage> {
//   final PdfViewerController _pdfViewerController = PdfViewerController();
//   final TextEditingController _searchController = TextEditingController();
//   PdfTextSearchResult _searchResult = PdfTextSearchResult();
//
//   List<Map<String, dynamic>> _chapters = [
//     {'title': 'Вступ', 'page': 1},
//     {'title': 'Розділ 1: Основи', 'page': 5},
//     {'title': 'Розділ 2: Політика', 'page': 20},
//     {'title': 'Додатки', 'page': 100},
//   ];
//
//   List<String> _notes = [];
//
//   @override
//   void initState() {
//     super.initState();
//     _loadNotes();
//     _loadChapters();
//   }
//
//   Future<void> _loadChapters() async {
//     try {
//       final jsonString =
//       await DefaultAssetBundle.of(context).loadString('assets/chapters.json');
//       final List<dynamic> jsonData = json.decode(jsonString);
//       setState(() {
//         _chapters = jsonData.cast<Map<String, dynamic>>();
//       });
//     } catch (_) {
//       // Якщо немає файлу, використовуємо дефолт
//     }
//   }
//
//   Future<void> _loadNotes() async {
//     final file = await _getLocalFile();
//     if (await file.exists()) {
//       final content = await file.readAsString();
//       setState(() {
//         _notes = List<String>.from(json.decode(content));
//       });
//     }
//   }
//
//   Future<void> _saveNotes() async {
//     final file = await _getLocalFile();
//     await file.writeAsString(json.encode(_notes));
//   }
//
//   Future<File> _getLocalFile() async {
//     final directory = await getApplicationDocumentsDirectory();
//     return File('${directory.path}/notes.json');
//   }
//
//   void _addNote(String note) async {
//     setState(() {
//       _notes.add(note);
//     });
//     await _saveNotes();
//   }
//
//   void _showNotesDialog() {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Збережені нотатки'),
//         content: SizedBox(
//           width: double.maxFinite,
//           height: 300,
//           child: ListView.builder(
//             itemCount: _notes.length,
//             itemBuilder: (context, index) => ListTile(
//               leading: const Icon(Icons.note),
//               title: Text(_notes[index]),
//             ),
//           ),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('Закрити'),
//           ),
//         ],
//       ),
//     );
//   }
//
//   void _showChaptersDialog() {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Зміст'),
//         content: SizedBox(
//           width: double.maxFinite,
//           height: 300,
//           child: ListView.builder(
//             itemCount: _chapters.length,
//             itemBuilder: (context, index) => ListTile(
//               title: Text(_chapters[index]['title']),
//               onTap: () {
//                 Navigator.pop(context);
//                 _pdfViewerController.jumpToPage(_chapters[index]['page']);
//               },
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//   void _manualAddNoteDialog() {
//     showDialog(
//       context: context,
//       builder: (context) {
//         final controller = TextEditingController();
//         return AlertDialog(
//           title: const Text('Нотатка'),
//           content: TextField(
//             controller: controller,
//             decoration: const InputDecoration(hintText: 'Введіть текст'),
//             maxLines: 4,
//           ),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.pop(context),
//               child: const Text('Скасувати'),
//             ),
//             TextButton(
//               onPressed: () {
//                 if (controller.text.trim().isNotEmpty) {
//                   _addNote(controller.text.trim());
//                   Navigator.pop(context);
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     const SnackBar(content: Text('Нотатку збережено')),
//                   );
//                 }
//               },
//               child: const Text('Зберегти'),
//             ),
//           ],
//         );
//       },
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('MVS Reader'),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.search),
//             onPressed: () async {
//               final result = await _pdfViewerController.searchText(
//                 _searchController.text,
//               );
//               setState(() {
//                 _searchResult = result;
//               });
//             },
//           ),
//           IconButton(
//             icon: const Icon(Icons.clear),
//             onPressed: () {
//               _searchResult.clear();
//               _searchController.clear();
//             },
//           ),
//           IconButton(
//             icon: const Icon(Icons.notes),
//             onPressed: _showNotesDialog,
//           ),
//           IconButton(
//             icon: const Icon(Icons.menu_book),
//             onPressed: _showChaptersDialog,
//           ),
//           IconButton(
//             icon: const Icon(Icons.note_add),
//             onPressed: _manualAddNoteDialog,
//           ),
//         ],
//         bottom: PreferredSize(
//           preferredSize: const Size.fromHeight(48),
//           child: Padding(
//             padding: const EdgeInsets.all(8),
//             child: TextField(
//               controller: _searchController,
//               decoration: const InputDecoration(
//                 hintText: 'Пошук у PDF',
//                 filled: true,
//                 border: OutlineInputBorder(),
//               ),
//             ),
//           ),
//         ),
//       ),
//       body: SfPdfViewer.asset(
//         'assets/guide.pdf',
//         controller: _pdfViewerController,
//         // pageLayoutMode: PdfPageLayoutMode.twoColumn, // ❌ недоступно
//         canShowScrollHead: true,
//         canShowScrollStatus: true,
//         enableTextSelection: true,
//       ),
//     );
//   }
// }
