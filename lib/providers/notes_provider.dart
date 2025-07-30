import 'package:flutter/material.dart';

class Note {
  final String content;
  Note({required this.content});
}

class NotesProvider with ChangeNotifier {
  final List<Note> _notes = [];

  List<Note> get notes => _notes;

  void addNote(String content) {
    _notes.add(Note(content: content));
    notifyListeners();
  }

  void removeNote(String content) {
    _notes.removeWhere((note) => note.content == content);
    notifyListeners();
  }

  bool isHighlighted(String word) {
    return _notes.any((n) => n.content.contains(word));
  }
}
