import 'package:flutter/material.dart';
import '../models/note_model.dart';

class NotesProvider extends ChangeNotifier {
  final List<NoteModel> _notes = [];

  List<NoteModel> get notes => _notes;

  void addNote(String content) {
    if (_notes.any((note) => note.content == content)) return;
    _notes.add(NoteModel(content: content));
    notifyListeners();
  }

  bool isHighlighted(String text) {
    return _notes.any((note) => text.contains(note.content));
  }
}
