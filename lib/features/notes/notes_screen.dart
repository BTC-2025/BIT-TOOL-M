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

  // Inline note creation controllers
  final TextEditingController _inlineTitleController = TextEditingController();
  final TextEditingController _inlineContentController = TextEditingController();
  bool _inlineIsPinned = false;
  String _inlineCategory = 'Bit Tool';
  String _inlineColorHex = '#A7F3D0';

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

  @override
  void dispose() {
    _inlineTitleController.dispose();
    _inlineContentController.dispose();
    super.dispose();
  }

  Color _parseColor(String hex) {
    try {
      final clean = hex.replaceAll('#', '');
      if (clean.length == 6) {
        return Color(int.parse('FF$clean', radix: 16));
      }
    } catch (_) {}
    return const Color(0xFFA7F3D0);
  }

  void _saveInlineNote() {
    final title = _inlineTitleController.text.trim();
    final content = _inlineContentController.text.trim();
    if (title.isEmpty && content.isEmpty) return;

    final provider = context.read<NotesProvider>();
    provider.addNote(
      title: title.isEmpty ? 'Untitled' : title,
      content: content,
      category: _inlineCategory,
      colorHex: _inlineColorHex,
      isPinned: _inlineIsPinned,
    );

    _inlineTitleController.clear();
    _inlineContentController.clear();
    setState(() {
      _inlineIsPinned = false;
      _inlineColorHex = '#A7F3D0';
      _inlineCategory = 'Bit Tool';
    });
  }

  void _clearInlineNote() {
    _inlineTitleController.clear();
    _inlineContentController.clear();
    setState(() {
      _inlineIsPinned = false;
    });
  }

  void _showNoteEditDialog(NoteItem note) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final titleController = TextEditingController(text: note.title);
    final contentController = TextEditingController(text: note.content);
    String category = note.category;
    String colorHex = note.colorHex;
    bool isPinned = note.isPinned;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
            final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
            final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

            return Dialog(
              backgroundColor: cardBg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: isDark ? BorderSide(color: borderColor) : BorderSide.none,
              ),
              child: Container(
                width: 460,
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Edit Note',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: textColor,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 20),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: titleController,
                      style: TextStyle(color: textColor, fontSize: 15, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        hintText: 'Note Title...',
                        hintStyle: TextStyle(color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: borderColor),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: contentController,
                      maxLines: 4,
                      style: TextStyle(color: textColor, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: "What's on your mind?",
                        hintStyle: TextStyle(color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: borderColor),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2563EB),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () {
                            context.read<NotesProvider>().updateNote(
                              note.id,
                              title: titleController.text.trim(),
                              content: contentController.text.trim(),
                              category: category,
                              colorHex: colorHex,
                              isPinned: isPinned,
                            );
                            Navigator.pop(ctx);
                          },
                          child: const Text('Save'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showColorPickerSheet(NoteItem note) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Change Note Color',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
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
                        border: Border.all(color: const Color(0xFFCBD5E1)),
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
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final notesProvider = Provider.of<NotesProvider>(context);
    final allNotes = notesProvider.notes;

    // Filter notes based on selected tab
    final filteredNotes = allNotes.where((n) {
      if (_selectedFilter == 'All Apps') return true;
      if (_selectedFilter == 'Archived') return false;
      return n.category.toLowerCase() == _selectedFilter.toLowerCase();
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ─── Inline Note Creation Box (Screenshot 3) ──────────────────────
          Center(
            child: Container(
              width: 560,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Title Row with Pin Icon
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _inlineTitleController,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                          decoration: InputDecoration(
                            hintText: 'Note Title',
                            hintStyle: TextStyle(
                              color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          setState(() {
                            _inlineIsPinned = !_inlineIsPinned;
                          });
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(
                            _inlineIsPinned ? Icons.push_pin : Icons.push_pin_outlined,
                            size: 20,
                            color: _inlineIsPinned
                                ? const Color(0xFF2563EB)
                                : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Content Field
                  TextField(
                    controller: _inlineContentController,
                    maxLines: null,
                    minLines: 2,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
                    ),
                    decoration: InputDecoration(
                      hintText: "What's on your mind?",
                      hintStyle: TextStyle(
                        color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                        fontSize: 14,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Bottom Action Bar: Icons + Cancel + Save Note
                  Row(
                    children: [
                      InkWell(
                        onTap: () {
                          // Quick color rotation
                          final idx = _pastelColors.indexWhere((c) => c['hex'] == _inlineColorHex);
                          final nextIdx = (idx + 1) % _pastelColors.length;
                          setState(() {
                            _inlineColorHex = _pastelColors[nextIdx]['hex'] as String;
                          });
                        },
                        borderRadius: BorderRadius.circular(6),
                        child: Padding(
                          padding: const EdgeInsets.all(6),
                          child: Icon(
                            Icons.palette_outlined,
                            size: 19,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () {},
                        borderRadius: BorderRadius.circular(6),
                        child: Padding(
                          padding: const EdgeInsets.all(6),
                          child: Icon(
                            Icons.check_box_outlined,
                            size: 19,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () {},
                        borderRadius: BorderRadius.circular(6),
                        child: Padding(
                          padding: const EdgeInsets.all(6),
                          child: Icon(
                            Icons.image_outlined,
                            size: 19,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: _clearInlineNote,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        ),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _saveInlineNote,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDark ? const Color(0xFF2563EB) : const Color(0xFF0F172A),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Save Note',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 28),

          // ─── Filter Tabs Row (Screenshot 3) ───────────────────────────────
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
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? (isDark ? const Color(0xFF2563EB) : const Color(0xFF0F172A))
                            : (isDark ? const Color(0xFF1E293B) : Colors.white),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? (isDark ? const Color(0xFF2563EB) : const Color(0xFF0F172A))
                              : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                        ),
                      ),
                      child: Text(
                        tab,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected
                              ? Colors.white
                              : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569)),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 24),

          // ─── Notes Grid / Cards Row (Screenshot 3) ────────────────────────
          if (filteredNotes.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Text(
                  'No notes in $_selectedFilter. Tap "Save Note" above to add one!',
                  style: TextStyle(
                    color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
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
      onTap: () => _showNoteEditDialog(note),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 255,
        constraints: const BoxConstraints(minHeight: 175),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
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
                    _buildCategoryBadge(note.category),
                    InkWell(
                      onTap: () {
                        context.read<NotesProvider>().togglePin(note.id);
                      },
                      borderRadius: BorderRadius.circular(6),
                      child: Padding(
                        padding: const EdgeInsets.all(2),
                        child: Icon(
                          note.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                          size: 18,
                          color: const Color(0xFF475569),
                        ),
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
                  borderRadius: BorderRadius.circular(6),
                  child: const Padding(
                    padding: EdgeInsets.all(3),
                    child: Icon(
                      Icons.palette_outlined,
                      size: 17,
                      color: Color(0xFF475569),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                InkWell(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Note "${note.title}" archived'),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(6),
                  child: const Padding(
                    padding: EdgeInsets.all(3),
                    child: Icon(
                      Icons.inventory_2_outlined,
                      size: 17,
                      color: Color(0xFF475569),
                    ),
                  ),
                ),
                const Spacer(),
                InkWell(
                  onTap: () {
                    context.read<NotesProvider>().deleteNote(note.id);
                  },
                  borderRadius: BorderRadius.circular(6),
                  child: const Padding(
                    padding: EdgeInsets.all(3),
                    child: Icon(
                      Icons.delete_outline_rounded,
                      size: 18,
                      color: Color(0xFF475569),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryBadge(String category) {
    String label = category.toUpperCase();
    Widget? leadingIcon;

    if (category.toLowerCase() == 'bnx mail') {
      leadingIcon = const Padding(
        padding: EdgeInsets.only(right: 4),
        child: Icon(Icons.near_me_rounded, size: 11, color: Color(0xFF0F172A)),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leadingIcon != null) leadingIcon,
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
