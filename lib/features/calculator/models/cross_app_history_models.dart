/// Models for Cross-App History in Beta Calc.
library;

class CrossAppTapeStep {
  final String id;
  final String label; // e.g. 'BASE VALUE' or '+'
  final String timestamp; // e.g. '15:47:42'
  final String expression; // e.g. '= 99' or '+ 1'
  final String result; // e.g. '₹99.00' or '₹100.00'
  final double value;
  final double runningTotal;
  final String operator;

  const CrossAppTapeStep({
    this.id = '',
    required this.label,
    required this.timestamp,
    required this.expression,
    required this.result,
    required this.value,
    this.runningTotal = 0.0,
    this.operator = '+',
  });
}

class CrossAppTape {
  final String id;
  final String title;
  final String dateString;
  final int itemCount;
  final String totalFormatted;
  final double totalValue;
  final List<CrossAppTapeStep> steps;

  double get totalAmount => totalValue;

  const CrossAppTape({
    required this.id,
    required this.title,
    required this.dateString,
    required this.itemCount,
    required this.totalFormatted,
    required this.totalValue,
    required this.steps,
  });
}

class CrossAppItem {
  final String id;
  final String name;
  final String iconKey; // 'bnx_mail', 'bit_tool', 'cliks', 'cliks_business'
  final List<CrossAppTape> tapes;

  const CrossAppItem({
    required this.id,
    required this.name,
    required this.iconKey,
    required this.tapes,
  });
}

class CrossAppHistoryData {
  /// Returns the standard application groups with zero initial tapes.
  /// All tapes and counts are derived strictly from the authenticated API.
  static List<CrossAppItem> getInitialApps() {
    return const [
      CrossAppItem(
        id: 'bnx_mail',
        name: 'BNX Mail',
        iconKey: 'bnx_mail',
        tapes: [],
      ),
      CrossAppItem(
        id: 'bit_tool',
        name: 'Bit Tool',
        iconKey: 'bit_tool',
        tapes: [],
      ),
      CrossAppItem(
        id: 'cliks',
        name: 'Cliks',
        iconKey: 'cliks',
        tapes: [],
      ),
      CrossAppItem(
        id: 'cliks_business',
        name: 'Cliks Business',
        iconKey: 'cliks_business',
        tapes: [],
      ),
    ];
  }
}
