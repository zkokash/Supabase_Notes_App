import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://gcyoefcxqbgbknjntdzg.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdjeW9lZmN4cWJnYmtuam50ZHpnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjA3ODc3NjgsImV4cCI6MjA3NjM2Mzc2OH0.4ZF-RFY7SOfnMHvo2enmQD8VcqwUsRCn2db448lSLsM',
  );
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: MyHomePage());
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final supabase = Supabase.instance.client;
  List<dynamic> notes = [];

  @override
  void initState() {
    super.initState();
    fetchNotes();
  }

  Future<void> fetchNotes() async {
    final response = await supabase
        .from('notes')
        .select()
        .order('id', ascending: false);
    setState(() {
      notes = response;
    });
  }

  Future<void> addNote(String title, String content) async {
    await supabase.from('notes').insert({'title': title, 'content': content});
    fetchNotes();
  }

  Future<void> updateNote(int id, String title, String content) async {
    await supabase
        .from('notes')
        .update({'title': title, 'content': content})
        .eq('id', id);
    fetchNotes();
  }

  Future<void> deleteNote(int id) async {
    await supabase.from('notes').delete().eq('id', id);
    fetchNotes();
  }

  void showNoteDialog({
    int? id,
    String? existingTitle,
    String? existingContent,
  }) {
    final titleController = TextEditingController(text: existingTitle ?? '');
    final contentController = TextEditingController(
      text: existingContent ?? '',
    );
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(id == null ? 'Add Note' : 'Edit Note'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            TextField(
              controller: contentController,
              decoration: const InputDecoration(labelText: 'Content'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final title = titleController.text.trim();
              final content = contentController.text.trim();
              if (id == null) {
                addNote(title, content);
              } else {
                updateNote(id, title, content);
              }
              Navigator.pop(context);
            },
            child: Text(id == null ? 'Add' : 'Update'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Supabase Notes')),
      body: ListView.builder(
        itemCount: notes.length,
        itemBuilder: (_, index) {
          final note = notes[index];
          return Card(
            child: ListTile(
              title: Text(note['title']),
              subtitle: Text(note['content']),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => showNoteDialog(
                      id: note['id'],
                      existingTitle: note['title'],
                      existingContent: note['content'],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => deleteNote(note['id']),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showNoteDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
