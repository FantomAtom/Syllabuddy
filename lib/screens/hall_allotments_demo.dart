// lib/screens/hall_allotments_demo.dart
import 'package:flutter/material.dart';
import 'package:syllabuddy/theme.dart';

class HallAllotmentsDemo extends StatelessWidget {
  const HallAllotmentsDemo({Key? key}) : super(key: key);

  // Sample data (10 rows).
  List<Map<String, dynamic>> get sampleRows => [
        {
          'sno': 1,
          'deptLeft': 'BCA I\nBCOM II',
          'regsLeft': '25CA01, 25CA02, 25CA03\n25CO01, 25CO02, 25CO03',
          'hall': 'F1',
        },
        {
          'sno': 2,
          'deptLeft': 'BCA II\nBCOM I',
          'regsLeft': '25CA04, 25CA05, 25CA06\n25CO04, 25CO05, 25CO06',
          'hall': 'F2',
        },
        {
          'sno': 3,
          'deptLeft': 'BBA I\nBSC II',
          'regsLeft': '25BB01, 25BB02, 25BB03\n25BS01, 25BS02, 25BS03',
          'hall': 'F3',
        },
        {
          'sno': 4,
          'deptLeft': 'BBA II\nBSC I',
          'regsLeft': '25BB04, 25BB05, 25BB06\n25BS04, 25BS05, 25BS06',
          'hall': 'F4',
        },
        {
          'sno': 5,
          'deptLeft': 'BCA III\nBCOM II',
          'regsLeft': '23CA30, 23CA31, 23CA32\n23CO21, 23CO22, 23CO23',
          'hall': 'G1',
        },
        {
          'sno': 6,
          'deptLeft': 'BSC III\nBBA I',
          'regsLeft': '23BS40, 23BS41, 23BS42\n25BB07, 25BB08, 25BB09',
          'hall': 'G2',
        },
        {
          'sno': 7,
          'deptLeft': 'BCOM III\nBCA I',
          'regsLeft': '23CO31, 23CO32, 23CO33\n25CA07, 25CA08, 25CA09',
          'hall': 'G3',
        },
        {
          'sno': 8,
          'deptLeft': 'BBA III\nBCOM I',
          'regsLeft': '23BB50, 23BB51, 23BB52\n25CO07, 25CO08, 25CO09',
          'hall': 'G4',
        },
        {
          'sno': 9,
          'deptLeft': 'BSC I\nBCA II',
          'regsLeft': '25BS07, 25BS08, 25BS09\n25CA10, 25CA11, 25CA12',
          'hall': 'H1',
        },
        {
          'sno': 10,
          'deptLeft': 'BCOM II\nBBA II',
          'regsLeft': '25CO10, 25CO11, 25CO12\n25BB10, 25BB11, 25BB12',
          'hall': 'H2',
        },
      ];

  Widget _buildHeader(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    return ClipRRect(
      borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(40), bottomRight: Radius.circular(40)),
      child: Container(
        width: double.infinity,
        color: primary,
        // RESTORED: original padding values
        padding: const EdgeInsets.only(top: 80, bottom: 40),
        child: Center(
          child: Text(
            'Hall Allotments',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white.withOpacity(0.95)),
          ),
        ),
      ),
    );
  }

  TableRow _buildHeaderRow(BuildContext context) {
  final primary = Theme.of(context).primaryColor;

  return TableRow(
    decoration: const BoxDecoration(color: kPrimaryColor),
    children: [
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          'S.NO',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          'YEAR/DEPT',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          'REG.NO',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          'HALL NO.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    ],
  );
}


  List<TableRow> _buildDataRows() {
    return sampleRows.map((r) {
      return TableRow(children: [
        Padding(padding: const EdgeInsets.all(12.0), child: Text(r['sno'].toString(), textAlign: TextAlign.center)),
        Padding(padding: const EdgeInsets.all(12.0), child: Text(r['deptLeft'], textAlign: TextAlign.center)),
        Padding(padding: const EdgeInsets.all(12.0), child: Text(r['regsLeft'], textAlign: TextAlign.center)),
        Padding(padding: const EdgeInsets.all(12.0), child: Text(r['hall'], textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold))),
      ]);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    // bottom padding so content doesn't butt against nav bars (or bottom insets)
    final double bottomInset = MediaQuery.of(context).padding.bottom + 12.0;

    return Scaffold(
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            // Header (original style restored)
            _buildHeader(context),

            const SizedBox(height: 12),

            // Expandable content area (table) - scrolls vertically and horizontally
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    // Vertical scroll that contains a horizontally scrollable table.
                    child: SingleChildScrollView(
                      // vertical scroll
                      child: SingleChildScrollView(
                        // horizontal scroll for wide table
                        scrollDirection: Axis.horizontal,
                        child: ConstrainedBox(
                          // ensure table takes at least the viewport width so horizontal scroll behaves well
                          constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width - 24),
                          child: Padding(
                            padding: EdgeInsets.only(bottom: bottomInset),
                            child: Table(
                              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                              border: TableBorder.all(color: Colors.black54, width: 1),
                              columnWidths: const {
                                0: FixedColumnWidth(56),
                                1: FixedColumnWidth(220),
                                2: FixedColumnWidth(260),
                                3: FixedColumnWidth(96),
                              },
                              children: [
                                _buildHeaderRow(context),
                                ..._buildDataRows(),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
