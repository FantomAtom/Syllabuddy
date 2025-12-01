// lib/widgets/unit_expansion.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../styles/app_styles.dart';

/// Polished, modern expansion widget for subject units.
/// - looks consistent with AppOptionCard / OptionCard via AppStyles
/// - has a rotating chevron, AnimatedSize content, copy action and optional share callback
class UnitExpansion extends StatefulWidget {
  final String title;
  final String content;
  final bool initiallyExpanded;
  final VoidCallback? onCopied;

  const UnitExpansion({
    Key? key,
    required this.title,
    required this.content,
    this.initiallyExpanded = false,
    this.onCopied,
  }) : super(key: key);

  @override
  State<UnitExpansion> createState() => _UnitExpansionState();
}

class _UnitExpansionState extends State<UnitExpansion> with SingleTickerProviderStateMixin {
  late bool _expanded;
  late AnimationController _ctrl;
  late Animation<double> _chevAnim;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 220));
    _chevAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
    if (_expanded) _ctrl.value = 1.0;
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _expanded = !_expanded);
    if (_expanded) {
      _ctrl.forward();
    } else {
      _ctrl.reverse();
    }
  }

  void _copyToClipboard() {
    if (widget.content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No content to copy.')));
      return;
    }
    Clipboard.setData(ClipboardData(text: widget.content));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied to clipboard!')));
    widget.onCopied?.call();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = theme.cardColor;
    final textColor = theme.textTheme.bodyMedium?.color ?? Colors.black;
    final iconColor = theme.primaryColor;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
        boxShadow: [AppStyles.shadow(context)],
        border: Border.all(color: theme.dividerColor.withOpacity(0.06)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
        child: Column(
          children: [
            // Header row
            InkWell(
              onTap: _toggle,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.title,
                        style: TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                        ),
                      ),
                    ),

                    // copy button
                    IconButton(
                      icon: const Icon(Icons.copy, size: 20),
                      color: iconColor,
                      tooltip: 'Copy content',
                      onPressed: widget.content.isNotEmpty ? _copyToClipboard : null,
                    ),

                    // rotating chevron
                    RotationTransition(
                      turns: Tween<double>(begin: 0, end: 0.5).animate(_chevAnim),
                      child: Icon(Icons.expand_more, color: textColor),
                    ),
                  ],
                ),
              ),
            ),

            // Animated content area
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeInOut,
              child: ConstrainedBox(
                constraints: _expanded ? const BoxConstraints() : const BoxConstraints(maxHeight: 0),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: widget.content.isNotEmpty
                      ? Text(
                          widget.content,
                          style: const TextStyle(fontSize: 15, height: 1.6),
                        )
                      : Text('No content.', style: TextStyle(color: textColor?.withOpacity(0.7))),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
