import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/providers/app_providers.dart';
import '../../core/providers/session_provider.dart';
import '../../core/models/calculator_models.dart';
import '../../core/widgets/neumorphic_widgets.dart';
import '../../core/theme/app_spacing.dart';

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  final ScrollController _tapeScrollController = ScrollController();
  bool _showHistoryList = false;

  @override
  void dispose() {
    _tapeScrollController.dispose();
    super.dispose();
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Header ──
        _buildHeader(context, calcProvider, isDark, primaryColor),

        Expanded(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 24),

                  // ── History Sections (Togglable) ──
                  if (_showHistoryList &&
                      calcProvider.historySections.isNotEmpty) ...[
                    const Text(
                      'Calculation Logs',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildHistorySectionsList(
                      context,
                      calcProvider,
                      isDark,
                      primaryColor,
                    ),
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 24),
                  ],

                  // ── SET BASE ──
                  if (!calcProvider.hasBase) ...[
                    _buildSetBase(
                      context,
                      calcProvider,
                      isDark,
                      primaryColor,
                      onSurface,
                    ),
                    const SizedBox(height: 12),
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

                  const SizedBox(height: 12),

                  // ── Mode Tabs ──
                  _buildModeTabs(context, calcProvider, isDark, primaryColor),

                  const SizedBox(height: 8),

                  // ── Mode-specific content ──
                  _buildModeContent(
                    context,
                    calcProvider,
                    isDark,
                    primaryColor,
                  ),

                  const SizedBox(height: 12),

                  // ── Number Pad ──
                  _buildNumberPad(
                    context,
                    calcProvider,
                    isDark,
                    primaryColor,
                    onSurface,
                  ),

                  const SizedBox(height: 12),

                  // ── Total Bar ──
                  _buildTotalBar(context, calcProvider, isDark, primaryColor),

                  // ── Ecosystem Sessions ──
                  const SizedBox(height: AppSpacing.lg),
                  const Text(
                    'Ecosystem Sessions',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _buildEcosystemSessionsList(),
                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
          ),
        ),
      ],
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
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
      child: Row(
        children: [
          Icon(Icons.auto_awesome, color: primary, size: 18),
          const SizedBox(width: 6),
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
          _headerAction(Icons.save_alt_rounded, 'Save', () {
            calc.saveCurrentToHistory();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Saved to history logs')),
            );
          }),
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
          _headerAction(Icons.delete_outline, 'Clear', () => calc.clearAll()),
        ],
      ),
    );
  }

  Widget _headerAction(IconData icon, String tooltip, VoidCallback onTap) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(6.0),
          child: Icon(icon, size: 18, color: Colors.grey.shade600),
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
      borderRadius: 16,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Text(
            'SET BASE',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade500,
              letterSpacing: 0.5,
            ),
          ),
          const Spacer(),
          Text(
            calc.currentInput == '0' ? '0' : calc.currentInput,
            style: TextStyle(
              fontSize: 22,
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CONTINUE',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade500,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                calc.pendingOperator,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade500,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    calc.currentInput,
                    style: TextStyle(
                      fontSize: 22,
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
          calc.currencyType == CurrencyType.inr ? 'INR' : 'USD',
          calc.currencyType == CurrencyType.inr
              ? Icons.currency_rupee
              : Icons.attach_money,
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
          if (mode == CalcMode.currency) {
            calc.toggleCurrency();
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isActive
                ? (mode == CalcMode.discount
                      ? const Color(0xFFEA580C)
                      : activeColor)
                : (isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.grey.shade200),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 12,
                color: isActive ? Colors.white : Colors.grey.shade600,
              ),
              const SizedBox(width: 3),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: isActive ? Colors.white : Colors.grey.shade600,
                  ),
                ),
              ),
            ],
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
  // PRICE COMPARISON TABLE
  // ═══════════════════════════════════════════════════════════
  Widget _buildComparisonTable(
    BuildContext context,
    CalculatorProvider calc,
    bool isDark,
    Color primary,
  ) {
    return NeumorphicCard(
      borderRadius: 14,
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.compare_arrows, size: 14, color: primary),
              const SizedBox(width: 6),
              Text(
                'PRICE COMPARISON',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: primary,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Analysis Banner
          if (calc.comparisonRows.isNotEmpty) ...[
            Builder(
              builder: (context) {
                double totalA = 0;
                double totalB = 0;
                int countA = 0;
                int countB = 0;
                for (var r in calc.comparisonRows) {
                  if (r.valueA != null) {
                    totalA += r.finalA;
                    countA++;
                  }
                  if (r.valueB != null) {
                    totalB += r.finalB;
                    countB++;
                  }
                }
                if (countA > 0 || countB > 0) {
                  String analysisMsg = '';
                  Color bannerColor = Colors.grey.shade400;
                  if (totalA < totalB && totalA > 0) {
                    final percent = ((totalB - totalA) / totalB * 100)
                        .toStringAsFixed(0);
                    analysisMsg =
                        'Side A is cheaper by $percent% (A: ${_formatDisplay(totalA)} vs B: ${_formatDisplay(totalB)})';
                    bannerColor = const Color(0xFF16A34A);
                  } else if (totalB < totalA && totalB > 0) {
                    final percent = ((totalA - totalB) / totalA * 100)
                        .toStringAsFixed(0);
                    analysisMsg =
                        'Side B is cheaper by $percent% (B: ${_formatDisplay(totalB)} vs A: ${_formatDisplay(totalA)})';
                    bannerColor = const Color(0xFF16A34A);
                  } else if (totalA == totalB && totalA > 0) {
                    analysisMsg = 'Both Side A and Side B are equal';
                    bannerColor = primary;
                  } else {
                    analysisMsg = 'Enter prices to compare';
                  }

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: bannerColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: bannerColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      analysisMsg,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        color: bannerColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],

          // Table header
          Row(
            children: [
              Expanded(
                flex: 3,
                child: Text(
                  'Description',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade500,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'Side A',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade500,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'Side B',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade500,
                  ),
                ),
              ),
            ],
          ),
          Divider(color: Colors.grey.withValues(alpha: 0.2)),

          // Rows
          if (calc.comparisonRows.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: Text(
                  'No comparison items yet.\nAdd description and values below.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                ),
              ),
            )
          else
            ...calc.comparisonRows.asMap().entries.map((e) {
              final idx = e.key;
              final row = e.value;
              final finalValA = row.finalA;
              final finalValB = row.finalB;
              final isACheaper =
                  row.valueA != null &&
                  row.valueB != null &&
                  finalValA < finalValB;
              final isBCheaper =
                  row.valueA != null &&
                  row.valueB != null &&
                  finalValB < finalValA;
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
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
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Qty: A:${row.qtyA.toInt()} B:${row.qtyB.toInt()} | Disc: A:${row.discountA.toInt()}% B:${row.discountB.toInt()}%',
                            style: TextStyle(
                              fontSize: 8.5,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        row.valueA != null ? _formatDisplay(finalValA) : '—',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isACheaper
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: isACheaper ? const Color(0xFF16A34A) : null,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        row.valueB != null ? _formatDisplay(finalValB) : '—',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isBCheaper
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: isBCheaper ? const Color(0xFF16A34A) : null,
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () => calc.removeComparisonRow(idx),
                      child: Icon(
                        Icons.close,
                        size: 14,
                        color: Colors.red.shade400,
                      ),
                    ),
                  ],
                ),
              );
            }),

          const SizedBox(height: 6),
          Divider(color: Colors.grey.withValues(alpha: 0.3)),
          // Totals sum row
          Builder(
            builder: (context) {
              double totalA = 0;
              double totalB = 0;
              for (var r in calc.comparisonRows) {
                if (r.valueA != null) totalA += r.finalA;
                if (r.valueB != null) totalB += r.finalB;
              }
              final isATotalCheaper = totalA < totalB && totalA > 0;
              final isBTotalCheaper = totalB < totalA && totalB > 0;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    const Expanded(
                      flex: 3,
                      child: Text(
                        'Total Sum',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        _formatDisplay(totalA),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isATotalCheaper
                              ? const Color(0xFF16A34A)
                              : null,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        _formatDisplay(totalB),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isBTotalCheaper
                              ? const Color(0xFF16A34A)
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 8),

          // Add row input
          _ComparisonAddRow(calc: calc),
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
        const SizedBox(height: 8),
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
        const SizedBox(height: 8),
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
        const SizedBox(height: 8),
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
                  const SizedBox(height: 8),
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
            const SizedBox(width: 8),
            // Right column — = button spanning 2 rows
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
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: NeumorphicButton(
          padding: const EdgeInsets.symmetric(vertical: 14),
          borderRadius: 14,
          onPressed: onTap,
          child: icon != null
              ? Icon(icon, color: textColor ?? onSurface, size: 18)
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1B3A2D),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isUsd ? 'TOTAL (SIMULATED USD)' : 'TAPE RUNNING TOTAL',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Colors.white.withValues(alpha: 0.6),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
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
                      fontSize: 22,
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
  // ECOSYSTEM SESSIONS — preserved from original
  // ═══════════════════════════════════════════════════════════
  Widget _buildEcosystemSessionsList() {
    return Consumer<SessionProvider>(
      builder: (context, sessionProvider, child) {
        final calcActivities = sessionProvider.activities
            .where((act) => act.module == 'Calculator')
            .toList();

        if (calcActivities.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: Text(
                'No ecosystem logs found.',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: calcActivities.length,
          itemBuilder: (context, i) {
            final act = calcActivities[i];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: NeumorphicCard(
                borderRadius: 16,
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: NeumorphicDecoration.build(
                        context: context,
                        inset: true,
                        borderRadius: 12,
                      ),
                      child: Icon(
                        Icons.calculate_outlined,
                        color: Theme.of(context).primaryColor,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _extractEcosystem(act.description),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              Text(
                                '${act.timestamp.hour}:${act.timestamp.minute.toString().padLeft(2, '0')}',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            act.description,
                            style: const TextStyle(fontSize: 12),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(
                                Icons.devices,
                                size: 12,
                                color: Colors.grey.shade500,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                act.device,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                act.status,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: act.status == 'Success'
                                      ? Colors.green
                                      : Colors.red,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
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

  String _extractEcosystem(String description) {
    if (description.toLowerCase().contains('bnx mail')) {
      return 'BNX Mail';
    }
    if (description.toLowerCase().contains('clicksbusiness')) {
      return 'ClicksBusiness';
    }
    if (description.toLowerCase().contains('clicks')) {
      return 'Clicks';
    }
    if (description.toLowerCase().contains('b2auth')) {
      return 'B2Auth';
    }
    return 'BNX Ecosystem';
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
  final _valAController = TextEditingController();
  final _valBController = TextEditingController();
  final _qtyAController = TextEditingController(text: '1');
  final _qtyBController = TextEditingController(text: '1');
  final _discAController = TextEditingController(text: '0');
  final _discBController = TextEditingController(text: '0');

  @override
  void dispose() {
    _descController.dispose();
    _valAController.dispose();
    _valBController.dispose();
    _qtyAController.dispose();
    _qtyBController.dispose();
    _discAController.dispose();
    _discBController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              flex: 3,
              child: SizedBox(
                height: 32,
                child: TextField(
                  controller: _descController,
                  style: const TextStyle(fontSize: 11),
                  decoration: InputDecoration(
                    hintText: 'Description',
                    hintStyle: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade400,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    isDense: true,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              flex: 2,
              child: SizedBox(
                height: 32,
                child: TextField(
                  controller: _valAController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(fontSize: 11),
                  decoration: InputDecoration(
                    hintText: 'Price A',
                    hintStyle: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade400,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    isDense: true,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              flex: 2,
              child: SizedBox(
                height: 32,
                child: TextField(
                  controller: _valBController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(fontSize: 11),
                  decoration: InputDecoration(
                    hintText: 'Price B',
                    hintStyle: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade400,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    isDense: true,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),
            InkWell(
              onTap: () {
                widget.calc.addComparisonRow();
                final idx = widget.calc.comparisonRows.length - 1;
                widget.calc.updateComparisonRow(
                  idx,
                  description: _descController.text,
                  valueA: double.tryParse(_valAController.text),
                  valueB: double.tryParse(_valBController.text),
                  qtyA: double.tryParse(_qtyAController.text) ?? 1.0,
                  qtyB: double.tryParse(_qtyBController.text) ?? 1.0,
                  discountA: double.tryParse(_discAController.text) ?? 0.0,
                  discountB: double.tryParse(_discBController.text) ?? 0.0,
                );
                _descController.clear();
                _valAController.clear();
                _valBController.clear();
                _qtyAController.text = '1';
                _qtyBController.text = '1';
                _discAController.text = '0';
                _discBController.text = '0';
              },
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: const Color(0xFF16A34A),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 16),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 28,
                child: TextField(
                  controller: _qtyAController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(fontSize: 10),
                  decoration: InputDecoration(
                    labelText: 'Qty A',
                    labelStyle: const TextStyle(fontSize: 8.5),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 4,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    isDense: true,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: SizedBox(
                height: 28,
                child: TextField(
                  controller: _discAController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(fontSize: 10),
                  decoration: InputDecoration(
                    labelText: 'Disc A %',
                    labelStyle: const TextStyle(fontSize: 8.5),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 4,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    isDense: true,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: SizedBox(
                height: 28,
                child: TextField(
                  controller: _qtyBController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(fontSize: 10),
                  decoration: InputDecoration(
                    labelText: 'Qty B',
                    labelStyle: const TextStyle(fontSize: 8.5),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 4,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    isDense: true,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: SizedBox(
                height: 28,
                child: TextField(
                  controller: _discBController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(fontSize: 10),
                  decoration: InputDecoration(
                    labelText: 'Disc B %',
                    labelStyle: const TextStyle(fontSize: 8.5),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 4,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    isDense: true,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 32),
          ],
        ),
      ],
    );
  }
}
