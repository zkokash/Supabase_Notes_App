import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://vqskavjmfqnsxtjubidi.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZxc2thdmptZnFuc3h0anViaWRpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDg1MjA0NDMsImV4cCI6MjA2NDA5NjQ0M30.fTWVqxQ1-qrQs26SKpHVYcyo8v32VmRthpbwaPkTUEE',
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Supabase Notes',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const NotesPage(),
    );
  }
}

class NotesPage extends StatefulWidget {
  const NotesPage({super.key});
  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
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

  Future<String?> uploadImage() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null && result.files.single.bytes != null) {
      final file = result.files.single;
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${p.basename(file.name)}';
      await supabase.storage
          .from('noteimages') // <- fixed bucket name
          .uploadBinary(
            fileName,
            file.bytes!,
            fileOptions: const FileOptions(upsert: true),
          );
      final publicUrl = supabase.storage
          .from('noteimages')
          .getPublicUrl(fileName);
      return publicUrl;
    }
    return null;
  }

  Future<void> addNote(String title, String content, String? imageUrl) async {
    await supabase.from('notes').insert({
      'title': title,
      'content': content,
      'image_url': imageUrl,
    });
    fetchNotes();
  }

  Future<void> updateNote(
    int id,
    String title,
    String content,
    String? imageUrl,
  ) async {
    await supabase
        .from('notes')
        .update({'title': title, 'content': content, 'image_url': imageUrl})
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
    String? existingImageUrl,
  }) {
    final titleController = TextEditingController(text: existingTitle ?? '');
    final contentController = TextEditingController(
      text: existingContent ?? '',
    );
    String? imageUrl = existingImageUrl;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(id == null ? 'Add Note' : 'Edit Note'),
        content: SingleChildScrollView(
          child: Column(
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
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: () async {
                  final url = await uploadImage();
                  if (url != null) {
                    setState(() {
                      imageUrl = url;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Image uploaded')),
                    );
                  }
                },
                icon: const Icon(Icons.image),
                label: const Text('Upload Image'),
              ),
              if (imageUrl != null)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Image.network(imageUrl!, height: 100),
                ),
            ],
          ),
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
                addNote(title, content, imageUrl);
              } else {
                updateNote(id, title, content, imageUrl);
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
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
                          existingImageUrl: note['image_url'],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => deleteNote(note['id']),
                      ),
                    ],
                  ),
                ),
                if (note['image_url'] != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10.0,
                      vertical: 5,
                    ),
                    child: Image.network(note['image_url'], height: 150),
                  ),
              ],
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
