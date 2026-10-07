import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_theme.dart';

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
  DateTime? _lastShiftTap;
  Timer? _backspaceTimer;

  @override
  void dispose() {
    _backspaceTimer?.cancel();
    _textController.dispose();
    _textFocusNode.dispose();
    super.dispose();
  }

  void _insertText(String textToInsert) {
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

    _textController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newCursorPos),
    );

    // If shift was active (not caps lock), revert back to lowercase
    if (_isShift && !_isCapsLock) {
      setState(() {
        _isShift = false;
      });
    }

    // Keep focus
    _textFocusNode.requestFocus();
  }

  void _handleBackspace() {
    final text = _textController.text;
    final selection = _textController.selection;

    int start = selection.start;
    int end = selection.end;

    if (start < 0 || end < 0) {
      start = text.length;
      end = text.length;
    }

    if (start == end) {
      if (start > 0) {
        final newText = text.replaceRange(start - 1, start, '');
        _textController.value = TextEditingValue(
          text: newText,
          selection: TextSelection.collapsed(offset: start - 1),
        );
      }
    } else {
      final newText = text.replaceRange(start, end, '');
      _textController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: start),
      );
    }

    _textFocusNode.requestFocus();
  }

  void _startContinuousBackspace() {
    _handleBackspace();
    _backspaceTimer?.cancel();
    _backspaceTimer = Timer.periodic(const Duration(milliseconds: 90), (_) {
      _handleBackspace();
    });
  }

  void _stopContinuousBackspace() {
    _backspaceTimer?.cancel();
  }

  void _toggleShift() {
    final now = DateTime.now();
    if (_lastShiftTap != null &&
        now.difference(_lastShiftTap!) < const Duration(milliseconds: 300)) {
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
    setState(() {
      _isNumberMode = !_isNumberMode;
      _isShift = false;
      _isCapsLock = false;
    });
  }

  Future<void> _copyText() async {
    final text = _textController.text;
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nothing to copy. Type some text first.'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
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
              Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Palette matching the uploaded design
    final Color keyboardBg = isDark
        ? const Color(0xFF222630)
        : const Color(0xFFDCE0E8);
    final Color keyBg = isDark ? const Color(0xFF333846) : Colors.white;
    final Color funcKeyBg = isDark
        ? const Color(0xFF2A2F3D)
        : const Color(0xFFB3B9C5);
    final Color keyTextColor = isDark ? Colors.white : const Color(0xFF1E293B);
    const Color returnKeyColor = Color(0xFF2563EB);

    final bool isCapitalized = _isShift || _isCapsLock;

    // Rows configuration
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

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 20.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Top Bar: Title & Copy Text Button ──────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Keyboard',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    InkWell(
                      onTap: _copyText,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? NeumorphicTheme.darkCard
                              : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.12)
                                : const Color(0xFFE2E8F0),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              offset: const Offset(0, 2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.copy_rounded,
                              size: 15,
                              color: isDark
                                  ? Colors.grey.shade300
                                  : const Color(0xFF475569),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Copy Text',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? Colors.grey.shade300
                                    : const Color(0xFF334155),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // ── Text Input Area ─────────────────────────────────────────
                Container(
                  height: 190,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1A1D24) : Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.12)
                          : const Color(0xFFE2E8F0),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        offset: const Offset(0, 3),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    controller: _textController,
                    focusNode: _textFocusNode,
                    maxLines: null,
                    expands: true,
                    style: TextStyle(
                      fontSize: 18,
                      height: 1.4,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                    decoration: InputDecoration(
                      hintText: 'Type here...',
                      hintStyle: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w400,
                        color: isDark
                            ? Colors.grey.shade600
                            : const Color(0xFFCBD5E1),
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // ── Virtual Keyboard ────────────────────────────────────────
                Container(
                  decoration: BoxDecoration(
                    color: keyboardBg,
                    borderRadius: BorderRadius.circular(26),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: isDark ? 0.35 : 0.08,
                        ),
                        offset: const Offset(0, 8),
                        blurRadius: 24,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      // ── Row 1 (10 keys) ───────────────────────────────────
                      Row(
                        children: row1Keys.map((key) {
                          return Expanded(
                            child: _buildStandardKey(
                              label: key,
                              keyBg: keyBg,
                              textColor: keyTextColor,
                              onTap: () => _insertText(key),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 10),

                      // ── Row 2 (9 keys indented) ───────────────────────────
                      Row(
                        children: [
                          const Spacer(flex: 1),
                          ...row2Keys.map((key) {
                            return Expanded(
                              flex: 2,
                              child: _buildStandardKey(
                                label: key,
                                keyBg: keyBg,
                                textColor: keyTextColor,
                                onTap: () => _insertText(key),
                              ),
                            );
                          }),
                          const Spacer(flex: 1),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // ── Row 3 (Shift, 7 keys, Backspace) ──────────────────
                      Row(
                        children: [
                          // Shift Key
                          Expanded(
                            flex: 3,
                            child: _buildFunctionKey(
                              child: Icon(
                                _isCapsLock
                                    ? Icons.arrow_upward_rounded
                                    : (_isShift
                                          ? Icons.arrow_upward_rounded
                                          : Icons.keyboard_control_key_rounded),
                                size: 20,
                                color: _isShift || _isCapsLock
                                    ? (isDark
                                          ? Colors.white
                                          : const Color(0xFF1E293B))
                                    : (isDark
                                          ? Colors.grey.shade400
                                          : const Color(0xFF475569)),
                              ),
                              bgColor: (_isShift || _isCapsLock)
                                  ? (isDark
                                        ? const Color(0xFF475569)
                                        : Colors.white)
                                  : funcKeyBg,
                              onTap: _toggleShift,
                            ),
                          ),
                          const SizedBox(width: 4),

                          // Row 3 Letters/Symbols
                          ...row3Keys.map((key) {
                            return Expanded(
                              flex: 2,
                              child: _buildStandardKey(
                                label: key,
                                keyBg: keyBg,
                                textColor: keyTextColor,
                                onTap: () => _insertText(key),
                              ),
                            );
                          }),
                          const SizedBox(width: 4),

                          // Backspace Key
                          Expanded(
                            flex: 3,
                            child: GestureDetector(
                              onLongPressStart: (_) =>
                                  _startContinuousBackspace(),
                              onLongPressEnd: (_) => _stopContinuousBackspace(),
                              child: _buildFunctionKey(
                                child: Icon(
                                  Icons.backspace_outlined,
                                  size: 19,
                                  color: isDark
                                      ? Colors.grey.shade300
                                      : const Color(0xFF334155),
                                ),
                                bgColor: funcKeyBg,
                                onTap: _handleBackspace,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // ── Row 4 (123, space, return) ────────────────────────
                      Row(
                        children: [
                          // 123 / ABC Toggle
                          Expanded(
                            flex: 3,
                            child: _buildFunctionKey(
                              child: Text(
                                _isNumberMode ? 'ABC' : '123',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF1E293B),
                                ),
                              ),
                              bgColor: funcKeyBg,
                              onTap: _toggleNumberMode,
                            ),
                          ),
                          const SizedBox(width: 6),

                          // Space Key
                          Expanded(
                            flex: 8,
                            child: _buildStandardKey(
                              label: 'space',
                              keyBg: keyBg,
                              textColor: isDark
                                  ? Colors.grey.shade300
                                  : const Color(0xFF334155),
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              onTap: () => _insertText(' '),
                            ),
                          ),
                          const SizedBox(width: 6),

                          // Return Key
                          Expanded(
                            flex: 4,
                            child: _buildFunctionKey(
                              child: const Text(
                                'return',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              bgColor: returnKeyColor,
                              onTap: () => _insertText('\n'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStandardKey({
    required String label,
    required Color keyBg,
    required Color textColor,
    required VoidCallback onTap,
    double fontSize = 20,
    FontWeight fontWeight = FontWeight.w400,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3.0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          borderRadius: BorderRadius.circular(9),
          child: Ink(
            height: 48,
            decoration: BoxDecoration(
              color: keyBg,
              borderRadius: BorderRadius.circular(9),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  offset: const Offset(0, 1.5),
                  blurRadius: 1,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: fontWeight,
                  color: textColor,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFunctionKey({
    required Widget child,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2.0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          borderRadius: BorderRadius.circular(9),
          child: Ink(
            height: 48,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(9),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  offset: const Offset(0, 1.5),
                  blurRadius: 1,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}
