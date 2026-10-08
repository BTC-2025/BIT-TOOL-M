/// Models and seed data for Cross-App History in Beta Calc.
library;

class CrossAppTapeStep {
  final String label; // e.g. 'BASE VALUE' or '+'
  final String timestamp; // e.g. '15:47:42'
  final String expression; // e.g. '= 99' or '+ 1'
  final String result; // e.g. '₹99.00' or '₹100.00'
  final double value;
  final String operator;

  const CrossAppTapeStep({
    required this.label,
    required this.timestamp,
    required this.expression,
    required this.result,
    required this.value,
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
  static List<CrossAppItem> getInitialApps() {
    return [
      const CrossAppItem(
        id: 'bnx_mail',
        name: 'BNX Mail',
        iconKey: 'bnx_mail',
        tapes: [
          CrossAppTape(
            id: 'bnx_1',
            title: 'Tape - 15:47 [BNX Mail]',
            dateString: '14/08/2026 15:47',
            itemCount: 2,
            totalFormatted: '₹100.00',
            totalValue: 100.0,
            steps: [
              CrossAppTapeStep(
                label: 'BASE VALUE',
                timestamp: '15:47:42',
                expression: '= 99',
                result: '₹99.00',
                value: 99.0,
                operator: '=',
              ),
              CrossAppTapeStep(
                label: '+',
                timestamp: '15:47:44',
                expression: '+ 1',
                result: '₹100.00',
                value: 1.0,
                operator: '+',
              ),
            ],
          ),
        ],
      ),
      const CrossAppItem(
        id: 'bit_tool',
        name: 'Bit Tool',
        iconKey: 'bit_tool',
        tapes: [
          CrossAppTape(
            id: 'bt_1',
            title: 'Tape - 10:06:05',
            dateString: '07/10/2026 10:06',
            itemCount: 2,
            totalFormatted: '₹7,553.00',
            totalValue: 7553.0,
            steps: [
              CrossAppTapeStep(
                label: 'BASE VALUE',
                timestamp: '10:06:02',
                expression: '= 7500',
                result: '₹7,500.00',
                value: 7500.0,
                operator: '=',
              ),
              CrossAppTapeStep(
                label: '+',
                timestamp: '10:06:05',
                expression: '+ 53',
                result: '₹7,553.00',
                value: 53.0,
                operator: '+',
              ),
            ],
          ),
          CrossAppTape(
            id: 'bt_2',
            title: 'Tape - 11:59:06 AM',
            dateString: '21/08/2026 11:59',
            itemCount: 1,
            totalFormatted: '₹82.00',
            totalValue: 82.0,
            steps: [
              CrossAppTapeStep(
                label: 'BASE VALUE',
                timestamp: '11:59:06',
                expression: '= 82',
                result: '₹82.00',
                value: 82.0,
                operator: '=',
              ),
            ],
          ),
          CrossAppTape(
            id: 'bt_3',
            title: 'Tape - 15:11:40',
            dateString: '17/08/2026 15:11',
            itemCount: 2,
            totalFormatted: '₹91.00',
            totalValue: 91.0,
            steps: [
              CrossAppTapeStep(
                label: 'BASE VALUE',
                timestamp: '15:11:35',
                expression: '= 90',
                result: '₹90.00',
                value: 90.0,
                operator: '=',
              ),
              CrossAppTapeStep(
                label: '+',
                timestamp: '15:11:40',
                expression: '+ 1',
                result: '₹91.00',
                value: 1.0,
                operator: '+',
              ),
            ],
          ),
          CrossAppTape(
            id: 'bt_4',
            title: 'Tape - 15:11:10',
            dateString: '17/08/2026 15:11',
            itemCount: 2,
            totalFormatted: '₹90.00',
            totalValue: 90.0,
            steps: [
              CrossAppTapeStep(
                label: 'BASE VALUE',
                timestamp: '15:11:05',
                expression: '= 80',
                result: '₹80.00',
                value: 80.0,
                operator: '=',
              ),
              CrossAppTapeStep(
                label: '+',
                timestamp: '15:11:10',
                expression: '+ 10',
                result: '₹90.00',
                value: 10.0,
                operator: '+',
              ),
            ],
          ),
          CrossAppTape(
            id: 'bt_5',
            title: 'Tape - 10:07:45',
            dateString: '07/08/2026 10:07',
            itemCount: 2,
            totalFormatted: '₹3.00',
            totalValue: 3.0,
            steps: [
              CrossAppTapeStep(
                label: 'BASE VALUE',
                timestamp: '10:07:40',
                expression: '= 2',
                result: '₹2.00',
                value: 2.0,
                operator: '=',
              ),
              CrossAppTapeStep(
                label: '+',
                timestamp: '10:07:45',
                expression: '+ 1',
                result: '₹3.00',
                value: 1.0,
                operator: '+',
              ),
            ],
          ),
          CrossAppTape(
            id: 'bt_6',
            title: 'Tape - 09:55:01',
            dateString: '07/08/2026 09:55',
            itemCount: 5,
            totalFormatted: '₹94.00',
            totalValue: 94.0,
            steps: [
              CrossAppTapeStep(
                label: 'BASE VALUE',
                timestamp: '09:54:40',
                expression: '= 20',
                result: '₹20.00',
                value: 20.0,
                operator: '=',
              ),
              CrossAppTapeStep(
                label: '+',
                timestamp: '09:54:45',
                expression: '+ 20',
                result: '₹40.00',
                value: 20.0,
                operator: '+',
              ),
              CrossAppTapeStep(
                label: '+',
                timestamp: '09:54:50',
                expression: '+ 20',
                result: '₹60.00',
                value: 20.0,
                operator: '+',
              ),
              CrossAppTapeStep(
                label: '+',
                timestamp: '09:54:55',
                expression: '+ 20',
                result: '₹80.00',
                value: 20.0,
                operator: '+',
              ),
              CrossAppTapeStep(
                label: '+',
                timestamp: '09:55:01',
                expression: '+ 14',
                result: '₹94.00',
                value: 14.0,
                operator: '+',
              ),
            ],
          ),
        ],
      ),
      const CrossAppItem(
        id: 'cliks',
        name: 'Cliks',
        iconKey: 'cliks',
        tapes: [
          CrossAppTape(
            id: 'cliks_1',
            title: 'Tape - 14:20:00 [Cliks]',
            dateString: '05/10/2026 14:20',
            itemCount: 3,
            totalFormatted: '₹2,450.00',
            totalValue: 2450.0,
            steps: [
              CrossAppTapeStep(
                label: 'BASE VALUE',
                timestamp: '14:19:40',
                expression: '= 2000',
                result: '₹2,000.00',
                value: 2000.0,
                operator: '=',
              ),
              CrossAppTapeStep(
                label: '+',
                timestamp: '14:19:50',
                expression: '+ 400',
                result: '₹2,400.00',
                value: 400.0,
                operator: '+',
              ),
              CrossAppTapeStep(
                label: '+',
                timestamp: '14:20:00',
                expression: '+ 50',
                result: '₹2,450.00',
                value: 50.0,
                operator: '+',
              ),
            ],
          ),
          CrossAppTape(
            id: 'cliks_2',
            title: 'Tape - 11:15:22 [Cliks]',
            dateString: '02/10/2026 11:15',
            itemCount: 2,
            totalFormatted: '₹320.00',
            totalValue: 320.0,
            steps: [
              CrossAppTapeStep(
                label: 'BASE VALUE',
                timestamp: '11:15:10',
                expression: '= 300',
                result: '₹300.00',
                value: 300.0,
                operator: '=',
              ),
              CrossAppTapeStep(
                label: '+',
                timestamp: '11:15:22',
                expression: '+ 20',
                result: '₹320.00',
                value: 20.0,
                operator: '+',
              ),
            ],
          ),
        ],
      ),
      const CrossAppItem(
        id: 'cliks_business',
        name: 'Cliks Business',
        iconKey: 'cliks_business',
        tapes: [
          CrossAppTape(
            id: 'cb_1',
            title: 'Tape - 16:45:10 [Invoice]',
            dateString: '06/10/2026 16:45',
            itemCount: 4,
            totalFormatted: '₹12,890.00',
            totalValue: 12890.0,
            steps: [
              CrossAppTapeStep(
                label: 'BASE VALUE',
                timestamp: '16:44:30',
                expression: '= 10000',
                result: '₹10,000.00',
                value: 10000.0,
                operator: '=',
              ),
              CrossAppTapeStep(
                label: '+',
                timestamp: '16:44:45',
                expression: '+ 2000',
                result: '₹12,000.00',
                value: 2000.0,
                operator: '+',
              ),
              CrossAppTapeStep(
                label: '+',
                timestamp: '16:45:00',
                expression: '+ 800',
                result: '₹12,800.00',
                value: 800.0,
                operator: '+',
              ),
              CrossAppTapeStep(
                label: '+',
                timestamp: '16:45:10',
                expression: '+ 90',
                result: '₹12,890.00',
                value: 90.0,
                operator: '+',
              ),
            ],
          ),
        ],
      ),
    ];
  }
}
