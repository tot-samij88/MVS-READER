import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/notes_provider.dart';

class NotesScreen extends StatelessWidget {
  const NotesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final notes = Provider.of<NotesProvider>(context).notes;

    return Scaffold(
      appBar: AppBar(title: const Text('Нотатки')),
      body: ListView.builder(
        itemCount: notes.length,
        itemBuilder: (_, i) => ListTile(
          title: Text(notes[i].content),
        ),
      ),
    );
  }
}
