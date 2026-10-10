import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:flutter/services.dart';
import 'widgets/currency_converter_widget.dart';
import 'package:provider/provider.dart';
import '../../core/providers/app_providers.dart';
import '../../core/models/calculator_models.dart';
import '../../core/widgets/neumorphic_widgets.dart';
import 'widgets/cross_app_history_widget.dart';
import 'models/cross_app_history_models.dart';

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  final ScrollController _tapeScrollController = ScrollController();
  bool _showHistoryList = false;
  int _mobileTab = 0; // 0: Calculator, 1: Cross-App History

  @override
  void dispose() {
    _tapeScrollController.dispose();
    super.dispose();
  }

  void _loadCrossAppTape(CrossAppTape tape, CalculatorProvider calc) {
    calc.loadFromCrossAppTape(tape);
    _scrollTapeToBottom();
  }

  void _scrollTapeToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_tapeScrollController.hasClients) {
        _tapeScrollController.animateTo(
          _tapeScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final calcProvider = Provider.of<CalculatorProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isDesktop = constraints.maxWidth >= 880;

        if (isDesktop) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Left: Cross-App History ──
              SizedBox(
                width: 320,
                child: CrossAppHistoryWidget(
                  onLoadTape: (tape) => _loadCrossAppTape(tape, calcProvider),
                ),
              ),
              const SizedBox(width: 16),

              // ── Right: Compact Before Calculator Card ──
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: calcProvider.activeMode == CalcMode.currency ? 640 : 480,
                    ),
                    child: _buildCalculatorCard(
                      context,
                      calcProvider,
                      isDark,
                      primaryColor,
                      onSurface,
                    ),
                  ),
                ),
              ),
            ],
          );
        } else {
          // Mobile / Narrow Layout with Top Switcher
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF334155)
                        : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _mobileTab = 0),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: _mobileTab == 0
                                ? primaryColor
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Calculator',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: _mobileTab == 0
                                  ? Colors.white
                                  : (isDark
                                        ? const Color(0xFF94A3B8)
                                        : const Color(0xFF64748B)),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _mobileTab = 1),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: _mobileTab == 1
                                ? primaryColor
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Cross-App History',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: _mobileTab == 1
                                  ? Colors.white
                                  : (isDark
                                        ? const Color(0xFF94A3B8)
                                        : const Color(0xFF64748B)),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _mobileTab == 0
                    ? _buildCalculatorCard(
                        context,
                        calcProvider,
                        isDark,
                        primaryColor,
                        onSurface,
                      )
                    : CrossAppHistoryWidget(
                        onLoadTape: (tape) {
                          _loadCrossAppTape(tape, calcProvider);
                          setState(() => _mobileTab = 0);
                        },
                      ),
              ),
            ],
          );
        }
      },
    );
  }

  Widget _buildCalculatorCard(
    BuildContext context,
    CalculatorProvider calcProvider,
    bool isDark,
    Color primaryColor,
    Color onSurface,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header: # BETA CALC [Save] [Logs] [Share] [Clear] ──
          _buildHeader(context, calcProvider, isDark, primaryColor),

          Divider(
            height: 1,
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 14.0,
                vertical: 12.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── History Sections (Togglable) ──
                  if (_showHistoryList &&
                      calcProvider.historySections.isNotEmpty) ...[
                    const Text(
                      'Calculation Logs',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildHistorySectionsList(
                      context,
                      calcProvider,
                      isDark,
                      primaryColor,
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16),
                  ],

                  // ── Mode-specific view routing ──
                  if (calcProvider.activeMode == CalcMode.currency) ...[
                    // ── Mode Tabs ──
                    _buildModeTabs(context, calcProvider, isDark, primaryColor),
                    const SizedBox(height: 12),
                    // ── Live Two-Sided Currency Converter ──
                    const CurrencyConverterWidget(),
                    const SizedBox(height: 8),
                  ] else ...[
                    // ── SET BASE ──
                    if (!calcProvider.hasBase) ...[
                      _buildSetBase(
                        context,
                        calcProvider,
                        isDark,
                        primaryColor,
                        onSurface,
                      ),
                      const SizedBox(height: 8),
                    ],

                    // ── Tape Entries ──
                    if (calcProvider.tapeEntries.isNotEmpty) ...[
                      _buildTapeList(context, calcProvider, isDark, primaryColor),
                      const SizedBox(height: 8),
                    ],

                    // ── CONTINUE section ──
                    if (calcProvider.hasBase)
                      _buildContinueSection(
                        context,
                        calcProvider,
                        isDark,
                        onSurface,
                      ),

                    const SizedBox(height: 8),

                    // ── Mode Tabs ──
                    _buildModeTabs(context, calcProvider, isDark, primaryColor),

                    const SizedBox(height: 6),

                    // ── Mode-specific content ──
                    _buildModeContent(
                      context,
                      calcProvider,
                      isDark,
                      primaryColor,
                    ),

                    const SizedBox(height: 8),

                    // ── Number Pad ──
                    _buildNumberPad(
                      context,
                      calcProvider,
                      isDark,
                      primaryColor,
                      onSurface,
                    ),

                    const SizedBox(height: 10),

                    // ── Total Bar ──
                    _buildTotalBar(context, calcProvider, isDark, primaryColor),
                    const SizedBox(height: 8),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // HEADER — ✦ BETA CALC  [↻] [⤴] [🗑] [✕]
  // ═══════════════════════════════════════════════════════════
  Widget _buildHeader(
    BuildContext context,
    CalculatorProvider calc,
    bool isDark,
    Color primary,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        children: [
          const Text(
            '#',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Color(0xFF10B981),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'BETA CALC',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const Spacer(),
          if (calc.activeMode != CalcMode.currency) ...[
            if (calc.isSavingTape || calc.isSavingCompare)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.0),
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else
              _headerAction(Icons.save_alt_rounded, 'Save to Cloud History', () async {
                if (calc.activeMode == CalcMode.compare) {
                  if (calc.comparisonRows.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('No comparison rows to save')),
                    );
                    return;
                  }
                  calc.saveCurrentToHistory();
                  try {
                    await calc.saveCompareSession();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Comparison session saved successfully'),
                          backgroundColor: Color(0xFF10B981),
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to save comparison: $e'),
                          backgroundColor: Colors.red.shade700,
                        ),
                      );
                    }
                  }
                } else {
                  if (calc.tapeEntries.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('No tape entries to save')),
                    );
                    return;
                  }
                  calc.saveCurrentToHistory();
                  try {
                    await calc.saveTapeSession();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Tape session saved successfully'),
                          backgroundColor: Color(0xFF10B981),
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to save tape session: $e'),
                          backgroundColor: Colors.red.shade700,
                        ),
                      );
                    }
                  }
                }
              }),
          ],
          _headerAction(
            _showHistoryList
                ? Icons.history_toggle_off_rounded
                : Icons.history_rounded,
            'Toggle Logs',
            () {
              setState(() {
                _showHistoryList = !_showHistoryList;
              });
            },
          ),
          _headerAction(Icons.share_outlined, 'Share', () {
            final summary = calc.copyTapeSummary();
            Clipboard.setData(ClipboardData(text: summary));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Log summary copied to clipboard')),
            );
          }),
          _headerAction(
            Icons.delete_outline,
            'Clear',
            () => calc.clearAll(),
            iconColor: Colors.red.shade400,
          ),
        ],
      ),
    );
  }

  Widget _headerAction(
    IconData icon,
    String tooltip,
    VoidCallback onTap, {
    Color? iconColor,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(6.0),
          child: Icon(icon, size: 18, color: iconColor ?? Colors.grey.shade600),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // SET BASE — input field with "SET BASE" label
  // ═══════════════════════════════════════════════════════════
  Widget _buildSetBase(
    BuildContext context,
    CalculatorProvider calc,
    bool isDark,
    Color primary,
    Color onSurface,
  ) {
    return NeumorphicCard(
      borderRadius: 14,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        children: [
          Text(
            'SET BASE',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade500,
              letterSpacing: 0.5,
            ),
          ),
          const Spacer(),
          Text(
            calc.currentInput == '0' ? '0' : calc.currentInput,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: onSurface,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // HISTORY SECTIONS — Groups of past calculations/comparisons
  // ═══════════════════════════════════════════════════════════
  Widget _buildHistorySectionsList(
    BuildContext context,
    CalculatorProvider calc,
    bool isDark,
    Color primary,
  ) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: calc.historySections.length,
      itemBuilder: (context, i) {
        final section = calc.historySections[i];
        final timeStr =
            '${section.timestamp.hour.toString().padLeft(2, '0')}:${section.timestamp.minute.toString().padLeft(2, '0')}:${section.timestamp.second.toString().padLeft(2, '0')} ${section.timestamp.hour >= 12 ? 'PM' : 'AM'}';
        final isComparison = section.type == CalculationType.comparison;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: NeumorphicCard(
            borderRadius: 16,
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isComparison
                              ? Icons.compare_arrows_rounded
                              : Icons.history_rounded,
                          size: 14,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          timeStr,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '${isComparison ? section.comparisonRows!.length : section.tapeEntries!.length} Items',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isComparison
                                ? 'PRICE COMPARISON LOG'
                                : 'CALCULATED LOG',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${calc.getCurrencySymbol()}${section.totalValue.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    NeumorphicButton(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      borderRadius: 8,
                      color: Colors.teal.shade400,
                      onPressed: () => calc.restoreHistorySection(section.id),
                      child: const Text(
                        'RESTORE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        final summary = calc.copySectionSummary(section.id);
                        Clipboard.setData(ClipboardData(text: summary));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Log copied to clipboard'),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          Icons.share_rounded,
                          size: 16,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => calc.deleteHistorySection(section.id),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          Icons.delete_outline_rounded,
                          size: 16,
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════
  // TAPE LIST — scrollable list of tape entries
  // ═══════════════════════════════════════════════════════════
  Widget _buildTapeList(
    BuildContext context,
    CalculatorProvider calc,
    bool isDark,
    Color primary,
  ) {
    _scrollTapeToBottom();
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 200),
      child: ListView.builder(
        controller: _tapeScrollController,
        shrinkWrap: true,
        itemCount: calc.tapeEntries.length,
        itemBuilder: (context, i) {
          final entry = calc.tapeEntries[i];
          return _buildTapeEntryWidget(
            context,
            calc,
            entry,
            i,
            isDark,
            primary,
          );
        },
      ),
    );
  }

  Widget _buildTapeEntryWidget(
    BuildContext context,
    CalculatorProvider calc,
    TapeEntry entry,
    int index,
    bool isDark,
    Color primary,
  ) {
    final currencySymbol = calc.getCurrencySymbol();
    final displayTotal = calc.currencyType == CurrencyType.usd
        ? entry.runningTotal / calc.simulatedUsdRate
        : entry.runningTotal;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Main entry row
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // BASE chip or operator
              if (entry.isBase) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF16A34A),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'BASE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Base Amount',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ),
              ] else ...[
                const SizedBox(width: 4),
                Expanded(
                  child: Row(
                    children: [
                      if (entry.presetTag != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: entry.operator == '+'
                                ? const Color(0xFF16A34A).withValues(alpha: 0.1)
                                : Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            entry.presetTag!,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: entry.operator == '+'
                                  ? const Color(0xFF16A34A)
                                  : Colors.red,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),

          Padding(
            padding: const EdgeInsets.only(left: 4, top: 2),
            child: Row(
              children: [
                Text(
                  entry.isBase ? '= ' : '${entry.operator} ',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _formatDisplay(entry.value),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text(
                      '$currencySymbol${_formatDisplay(displayTotal)}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => calc.removeTapeEntry(index),
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Icon(
                      Icons.close,
                      size: 14,
                      color: Colors.red.shade400,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Label row
          Padding(
            padding: const EdgeInsets.only(left: 4, top: 2, bottom: 4),
            child: _buildLabelRow(context, calc, entry, index, isDark),
          ),

          Divider(height: 1, color: Colors.grey.withValues(alpha: 0.15)),
        ],
      ),
    );
  }

  Widget _buildLabelRow(
    BuildContext context,
    CalculatorProvider calc,
    TapeEntry entry,
    int index,
    bool isDark,
  ) {
    if (entry.label != null && entry.label!.isNotEmpty) {
      return Row(
        children: [
          Icon(Icons.label_outline, size: 13, color: Colors.grey.shade500),
          const SizedBox(width: 4),
          Text(
            entry.label!,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade500,
              fontStyle: FontStyle.italic,
            ),
          ),
          const Spacer(),
          InkWell(
            onTap: () => calc.addLabel(index, ''),
            child: Icon(Icons.close, size: 12, color: Colors.grey.shade400),
          ),
        ],
      );
    }

    return InkWell(
      onTap: () => _showLabelDialog(context, calc, index),
      child: Row(
        children: [
          Icon(Icons.edit_outlined, size: 13, color: Colors.grey.shade400),
          const SizedBox(width: 4),
          Text(
            'Add label...',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }

  void _showLabelDialog(
    BuildContext context,
    CalculatorProvider calc,
    int index,
  ) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'Add Label',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Enter label...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              calc.addLabel(index, controller.text);
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // CONTINUE SECTION — shows current input being built
  // ═══════════════════════════════════════════════════════════
  Widget _buildContinueSection(
    BuildContext context,
    CalculatorProvider calc,
    bool isDark,
    Color onSurface,
  ) {
    return NeumorphicCard(
      borderRadius: 14,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CONTINUE',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade500,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Text(
                calc.pendingOperator,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade500,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    calc.currentInput,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: onSurface,
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

  // ═══════════════════════════════════════════════════════════
  // MODE TABS — GST | Discount | USD/INR | Compare
  // ═══════════════════════════════════════════════════════════
  Widget _buildModeTabs(
    BuildContext context,
    CalculatorProvider calc,
    bool isDark,
    Color primary,
  ) {
    return Row(
      children: [
        _modeTab(
          context,
          calc,
          CalcMode.gst,
          '% GST',
          Icons.percent,
          primary,
          isDark,
        ),
        const SizedBox(width: 6),
        _modeTab(
          context,
          calc,
          CalcMode.discount,
          'Discount',
          Icons.local_offer_outlined,
          const Color(0xFFEA580C),
          isDark,
        ),
        const SizedBox(width: 6),
        _modeTab(
          context,
          calc,
          CalcMode.currency,
          'INR',
          Icons.currency_rupee,
          primary,
          isDark,
        ),
        const SizedBox(width: 6),
        _modeTab(
          context,
          calc,
          CalcMode.compare,
          'Compare',
          Icons.compare_arrows,
          primary,
          isDark,
        ),
      ],
    );
  }

  Widget _modeTab(
    BuildContext context,
    CalculatorProvider calc,
    CalcMode mode,
    String label,
    IconData icon,
    Color activeColor,
    bool isDark,
  ) {
    final isActive = calc.activeMode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          calc.setMode(mode);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 2),
          decoration: BoxDecoration(
            color: isActive
                ? (mode == CalcMode.discount
                      ? const Color(0xFFEA580C)
                      : activeColor)
                : (isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.grey.shade200),
            borderRadius: BorderRadius.circular(14),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 12,
                  color: isActive ? Colors.white : Colors.grey.shade600,
                ),
                const SizedBox(width: 3),
                Text(
                  label,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: isActive ? Colors.white : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // MODE CONTENT — contextual presets / comparison table
  // ═══════════════════════════════════════════════════════════
  Widget _buildModeContent(
    BuildContext context,
    CalculatorProvider calc,
    bool isDark,
    Color primary,
  ) {
    switch (calc.activeMode) {
      case CalcMode.gst:
        return _buildPresetRow(
          context,
          calc,
          presets: [5, 12, 18, 28],
          isGst: true,
          color: const Color(0xFF16A34A),
        );
      case CalcMode.discount:
        return _buildPresetRow(
          context,
          calc,
          presets: [5, 10, 20, 50],
          isGst: false,
          color: Colors.red.shade600,
        );
      case CalcMode.currency:
        return const SizedBox(
          height: 4,
        ); // Currency mode just toggles the total display
      case CalcMode.compare:
        return _buildComparisonTable(context, calc, isDark, primary);
    }
  }

  Widget _buildPresetRow(
    BuildContext context,
    CalculatorProvider calc, {
    required List<int> presets,
    required bool isGst,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: presets.map((p) {
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: GestureDetector(
                onTap: () {
                  if (isGst) {
                    calc.applyGstPreset(p.toDouble());
                  } else {
                    calc.applyDiscountPreset(p.toDouble());
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: color.withValues(alpha: 0.3)),
                  ),
                  child: Center(
                    child: Text(
                      isGst ? '+$p%' : '-$p%',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // PRICE COMPARISON TABLE — Dynamic Multi-Side Comparison
  // ═══════════════════════════════════════════════════════════
  Color _getSideColor(String side) {
    switch (side.toUpperCase()) {
      case 'A':
        return const Color(0xFF2563EB); // Royal Blue
      case 'B':
        return const Color(0xFF7C3AED); // Vivid Purple
      case 'C':
        return const Color(0xFFEA580C); // Warm Orange
      case 'D':
        return const Color(0xFF0D9488); // Deep Teal
      case 'E':
        return const Color(0xFFE11D48); // Rose / Crimson
      case 'F':
        return const Color(0xFF4F46E5); // Indigo
      default:
        return const Color(0xFF64748B);
    }
  }

  Widget _buildComparisonTable(
    BuildContext context,
    CalculatorProvider calc,
    bool isDark,
    Color primary,
  ) {
    return NeumorphicCard(
      borderRadius: 16,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header Row ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(Icons.compare_arrows_rounded, size: 14, color: primary),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'PRICE COMPARISON',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: primary,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.black.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${calc.comparisonRows.length} ${calc.comparisonRows.length == 1 ? 'item' : 'items'}',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.grey.shade300 : Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (calc.comparisonSides.length < 6)
                    Tooltip(
                      message: 'Add side to comparison (Side ${String.fromCharCode(65 + calc.comparisonSides.length)})',
                      child: InkWell(
                        borderRadius: BorderRadius.circular(6),
                        onTap: () => calc.addComparisonSide(),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                          margin: const EdgeInsets.only(right: 6),
                          decoration: BoxDecoration(
                            color: primary.withValues(alpha: isDark ? 0.18 : 0.1),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: primary.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.add_rounded, size: 11, color: primary),
                              const SizedBox(width: 2),
                              Text(
                                '+ Side',
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                  color: primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  if (calc.comparisonRows.isNotEmpty)
                    Tooltip(
                      message: 'Clear all items',
                      child: InkWell(
                        borderRadius: BorderRadius.circular(6),
                        onTap: () => calc.clearComparisonRows(),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.delete_sweep_outlined,
                                size: 13,
                                color: Colors.red.shade400,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                'Clear',
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.red.shade400,
                                ),
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
          const SizedBox(height: 10),

          // ── Executive Analysis Banner ──
          if (calc.comparisonRows.isNotEmpty) ...[
            Builder(
              builder: (context) {
                final totals = <String, double>{};
                final counts = <String, int>{};
                for (final side in calc.comparisonSides) {
                  totals[side] = 0.0;
                  counts[side] = 0;
                }
                for (var r in calc.comparisonRows) {
                  for (final side in calc.comparisonSides) {
                    final val = r.getValue(side);
                    if (val != null) {
                      totals[side] = (totals[side] ?? 0.0) + r.getFinal(side);
                      counts[side] = (counts[side] ?? 0) + 1;
                    }
                  }
                }

                final activeSidesWithData = calc.comparisonSides
                    .where((s) => (counts[s] ?? 0) > 0 && (totals[s] ?? 0) > 0)
                    .toList();

                if (activeSidesWithData.isNotEmpty) {
                  String analysisMsg = '';
                  String headline = '';
                  Color bannerColor = Colors.grey.shade500;
                  IconData bannerIcon = Icons.info_outline_rounded;
                  double diff = 0.0;

                  if (activeSidesWithData.length == 1) {
                    final s = activeSidesWithData.first;
                    headline = 'Side $s total: ${_formatDisplay(totals[s]!)}';
                    analysisMsg = 'Enter prices on other sides to compare';
                    bannerColor = primary;
                    bannerIcon = Icons.info_outline_rounded;
                  } else if (activeSidesWithData.length == 2 && calc.comparisonSides.length == 2) {
                    // Exact backward compatibility for Side A and Side B
                    final totalA = totals['A'] ?? 0.0;
                    final totalB = totals['B'] ?? 0.0;
                    diff = (totalA - totalB).abs();

                    if (totalA < totalB && totalA > 0) {
                      final percent = ((totalB - totalA) / totalB * 100).toStringAsFixed(0);
                      headline = 'Side A is cheaper by $percent%';
                      analysisMsg =
                          'Side A is cheaper by $percent% (A: ${_formatDisplay(totalA)} vs B: ${_formatDisplay(totalB)})';
                      bannerColor = const Color(0xFF16A34A);
                      bannerIcon = Icons.trending_down_rounded;
                    } else if (totalB < totalA && totalB > 0) {
                      final percent = ((totalA - totalB) / totalA * 100).toStringAsFixed(0);
                      headline = 'Side B is cheaper by $percent%';
                      analysisMsg =
                          'Side B is cheaper by $percent% (B: ${_formatDisplay(totalB)} vs A: ${_formatDisplay(totalA)})';
                      bannerColor = const Color(0xFF16A34A);
                      bannerIcon = Icons.trending_down_rounded;
                    } else if (totalA == totalB && totalA > 0) {
                      headline = 'Both sides are equal';
                      analysisMsg = 'Both Side A and Side B are equal';
                      bannerColor = primary;
                      bannerIcon = Icons.balance_rounded;
                    } else {
                      headline = 'Enter item prices to compare';
                      analysisMsg = 'Enter prices to compare';
                    }
                  } else {
                    // Multi-side dynamic comparison (3+ sides or multiple sides active)
                    final sorted = List<String>.from(activeSidesWithData)
                      ..sort((a, b) => totals[a]!.compareTo(totals[b]!));
                    final bestSide = sorted.first;
                    final bestTotal = totals[bestSide]!;
                    final secondBestSide = sorted[1];
                    final secondBestTotal = totals[secondBestSide]!;
                    final worstTotal = totals[sorted.last]!;

                    if (bestTotal == worstTotal) {
                      headline = 'All sides are equal';
                      analysisMsg = 'All sides equal at ${_formatDisplay(bestTotal)}';
                      bannerColor = primary;
                      bannerIcon = Icons.balance_rounded;
                    } else {
                      diff = secondBestTotal - bestTotal;
                      final percent = ((secondBestTotal - bestTotal) / secondBestTotal * 100).toStringAsFixed(0);
                      headline = 'Side $bestSide is cheapest by $percent%';
                      final breakdown = sorted
                          .map((s) => '$s: ${_formatDisplay(totals[s]!)}')
                          .join(' vs ');
                      analysisMsg = 'Side $bestSide is cheapest ($breakdown)';
                      bannerColor = const Color(0xFF16A34A);
                      bannerIcon = Icons.trending_down_rounded;
                    }
                  }

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                      color: bannerColor.withValues(alpha: isDark ? 0.14 : 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: bannerColor.withValues(alpha: 0.28),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: bannerColor.withValues(alpha: 0.18),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(bannerIcon, size: 14, color: bannerColor),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                headline,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: bannerColor,
                                ),
                              ),
                              Text(
                                analysisMsg,
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w500,
                                  color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (diff > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: bannerColor.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Save ${_formatDisplay(diff)}',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                color: bannerColor,
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],

          // ── Responsive Multi-Column Table Layout ──
          LayoutBuilder(
            builder: (context, constraints) {
              final sideCount = calc.comparisonSides.length;
              final minTableWidth = sideCount <= 3
                  ? constraints.maxWidth
                  : math.max(constraints.maxWidth, 110.0 + (sideCount * 76.0) + 28.0);
              final isHorizScrollable = minTableWidth > constraints.maxWidth;

              Widget tableContent = SizedBox(
                width: isHorizScrollable ? minTableWidth : constraints.maxWidth,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Table Header (Strictly synchronized with data columns) ──
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.04)
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Text(
                              'Description',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                          for (final side in calc.comparisonSides) ...[
                            Expanded(
                              flex: 2,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 14,
                                    height: 14,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: _getSideColor(side).withValues(alpha: 0.15),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Text(
                                      side,
                                      style: TextStyle(
                                        fontSize: 8.5,
                                        fontWeight: FontWeight.w900,
                                        color: _getSideColor(side),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      'Side $side',
                                      textAlign: TextAlign.center,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ),
                                  if (calc.comparisonSides.length > 2 && side != 'A' && side != 'B') ...[
                                    const SizedBox(width: 2),
                                    Tooltip(
                                      message: 'Remove Side $side',
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(8),
                                        onTap: () => calc.removeComparisonSide(side),
                                        child: Padding(
                                          padding: const EdgeInsets.all(2.0),
                                          child: Icon(
                                            Icons.close_rounded,
                                            size: 11,
                                            color: Colors.red.shade400,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                          // Action column spacer to match delete button width
                          const SizedBox(width: 28),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),

                    // ── Table Rows ──
                    if (calc.comparisonRows.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.compare_arrows_rounded,
                                size: 26,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'No comparison items yet.\nAdd items below to see side-by-side analysis.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey.shade400,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ...calc.comparisonRows.asMap().entries.map((e) {
                        final idx = e.key;
                        final row = e.value;
                        final isEven = idx % 2 == 0;

                        final sidesWithVal = calc.comparisonSides
                            .where((s) => row.getValue(s) != null)
                            .toList();
                        final hasMultipleVals = sidesWithVal.length >= 2;
                        double? minFinal;
                        double? maxFinal;
                        if (hasMultipleVals) {
                          minFinal = sidesWithVal.map((s) => row.getFinal(s)).reduce(math.min);
                          maxFinal = sidesWithVal.map((s) => row.getFinal(s)).reduce(math.max);
                        }

                        final hasCustomModifiers = calc.comparisonSides.any((s) {
                          return row.getQty(s) != 1.0 || row.getDiscount(s) > 0;
                        });

                        return Container(
                          margin: const EdgeInsets.only(bottom: 3),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: isEven ? 0.03 : 0.01)
                                : (isEven ? const Color(0xFFF8FAFC) : Colors.transparent),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.04)
                                  : Colors.black.withValues(alpha: 0.02),
                            ),
                          ),
                          child: Row(
                            children: [
                              // Column 1: Description
                              Expanded(
                                flex: 3,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      row.description.isEmpty ? '—' : row.description,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Theme.of(context).colorScheme.onSurface,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    if (hasCustomModifiers)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 2),
                                        child: Wrap(
                                          spacing: 4,
                                          runSpacing: 2,
                                          children: calc.comparisonSides.where((s) {
                                            return row.getQty(s) != 1.0 || row.getDiscount(s) > 0;
                                          }).map((s) {
                                            final qty = row.getQty(s);
                                            final disc = row.getDiscount(s);
                                            final sideColor = _getSideColor(s);
                                            return Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 4,
                                                vertical: 1,
                                              ),
                                              decoration: BoxDecoration(
                                                color: sideColor.withValues(alpha: 0.08),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                '$s: ${qty.toInt()}×${disc > 0 ? ' (-${disc.toInt()}%)' : ''}',
                                                style: TextStyle(
                                                  fontSize: 8.5,
                                                  fontWeight: FontWeight.w700,
                                                  color: sideColor,
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                        ),
                                      )
                                    else
                                      Text(
                                        calc.comparisonSides.length == 2
                                            ? 'Qty: A:${row.qtyA.toInt()} B:${row.qtyB.toInt()} | Disc: A:${row.discountA.toInt()}% B:${row.discountB.toInt()}%'
                                            : '${calc.comparisonSides.map((s) => '$s:${row.getQty(s).toInt()}').join(' ')} | Disc 0%',
                                        style: TextStyle(
                                          fontSize: 8.5,
                                          color: Colors.grey.shade500,
                                        ),
                                      ),
                                  ],
                                ),
                              ),

                              // Side Columns
                              for (final side in calc.comparisonSides) ...[
                                Expanded(
                                  flex: 2,
                                  child: Builder(
                                    builder: (context) {
                                      final val = row.getValue(side);
                                      final finalVal = row.getFinal(side);
                                      final isCheapest = hasMultipleVals &&
                                          minFinal != null &&
                                          maxFinal != null &&
                                          minFinal < maxFinal &&
                                          finalVal == minFinal &&
                                          val != null;

                                      return Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isCheapest
                                                  ? const Color(0xFF16A34A).withValues(alpha: 0.12)
                                                  : Colors.transparent,
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              val != null ? _formatDisplay(finalVal) : '—',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: isCheapest
                                                    ? FontWeight.w800
                                                    : FontWeight.w600,
                                                color: isCheapest
                                                    ? const Color(0xFF16A34A)
                                                    : Theme.of(context).colorScheme.onSurface,
                                              ),
                                            ),
                                          ),
                                          if (val != null && (row.getQty(side) != 1 || row.getDiscount(side) > 0))
                                            Text(
                                              '@ ${_formatDisplay(val)}',
                                              style: TextStyle(
                                                fontSize: 8,
                                                color: Colors.grey.shade500,
                                              ),
                                            ),
                                        ],
                                      );
                                    },
                                  ),
                                ),
                              ],

                              // Delete button column
                              SizedBox(
                                width: 28,
                                height: 28,
                                child: Tooltip(
                                  message: 'Remove row',
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(14),
                                    onTap: () => calc.removeComparisonRow(idx),
                                    child: Icon(
                                      Icons.close_rounded,
                                      size: 14,
                                      color: Colors.red.shade400,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),

                    const SizedBox(height: 6),

                    // ── Totals Sum Row (Elevated & synchronized with columns) ──
                    Builder(
                      builder: (context) {
                        final totals = <String, double>{};
                        for (final s in calc.comparisonSides) {
                          totals[s] = 0.0;
                        }
                        for (var r in calc.comparisonRows) {
                          for (final s in calc.comparisonSides) {
                            if (r.getValue(s) != null) {
                              totals[s] = (totals[s] ?? 0.0) + r.getFinal(s);
                            }
                          }
                        }

                        final positiveTotals = calc.comparisonSides
                            .where((s) => (totals[s] ?? 0.0) > 0.0)
                            .toList();
                        final hasMultiplePositives = positiveTotals.length >= 2;
                        double? minTotal;
                        double? maxTotal;
                        if (hasMultiplePositives) {
                          minTotal = positiveTotals.map((s) => totals[s]!).reduce(math.min);
                          maxTotal = positiveTotals.map((s) => totals[s]!).reduce(math.max);
                        }

                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.05)
                                : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.08)
                                  : const Color(0xFFCBD5E1),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.receipt_long_rounded,
                                      size: 13,
                                      color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Total Sum',
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w800,
                                        color: isDark ? Colors.grey.shade200 : Colors.grey.shade800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              for (final side in calc.comparisonSides) ...[
                                Expanded(
                                  flex: 2,
                                  child: Builder(
                                    builder: (context) {
                                      final sideTotal = totals[side] ?? 0.0;
                                      final isCheapest = hasMultiplePositives &&
                                          minTotal != null &&
                                          maxTotal != null &&
                                          minTotal < maxTotal &&
                                          sideTotal == minTotal;

                                      return Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 4,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isCheapest
                                              ? const Color(0xFF16A34A).withValues(alpha: 0.15)
                                              : Colors.transparent,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          _formatDisplay(sideTotal),
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w800,
                                            color: isCheapest
                                                ? const Color(0xFF16A34A)
                                                : (isDark ? Colors.grey.shade200 : Colors.grey.shade900),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                              const SizedBox(width: 28),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 8),

                    // ── Add Item Row Input (Clean, modern, aligned) ──
                    _ComparisonAddRow(calc: calc),
                  ],
                ),
              );

              if (isHorizScrollable) {
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: tableContent,
                );
              }
              return tableContent;
            },
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // NUMBER PAD — matches image layout
  // ═══════════════════════════════════════════════════════════
  Widget _buildNumberPad(
    BuildContext context,
    CalculatorProvider calc,
    bool isDark,
    Color primary,
    Color onSurface,
  ) {
    if (calc.showScientific) {
      return _buildScientificPad(context, calc, isDark, primary, onSurface);
    }

    return Column(
      children: [
        // Row 1: ↺  ⌫  /  ×
        Row(
          children: [
            _padButton(
              context,
              calc,
              label: '↺',
              textColor: const Color(0xFFEA580C),
              onTap: () => calc.clearAll(),
              onSurface: onSurface,
            ),
            _padButton(
              context,
              calc,
              icon: Icons.backspace_outlined,
              textColor: Colors.grey.shade600,
              onTap: () => calc.backspace(),
              onSurface: onSurface,
            ),
            _padButton(
              context,
              calc,
              label: '/',
              textColor: primary,
              onTap: () => calc.setOperator('÷'),
              onSurface: onSurface,
            ),
            _padButton(
              context,
              calc,
              label: '×',
              textColor: Colors.red,
              onTap: () => calc.setOperator('×'),
              onSurface: onSurface,
            ),
          ],
        ),
        const SizedBox(height: 6),
        // Row 2: 7 8 9 -
        Row(
          children: [
            _padButton(
              context,
              calc,
              label: '7',
              onTap: () => calc.enterDigit('7'),
              onSurface: onSurface,
            ),
            _padButton(
              context,
              calc,
              label: '8',
              onTap: () => calc.enterDigit('8'),
              onSurface: onSurface,
            ),
            _padButton(
              context,
              calc,
              label: '9',
              onTap: () => calc.enterDigit('9'),
              onSurface: onSurface,
            ),
            _padButton(
              context,
              calc,
              label: '-',
              textColor: primary,
              onTap: () => calc.setOperator('-'),
              onSurface: onSurface,
            ),
          ],
        ),
        const SizedBox(height: 6),
        // Row 3: 4 5 6 +
        Row(
          children: [
            _padButton(
              context,
              calc,
              label: '4',
              onTap: () => calc.enterDigit('4'),
              onSurface: onSurface,
            ),
            _padButton(
              context,
              calc,
              label: '5',
              onTap: () => calc.enterDigit('5'),
              onSurface: onSurface,
            ),
            _padButton(
              context,
              calc,
              label: '6',
              onTap: () => calc.enterDigit('6'),
              onSurface: onSurface,
            ),
            _padButton(
              context,
              calc,
              label: '+',
              textColor: const Color(0xFF16A34A),
              onTap: () => calc.setOperator('+'),
              onSurface: onSurface,
            ),
          ],
        ),
        const SizedBox(height: 6),
        // Row 4 & 5: [1][2][3][ = spans 2 rows ]  /  [SCI][0][.][ = cont ]
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left 3 columns — 2 rows
            Expanded(
              flex: 3,
              child: Column(
                children: [
                  Row(
                    children: [
                      _padButton(
                        context,
                        calc,
                        label: '1',
                        onTap: () => calc.enterDigit('1'),
                        flex: 1,
                        onSurface: onSurface,
                      ),
                      _padButton(
                        context,
                        calc,
                        label: '2',
                        onTap: () => calc.enterDigit('2'),
                        flex: 1,
                        onSurface: onSurface,
                      ),
                      _padButton(
                        context,
                        calc,
                        label: '3',
                        onTap: () => calc.enterDigit('3'),
                        flex: 1,
                        onSurface: onSurface,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _padButton(
                        context,
                        calc,
                        label: 'SCI',
                        textColor: primary,
                        onTap: () => calc.toggleScientific(),
                        flex: 1,
                        onSurface: onSurface,
                      ),
                      _padButton(
                        context,
                        calc,
                        label: '0',
                        onTap: () => calc.enterDigit('0'),
                        flex: 1,
                        onSurface: onSurface,
                      ),
                      _padButton(
                        context,
                        calc,
                        label: '.',
                        onTap: () => calc.enterDigit('.'),
                        flex: 1,
                        onSurface: onSurface,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            // Right column — = button spanning 2 rows
            Expanded(
              flex: 1,
              child: SizedBox(
                height: 94,
                child: NeumorphicButton(
                  padding: EdgeInsets.zero,
                  borderRadius: 12,
                  color: const Color(0xFF16A34A),
                  onPressed: () => calc.calculate(),
                  child: const Icon(
                    Icons.drag_handle,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════
  // SCIENTIFIC PAD — shown when SCI is toggled
  // ═══════════════════════════════════════════════════════════
  Widget _buildScientificPad(
    BuildContext context,
    CalculatorProvider calc,
    bool isDark,
    Color primary,
    Color onSurface,
  ) {
    return Column(
      children: [
        // Scientific functions row 1
        Row(
          children: [
            _padButton(
              context,
              calc,
              label: 'sin',
              textColor: primary,
              onTap: () => calc.append('sin'),
              onSurface: onSurface,
            ),
            _padButton(
              context,
              calc,
              label: 'cos',
              textColor: primary,
              onTap: () => calc.append('cos'),
              onSurface: onSurface,
            ),
            _padButton(
              context,
              calc,
              label: 'tan',
              textColor: primary,
              onTap: () => calc.append('tan'),
              onSurface: onSurface,
            ),
            _padButton(
              context,
              calc,
              label: 'log',
              textColor: primary,
              onTap: () => calc.append('log'),
              onSurface: onSurface,
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Scientific functions row 2
        Row(
          children: [
            _padButton(
              context,
              calc,
              label: 'ln',
              textColor: primary,
              onTap: () => calc.append('ln'),
              onSurface: onSurface,
            ),
            _padButton(
              context,
              calc,
              label: '^',
              textColor: primary,
              onTap: () => calc.append('^'),
              onSurface: onSurface,
            ),
            _padButton(
              context,
              calc,
              label: 'π',
              textColor: primary,
              onTap: () => calc.append('π'),
              onSurface: onSurface,
            ),
            _padButton(
              context,
              calc,
              label: '( )',
              textColor: primary,
              onTap: () {
                // Auto-determine open/close paren
                final openCount = calc.currentInput.split('(').length - 1;
                final closeCount = calc.currentInput.split(')').length - 1;
                calc.append(openCount > closeCount ? ')' : '(');
              },
              onSurface: onSurface,
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Row: ↺  ⌫  /  ×
        Row(
          children: [
            _padButton(
              context,
              calc,
              label: '↺',
              textColor: const Color(0xFFEA580C),
              onTap: () => calc.clearAll(),
              onSurface: onSurface,
            ),
            _padButton(
              context,
              calc,
              icon: Icons.backspace_outlined,
              textColor: Colors.grey.shade600,
              onTap: () => calc.backspace(),
              onSurface: onSurface,
            ),
            _padButton(
              context,
              calc,
              label: '/',
              textColor: primary,
              onTap: () => calc.setOperator('÷'),
              onSurface: onSurface,
            ),
            _padButton(
              context,
              calc,
              label: '×',
              textColor: Colors.red,
              onTap: () => calc.setOperator('×'),
              onSurface: onSurface,
            ),
          ],
        ),
        const SizedBox(height: 8),
        // 7 8 9 -
        Row(
          children: [
            _padButton(
              context,
              calc,
              label: '7',
              onTap: () => calc.enterDigit('7'),
              onSurface: onSurface,
            ),
            _padButton(
              context,
              calc,
              label: '8',
              onTap: () => calc.enterDigit('8'),
              onSurface: onSurface,
            ),
            _padButton(
              context,
              calc,
              label: '9',
              onTap: () => calc.enterDigit('9'),
              onSurface: onSurface,
            ),
            _padButton(
              context,
              calc,
              label: '-',
              textColor: primary,
              onTap: () => calc.setOperator('-'),
              onSurface: onSurface,
            ),
          ],
        ),
        const SizedBox(height: 8),
        // 4 5 6 +
        Row(
          children: [
            _padButton(
              context,
              calc,
              label: '4',
              onTap: () => calc.enterDigit('4'),
              onSurface: onSurface,
            ),
            _padButton(
              context,
              calc,
              label: '5',
              onTap: () => calc.enterDigit('5'),
              onSurface: onSurface,
            ),
            _padButton(
              context,
              calc,
              label: '6',
              onTap: () => calc.enterDigit('6'),
              onSurface: onSurface,
            ),
            _padButton(
              context,
              calc,
              label: '+',
              textColor: const Color(0xFF16A34A),
              onTap: () => calc.setOperator('+'),
              onSurface: onSurface,
            ),
          ],
        ),
        const SizedBox(height: 8),
        // [1][2][3][ = ]  /  [SCI][0][.][ = ]
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Column(
                children: [
                  Row(
                    children: [
                      _padButton(
                        context,
                        calc,
                        label: '1',
                        onTap: () => calc.enterDigit('1'),
                        flex: 1,
                        onSurface: onSurface,
                      ),
                      _padButton(
                        context,
                        calc,
                        label: '2',
                        onTap: () => calc.enterDigit('2'),
                        flex: 1,
                        onSurface: onSurface,
                      ),
                      _padButton(
                        context,
                        calc,
                        label: '3',
                        onTap: () => calc.enterDigit('3'),
                        flex: 1,
                        onSurface: onSurface,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _padButton(
                        context,
                        calc,
                        label: 'SCI',
                        textColor: const Color(0xFFEA580C),
                        onTap: () => calc.toggleScientific(),
                        flex: 1,
                        onSurface: onSurface,
                      ),
                      _padButton(
                        context,
                        calc,
                        label: '0',
                        onTap: () => calc.enterDigit('0'),
                        flex: 1,
                        onSurface: onSurface,
                      ),
                      _padButton(
                        context,
                        calc,
                        label: '.',
                        onTap: () => calc.enterDigit('.'),
                        flex: 1,
                        onSurface: onSurface,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 1,
              child: SizedBox(
                height: 112,
                child: NeumorphicButton(
                  padding: EdgeInsets.zero,
                  borderRadius: 14,
                  color: const Color(0xFF16A34A),
                  onPressed: () => calc.calculate(),
                  child: const Icon(
                    Icons.drag_handle,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _padButton(
    BuildContext context,
    CalculatorProvider calc, {
    String? label,
    IconData? icon,
    Color? textColor,
    required VoidCallback onTap,
    int flex = 1,
    required Color onSurface,
  }) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: NeumorphicButton(
          padding: const EdgeInsets.symmetric(vertical: 10),
          borderRadius: 12,
          onPressed: onTap,
          child: icon != null
              ? Icon(icon, color: textColor ?? onSurface, size: 16)
              : Text(
                  label ?? '',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: textColor ?? onSurface,
                  ),
                ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // TOTAL BAR — bottom bar showing running total
  // ═══════════════════════════════════════════════════════════
  Widget _buildTotalBar(
    BuildContext context,
    CalculatorProvider calc,
    bool isDark,
    Color primary,
  ) {
    final isUsd = calc.currencyType == CurrencyType.usd;
    final total = calc.getTotalInCurrency();
    final symbol = calc.getCurrencySymbol();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isUsd ? 'TOTAL (SIMULATED USD)' : 'TAPE RUNNING TOTAL',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: Colors.white.withValues(alpha: 0.6),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '$symbol${_formatDisplay(total)}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF4ADE80),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (isUsd)
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '₹${_formatDisplay(calc.runningTotal)}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              if (!isUsd && calc.runningTotal != 0)
                Text(
                  'Base Value',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.4),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════
  String _formatDisplay(double value) {
    if (value == value.toInt().toDouble()) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(2);
  }
}

// ═════════════════════════════════════════════════════════════
// ═════════════════════════════════════════════════════════════
// COMPARISON ADD ROW — Stateful widget for adding comparison rows
// ═════════════════════════════════════════════════════════════
class _ComparisonAddRow extends StatefulWidget {
  final CalculatorProvider calc;
  const _ComparisonAddRow({required this.calc});

  @override
  State<_ComparisonAddRow> createState() => _ComparisonAddRowState();
}

class _ComparisonAddRowState extends State<_ComparisonAddRow> {
  final _descController = TextEditingController();
  final Map<String, TextEditingController> _valControllers = {};
  final Map<String, TextEditingController> _qtyControllers = {};
  final Map<String, TextEditingController> _discControllers = {};

  TextEditingController _getValController(String side) {
    return _valControllers.putIfAbsent(side, () => TextEditingController());
  }

  TextEditingController _getQtyController(String side) {
    return _qtyControllers.putIfAbsent(side, () => TextEditingController(text: '1'));
  }

  TextEditingController _getDiscController(String side) {
    return _discControllers.putIfAbsent(side, () => TextEditingController(text: '0'));
  }

  @override
  void dispose() {
    _descController.dispose();
    for (final c in _valControllers.values) {
      c.dispose();
    }
    for (final c in _qtyControllers.values) {
      c.dispose();
    }
    for (final c in _discControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _submitRow() {
    widget.calc.addComparisonRow();
    final idx = widget.calc.comparisonRows.length - 1;

    final sideValues = <String, double?>{};
    final sideQtys = <String, double>{};
    final sideDiscounts = <String, double>{};

    for (final side in widget.calc.comparisonSides) {
      final valText = _getValController(side).text;
      sideValues[side] = double.tryParse(valText);
      sideQtys[side] = double.tryParse(_getQtyController(side).text) ?? 1.0;
      sideDiscounts[side] = double.tryParse(_getDiscController(side).text) ?? 0.0;
    }

    widget.calc.updateComparisonRow(
      idx,
      description: _descController.text,
      valueA: sideValues['A'],
      valueB: sideValues['B'],
      qtyA: sideQtys['A'] ?? 1.0,
      qtyB: sideQtys['B'] ?? 1.0,
      discountA: sideDiscounts['A'] ?? 0.0,
      discountB: sideDiscounts['B'] ?? 0.0,
      sideValues: sideValues,
      sideQtys: sideQtys,
      sideDiscounts: sideDiscounts,
    );

    _descController.clear();
    for (final c in _valControllers.values) {
      c.clear();
    }
    for (final c in _qtyControllers.values) {
      c.text = '1';
    }
    for (final c in _discControllers.values) {
      c.text = '0';
    }
  }

  Widget _buildTextInput({
    required TextEditingController controller,
    required String hintText,
    required bool isDark,
    TextInputType? keyboardType,
    IconData? prefixIcon,
    String? prefixText,
  }) {
    return Container(
      height: 32,
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.12)
              : const Color(0xFFCBD5E1),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          if (prefixIcon != null) ...[
            Icon(prefixIcon, size: 14, color: Colors.grey.shade400),
            const SizedBox(width: 4),
          ],
          if (prefixText != null) ...[
            Text(
              prefixText,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade500,
              ),
            ),
            const SizedBox(width: 2),
          ],
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: keyboardType,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade400,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 7),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModifierInput({
    required TextEditingController controller,
    required String hint,
    String? prefix,
    String? suffix,
    required bool isDark,
  }) {
    return Container(
      height: 26,
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : const Color(0xFFCBD5E1),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          if (prefix != null)
            Text(
              prefix,
              style: TextStyle(
                fontSize: 8.5,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade500,
              ),
            ),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(
                  fontSize: 8.5,
                  color: Colors.grey.shade400,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 2),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          if (suffix != null)
            Text(
              suffix,
              style: TextStyle(
                fontSize: 8.5,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade500,
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.03)
            : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Row 1: Primary Inputs (matching columns) ──
          Row(
            children: [
              Expanded(
                flex: 3,
                child: _buildTextInput(
                  controller: _descController,
                  hintText: 'Description',
                  isDark: isDark,
                  prefixIcon: Icons.edit_note_rounded,
                ),
              ),
              for (final side in widget.calc.comparisonSides) ...[
                const SizedBox(width: 4),
                Expanded(
                  flex: 2,
                  child: _buildTextInput(
                    controller: _getValController(side),
                    hintText: 'Price $side',
                    isDark: isDark,
                    keyboardType: TextInputType.number,
                    prefixText: '₹',
                  ),
                ),
              ],
              const SizedBox(width: 4),
              SizedBox(
                width: 28,
                height: 32,
                child: Tooltip(
                  message: 'Add item to comparison',
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: _submitRow,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF16A34A),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF16A34A).withValues(alpha: 0.25),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.add_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),

          // ── Row 2: Secondary Inputs (Qty & Disc for each active side) ──
          Row(
            children: [
              Expanded(
                flex: 3,
                child: Row(
                  children: [
                    Icon(
                      Icons.tune_rounded,
                      size: 11,
                      color: Colors.grey.shade500,
                    ),
                    const SizedBox(width: 3),
                    Flexible(
                      child: Text(
                        'Qty & Disc %',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              for (final side in widget.calc.comparisonSides) ...[
                const SizedBox(width: 4),
                Expanded(
                  flex: 2,
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildModifierInput(
                          controller: _getQtyController(side),
                          hint: 'Qty',
                          prefix: '×',
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: 3),
                      Expanded(
                        child: _buildModifierInput(
                          controller: _getDiscController(side),
                          hint: 'Disc',
                          suffix: '%',
                          isDark: isDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(width: 4),
              // Spacer to align with 28px add button
              const SizedBox(width: 28),
            ],
          ),
        ],
      ),
    );
  }
}
