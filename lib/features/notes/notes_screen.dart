import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/note_model.dart';
import '../../core/providers/notes_provider.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  String _selectedFilter = 'All Apps';
  bool _isSavingInline = false;

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
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<NotesProvider>();
      if (provider.status == NotesStatus.initial) {
        provider.fetchNotes(allApps: true);
      }
    });
  }

  @override
  void dispose() {
    _inlineTitleController.dispose();
    _inlineContentController.dispose();
    super.dispose();
  }

  Color _parseColor(String colorStr) {
    try {
      final trimmed = colorStr.trim();
      // Handle rgba(r, g, b, a)
      if (trimmed.startsWith('rgba(') && trimmed.endsWith(')')) {
        final parts = trimmed
            .substring(5, trimmed.length - 1)
            .split(',')
            .map((s) => s.trim())
            .toList();
        if (parts.length == 4) {
          final r = int.parse(parts[0]);
          final g = int.parse(parts[1]);
          final b = int.parse(parts[2]);
          final a = double.parse(parts[3]);
          return Color.fromRGBO(r, g, b, a);
        }
      }
      // Handle rgb(r, g, b)
      if (trimmed.startsWith('rgb(') && trimmed.endsWith(')')) {
        final parts = trimmed
            .substring(4, trimmed.length - 1)
            .split(',')
            .map((s) => s.trim())
            .toList();
        if (parts.length == 3) {
          final r = int.parse(parts[0]);
          final g = int.parse(parts[1]);
          final b = int.parse(parts[2]);
          return Color.fromRGBO(r, g, b, 1.0);
        }
      }
      // Handle Hex
      final clean = trimmed.replaceAll('#', '');
      if (clean.length == 6) {
        return Color(int.parse('FF$clean', radix: 16));
      } else if (clean.length == 8) {
        return Color(int.parse(clean, radix: 16));
      }
    } catch (_) {}
    return const Color(0xFFA7F3D0);
  }

  Future<void> _saveInlineNote() async {
    final title = _inlineTitleController.text.trim();
    final content = _inlineContentController.text.trim();
    if (title.isEmpty && content.isEmpty) return;

    setState(() => _isSavingInline = true);
    final provider = context.read<NotesProvider>();

    try {
      await provider.createNote(
        title: title.isEmpty ? 'Untitled' : title,
        content: content,
        color: _inlineColorHex,
        isPinned: _inlineIsPinned,
        applicationName: _inlineCategory,
      );

      _inlineTitleController.clear();
      _inlineContentController.clear();
      setState(() {
        _inlineIsPinned = false;
        _inlineColorHex = '#A7F3D0';
        _inlineCategory = 'Bit Tool';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Note created successfully'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create note: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSavingInline = false);
      }
    }
  }

  void _clearInlineNote() {
    _inlineTitleController.clear();
    _inlineContentController.clear();
    setState(() {
      _inlineIsPinned = false;
    });
  }

  void _showNoteEditDialog(NoteModel note) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final titleController = TextEditingController(text: note.title);
    final contentController = TextEditingController(text: note.content);
    String category = note.applicationName;
    String colorHex = note.color;
    bool isPinned = note.isPinned;
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
            final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
            final borderColor = isDark
                ? const Color(0xFF334155)
                : const Color(0xFFE2E8F0);

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
                      style: TextStyle(
                        color: textColor,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Note Title...',
                        hintStyle: TextStyle(
                          color: isDark
                              ? const Color(0xFF64748B)
                              : const Color(0xFF94A3B8),
                        ),
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
                        hintStyle: TextStyle(
                          color: isDark
                              ? const Color(0xFF64748B)
                              : const Color(0xFF94A3B8),
                        ),
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
                          onPressed: isSaving ? null : () => Navigator.pop(ctx),
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
                          onPressed: isSaving
                              ? null
                              : () async {
                                  setDialogState(() => isSaving = true);
                                  try {
                                    await context.read<NotesProvider>().updateNote(
                                          note.id,
                                          title: titleController.text.trim(),
                                          content: contentController.text.trim(),
                                          category: category,
                                          colorHex: colorHex,
                                          isPinned: isPinned,
                                        );
                                    if (ctx.mounted) {
                                      Navigator.pop(ctx);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Note updated successfully'),
                                          duration: Duration(seconds: 2),
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    setDialogState(() => isSaving = false);
                                    if (ctx.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Failed to update note: $e'),
                                          backgroundColor: Colors.redAccent,
                                        ),
                                      );
                                    }
                                  }
                                },
                          child: isSaving
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor:
                                        AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Text('Save'),
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

  void _showDeleteConfirmDialog(NoteModel note) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Delete Note',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          content: Text(
            'Are you sure you want to delete "${note.displayTitle}"? This action cannot be undone.',
            style: TextStyle(
              color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () async {
                Navigator.pop(ctx);
                try {
                  await context.read<NotesProvider>().deleteNote(note.id);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Note deleted successfully'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to delete note: $e'),
                        backgroundColor: Colors.redAccent,
                      ),
                    );
                  }
                }
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _showColorPickerSheet(NoteModel note) {
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
                    onTap: () async {
                      Navigator.pop(ctx);
                      try {
                        await context.read<NotesProvider>().updateNote(
                              note.id,
                              colorHex: c['hex'] as String,
                            );
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Failed to update color: $e'),
                              backgroundColor: Colors.redAccent,
                            ),
                          );
                        }
                      }
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

    // Filter notes based on selected tab
    final filteredNotes = notesProvider.notes.where((n) {
      if (_selectedFilter == 'Archived') {
        return n.isArchived;
      }
      // Non-archived tabs should not show archived notes
      if (n.isArchived) return false;

      if (_selectedFilter == 'All Apps') return true;
      return n.applicationName.toLowerCase() == _selectedFilter.toLowerCase();
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ─── Inline Note Creation Box ────────────────────────────────────
          Center(
            child: Container(
              width: 560,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF334155)
                      : const Color(0xFFE2E8F0),
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
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF0F172A),
                          ),
                          decoration: InputDecoration(
                            hintText: 'Note Title',
                            hintStyle: TextStyle(
                              color: isDark
                                  ? const Color(0xFF64748B)
                                  : const Color(0xFF94A3B8),
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
                            _inlineIsPinned
                                ? Icons.push_pin
                                : Icons.push_pin_outlined,
                            size: 20,
                            color: _inlineIsPinned
                                ? const Color(0xFF2563EB)
                                : (isDark
                                      ? const Color(0xFF94A3B8)
                                      : const Color(0xFF64748B)),
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
                      color: isDark
                          ? const Color(0xFFE2E8F0)
                          : const Color(0xFF334155),
                    ),
                    decoration: InputDecoration(
                      hintText: "What's on your mind?",
                      hintStyle: TextStyle(
                        color: isDark
                            ? const Color(0xFF64748B)
                            : const Color(0xFF94A3B8),
                        fontSize: 14,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Bottom Action Bar: Palette + Cancel + Save Note
                  Row(
                    children: [
                      InkWell(
                        onTap: () {
                          final idx = _pastelColors.indexWhere(
                            (c) => c['hex'] == _inlineColorHex,
                          );
                          final nextIdx = (idx + 1) % _pastelColors.length;
                          setState(() {
                            _inlineColorHex =
                                _pastelColors[nextIdx]['hex'] as String;
                          });
                        },
                        borderRadius: BorderRadius.circular(6),
                        child: Padding(
                          padding: const EdgeInsets.all(6),
                          child: Icon(
                            Icons.palette_outlined,
                            size: 19,
                            color: isDark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF64748B),
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
                            color: isDark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF64748B),
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
                            color: isDark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF64748B),
                          ),
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: _isSavingInline ? null : _clearInlineNote,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF64748B),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _isSavingInline ? null : _saveInlineNote,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDark
                              ? const Color(0xFF2563EB)
                              : const Color(0xFF0F172A),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                        ),
                        child: _isSavingInline
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor:
                                      AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text(
                                'Save Note',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 28),

          // ─── Filter Tabs Row ─────────────────────────────────────────────
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _filterTabs.map((tab) {
                final isSelected = _selectedFilter == tab;
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: InkWell(
                    onTap: () {
                      setState(() => _selectedFilter = tab);
                      notesProvider.setFilter(tab);
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? (isDark
                                  ? const Color(0xFF2563EB)
                                  : const Color(0xFF0F172A))
                            : (isDark ? const Color(0xFF1E293B) : Colors.white),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? (isDark
                                    ? const Color(0xFF2563EB)
                                    : const Color(0xFF0F172A))
                              : (isDark
                                    ? const Color(0xFF334155)
                                    : const Color(0xFFE2E8F0)),
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
                              : (isDark
                                    ? const Color(0xFF94A3B8)
                                    : const Color(0xFF475569)),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 24),

          // ─── Notes State Display (Loading / Error / Empty / Grid) ────────
          if (notesProvider.isLoading && notesProvider.notes.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 48),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Loading notes...',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else if (notesProvider.hasError && notesProvider.notes.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      size: 40,
                      color: Colors.redAccent.withValues(alpha: 0.8),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      notesProvider.errorMessage ?? 'Unable to load notes',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isDark
                            ? const Color(0xFFCBD5E1)
                            : const Color(0xFF475569),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () => notesProvider.fetchNotes(
                        allApps: true,
                        forceRefresh: true,
                      ),
                      icon: const Icon(Icons.refresh_rounded, size: 16),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
          else if (filteredNotes.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 48),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _selectedFilter == 'Archived'
                          ? Icons.inventory_2_outlined
                          : Icons.note_alt_outlined,
                      size: 40,
                      color: isDark
                          ? const Color(0xFF475569)
                          : const Color(0xFF94A3B8),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _selectedFilter == 'Archived'
                          ? 'No archived notes.'
                          : 'No notes in $_selectedFilter. Tap "Save Note" above to add one!',
                      style: TextStyle(
                        color: isDark
                            ? const Color(0xFF64748B)
                            : const Color(0xFF94A3B8),
                        fontSize: 14,
                      ),
                    ),
                  ],
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

  Widget _buildNoteCard(NoteModel note) {
    final bgColor = _parseColor(note.color);

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
                    _buildCategoryBadge(note.applicationName),
                    InkWell(
                      onTap: () async {
                        try {
                          await context.read<NotesProvider>().togglePin(note.id);
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Failed to pin note: $e'),
                                backgroundColor: Colors.redAccent,
                              ),
                            );
                          }
                        }
                      },
                      borderRadius: BorderRadius.circular(6),
                      child: Padding(
                        padding: const EdgeInsets.all(2),
                        child: Icon(
                          note.isPinned
                              ? Icons.push_pin
                              : Icons.push_pin_outlined,
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
                  note.displayTitle,
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
                  onTap: () async {
                    try {
                      await context.read<NotesProvider>().toggleArchive(note.id);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Note "${note.displayTitle}" ${!note.isArchived ? "archived" : "restored"}',
                            ),
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to archive note: $e'),
                            backgroundColor: Colors.redAccent,
                          ),
                        );
                      }
                    }
                  },
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.all(3),
                    child: Icon(
                      note.isArchived
                          ? Icons.unarchive_outlined
                          : Icons.inventory_2_outlined,
                      size: 17,
                      color: const Color(0xFF475569),
                    ),
                  ),
                ),
                const Spacer(),
                InkWell(
                  onTap: () => _showDeleteConfirmDialog(note),
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
