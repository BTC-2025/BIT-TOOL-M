import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum KeyboardTheme { studioPro, cyberNeon, sunsetGlow, retroTypewriter }

class KeyboardScreen extends StatefulWidget {
  const KeyboardScreen({super.key});

  @override
  State<KeyboardScreen> createState() => _KeyboardScreenState();
}

class _KeyboardScreenState extends State<KeyboardScreen> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _textFocusNode = FocusNode();

  // Keyboard state
  bool _isShift = false;
  bool _isCapsLock = false;
  bool _isNumberMode = false;
  bool _isEmojiMode = false;
  bool _soundEnabled = true;
  DateTime? _lastShiftTap;
  Timer? _backspaceTimer;

  // Set of keys currently visually active / flashing with animation
  final Set<String> _activeFlashedKeys = <String>{};
  final List<Timer> _flashTimers = <Timer>[];
  final Map<String, int> _keyFlashGeneration = <String, int>{};
  String _previousText = '';
  bool _isInternalTextInsertion = false;

  // Selected Theme
  KeyboardTheme _selectedTheme = KeyboardTheme.studioPro;

  // Typing Speed & Analytics
  DateTime? _typingSessionStart;
  int _keystrokes = 0;
  int _currentWpm = 0;
  Timer? _wpmTimer;

  // Selected Emoji Category
  int _selectedEmojiCategory = 0;

  final List<Map<String, dynamic>> _emojiCategories = [
    {
      'name': 'Smileys',
      'icon': Icons.sentiment_satisfied_alt_rounded,
      'emojis': [
        '😀',
        '😃',
        '😄',
        '😁',
        '😅',
        '😂',
        '🤣',
        '😊',
        '😇',
        '🙂',
        '😉',
        '😍',
        '🥰',
        '😘',
        '😋',
        '😎',
        '🥳',
        '🤩',
        '🤔',
        '🤫',
        '🤗',
        '🫡',
        '🤤',
        '😴',
        '🤯',
        '🤠',
        '🥺',
        '😭',
        '🤓',
        '🤑',
        '😈',
        '🤡',
        '👻',
        '💀',
        '👽',
        '🤖',
        '🎃',
        '😺',
        '😸',
        '😻',
      ],
    },
    {
      'name': 'Gestures',
      'icon': Icons.pan_tool_alt_rounded,
      'emojis': [
        '👍',
        '👎',
        '👏',
        '🙌',
        '🫶',
        '✌️',
        '🤞',
        '🤟',
        '🤘',
        '🤙',
        '👋',
        '✍️',
        '🤝',
        '🙏',
        '💪',
        '👈',
        '👉',
        '👆',
        '👇',
        '👌',
        '👊',
        '🤛',
        '🤜',
        '🖐️',
        '✋',
        '🖖',
        '🫰',
        '🫱',
        '🫲',
        '🫳',
      ],
    },
    {
      'name': 'Hearts & Fire',
      'icon': Icons.local_fire_department_rounded,
      'emojis': [
        '❤️',
        '🧡',
        '💛',
        '💚',
        '💙',
        '💜',
        '🖤',
        '🤍',
        '💔',
        '❣️',
        '💕',
        '🔥',
        '✨',
        '⚡',
        '💥',
        '🌟',
        '⭐',
        '💫',
        '🎉',
        '🎊',
        '💐',
        '🌸',
        '🌹',
        '🌺',
        '🍀',
        '🌈',
        '☀️',
        '🌙',
        '⭐',
        '💎',
      ],
    },
    {
      'name': 'Tech & Work',
      'icon': Icons.devices_rounded,
      'emojis': [
        '💡',
        '🚀',
        '💻',
        '📱',
        '⌚',
        '🎧',
        '☕',
        '🍔',
        '🍕',
        '⚽',
        '🎮',
        '🎨',
        '🎵',
        '📚',
        '🏆',
        '🔒',
        '🔑',
        '📌',
        '🎁',
        '📦',
        '🔔',
        '🏷️',
        '🛠️',
        '⚙️',
        '🧭',
        '📷',
        '🎬',
        '📡',
        '🕹️',
        '🕶️',
      ],
    },
    {
      'name': 'Symbols',
      'icon': Icons.stars_rounded,
      'emojis': [
        '✅',
        '❌',
        '⚠️',
        '💯',
        '🆗',
        '🆒',
        '🆕',
        '🆓',
        '➡️',
        '⬅️',
        '⬆️',
        '⬇️',
        '☀️',
        '🌙',
        '⭐',
        '☁️',
        '⚡',
        '🌈',
        '🔔',
        '🏷️',
      ],
    },
  ];

  @override
  void initState() {
    super.initState();
    _previousText = _textController.text;
    _textController.addListener(_onTextChanged);
    _wpmTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _calculateWpm(),
    );
    HardwareKeyboard.instance.addHandler(_onHardwareKeyEvent);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onHardwareKeyEvent);
    _wpmTimer?.cancel();
    _backspaceTimer?.cancel();
    for (final timer in _flashTimers) {
      timer.cancel();
    }
    _flashTimers.clear();
    _textController.removeListener(_onTextChanged);
    _textController.dispose();
    _textFocusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final currentText = _textController.text;
    if (!_isInternalTextInsertion && currentText != _previousText) {
      if (currentText.length > _previousText.length) {
        // Direct insertion into TextField (e.g. typing via hardware keyboard)
        final selectionEnd = _textController.selection.baseOffset;
        final count = currentText.length - _previousText.length;
        final start =
            (selectionEnd >= count && selectionEnd <= currentText.length)
            ? selectionEnd - count
            : _previousText.length;
        final end =
            (selectionEnd >= count && selectionEnd <= currentText.length)
            ? selectionEnd
            : currentText.length;
        final added = currentText.substring(start, end);

        for (final char in added.split('')) {
          if (char == ' ') {
            _flashKey('space');
          } else if (char == '\n' || char == '\r') {
            _flashKey('return');
          } else {
            _flashKey(char.toLowerCase());
          }
        }
      } else if (currentText.length < _previousText.length) {
        // Deletion in TextField
        _flashKey('delete');
      }
      _previousText = currentText;
    }
    if (mounted) setState(() {});
  }

  bool _onHardwareKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent || event is KeyRepeatEvent) {
      final logical = event.logicalKey;

      if (logical == LogicalKeyboardKey.space) {
        _flashKey('space');
        return false;
      }
      if (logical == LogicalKeyboardKey.enter ||
          logical == LogicalKeyboardKey.numpadEnter) {
        _flashKey('return');
        return false;
      }
      if (logical == LogicalKeyboardKey.backspace ||
          logical == LogicalKeyboardKey.delete) {
        _flashKey('delete');
        return false;
      }
      if (logical == LogicalKeyboardKey.shiftLeft ||
          logical == LogicalKeyboardKey.shiftRight) {
        _flashKey('shift');
        return false;
      }
      if (logical == LogicalKeyboardKey.capsLock) {
        _toggleShift();
        return false;
      }

      // Check character if present
      final char = event.character;
      if (char != null && char.isNotEmpty) {
        if (char == ' ') {
          _flashKey('space');
        } else if (char == '\n' || char == '\r') {
          _flashKey('return');
        } else {
          _flashKey(char.toLowerCase());
        }
        return false;
      }

      // Fallback to logical key label (for macOS physical keyboard where char might be null)
      final label = logical.keyLabel;
      if (label.isNotEmpty && label.length == 1) {
        _flashKey(label.toLowerCase());
        return false;
      }
    }
    return false; // allow TextField to process keystroke naturally
  }

  void _flashKey(String key) {
    final cleanKey = key.toLowerCase();
    final nextGen = (_keyFlashGeneration[cleanKey] ?? 0) + 1;
    _keyFlashGeneration[cleanKey] = nextGen;

    setState(() {
      _activeFlashedKeys.add(cleanKey);
    });

    HapticFeedback.lightImpact();
    if (_soundEnabled) {
      SystemSound.play(SystemSoundType.click);
    }

    _recordKeystroke();

    Timer? timer;
    timer = Timer(const Duration(milliseconds: 130), () {
      if (timer != null) {
        _flashTimers.remove(timer);
      }
      if (mounted) {
        if (_keyFlashGeneration[cleanKey] == nextGen) {
          setState(() {
            _activeFlashedKeys.remove(cleanKey);
          });
        }
      }
    });
    _flashTimers.add(timer);
  }

  void _recordKeystroke() {
    _typingSessionStart ??= DateTime.now();
    _keystrokes++;
    _calculateWpm();
  }

  void _calculateWpm() {
    if (_typingSessionStart == null || _textController.text.trim().isEmpty) {
      if (_currentWpm != 0 && mounted) {
        setState(() => _currentWpm = 0);
      }
      return;
    }

    final elapsedSeconds = DateTime.now()
        .difference(_typingSessionStart!)
        .inSeconds;
    if (elapsedSeconds < 2) return;

    final words = _textController.text.trim().split(RegExp(r'\s+')).length;
    final minutes = elapsedSeconds / 60.0;
    final wpm = (words / minutes).round();

    if (_currentWpm != wpm && mounted) {
      setState(() => _currentWpm = wpm);
    }
  }

  void _insertText(String textToInsert) {
    if (textToInsert == ' ') {
      _flashKey('space');
    } else if (textToInsert == '\n') {
      _flashKey('return');
    } else {
      _flashKey(textToInsert);
    }
    final text = _textController.text;
    final selection = _textController.selection;

    int start = selection.start;
    int end = selection.end;

    if (start < 0 || end < 0) {
      start = text.length;
      end = text.length;
    }

    final newText = text.replaceRange(start, end, textToInsert);
    final newCursorPos = start + textToInsert.length;

    _isInternalTextInsertion = true;
    _textController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newCursorPos),
    );
    _previousText = newText;
    _isInternalTextInsertion = false;

    // If shift was active (not caps lock), revert back to lowercase
    if (_isShift && !_isCapsLock) {
      setState(() {
        _isShift = false;
      });
    }

    _textFocusNode.requestFocus();
  }

  void _handleBackspace() {
    _flashKey('delete');
    final text = _textController.text;
    final selection = _textController.selection;

    int start = selection.start;
    int end = selection.end;

    if (start < 0 || end < 0) {
      start = text.length;
      end = text.length;
    }

    String newText;
    int newCursorPos;
    if (start == end) {
      if (start > 0) {
        newText = text.replaceRange(start - 1, start, '');
        newCursorPos = start - 1;
      } else {
        newText = text;
        newCursorPos = 0;
      }
    } else {
      newText = text.replaceRange(start, end, '');
      newCursorPos = start;
    }

    _isInternalTextInsertion = true;
    _textController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newCursorPos),
    );
    _previousText = newText;
    _isInternalTextInsertion = false;

    _textFocusNode.requestFocus();
  }

  void _startContinuousBackspace() {
    _handleBackspace();
    _backspaceTimer?.cancel();
    _backspaceTimer = Timer.periodic(const Duration(milliseconds: 70), (_) {
      _handleBackspace();
    });
  }

  void _stopContinuousBackspace() {
    _backspaceTimer?.cancel();
  }

  void _toggleShift() {
    _flashKey('shift');
    final now = DateTime.now();
    if (_lastShiftTap != null &&
        now.difference(_lastShiftTap!) < const Duration(milliseconds: 320)) {
      // Double tap -> Caps Lock
      setState(() {
        _isCapsLock = !_isCapsLock;
        _isShift = _isCapsLock;
      });
    } else {
      setState(() {
        if (_isCapsLock) {
          _isCapsLock = false;
          _isShift = false;
        } else {
          _isShift = !_isShift;
        }
      });
    }
    _lastShiftTap = now;
  }

  void _toggleNumberMode() {
    _flashKey(_isNumberMode ? 'abc' : '123');
    setState(() {
      _isNumberMode = !_isNumberMode;
      _isEmojiMode = false;
      _isShift = false;
      _isCapsLock = false;
    });
  }

  void _toggleEmojiMode() {
    _flashKey('emoji');
    setState(() {
      _isEmojiMode = !_isEmojiMode;
      _isNumberMode = false;
    });
  }

  void _transformText(String Function(String) transform) {
    final text = _textController.text;
    if (text.isEmpty) return;
    _textController.value = TextEditingValue(
      text: transform(text),
      selection: _textController.selection,
    );
  }

  void _clearText() {
    _textController.clear();
    _typingSessionStart = null;
    _keystrokes = 0;
    _currentWpm = 0;
    _textFocusNode.requestFocus();
  }

  Future<void> _copyText() async {
    final text = _textController.text;
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.info_outline, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text('Nothing to copy. Type some text first.'),
            ],
          ),
          backgroundColor: const Color(0xFF64748B),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text('Text copied to clipboard!'),
            ],
          ),
          backgroundColor: const Color(0xFF16A34A),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  _ThemeColors _getThemeColors() {
    switch (_selectedTheme) {
      case KeyboardTheme.cyberNeon:
        return _ThemeColors(
          deckBg: const Color(0xFF090D16),
          deckBorder: const Color(0xFF1E293B),
          standardKeyBg: const Color(0xFF161F30),
          standardKeyActive: const Color(0xFF1E2D44),
          standardKeyText: const Color(0xFFE2E8F0),
          standardKeyActiveText: const Color(0xFF38BDF8),
          functionKeyBg: const Color(0xFF1E293B),
          functionKeyActive: const Color(0xFF2A3A52),
          functionKeyText: const Color(0xFF94A3B8),
          accentColor: const Color(0xFF00F2FE),
          accentGradient: const [Color(0xFF0284C7), Color(0xFF00F2FE)],
          keyShadow: const Color(0x66000000),
          glowColor: const Color(0xFF38BDF8),
          editorBg: const Color(0xFF0F172A),
          editorBorder: const Color(0xFF1E293B),
          editorText: Colors.white,
        );
      case KeyboardTheme.sunsetGlow:
        return _ThemeColors(
          deckBg: const Color(0xFF1C1917),
          deckBorder: const Color(0xFF292524),
          standardKeyBg: const Color(0xFF292524),
          standardKeyActive: const Color(0xFF3A3430),
          standardKeyText: const Color(0xFFFAF6EE),
          standardKeyActiveText: const Color(0xFFFDBA74),
          functionKeyBg: const Color(0xFF44403C),
          functionKeyActive: const Color(0xFF524C47),
          functionKeyText: const Color(0xFFA8A29E),
          accentColor: const Color(0xFFF97316),
          accentGradient: const [Color(0xFFEA580C), Color(0xFFF97316)],
          keyShadow: const Color(0x66000000),
          glowColor: const Color(0xFFFB923C),
          editorBg: const Color(0xFF292524),
          editorBorder: const Color(0xFF44403C),
          editorText: const Color(0xFFFAF6EE),
        );
      case KeyboardTheme.retroTypewriter:
        return _ThemeColors(
          deckBg: const Color(0xFFEBE3D5),
          deckBorder: const Color(0xFFD6C8B7),
          standardKeyBg: const Color(0xFFFDFBF7),
          standardKeyActive: const Color(0xFFE8E0D1),
          standardKeyText: const Color(0xFF292524),
          standardKeyActiveText: const Color(0xFF9A3412),
          functionKeyBg: const Color(0xFFD6C8B7),
          functionKeyActive: const Color(0xFFC7B7A3),
          functionKeyText: const Color(0xFF44403C),
          accentColor: const Color(0xFFC2410C),
          accentGradient: const [Color(0xFF9A3412), Color(0xFFC2410C)],
          keyShadow: const Color(0x3378350F),
          glowColor: const Color(0xFFC2410C),
          editorBg: Colors.white,
          editorBorder: const Color(0xFFD6C8B7),
          editorText: const Color(0xFF292524),
        );
      case KeyboardTheme.studioPro:
        return _ThemeColors(
          deckBg: const Color(0xFFEEF2F6),
          deckBorder: const Color(0xFFE2E8F0),
          standardKeyBg: Colors.white,
          standardKeyActive: const Color(0xFFE2E8F0),
          standardKeyText: const Color(0xFF0F172A),
          standardKeyActiveText: const Color(0xFF1D4ED8),
          functionKeyBg: const Color(0xFFDCE2EC),
          functionKeyActive: const Color(0xFFCBD5E1),
          functionKeyText: const Color(0xFF334155),
          accentColor: const Color(0xFF2563EB),
          accentGradient: const [Color(0xFF1D4ED8), Color(0xFF2563EB)],
          keyShadow: const Color(0x1F000000),
          glowColor: const Color(0xFF3B82F6),
          editorBg: Colors.white,
          editorBorder: const Color(0xFFE2E8F0),
          editorText: const Color(0xFF0F172A),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = _getThemeColors();
    final isCapitalized = _isShift || _isCapsLock;

    final List<String> row1Keys = _isNumberMode
        ? ['1', '2', '3', '4', '5', '6', '7', '8', '9', '0']
        : [
            'q',
            'w',
            'e',
            'r',
            't',
            'y',
            'u',
            'i',
            'o',
            'p',
          ].map((k) => isCapitalized ? k.toUpperCase() : k).toList();

    final List<String> row2Keys = _isNumberMode
        ? ['-', '/', ':', ';', '(', ')', '\$', '&', '@']
        : [
            'a',
            's',
            'd',
            'f',
            'g',
            'h',
            'j',
            'k',
            'l',
          ].map((k) => isCapitalized ? k.toUpperCase() : k).toList();

    final List<String> row3Keys = _isNumberMode
        ? ['?', '!', "'", '"', ',', '.', '%']
        : [
            'z',
            'x',
            'c',
            'v',
            'b',
            'n',
            'm',
          ].map((k) => isCapitalized ? k.toUpperCase() : k).toList();

    final textLength = _textController.text.length;
    final wordCount = _textController.text.trim().isEmpty
        ? 0
        : _textController.text.trim().split(RegExp(r'\s+')).length;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 880),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Header: Title & Action Controls ───────────────────────────
              _buildHeader(textLength, wordCount),
              const SizedBox(height: 18),

              // ── Modern Text Editor Card ───────────────────────────────────
              _buildEditorCard(colors),
              const SizedBox(height: 20),

              // ── Tactile Animated Virtual Keyboard Deck ───────────────────
              _buildKeyboardDeck(colors, row1Keys, row2Keys, row3Keys),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(int textLength, int wordCount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2563EB).withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.keyboard_alt_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Keyboard',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.5,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Tactile on-screen virtual keyboard with smart input',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF64748B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Sound Click Feedback Toggle
            IconButton(
              icon: Icon(
                _soundEnabled
                    ? Icons.volume_up_rounded
                    : Icons.volume_off_rounded,
                size: 20,
                color: _soundEnabled
                    ? const Color(0xFF2563EB)
                    : const Color(0xFF94A3B8),
              ),
              onPressed: () => setState(() => _soundEnabled = !_soundEnabled),
              tooltip: _soundEnabled ? 'Audio Click: ON' : 'Audio Click: OFF',
            ),
            const SizedBox(width: 4),

            // Theme Selector Menu
            PopupMenuButton<KeyboardTheme>(
              initialValue: _selectedTheme,
              onSelected: (theme) => setState(() => _selectedTheme = theme),
              tooltip: 'Switch Keyboard Theme',
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.palette_outlined,
                      size: 16,
                      color: Color(0xFF64748B),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _getThemeName(_selectedTheme),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF334155),
                      ),
                    ),
                    const Icon(
                      Icons.arrow_drop_down,
                      size: 18,
                      color: Color(0xFF64748B),
                    ),
                  ],
                ),
              ),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: KeyboardTheme.studioPro,
                  child: Text('Studio Pro (Default)'),
                ),
                const PopupMenuItem(
                  value: KeyboardTheme.cyberNeon,
                  child: Text('Cyber Neon (Glow)'),
                ),
                const PopupMenuItem(
                  value: KeyboardTheme.sunsetGlow,
                  child: Text('Sunset Glow'),
                ),
                const PopupMenuItem(
                  value: KeyboardTheme.retroTypewriter,
                  child: Text('Retro Typewriter'),
                ),
              ],
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: textLength > 0 ? _clearText : null,
              icon: const Icon(Icons.delete_outline_rounded, size: 20),
              color: const Color(0xFFEF4444),
              tooltip: 'Clear All',
            ),
            const SizedBox(width: 4),
            ElevatedButton.icon(
              onPressed: _copyText,
              icon: const Icon(Icons.copy_rounded, size: 15),
              label: const Text('Copy Text'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _getThemeName(KeyboardTheme theme) {
    switch (theme) {
      case KeyboardTheme.studioPro:
        return 'Studio';
      case KeyboardTheme.cyberNeon:
        return 'Cyber Neon';
      case KeyboardTheme.sunsetGlow:
        return 'Sunset';
      case KeyboardTheme.retroTypewriter:
        return 'Retro';
    }
  }

  Widget _buildEditorCard(_ThemeColors colors) {
    return Container(
      decoration: BoxDecoration(
        color: colors.editorBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.editorBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // Editor Window Header Toolbar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: _selectedTheme == KeyboardTheme.cyberNeon
                  ? const Color(0xFF0F172A)
                  : const Color(0xFFF8FAFC),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              border: Border(bottom: BorderSide(color: colors.editorBorder)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: Color(0xFFEF4444),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF59E0B),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Live typing speed HUD
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: colors.accentColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.speed_rounded,
                            size: 13,
                            color: colors.accentColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$_currentWpm WPM',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: colors.accentColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${_textController.text.length} chars • $_keystrokes taps',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF94A3B8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),

                // Text Transform Tools
                Row(
                  children: [
                    _buildCaseButton(
                      'AA',
                      () => _transformText((t) => t.toUpperCase()),
                      'UPPERCASE',
                    ),
                    const SizedBox(width: 4),
                    _buildCaseButton(
                      'aa',
                      () => _transformText((t) => t.toLowerCase()),
                      'lowercase',
                    ),
                    const SizedBox(width: 4),
                    _buildCaseButton(
                      'Aa',
                      () => _transformText((t) {
                        return t
                            .split(' ')
                            .map((word) {
                              if (word.isEmpty) return word;
                              return word[0].toUpperCase() +
                                  word.substring(1).toLowerCase();
                            })
                            .join(' ');
                      }),
                      'Title Case',
                    ),
                  ],
                ),
              ],
            ),
          ),

          // TextField Input
          Container(
            height: 140,
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _textController,
              focusNode: _textFocusNode,
              maxLines: null,
              expands: true,
              style: TextStyle(
                fontSize: 17,
                height: 1.5,
                color: colors.editorText,
                fontWeight: FontWeight.w500,
              ),
              decoration: const InputDecoration(
                hintText: 'Type here...',
                hintStyle: TextStyle(
                  fontSize: 17,
                  color: Color(0xFF94A3B8),
                  fontWeight: FontWeight.w400,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),

          // Quick Emoji Access Strip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: _selectedTheme == KeyboardTheme.cyberNeon
                  ? const Color(0xFF161F30)
                  : const Color(0xFFF1F5F9).withValues(alpha: 0.6),
              border: Border(
                top: BorderSide(
                  color: colors.editorBorder.withValues(alpha: 0.6),
                ),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.emoji_emotions_outlined,
                  size: 16,
                  color: Color(0xFF94A3B8),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children:
                          [
                            '👋',
                            '✨',
                            '👍',
                            '❤️',
                            '🔥',
                            '🚀',
                            '😊',
                            '🎉',
                            '💡',
                            '🎯',
                            '💯',
                            '👏',
                            '🙏',
                            '⚡',
                            '☕',
                            '🌟',
                            '😎',
                            '🥳',
                            '🤩',
                            '💐',
                            '🌈',
                            '💎',
                            '🏆',
                            '🍕',
                          ].map((emoji) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                              child: InkWell(
                                onTap: () => _insertText(emoji),
                                borderRadius: BorderRadius.circular(8),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 5,
                                    vertical: 3,
                                  ),
                                  child: Text(
                                    emoji,
                                    style: const TextStyle(fontSize: 17),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                    ),
                  ),
                ),
                InkWell(
                  onTap: _toggleEmojiMode,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _isEmojiMode
                          ? colors.accentColor
                          : colors.accentColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _isEmojiMode ? 'Keys' : 'More',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: _isEmojiMode ? Colors.white : colors.accentColor,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCaseButton(String label, VoidCallback onTap, String tooltip) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Color(0xFF475569),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildKeyboardDeck(
    _ThemeColors colors,
    List<String> row1Keys,
    List<String> row2Keys,
    List<String> row3Keys,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: colors.deckBg,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: colors.deckBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: _isEmojiMode
          ? _buildFullEmojiDeck(colors)
          : Column(
              children: [
                // Deck Status Bar
                Padding(
                  padding: const EdgeInsets.only(bottom: 12, left: 6, right: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          _buildIndicatorPill(
                            label: 'SHIFT',
                            isActive: _isShift && !_isCapsLock,
                            activeColor: colors.accentColor,
                          ),
                          const SizedBox(width: 8),
                          _buildIndicatorPill(
                            label: 'CAPS LOCK',
                            isActive: _isCapsLock,
                            activeColor: const Color(0xFF10B981),
                          ),
                        ],
                      ),
                      Text(
                        _isNumberMode
                            ? 'Symbols & Numbers'
                            : 'Tactile Mechanical Deck',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Row 1 (10 Keys) ──────────────────────────────────────────
                Row(
                  children: row1Keys.map((key) {
                    final isFlashed = _activeFlashedKeys.contains(
                      key.toLowerCase(),
                    );
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3.5),
                        child: _VisualKeycap(
                          keyLabel: key,
                          isFlashed: isFlashed,
                          onTap: () => _insertText(key),
                          baseColor: colors.standardKeyBg,
                          activeColor: colors.standardKeyActive,
                          textColor: colors.standardKeyText,
                          activeTextColor: colors.standardKeyActiveText,
                          shadowColor: colors.keyShadow,
                          glowColor: colors.glowColor,
                          child: Text(
                            key,
                            style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w600,
                              color: isFlashed
                                  ? colors.standardKeyActiveText
                                  : colors.standardKeyText,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 9),

                // ── Row 2 (9 Keys Indented) ──────────────────────────────────
                Row(
                  children: [
                    const Spacer(flex: 1),
                    ...row2Keys.map((key) {
                      final isFlashed = _activeFlashedKeys.contains(
                        key.toLowerCase(),
                      );
                      return Expanded(
                        flex: 2,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3.5),
                          child: _VisualKeycap(
                            keyLabel: key,
                            isFlashed: isFlashed,
                            onTap: () => _insertText(key),
                            baseColor: colors.standardKeyBg,
                            activeColor: colors.standardKeyActive,
                            textColor: colors.standardKeyText,
                            activeTextColor: colors.standardKeyActiveText,
                            shadowColor: colors.keyShadow,
                            glowColor: colors.glowColor,
                            child: Text(
                              key,
                              style: TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w600,
                                color: isFlashed
                                    ? colors.standardKeyActiveText
                                    : colors.standardKeyText,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                    const Spacer(flex: 1),
                  ],
                ),
                const SizedBox(height: 9),

                // ── Row 3 (Shift, 7 Keys, Backspace) ─────────────────────────
                Row(
                  children: [
                    // Shift Key
                    Expanded(
                      flex: 3,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3.5),
                        child: _VisualKeycap(
                          keyLabel: 'Shift',
                          isFlashed: _activeFlashedKeys.contains('shift'),
                          onTap: _toggleShift,
                          isAccented: _isShift || _isCapsLock,
                          showMagnifier: false,
                          baseColor: (_isShift || _isCapsLock)
                              ? colors.accentColor.withValues(alpha: 0.18)
                              : colors.functionKeyBg,
                          activeColor: colors.functionKeyActive,
                          textColor: colors.functionKeyText,
                          activeTextColor: Colors.white,
                          shadowColor: colors.keyShadow,
                          glowColor: colors.glowColor,
                          child: Icon(
                            _isCapsLock
                                ? Icons.arrow_upward_rounded
                                : (_isShift
                                      ? Icons.arrow_upward_rounded
                                      : Icons.keyboard_control_key_rounded),
                            size: 21,
                            color: (_isShift || _isCapsLock)
                                ? colors.accentColor
                                : colors.functionKeyText,
                          ),
                        ),
                      ),
                    ),

                    // Middle Keys
                    ...row3Keys.map((key) {
                      final isFlashed = _activeFlashedKeys.contains(
                        key.toLowerCase(),
                      );
                      return Expanded(
                        flex: 2,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3.5),
                          child: _VisualKeycap(
                            keyLabel: key,
                            isFlashed: isFlashed,
                            onTap: () => _insertText(key),
                            baseColor: colors.standardKeyBg,
                            activeColor: colors.standardKeyActive,
                            textColor: colors.standardKeyText,
                            activeTextColor: colors.standardKeyActiveText,
                            shadowColor: colors.keyShadow,
                            glowColor: colors.glowColor,
                            child: Text(
                              key,
                              style: TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w600,
                                color: isFlashed
                                    ? colors.standardKeyActiveText
                                    : colors.standardKeyText,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),

                    // Backspace Key
                    Expanded(
                      flex: 3,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3.5),
                        child: _VisualKeycap(
                          keyLabel: 'Delete',
                          isFlashed: _activeFlashedKeys.contains('delete'),
                          onTap: _handleBackspace,
                          showMagnifier: false,
                          onLongPressStart: _startContinuousBackspace,
                          onLongPressEnd: _stopContinuousBackspace,
                          baseColor: colors.functionKeyBg,
                          activeColor: colors.functionKeyActive,
                          textColor: colors.functionKeyText,
                          activeTextColor: Colors.white,
                          shadowColor: colors.keyShadow,
                          glowColor: colors.glowColor,
                          child: Icon(
                            Icons.backspace_outlined,
                            size: 19,
                            color: _activeFlashedKeys.contains('delete')
                                ? Colors.white
                                : colors.functionKeyText,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 9),

                // ── Row 4 (123 / ABC, Emoji, Space, Return) ──────────────────
                Row(
                  children: [
                    // 123 / ABC Switch
                    Expanded(
                      flex: 3,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3.5),
                        child: _VisualKeycap(
                          keyLabel: _isNumberMode ? 'ABC' : '123',
                          isFlashed: _activeFlashedKeys.contains(
                            _isNumberMode ? 'abc' : '123',
                          ),
                          onTap: _toggleNumberMode,
                          showMagnifier: false,
                          baseColor: colors.functionKeyBg,
                          activeColor: colors.functionKeyActive,
                          textColor: colors.standardKeyText,
                          activeTextColor: Colors.white,
                          shadowColor: colors.keyShadow,
                          glowColor: colors.glowColor,
                          child: Text(
                            _isNumberMode ? 'ABC' : '123',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color:
                                  _activeFlashedKeys.contains(
                                    _isNumberMode ? 'abc' : '123',
                                  )
                                  ? Colors.white
                                  : colors.standardKeyText,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Emoji toggle keycap
                    Expanded(
                      flex: 2,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3.5),
                        child: _VisualKeycap(
                          keyLabel: 'Emoji',
                          isFlashed: _activeFlashedKeys.contains('emoji'),
                          onTap: _toggleEmojiMode,
                          showMagnifier: false,
                          baseColor: colors.functionKeyBg,
                          activeColor: colors.functionKeyActive,
                          textColor: colors.functionKeyText,
                          activeTextColor: Colors.white,
                          shadowColor: colors.keyShadow,
                          glowColor: colors.glowColor,
                          child: Icon(
                            Icons.emoji_emotions_outlined,
                            size: 20,
                            color: _activeFlashedKeys.contains('emoji')
                                ? Colors.white
                                : colors.functionKeyText,
                          ),
                        ),
                      ),
                    ),

                    // Space Key
                    Expanded(
                      flex: 7,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3.5),
                        child: _VisualKeycap(
                          keyLabel: 'space',
                          isFlashed: _activeFlashedKeys.contains('space'),
                          onTap: () => _insertText(' '),
                          showMagnifier: false,
                          baseColor: colors.standardKeyBg,
                          activeColor: colors.standardKeyActive,
                          textColor: colors.functionKeyText,
                          activeTextColor: colors.standardKeyActiveText,
                          shadowColor: colors.keyShadow,
                          glowColor: colors.glowColor,
                          child: Text(
                            'space',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _activeFlashedKeys.contains('space')
                                  ? colors.standardKeyActiveText
                                  : colors.functionKeyText,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Return Key
                    Expanded(
                      flex: 4,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3.5),
                        child: _VisualKeycap(
                          keyLabel: 'return',
                          isFlashed: _activeFlashedKeys.contains('return'),
                          onTap: () => _insertText('\n'),
                          isAccented: true,
                          showMagnifier: false,
                          baseColor: colors.accentGradient.last,
                          activeColor: colors.accentGradient.first,
                          textColor: Colors.white,
                          activeTextColor: Colors.white,
                          shadowColor: colors.accentGradient.first,
                          glowColor: colors.glowColor,
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'return',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(width: 4),
                              Icon(
                                Icons.keyboard_return_rounded,
                                color: Colors.white,
                                size: 15,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _buildFullEmojiDeck(_ThemeColors colors) {
    final currentCategory = _emojiCategories[_selectedEmojiCategory];
    final emojis = currentCategory['emojis'] as List<String>;

    return Column(
      children: [
        // Category Tabs
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: List.generate(_emojiCategories.length, (idx) {
                    final cat = _emojiCategories[idx];
                    final isSelected = _selectedEmojiCategory == idx;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: InkWell(
                        onTap: () =>
                            setState(() => _selectedEmojiCategory = idx),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? colors.accentColor
                                : colors.standardKeyBg,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                cat['icon'] as IconData,
                                size: 15,
                                color: isSelected
                                    ? Colors.white
                                    : colors.functionKeyText,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                cat['name'] as String,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected
                                      ? Colors.white
                                      : colors.standardKeyText,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
            // Close emoji panel button
            IconButton(
              onPressed: _toggleEmojiMode,
              icon: const Icon(Icons.close_rounded, size: 20),
              color: colors.functionKeyText,
              tooltip: 'Back to Keyboard',
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Emoji Grid
        Container(
          height: 170,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colors.standardKeyBg,
            borderRadius: BorderRadius.circular(16),
          ),
          child: GridView.builder(
            itemCount: emojis.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 10,
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
            ),
            itemBuilder: (context, idx) {
              final emoji = emojis[idx];
              return InkWell(
                onTap: () => _insertText(emoji),
                borderRadius: BorderRadius.circular(8),
                child: Center(
                  child: Text(emoji, style: const TextStyle(fontSize: 22)),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),

        // Bottom switch back button
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _toggleEmojiMode,
                icon: const Icon(Icons.keyboard_outlined, size: 16),
                label: const Text('Return to Keyboard'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.accentColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildIndicatorPill({
    required String label,
    required bool isActive,
    required Color activeColor,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isActive
            ? activeColor.withValues(alpha: 0.15)
            : const Color(0xFFCBD5E1).withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isActive ? activeColor : const Color(0xFFCBD5E1),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: isActive ? activeColor : const Color(0xFF94A3B8),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: isActive ? activeColor : const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemeColors {
  final Color deckBg;
  final Color deckBorder;
  final Color standardKeyBg;
  final Color standardKeyActive;
  final Color standardKeyText;
  final Color standardKeyActiveText;
  final Color functionKeyBg;
  final Color functionKeyActive;
  final Color functionKeyText;
  final Color accentColor;
  final List<Color> accentGradient;
  final Color keyShadow;
  final Color glowColor;
  final Color editorBg;
  final Color editorBorder;
  final Color editorText;

  _ThemeColors({
    required this.deckBg,
    required this.deckBorder,
    required this.standardKeyBg,
    required this.standardKeyActive,
    required this.standardKeyText,
    required this.standardKeyActiveText,
    required this.functionKeyBg,
    required this.functionKeyActive,
    required this.functionKeyText,
    required this.accentColor,
    required this.accentGradient,
    required this.keyShadow,
    required this.glowColor,
    required this.editorBg,
    required this.editorBorder,
    required this.editorText,
  });
}

/// A subtle tactile animated keycap widget with gentle micro-press
/// and soft highlight feedback
class _VisualKeycap extends StatefulWidget {
  final Widget child;
  final String keyLabel;
  final bool isFlashed;
  final VoidCallback onTap;
  final VoidCallback? onLongPressStart;
  final VoidCallback? onLongPressEnd;
  final Color baseColor;
  final Color activeColor;
  final Color textColor;
  final Color activeTextColor;
  final Color shadowColor;
  final Color glowColor;
  final bool isAccented;
  final bool showMagnifier;

  const _VisualKeycap({
    required this.child,
    required this.keyLabel,
    required this.isFlashed,
    required this.onTap,
    this.onLongPressStart,
    this.onLongPressEnd,
    required this.baseColor,
    required this.activeColor,
    required this.textColor,
    required this.activeTextColor,
    required this.shadowColor,
    required this.glowColor,
    this.isAccented = false,
    this.showMagnifier = false,
  });

  @override
  State<_VisualKeycap> createState() => _VisualKeycapState();
}

class _VisualKeycapState extends State<_VisualKeycap> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isDepressed = widget.isFlashed || _isPressed;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      onLongPressStart: widget.onLongPressStart != null
          ? (_) {
              setState(() => _isPressed = true);
              widget.onLongPressStart!();
            }
          : null,
      onLongPressEnd: widget.onLongPressEnd != null
          ? (_) {
              setState(() => _isPressed = false);
              widget.onLongPressEnd!();
            }
          : null,
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: isDepressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 90),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 90),
          curve: Curves.easeOutCubic,
          transform: Matrix4.translationValues(0, isDepressed ? 1.0 : 0.0, 0),
          height: 48,
          decoration: BoxDecoration(
            color: isDepressed ? widget.activeColor : widget.baseColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: widget.isAccented
                  ? Colors.transparent
                  : (isDepressed
                        ? widget.glowColor.withValues(alpha: 0.35)
                        : const Color(0xFFE2E8F0)),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.shadowColor.withValues(
                  alpha: isDepressed ? 0.06 : 0.16,
                ),
                offset: Offset(0, isDepressed ? 0.8 : 2.0),
                blurRadius: isDepressed ? 0.5 : 0.0,
              ),
            ],
          ),
          child: DefaultTextStyle(
            style: TextStyle(
              color: isDepressed ? widget.activeTextColor : widget.textColor,
              fontWeight: FontWeight.w600,
            ),
            child: IconTheme(
              data: IconThemeData(
                color: isDepressed ? widget.activeTextColor : widget.textColor,
                size: 19,
              ),
              child: Center(child: widget.child),
            ),
          ),
        ),
      ),
    );
  }
}
