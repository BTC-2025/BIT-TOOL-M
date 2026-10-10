import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/models/currency_models.dart';
import '../../../core/providers/currency_converter_provider.dart';
import '../../../core/widgets/neumorphic_widgets.dart';

/// Professional, two-sided live currency converter for BIT-TOOL macOS.
/// Replaces the legacy Compare mode with live reference exchange rates from the Frankfurter API.
class CurrencyConverterWidget extends StatefulWidget {
  const CurrencyConverterWidget({super.key});

  @override
  State<CurrencyConverterWidget> createState() => _CurrencyConverterWidgetState();
}

class _CurrencyConverterWidgetState extends State<CurrencyConverterWidget> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<CurrencyConverterProvider>().ensureInitialized();
      }
    });
  }

  Future<void> _openAttributionUrl() async {
    final uri = Uri.parse('https://frankfurter.dev/');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      // Ignored if browser cannot be launched
    }
  }

  void _showCurrencyPicker({
    required BuildContext context,
    required bool isBase,
    required CurrencyItem currentSelection,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.read<CurrencyConverterProvider>();
    final allCurrencies = provider.currencies;

    showDialog(
      context: context,
      builder: (ctx) {
        String searchQuery = '';
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            final filtered = allCurrencies.where((c) {
              final q = searchQuery.trim().toLowerCase();
              if (q.isEmpty) return true;
              return c.code.toLowerCase().contains(q) ||
                  c.name.toLowerCase().contains(q) ||
                  c.countryOrRegion.toLowerCase().contains(q);
            }).toList();

            final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
            final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
            final subColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
            final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

            return Dialog(
              backgroundColor: cardBg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: borderColor),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440, maxHeight: 540),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Dialog Title & Close
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              isBase ? 'Select Source Currency' : 'Select Target Currency',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, size: 20),
                            onPressed: () => Navigator.pop(dialogCtx),
                            color: subColor,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Search Box
                      TextField(
                        autofocus: true,
                        style: TextStyle(fontSize: 14, color: textColor),
                        decoration: InputDecoration(
                          hintText: 'Search by currency code, country, or name...',
                          hintStyle: TextStyle(fontSize: 13, color: subColor),
                          prefixIcon: Icon(Icons.search_rounded, size: 18, color: subColor),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          filled: true,
                          fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: borderColor),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: borderColor),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
                          ),
                        ),
                        onChanged: (val) {
                          setDialogState(() => searchQuery = val);
                        },
                      ),
                      const SizedBox(height: 12),

                      // Currencies List
                      Expanded(
                        child: filtered.isEmpty
                            ? Center(
                                child: Text(
                                  'No currencies matching "$searchQuery"',
                                  style: TextStyle(fontSize: 13, color: subColor),
                                ),
                              )
                            : ListView.separated(
                                itemCount: filtered.length,
                                separatorBuilder: (_, __) => Divider(
                                  height: 1,
                                  color: borderColor.withValues(alpha: 0.5),
                                ),
                                itemBuilder: (context, idx) {
                                  final item = filtered[idx];
                                  final isSelected = item.code == currentSelection.code;

                                  return ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 2,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    leading: Text(
                                      item.flag,
                                      style: const TextStyle(fontSize: 24),
                                    ),
                                    title: Row(
                                      children: [
                                        Text(
                                          item.code,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: isSelected
                                                ? const Color(0xFF2563EB)
                                                : textColor,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            item.name,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: textColor,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    subtitle: Text(
                                      item.countryOrRegion,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: subColor,
                                      ),
                                    ),
                                    trailing: Text(
                                      item.symbol,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: subColor,
                                      ),
                                    ),
                                    onTap: () {
                                      Navigator.pop(dialogCtx);
                                      if (isBase) {
                                        provider.setBaseCurrency(item);
                                      } else {
                                        provider.setQuoteCurrency(item);
                                      }
                                    },
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    return Consumer<CurrencyConverterProvider>(
      builder: (context, provider, _) {
        return NeumorphicCard(
          borderRadius: 20,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Header: Title & Quick Refresh ──
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2563EB).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.currency_exchange_rounded,
                            size: 18,
                            color: Color(0xFF2563EB),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'LIVE CURRENCY CONVERTER',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.6,
                                  color: textColor,
                                ),
                              ),
                              const SizedBox(height: 1),
                              Text(
                                'Real-time reference exchange rates (Frankfurter)',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: subColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Row(
                    children: [
                      if (provider.isLoadingRate)
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
                          ),
                        )
                      else
                        IconButton(
                          icon: const Icon(Icons.refresh_rounded, size: 18),
                          tooltip: 'Refresh live rate',
                          color: subColor,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () => provider.refreshRate(),
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── Error Banner if any ──
              if (provider.rateError != null) ...[
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFECACA)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        color: Color(0xFFEF4444),
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          provider.rateError!,
                          style: const TextStyle(
                            color: Color(0xFFB91C1C),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => provider.refreshRate(),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          'Retry',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFB91C1C),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // ── Stale Rate Banner if using cached rate after failure ──
              if (provider.isStale && provider.currentRate != null) ...[
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: Color(0xFFD97706),
                        size: 18,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Showing previously cached reference rate. Rate may be stale.',
                          style: TextStyle(
                            color: Color(0xFFB45309),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // ── Responsive Two-Sided Panels ──
              LayoutBuilder(
                builder: (context, constraints) {
                  final bool isWide = constraints.maxWidth >= 480;

                  final leftPanel = _buildCurrencyPanel(
                    context: context,
                    isBase: true,
                    currency: provider.baseCurrency,
                    controller: provider.baseAmountController,
                    formattedEquivalent: provider.formatDisplayValue(
                      provider.baseAmountController.text,
                      provider.baseCurrency,
                    ),
                    onAmountChanged: (val) => provider.updateBaseAmount(val),
                    isDark: isDark,
                    textColor: textColor,
                    subColor: subColor,
                    borderColor: borderColor,
                  );

                  final rightPanel = _buildCurrencyPanel(
                    context: context,
                    isBase: false,
                    currency: provider.quoteCurrency,
                    controller: provider.quoteAmountController,
                    formattedEquivalent: provider.formatDisplayValue(
                      provider.quoteAmountController.text,
                      provider.quoteCurrency,
                    ),
                    onAmountChanged: (val) => provider.updateQuoteAmount(val),
                    isDark: isDark,
                    textColor: textColor,
                    subColor: subColor,
                    borderColor: borderColor,
                  );

                  final swapButton = _buildSwapButton(
                    context: context,
                    onTap: () => provider.swapCurrencies(),
                    isDark: isDark,
                    isWide: isWide,
                  );

                  if (isWide) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: leftPanel),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 40),
                          child: swapButton,
                        ),
                        Expanded(child: rightPanel),
                      ],
                    );
                  } else {
                    return Column(
                      children: [
                        leftPanel,
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: swapButton,
                        ),
                        rightPanel,
                      ],
                    );
                  }
                },
              ),
              const SizedBox(height: 16),

              // ── Rate Details & Metadata Footer ──
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.03)
                      : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  children: [
                    // Rates in both directions
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              const Icon(
                                Icons.trending_up_rounded,
                                size: 16,
                                color: Color(0xFF10B981),
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  provider.rateDescriptionDirect,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (provider.rateDescriptionInverse.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Expanded(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Flexible(
                                  child: Text(
                                    provider.rateDescriptionInverse,
                                    textAlign: TextAlign.end,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: subColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    Divider(height: 1, color: borderColor.withValues(alpha: 0.6)),
                    const SizedBox(height: 8),

                    // Effective date and last refreshed time
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.calendar_today_rounded, size: 12, color: subColor),
                              const SizedBox(width: 5),
                              Flexible(
                                child: Text(
                                  provider.currentRate != null
                                      ? 'Effective: ${provider.currentRate!.date}'
                                      : 'Effective: —',
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 11, color: subColor),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Icon(Icons.access_time_rounded, size: 12, color: subColor),
                              const SizedBox(width: 5),
                              Flexible(
                                child: Text(
                                  provider.lastRefreshedAt != null
                                      ? 'Refreshed: ${DateFormat('hh:mm:ss a').format(provider.lastRefreshedAt!)}'
                                      : 'Refreshed: —',
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 11, color: subColor),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Attribution link
                    InkWell(
                      onTap: _openAttributionUrl,
                      borderRadius: BorderRadius.circular(6),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Reference rates provided by Frankfurter API (ECB)',
                              style: TextStyle(
                                fontSize: 10,
                                color: primaryColor,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(Icons.open_in_new_rounded, size: 10, color: primaryColor),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCurrencyPanel({
    required BuildContext context,
    required bool isBase,
    required CurrencyItem currency,
    required TextEditingController controller,
    required String formattedEquivalent,
    required ValueChanged<String> onAmountChanged,
    required bool isDark,
    required Color textColor,
    required Color subColor,
    required Color borderColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Flag, Country/Region, Currency Picker Dropdown Button
          InkWell(
            onTap: () => _showCurrencyPicker(
              context: context,
              isBase: isBase,
              currentSelection: currency,
            ),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Text(
                    currency.flag,
                    style: const TextStyle(fontSize: 22),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currency.code,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: textColor,
                          ),
                        ),
                        Text(
                          currency.countryOrRegion,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10.5,
                            color: subColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 18,
                    color: subColor,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Editable Amount Field
          TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
            ],
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
            decoration: InputDecoration(
              isDense: true,
              prefixText: '${currency.symbol} ',
              prefixStyle: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: subColor,
              ),
              hintText: '0.00',
              hintStyle: TextStyle(
                fontSize: 20,
                color: subColor.withValues(alpha: 0.4),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              filled: true,
              fillColor: isDark
                  ? Colors.white.withValues(alpha: 0.02)
                  : const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: borderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
              ),
            ),
            onChanged: onAmountChanged,
          ),
          const SizedBox(height: 8),

          // Formatted Currency Equivalent
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.02)
                  : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Formatted:',
                  style: TextStyle(fontSize: 10, color: subColor),
                ),
                Text(
                  formattedEquivalent,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwapButton({
    required BuildContext context,
    required VoidCallback onTap,
    required bool isDark,
    required bool isWide,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFF2563EB),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2563EB).withValues(alpha: 0.35),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            isWide ? Icons.swap_horiz_rounded : Icons.swap_vert_rounded,
            color: Colors.white,
            size: 20,
          ),
        ),
      ),
    );
  }
}
