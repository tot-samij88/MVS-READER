import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/notes_provider.dart';
import 'screens/reader_screen.dart';
import 'screens/notes_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => NotesProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EPUB Читалка',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const ReaderScreen(),
      routes: {
        '/notes': (_) => const NotesScreen(),
      },
    );
  }
}
