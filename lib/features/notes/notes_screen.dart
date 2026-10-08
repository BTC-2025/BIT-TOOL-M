import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/app_models.dart';
import '../../core/providers/app_providers.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  String _selectedFilter = 'All Apps';

  final List<String> _filterTabs = [
    'All Apps',
    'Archived',
    'Cliks',
    'BNX Mail',
    'Cliks Business',
    'Bit Tool',
  ];

  final List<Map<String, dynamic>> _pastelColors = [
    {'name': 'Mint', 'hex': '#A7F3D0', 'color': const Color(0xFFA7F3D0)},
    {'name': 'Yellow', 'hex': '#FDE047', 'color': const Color(0xFFFDE047)},
    {'name': 'Ice Blue', 'hex': '#BAE6FD', 'color': const Color(0xFFBAE6FD)},
    {'name': 'Pink', 'hex': '#FBCFE8', 'color': const Color(0xFFFBCFE8)},
    {'name': 'Lavender', 'hex': '#DDD6FE', 'color': const Color(0xFFDDD6FE)},
    {'name': 'Peach', 'hex': '#FED7AA', 'color': const Color(0xFFFED7AA)},
  ];

  Color _parseColor(String hex) {
    try {
      final clean = hex.replaceAll('#', '');
      if (clean.length == 6) {
        return Color(int.parse('FF$clean', radix: 16));
      }
    } catch (_) {}
    return const Color(0xFFA7F3D0);
  }

  void _showNoteDialog({NoteItem? note}) {
    final titleController = TextEditingController(text: note?.title ?? '');
    final contentController = TextEditingController(text: note?.content ?? '');
    String category = note?.category ?? 'Bit Tool';
    String colorHex = note?.colorHex ?? '#A7F3D0';
    bool isPinned = note?.isPinned ?? false;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Text(
                note == null ? 'Create New Note' : 'Edit Note',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Color(0xFF0F172A),
                ),
              ),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 440,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: titleController,
                        decoration: InputDecoration(
                          hintText: 'Note Title...',
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: ['Cliks', 'BNX Mail', 'Cliks Business', 'Bit Tool', 'General', 'Work', 'Ideas', 'Personal']
                                      .contains(category)
                                  ? category
                                  : 'Bit Tool',
                              decoration: InputDecoration(
                                labelText: 'Application / Category',
                                filled: true,
                                fillColor: const Color(0xFFF8FAFC),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                                ),
                              ),
                              items: ['Cliks', 'BNX Mail', 'Cliks Business', 'Bit Tool', 'General', 'Work', 'Ideas', 'Personal'].map((cat) {
                                return DropdownMenuItem(value: cat, child: Text(cat));
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setDialogState(() => category = val);
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          IconButton(
                            icon: Icon(
                              isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                              color: isPinned ? const Color(0xFF2563EB) : const Color(0xFF94A3B8),
                            ),
                            onPressed: () {
                              setDialogState(() => isPinned = !isPinned);
                            },
                            tooltip: 'Pin Note',
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: contentController,
                        maxLines: 5,
                        decoration: InputDecoration(
                          hintText: 'Take a note...',
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Select Card Color:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: _pastelColors.map((c) {
                          final isSelected = colorHex == c['hex'];
                          return GestureDetector(
                            onTap: () {
                              setDialogState(() => colorHex = c['hex']);
                            },
                            child: Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: c['color'] as Color,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFF0F172A)
                                      : Colors.transparent,
                                  width: 2.5,
                                ),
                              ),
                              child: isSelected
                                  ? const Icon(Icons.check, size: 18, color: Color(0xFF0F172A))
                                  : null,
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    final title = titleController.text.trim();
                    final content = contentController.text.trim();
                    if (title.isEmpty && content.isEmpty) return;

                    final provider = context.read<NotesProvider>();
                    if (note == null) {
                      provider.addNote(
                        title: title.isEmpty ? 'Untitled' : title,
                        content: content,
                        category: category,
                        colorHex: colorHex,
                        isPinned: isPinned,
                      );
                    } else {
                      provider.updateNote(
                        note.id,
                        title: title.isEmpty ? 'Untitled' : title,
                        content: content,
                        category: category,
                        colorHex: colorHex,
                        isPinned: isPinned,
                      );
                    }
                    Navigator.pop(ctx);
                  },
                  child: Text(note == null ? 'Create' : 'Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showColorPickerSheet(NoteItem note) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Change Note Color',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: _pastelColors.map((c) {
                  return GestureDetector(
                    onTap: () {
                      context.read<NotesProvider>().updateNote(
                            note.id,
                            colorHex: c['hex'] as String,
                          );
                      Navigator.pop(ctx);
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: c['color'] as Color,
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final notesProvider = Provider.of<NotesProvider>(context);
    final allNotes = notesProvider.notes;

    // Filter notes based on selected tab
    final filteredNotes = allNotes.where((n) {
      if (_selectedFilter == 'All Apps') return true;
      if (_selectedFilter == 'Archived') return false; // simple mock for archived
      return n.category.toLowerCase() == _selectedFilter.toLowerCase();
    }).toList();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 12),

          // ─── Top Floating Search / Create Note Input Pill ─────────────────────
          Center(
            child: InkWell(
              onTap: () => _showNoteDialog(),
              borderRadius: BorderRadius.circular(24),
              child: Container(
                width: 480,
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.add_rounded,
                      color: Color(0xFF64748B),
                      size: 20,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Create a new note...',
                        style: TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.check_box_outlined,
                      color: Color(0xFF64748B),
                      size: 20,
                    ),
                    SizedBox(width: 14),
                    Icon(
                      Icons.image_outlined,
                      color: Color(0xFF64748B),
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 28),

          // ─── Filter Tabs Row ──────────────────────────────────────────────────
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _filterTabs.map((tab) {
                final isSelected = _selectedFilter == tab;
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: InkWell(
                    onTap: () => setState(() => _selectedFilter = tab),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF0F172A)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF0F172A)
                              : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Text(
                        tab,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.w500,
                          color: isSelected
                              ? Colors.white
                              : const Color(0xFF475569),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 28),

          // ─── Notes Grid / Cards Row ───────────────────────────────────────────
          if (filteredNotes.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Text(
                  'No notes in $_selectedFilter. Tap "Create a new note" above!',
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 14,
                  ),
                ),
              ),
            )
          else
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: filteredNotes.map((note) {
                return _buildNoteCard(note);
              }).toList(),
            ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildNoteCard(NoteItem note) {
    final bgColor = _parseColor(note.colorHex);

    return InkWell(
      onTap: () => _showNoteDialog(note: note),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 250,
        constraints: const BoxConstraints(minHeight: 170),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: App Source Badge + Pin Icon
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        note.category.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        context.read<NotesProvider>().togglePin(note.id);
                      },
                      child: Icon(
                        note.isPinned
                            ? Icons.push_pin
                            : Icons.push_pin_outlined,
                        size: 18,
                        color: const Color(0xFF475569),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Title
                Text(
                  note.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),

                // Content
                Text(
                  note.content,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF334155),
                    height: 1.3,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Bottom Actions Row: Palette, Archive, Trash
            Row(
              children: [
                InkWell(
                  onTap: () => _showColorPickerSheet(note),
                  child: const Icon(
                    Icons.palette_outlined,
                    size: 18,
                    color: Color(0xFF475569),
                  ),
                ),
                const SizedBox(width: 14),
                InkWell(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Note "${note.title}" archived'),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                  child: const Icon(
                    Icons.archive_outlined,
                    size: 18,
                    color: Color(0xFF475569),
                  ),
                ),
                const Spacer(),
                InkWell(
                  onTap: () {
                    context.read<NotesProvider>().deleteNote(note.id);
                  },
                  child: const Icon(
                    Icons.delete_outline,
                    size: 18,
                    color: Color(0xFF475569),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
