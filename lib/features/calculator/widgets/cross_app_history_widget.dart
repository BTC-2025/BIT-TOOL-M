import 'package:flutter/material.dart';
import '../models/cross_app_history_models.dart';

class CrossAppHistoryWidget extends StatefulWidget {
  final Function(CrossAppTape tape)? onLoadTape;

  const CrossAppHistoryWidget({super.key, this.onLoadTape});

  @override
  State<CrossAppHistoryWidget> createState() => _CrossAppHistoryWidgetState();
}

class _CrossAppHistoryWidgetState extends State<CrossAppHistoryWidget> {
  final List<CrossAppItem> _apps = CrossAppHistoryData.getInitialApps();
  CrossAppItem? _selectedApp;
  CrossAppTape? _selectedTape;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: _buildCurrentView(isDark),
      ),
    );
  }

  Widget _buildCurrentView(bool isDark) {
    if (_selectedTape != null && _selectedApp != null) {
      return _buildTapeDetailsView(isDark);
    } else if (_selectedApp != null) {
      return _buildAppTapesView(isDark);
    } else {
      return _buildAppsListView(isDark);
    }
  }

  // ═══════════════════════════════════════════════════════════
  // LEVEL 1: APPLICATIONS LIST (Screenshot 1)
  // ═══════════════════════════════════════════════════════════
  Widget _buildAppsListView(bool isDark) {
    return Column(
      key: const ValueKey('AppsList'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header Row
        Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1E3A8A).withValues(alpha: 0.5)
                    : const Color(0xFFDBEAFE),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.history_rounded,
                color: Color(0xFF2563EB),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Cross-App History',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Section Title: APPLICATIONS
        Text(
          'APPLICATIONS',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 12),

        // App Items
        Expanded(
          child: ListView.separated(
            itemCount: _apps.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final app = _apps[i];
              return _buildAppItemCard(app, isDark);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAppItemCard(CrossAppItem app, bool isDark) {
    return InkWell(
      onTap: () {
        setState(() {
          _selectedApp = app;
          _selectedTape = null;
        });
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
          ),
        ),
        child: Row(
          children: [
            _buildAppIcon(app.iconKey, isDark),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    app.name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${app.tapes.length} ${app.tapes.length == 1 ? "Tape" : "Tapes"} saved',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: isDark ? const Color(0xFF64748B) : const Color(0xFFCBD5E1),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // LEVEL 2: APP TAPES LIST (Screenshot 2 & 4)
  // ═══════════════════════════════════════════════════════════
  Widget _buildAppTapesView(bool isDark) {
    final app = _selectedApp!;
    return Column(
      key: ValueKey('AppTapes_${app.id}'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Back Header
        Row(
          children: [
            InkWell(
              onTap: () {
                setState(() {
                  _selectedApp = null;
                  _selectedTape = null;
                });
              },
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF334155)
                        : const Color(0xFFE2E8F0),
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.arrow_back_rounded,
                  size: 16,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              app.name,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),

        // Subheader: APP ICON + <APP NAME> TAPES
        Row(
          children: [
            _buildAppIcon(app.iconKey, isDark, size: 16),
            const SizedBox(width: 6),
            Text(
              '${app.name.toUpperCase()} TAPES',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                color: isDark
                    ? const Color(0xFF94A3B8)
                    : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // List of Tapes
        Expanded(
          child: ListView.separated(
            physics: const BouncingScrollPhysics(),
            itemCount: app.tapes.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final tape = app.tapes[i];
              return _buildTapeItemCard(tape, isDark);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTapeItemCard(CrossAppTape tape, bool isDark) {
    return InkWell(
      onTap: () {
        setState(() {
          _selectedTape = tape;
        });
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tape.title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${tape.dateString} • ${tape.itemCount} ${tape.itemCount == 1 ? "item" : "items"}',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              tape.totalFormatted,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.chevron_right_rounded,
              color: isDark ? const Color(0xFF64748B) : const Color(0xFFCBD5E1),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // LEVEL 3: TAPE DETAILS (Screenshot 3)
  // ═══════════════════════════════════════════════════════════
  Widget _buildTapeDetailsView(bool isDark) {
    final tape = _selectedTape!;
    final app = _selectedApp!;

    return Column(
      key: ValueKey('TapeDetails_${tape.id}'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Back Header
        Row(
          children: [
            InkWell(
              onTap: () {
                setState(() {
                  _selectedTape = null;
                });
              },
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF334155)
                        : const Color(0xFFE2E8F0),
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.arrow_back_rounded,
                  size: 16,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Tape Details',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),

        // Subheader: APP ICON + TAPE TITLE
        Row(
          children: [
            _buildAppIcon(app.iconKey, isDark, size: 16),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                tape.title.toUpperCase(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: isDark
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF64748B),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Tape Steps List
        Expanded(
          child: ListView.separated(
            physics: const BouncingScrollPhysics(),
            itemCount: tape.steps.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final step = tape.steps[i];
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF0F172A)
                      : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF334155)
                        : const Color(0xFFF1F5F9),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          step.label,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF64748B),
                            letterSpacing: 0.4,
                          ),
                        ),
                        Text(
                          step.timestamp,
                          style: TextStyle(
                            fontSize: 10,
                            color: isDark
                                ? const Color(0xFF64748B)
                                : const Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          step.expression,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          step.result,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),

        // Action: Load into Calculator
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              if (widget.onLoadTape != null) {
                widget.onLoadTape!(tape);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Loaded "${tape.title}" to Beta Calc'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            icon: const Icon(Icons.calculate_rounded, size: 18),
            label: const Text(
              'Load to Calculator',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════
  // ICON HELPER
  // ═══════════════════════════════════════════════════════════
  Widget _buildAppIcon(String iconKey, bool isDark, {double size = 28}) {
    switch (iconKey) {
      case 'bnx_mail':
        return Container(
          width: size,
          height: size,
          padding: EdgeInsets.all(size * 0.1),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(size * 0.28),
          ),
          child: Image.asset(
            'assets/bnx_mail_logo.png',
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => Icon(
              Icons.mark_email_read_rounded,
              color: const Color(0xFF2563EB),
              size: size * 0.65,
            ),
          ),
        );
      case 'bit_tool':
        return Container(
          width: size,
          height: size,
          padding: EdgeInsets.all(size * 0.1),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(size * 0.28),
          ),
          child: Image.asset(
            'assets/bit_tool_logo.png',
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => Icon(
              Icons.token_rounded,
              color: const Color(0xFF2563EB),
              size: size * 0.7,
            ),
          ),
        );
      case 'cliks':
        return SizedBox(
          width: size,
          height: size,
          child: Image.asset(
            'assets/cliks_logo.png',
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => Container(
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF10B981), width: 1.5),
              ),
              child: Icon(
                Icons.check,
                color: const Color(0xFF10B981),
                size: size * 0.6,
              ),
            ),
          ),
        );
      case 'cliks_business':
        return SizedBox(
          width: size,
          height: size,
          child: Image.asset(
            'assets/cliks_business_img.png',
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF059669), width: 1.8),
              ),
              child: Icon(
                Icons.done_all,
                color: const Color(0xFF059669),
                size: size * 0.6,
              ),
            ),
          ),
        );
      default:
        return Icon(
          Icons.apps_rounded,
          color: const Color(0xFF2563EB),
          size: size,
        );
    }
  }
}
