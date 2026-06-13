import 'package:flutter/material.dart';
import 'package:get/state_manager.dart';
import 'package:get/instance_manager.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/public_note.dart';
import '../services/sync_service.dart';
import '../services/auth_service.dart';
import '../utils/translations.dart';

class NotesScreen extends StatelessWidget {
  const NotesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('notes_menu'.tr(context)),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: GetBuilder<SyncService>(
        builder: (syncService) {
          final notes = syncService.notes..sort((a, b) => b.timestamp.compareTo(a.timestamp));
          
          if (notes.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.note_alt_outlined, size: 80, color: Colors.grey.withOpacity(0.3)),
                  const SizedBox(height: 16),
                  Text('no_notes'.tr(context), style: const TextStyle(color: Colors.grey, fontSize: 16)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: notes.length,
            itemBuilder: (context, index) {
              final note = notes[index];
              return _NoteCard(note: note);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showNoteDialog(context),
        backgroundColor: Theme.of(context).primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _showNoteDialog(BuildContext context, {PublicNote? note}) {
    final TextEditingController contentController = TextEditingController(text: note?.content);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(note == null ? 'add_note_title'.tr(context) : 'edit_note_title'.tr(context)),
        content: TextField(
          controller: contentController,
          maxLines: 5,
          decoration: InputDecoration(
            hintText: 'note_content_hint'.tr(context),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('cancel'.tr(context))),
          ElevatedButton(
            onPressed: () async {
              final content = contentController.text.trim();
              if (content.isEmpty) return;

              final auth = context.read<AuthService>();
              final sync = Get.find<SyncService>();

              if (note == null) {
                // ADD
                final newNote = PublicNote(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  content: content,
                  author: auth.currentUser?.fullName ?? 'Unknown',
                  timestamp: DateTime.now().toIso8601String(),
                  updatedAt: DateTime.now().toIso8601String(),
                );
                await sync.addNote(newNote);
              } else {
                // UPDATE
                final updated = PublicNote(
                  id: note.id,
                  content: content,
                  author: note.author,
                  timestamp: note.timestamp,
                  version: note.version + 1,
                  updatedAt: DateTime.now().toIso8601String(),
                );
                await sync.updateNote(updated);
              }
              Navigator.pop(ctx);
            },
            child: Text('save'.tr(context)),
          ),
        ],
      ),
    );
  }
}

class _NoteCard extends StatelessWidget {
  final PublicNote note;
  const _NoteCard({required this.note});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final isAuthor = auth.currentUser?.fullName == note.author;
    final date = DateTime.tryParse(note.timestamp) ?? DateTime.now();
    final formattedDate = DateFormat('yyyy/MM/dd HH:mm').format(date);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                  child: Text(note.author.substring(0, 1).toUpperCase(),
                      style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(note.author, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(formattedDate, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ),
                if (isAuthor) ...[
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 20, color: Colors.blue),
                    onPressed: () => _editNote(context, note),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                    onPressed: () => _confirmDelete(context, note),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            Text(note.content, style: const TextStyle(fontSize: 15, height: 1.4)),
          ],
        ),
      ),
    );
  }

  void _editNote(BuildContext context, PublicNote note) {
    // Show same dialog but for edit
    (context.findAncestorWidgetOfExactType<NotesScreen>() as NotesScreen?)?._showNoteDialog(context, note: note);
  }

  void _confirmDelete(BuildContext context, PublicNote note) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('confirm_delete'.tr(context)),
        content: Text('Cette action est irréversible.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('cancel'.tr(context))),
          TextButton(
            onPressed: () async {
              await Get.find<SyncService>().deleteNote(note.id);
              Navigator.pop(ctx);
            },
            child: Text('delete'.tr(context), style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
