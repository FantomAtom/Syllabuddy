// lib/screens/exams_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'hall_allotments_demo.dart';
import 'package:syllabuddy/theme.dart';
import 'package:syllabuddy/widgets/app_header.dart';
import 'package:syllabuddy/styles/app_styles.dart';

class ExamsScreen extends StatelessWidget {
  const ExamsScreen({Key? key}) : super(key: key);

  DateTime? _toDateTime(dynamic maybe) {
    if (maybe == null) return null;
    try {
      if (maybe is Timestamp) return maybe.toDate();
      if (maybe is int) return DateTime.fromMillisecondsSinceEpoch(maybe);
      if (maybe is String) return DateTime.parse(maybe);
      if (maybe is Map) {
        final secondsKey = maybe.containsKey('_seconds') ? '_seconds' : (maybe.containsKey('seconds') ? 'seconds' : null);
        final nanosKey = maybe.containsKey('_nanoseconds') ? '_nanoseconds' : (maybe.containsKey('nanoseconds') ? 'nanoseconds' : null);
        if (secondsKey != null) {
          final secondsVal = maybe[secondsKey];
          final nanosVal = nanosKey != null ? maybe[nanosKey] ?? 0 : 0;
          final secondsInt = (secondsVal is num) ? secondsVal.toInt() : int.tryParse(secondsVal.toString()) ?? 0;
          final nanosInt = (nanosVal is num) ? nanosVal.toInt() : int.tryParse(nanosVal.toString()) ?? 0;
          return DateTime.fromMillisecondsSinceEpoch(secondsInt * 1000 + (nanosInt ~/ 1000000));
        }
      }
    } catch (_) {}
    return null;
  }

  Map<String, DateTime?> _computeRange(List<dynamic>? subjects) {
    final dates = <DateTime>[];
    if (subjects != null) {
      for (final s in subjects) {
        try {
          final d = _toDateTime(s['date']);
          if (d != null) dates.add(d);
        } catch (_) {}
      }
    }
    if (dates.isEmpty) return {'start': null, 'end': null};
    dates.sort();
    return {'start': dates.first, 'end': dates.last};
  }

  String _formatDateRange(DateTime? start, DateTime? end) {
    if (start == null && end == null) return 'No dates';
    if (start != null && end != null) {
      final s = '${start.toLocal()}'.split(' ')[0];
      final e = '${end.toLocal()}'.split(' ')[0];
      return s == e ? s : '$s — $e';
    }
    final only = (start ?? end)!;
    return '${only.toLocal()}'.split(' ')[0];
  }

  void _showExamDetails(BuildContext context, Map<String, dynamic> data) {
    final subjects = (data['subjects'] as List<dynamic>?) ?? [];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: Wrap(
            children: [
              ListTile(
                title: Text(data['examName']?.toString() ?? 'Exam'),
                subtitle: Text('${data['degreeId'] ?? ''} • ${data['departmentId'] ?? ''}'),
              ),
              const Divider(),
              if (subjects.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No subjects recorded for this exam.'),
                )
              else
                ...subjects.map((s) {
                  final subjectId = s['subjectId']?.toString() ?? 'unknown';
                  final display = s['displayName']?.toString() ?? subjectId;
                  final ts = _toDateTime(s['date']);
                  final dateText = ts != null ? '${ts.toLocal()}'.split(' ')[0] : 'No date';
                  return ListTile(
                    title: Text(display),
                    subtitle: Text(subjectId),
                    trailing: Text(dateText),
                  );
                }).toList(),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  LinearGradient _primaryGradient(Color base) {
    final h = HSLColor.fromColor(base);
    final darker = h.withLightness((h.lightness - 0.12).clamp(0.0, 1.0)).toColor();
    return LinearGradient(colors: [darker, base], stops: const [0.0, 0.5], begin: Alignment.bottomCenter, end: Alignment.topCenter);
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    final now = DateTime.now();
    final stream = FirebaseFirestore.instance.collection('exam-sets').orderBy('createdAt', descending: true).snapshots();

    // FAB styled to match AppPrimaryButton (gradient + rounded + ripple)
    Widget _buildPrimaryFab() {
      final grad = AppStyles.primaryGradient(context);
      final borderRadius = BorderRadius.circular(AppStyles.radiusLarge);

      return Container(
        // make the container slightly larger than default FAB for a modern extended look
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(gradient: grad, borderRadius: borderRadius, boxShadow: [AppStyles.shadow(context)]),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: borderRadius,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HallAllotmentsDemo())),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                SizedBox(width: 8),
                Icon(Icons.view_list, color: Colors.white, size: 18),
                SizedBox(width: 10),
                Text('Halls', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                SizedBox(width: 8),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      // place the custom-decorated widget in the floatingActionButton slot
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 6, right: 6),
        child: _buildPrimaryFab(),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: Column(
        children: [
          const AppHeader(title: 'Exams', showBack: true),

          // small section heading + optional subtle description
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 18, 24, 6),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Exam schedules',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Theme.of(context).textTheme.bodyMedium?.color),
                  ),
                ),
              ],
            ),
          ),

          // content stream
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: stream,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                if (snap.hasError) return Center(child: Text('Error: ${snap.error}', style: TextStyle(color: Theme.of(context).colorScheme.error)));

                final docs = snap.data?.docs ?? [];
                final enriched = <Map<String, dynamic>>[];

                for (final d in docs) {
                  final data = d.data();
                  final subjects = data['subjects'] as List<dynamic>?;
                  final range = _computeRange(subjects);
                  enriched.add({
                    'id': d.id,
                    'data': data,
                    'start': range['start'] as DateTime?,
                    'end': range['end'] as DateTime?,
                  });
                }

                final ongoing = <Map<String, dynamic>>[];
                final upcoming = <Map<String, dynamic>>[];
                final undated = <Map<String, dynamic>>[];

                for (final e in enriched) {
                  final s = e['start'] as DateTime?;
                  final en = e['end'] as DateTime?;
                  if (s == null && en == null) {
                    undated.add(e);
                    continue;
                  }
                  final start = s ?? en!;
                  final end = en ?? s!;
                  final nowDate = DateTime(now.year, now.month, now.day);
                  final startDate = DateTime(start.year, start.month, start.day);
                  final endDate = DateTime(end.year, end.month, end.day);

                  if (!endDate.isBefore(nowDate) && !startDate.isAfter(nowDate)) {
                    ongoing.add(e);
                  } else if (startDate.isAfter(nowDate)) {
                    upcoming.add(e);
                  } else {
                    // past -> ignore in main lists
                  }
                }

                ongoing.sort((a, b) {
                  final aEnd = a['end'] as DateTime?;
                  final bEnd = b['end'] as DateTime?;
                  return (aEnd ?? DateTime.fromMillisecondsSinceEpoch(0)).compareTo(bEnd ?? DateTime.fromMillisecondsSinceEpoch(0));
                });
                upcoming.sort((a, b) {
                  final aStart = a['start'] as DateTime?;
                  final bStart = b['start'] as DateTime?;
                  return (aStart ?? DateTime.fromMillisecondsSinceEpoch(0)).compareTo(bStart ?? DateTime.fromMillisecondsSinceEpoch(0));
                });

                final content = <Widget>[];
                content.add(const SizedBox(height: 8));

                if (ongoing.isNotEmpty) {
                  content.add(Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text('Ongoing', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).textTheme.bodyMedium?.color)),
                  ));
                  content.add(const SizedBox(height: 8));
                  for (final e in ongoing) {
                    final data = e['data'] as Map<String, dynamic>;
                    final id = e['id'] as String;
                    final name = (data['examName'] ?? id).toString();
                    final start = e['start'] as DateTime?;
                    final end = e['end'] as DateTime?;
                    final rangeText = _formatDateRange(start, end);
                    final subjects = (data['subjects'] as List<dynamic>?) ?? [];

                    content.add(Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: _ExamCard(
                        title: name,
                        subtitle: '${data['degreeId'] ?? ''} • ${data['departmentId'] ?? ''}',
                        meta: rangeText,
                        badge: '${subjects.length} subjects',
                        onTap: () => _showExamDetails(context, data),
                        primary: primary,
                      ),
                    ));
                    content.add(const SizedBox(height: 12));
                  }
                }

                if (upcoming.isNotEmpty) {
                  content.add(Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text('Upcoming', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).textTheme.bodyMedium?.color)),
                  ));
                  content.add(const SizedBox(height: 8));
                  for (final e in upcoming) {
                    final data = e['data'] as Map<String, dynamic>;
                    final id = e['id'] as String;
                    final name = (data['examName'] ?? id).toString();
                    final start = e['start'] as DateTime?;
                    final end = e['end'] as DateTime?;
                    final rangeText = _formatDateRange(start, end);
                    final subjects = (data['subjects'] as List<dynamic>?) ?? [];

                    content.add(Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: _ExamCard(
                        title: name,
                        subtitle: '${data['degreeId'] ?? ''} • ${data['departmentId'] ?? ''}',
                        meta: rangeText,
                        badge: '${subjects.length} subjects',
                        onTap: () => _showExamDetails(context, data),
                        primary: primary,
                      ),
                    ));
                    content.add(const SizedBox(height: 12));
                  }
                }

                if (undated.isNotEmpty) {
                  content.add(Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text('Scheduled (no dates)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).textTheme.bodyMedium?.color)),
                  ));
                  content.add(const SizedBox(height: 8));
                  for (final e in undated) {
                    final data = e['data'] as Map<String, dynamic>;
                    final id = e['id'] as String;
                    final name = (data['examName'] ?? id).toString();
                    final subjects = (data['subjects'] as List<dynamic>?) ?? [];

                    content.add(Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: _ExamCard(
                        title: name,
                        subtitle: '${data['degreeId'] ?? ''} • ${data['departmentId'] ?? ''}',
                        meta: 'No dates assigned',
                        badge: '${subjects.length} subjects',
                        onTap: () => _showExamDetails(context, data),
                        primary: primary,
                      ),
                    ));
                    content.add(const SizedBox(height: 12));
                  }
                }

                if (ongoing.isEmpty && upcoming.isEmpty && undated.isEmpty) {
                  content.add(const SizedBox(height: 40));
                  content.add(Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Center(
                      child: Text('No upcoming or ongoing exams.', style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6))),
                    ),
                  ));
                }

                content.add(const SizedBox(height: 40));

                return ListView(padding: EdgeInsets.zero, children: [const SizedBox(height: 8), ...content]);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ExamCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String meta;
  final String badge;
  final VoidCallback onTap;
  final Color primary;

  const _ExamCard({
    required this.title,
    required this.subtitle,
    required this.meta,
    required this.badge,
    required this.onTap,
    required this.primary,
  });

  Color _deriveSurface(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? Theme.of(context).cardColor : Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    final surface = _deriveSurface(context);
    final textColor = Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black87;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
          boxShadow: [AppStyles.shadow(context)],
        ),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: primary.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
              child: Icon(Icons.calendar_today, color: primary, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primary)),
                const SizedBox(height: 6),
                Text(subtitle, style: TextStyle(fontSize: 13, color: textColor)),
                const SizedBox(height: 6),
                Text(meta, style: TextStyle(fontSize: 12, color: textColor.withOpacity(0.7))),
              ]),
            ),
            const SizedBox(width: 8),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(badge, style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
                const SizedBox(height: 8),
                Icon(Icons.arrow_forward_ios, size: 16, color: primary),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
