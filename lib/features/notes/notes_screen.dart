import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/app_models.dart';
import '../../core/providers/app_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/neumorphic_widgets.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';

  final List<String> _categories = [
    'All',
    'Work',
    'Ideas',
    'Personal',
    'General',
  ];

  final List<Map<String, dynamic>> _colorPalette = const [
    {'name': 'Blue', 'hex': '#3B82F6', 'color': Color(0xFF3B82F6)},
    {'name': 'Emerald', 'hex': '#10B981', 'color': Color(0xFF10B981)},
    {'name': 'Amber', 'hex': '#F59E0B', 'color': Color(0xFFF59E0B)},
    {'name': 'Purple', 'hex': '#8B5CF6', 'color': Color(0xFF8B5CF6)},
    {'name': 'Rose', 'hex': '#F43F5E', 'color': Color(0xFFF43F5E)},
  ];

  Color _parseColor(String hex) {
    try {
      final clean = hex.replaceAll('#', '');
      if (clean.length == 6) {
        return Color(int.parse('FF$clean', radix: 16));
      }
    } catch (_) {}
    return const Color(0xFF3B82F6);
  }

  void _showNoteDialog({NoteItem? note}) {
    final titleController = TextEditingController(text: note?.title ?? '');
    final contentController = TextEditingController(text: note?.content ?? '');
    String category = note?.category ?? 'Work';
    String colorHex = note?.colorHex ?? '#3B82F6';
    bool isPinned = note?.isPinned ?? false;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            return AlertDialog(
              backgroundColor: isDark
                  ? NeumorphicTheme.darkCard
                  : NeumorphicTheme.lightCard,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Text(
                note == null ? 'Create New Note' : 'Edit Note',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 480,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      NeumorphicTextField(
                        controller: titleController,
                        hintText: 'Note Title...',
                        prefixIcon: Icons.title_rounded,
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue:
                                  _categories.contains(category) &&
                                      category != 'All'
                                  ? category
                                  : 'Work',
                              decoration: InputDecoration(
                                labelText: 'Category',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                              ),
                              items: _categories
                                  .where((c) => c != 'All')
                                  .map(
                                    (c) => DropdownMenuItem(
                                      value: c,
                                      child: Text(c),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setDialogState(() => category = val);
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Row(
                            children: [
                              Checkbox(
                                value: isPinned,
                                onChanged: (val) {
                                  setDialogState(() => isPinned = val ?? false);
                                },
                              ),
                              const Text('Pin'),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Color Tag',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        children: _colorPalette.map((cp) {
                          final isSelected = colorHex == cp['hex'];
                          final c = cp['color'] as Color;
                          return GestureDetector(
                            onTap: () {
                              setDialogState(
                                () => colorHex = cp['hex'] as String,
                              );
                            },
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: c,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.transparent,
                                  width: 2.5,
                                ),
                                boxShadow: [
                                  if (isSelected)
                                    BoxShadow(
                                      color: c.withValues(alpha: 0.6),
                                      blurRadius: 8,
                                      spreadRadius: 1,
                                    ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        decoration: NeumorphicDecoration.build(
                          context: context,
                          inset: true,
                          borderRadius: 14,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        child: TextField(
                          controller: contentController,
                          maxLines: 6,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Write your notes or thoughts here...',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                NeumorphicButton(
                  onPressed: () {
                    final title = titleController.text.trim();
                    final content = contentController.text.trim();
                    if (title.isEmpty && content.isEmpty) return;

                    final provider = context.read<NotesProvider>();
                    if (note == null) {
                      provider.addNote(
                        title: title.isEmpty ? 'Untitled Note' : title,
                        content: content,
                        category: category,
                        colorHex: colorHex,
                        isPinned: isPinned,
                      );
                    } else {
                      provider.updateNote(
                        note.id,
                        title: title.isEmpty ? 'Untitled Note' : title,
                        content: content,
                        category: category,
                        colorHex: colorHex,
                        isPinned: isPinned,
                      );
                    }
                    Navigator.pop(ctx);
                  },
                  child: Text(note == null ? 'Create' : 'Save Changes'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notesProvider = context.watch<NotesProvider>();
    final notes = notesProvider.notes;

    final query = _searchController.text.toLowerCase().trim();
    final filteredNotes = notes.where((n) {
      final matchesQuery =
          query.isEmpty ||
          n.title.toLowerCase().contains(query) ||
          n.content.toLowerCase().contains(query);
      final matchesCat =
          _selectedCategory == 'All' || n.category == _selectedCategory;
      return matchesQuery && matchesCat;
    }).toList();

    final pinnedNotes = filteredNotes.where((n) => n.isPinned).toList();
    final otherNotes = filteredNotes.where((n) => !n.isPinned).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Notes & Thoughts',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${notes.length} saved memos and documents',
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(
                        context,
                      ).textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
              NeumorphicButton(
                onPressed: () => _showNoteDialog(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_rounded, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'New Note',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Search & Filter Row
          Row(
            children: [
              Expanded(
                child: NeumorphicTextField(
                  controller: _searchController,
                  hintText: 'Search notes by title or content...',
                  prefixIcon: Icons.search_rounded,
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Category Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _categories.map((cat) {
                final isSelected = _selectedCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedCategory = cat),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: NeumorphicDecoration.build(
                        context: context,
                        inset: isSelected,
                        borderRadius: 20,
                      ),
                      child: Text(
                        cat,
                        style: TextStyle(
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.w500,
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : null,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 24),

          // Empty State
          if (filteredNotes.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 48),
                child: Column(
                  children: [
                    Icon(
                      Icons.note_alt_outlined,
                      size: 64,
                      color: Theme.of(
                        context,
                      ).textTheme.bodySmall?.color?.withValues(alpha: 0.4),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No notes found',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(
                          context,
                        ).textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text('Tap "New Note" to jot down your thoughts.'),
                  ],
                ),
              ),
            ),

          // Pinned Notes Section
          if (pinnedNotes.isNotEmpty) ...[
            const Row(
              children: [
                Icon(Icons.push_pin_rounded, size: 16, color: Colors.amber),
                SizedBox(width: 8),
                Text(
                  'PINNED',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildNotesGrid(pinnedNotes),
            const SizedBox(height: 28),
          ],

          // Other Notes Section
          if (otherNotes.isNotEmpty) ...[
            if (pinnedNotes.isNotEmpty)
              const Text(
                'ALL NOTES',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            if (pinnedNotes.isNotEmpty) const SizedBox(height: 12),
            _buildNotesGrid(otherNotes),
          ],
        ],
      ),
    );
  }

  Widget _buildNotesGrid(List<NoteItem> notesList) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = constraints.maxWidth > 900
            ? 3
            : (constraints.maxWidth > 600 ? 2 : 1);

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: notesList.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            mainAxisExtent: 200,
          ),
          itemBuilder: (context, index) {
            final note = notesList[index];
            final tagColor = _parseColor(note.colorHex);

            return NeumorphicCard(
              borderRadius: 18,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: tagColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          note.category,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: tagColor,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          context.read<NotesProvider>().togglePin(note.id);
                        },
                        child: Icon(
                          note.isPinned
                              ? Icons.push_pin_rounded
                              : Icons.push_pin_outlined,
                          size: 18,
                          color: note.isPinned ? Colors.amber : Colors.grey,
                        ),
                      ),
                      const SizedBox(width: 8),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, size: 18),
                        onSelected: (val) {
                          if (val == 'edit') {
                            _showNoteDialog(note: note);
                          } else if (val == 'delete') {
                            context.read<NotesProvider>().deleteNote(note.id);
                          }
                        },
                        itemBuilder: (ctx) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit_outlined, size: 18),
                                SizedBox(width: 8),
                                Text('Edit'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.delete_outline,
                                  size: 18,
                                  color: Colors.red,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Delete',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    note.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Text(
                      note.content,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.color?.withValues(alpha: 0.8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatDate(note.updatedAt),
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(
                        context,
                      ).textTheme.bodySmall?.color?.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _formatDate(DateTime dt) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final m = months[dt.month - 1];
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$m ${dt.day}, ${dt.year} • $h:$min';
  }
}
