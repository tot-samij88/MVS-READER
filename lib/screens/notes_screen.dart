import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/notes_provider.dart';

class NotesScreen extends StatelessWidget {
  const NotesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final notesProvider = Provider.of<NotesProvider>(context);
    final notes = notesProvider.notes;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Нотатки'),
      ),
      body: notes.isEmpty
          ? const Center(child: Text('Немає збережених нотаток'))
          : ListView.builder(
        itemCount: notes.length,
        itemBuilder: (_, i) => Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: ListTile(
            title: Text(
              notes[i].content,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.redAccent),
              onPressed: () {
                notesProvider.removeNote(notes[i].content);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Нотатку видалено')),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
