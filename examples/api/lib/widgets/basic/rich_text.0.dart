// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Flutter code sample for [RichText].

void main() => runApp(const RichTextApp());

class RichTextApp extends StatelessWidget {
  const RichTextApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('RichText Sample')),
        body: const RichTextExample(),
      ),
    );
  }
}

class RichTextExample extends StatefulWidget {
  const RichTextExample({super.key});

  @override
  State<RichTextExample> createState() => _RichTextExampleState();
}

class _RichTextExampleState extends State<RichTextExample> with SingleTickerProviderStateMixin {
  final List<InlineSpan> _spans = <InlineSpan>[];
  SelectedContent selectedContent = const SelectedContent(plainText: '', fullText: '');

  void _tellMeMore(SelectableRegionState selectableRegionState) {
    int insertionPoint = -1;
    // debugPrint('TELL ME: Selected: ${selectedContent.plainText}\nRange: ${selectedContent.range}');
    final List<InlineSpan> newSpans = <InlineSpan>[];
    final List<InlineSpan> collectedSpans = <InlineSpan>[];
    String collectedText = '';
    final int start = selectedContent.range.start;
    final int end = selectedContent.range.end;
    int count = 0;
    for (final InlineSpan span in _spans) {
      final String spanText = span.toPlainText();
      // Get the start and end in terms of the local span start and end.
      // Values can be negative, which indicates that this span is
      // outside of the selected range.
      final int spanStart = start - collectedText.length;
      final int spanEnd = end - collectedText.length;
      try {
        if (spanEnd < 0 || spanStart > spanText.length) {
          // Outside of the selected area, so just add the span.
          newSpans.add(span);
          continue;
        }
        if (spanStart >= 0 && spanEnd < spanText.length) {
          // Selection is just within this span, so split it into three.
          if (spanStart > 0) {
            // Skip the first one if spanStart is zero.
            newSpans.add(TextSpan(
              text: spanText.substring(0, spanStart),
              style: span.style,
            ));
            count += 1;
          }
          collectedSpans.add(
            TextSpan(
              text: spanText.substring(spanStart, spanEnd),
              style: span.style,
            ),
          );
          newSpans.add(
            TextSpan(
              text: spanText.substring(spanEnd),
              style: span.style,
            ),
          );
          insertionPoint = count;
        } else if (spanStart < 0 && spanEnd >= spanText.length) {
          // Selection contains this entire span, so just add it to the
          // collection.
          collectedSpans.add(span);
        } else if (spanStart < 0) {
          // Selection ends in this span.
          collectedSpans.add(
            TextSpan(
              text: spanText.substring(0, spanEnd),
              style: span.style,
            ),
          );
          newSpans.add(
            TextSpan(
              text: spanText.substring(spanEnd),
              style: span.style,
            ),
          );
        } else if (spanEnd < spanText.length) {
          // Selection starts in this span.
          newSpans.add(
            TextSpan(
              text: spanText.substring(0, spanEnd),
              style: span.style,
            ),
          );
          collectedSpans.add(
            TextSpan(
              text: spanText.substring(spanEnd),
              style: span.style,
            ),
          );
          insertionPoint = count;
        }
      } finally {
        count += 1;
        collectedText = '$collectedText${span.toPlainText()}';
      }
    }
    // Insert the collected spans at the insertion point.
    newSpans.insert(insertionPoint, const TextSpan(text: '\n'));
    newSpans.insert(insertionPoint, DetailSpan(children: collectedSpans));
    newSpans.insert(insertionPoint, const TextSpan(text: '\n'));
    setState(() {
      _spans.clear();
      _spans.addAll(newSpans);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_spans.isEmpty) {
      _spans.addAll(<InlineSpan>[
        TextSpan(
            text: 'The Essential Woodworking Hand Plane:  Types and Applications\n',
            style: Theme.of(context).textTheme.headline6),
        const TextSpan(
          text: 'Woodworking hand planes are timeless tools that, in the skilled '
              'hands of a craftsman, transform rough lumber into finely finished '
              'pieces. These deceptively simple devices use sharp blades to '
              'shave thin layers from wood, achieving a precision and smoothness '
              'that power tools often struggle to replicate.\n\n',
        ),
        const TextSpan(
          text: 'categories of hand planes exist, each with unique roles in the '
              'woodworking process. Bench planes, the workhorses of the plane '
              'family, come in various sizes. The versatile jack plane excels '
              'at rough stock removal, while longer jointer planes create '
              'perfectly flat surfaces ideal for joinery. Smoothing planes, as '
              'their name suggests, leave behind a glass-like finish before '
              'sanding.\n\n',
        ),
        const TextSpan(
          text: 'Block planes stand apart, designed for one-handed use with blades '
              'oriented at lower angles. These are ideal for end grain work, '
              'chamfering edges, and tasks requiring maneuverability.  Shoulder '
              'planes are specialists for trimming joints like tenons, their '
              "blades extending to the edges of the tool's body for precision.\n\n",
        ),
        const TextSpan(
          text: 'Beyond these primary types lie more niche planes. Rabbet planes '
              'create stepped edges for joinery. Molding planes shape complex '
              'decorative profiles. Specialty planes, like the compass plane, '
              "handle curves with finesse. With such an array, a  woodworker's "
              'hand plane collection becomes a testament to their skill and the '
              'breadth of projects they undertake.\n\n',
        ),
        const TextSpan(
          text: 'Mastering hand planes is a satisfying journey. The rhythmic '
              'motion of shaving wood, the whisper of the blade, and the '
              'beauty of a freshly planed surface are all part of their appeal. '
              'Hand planes offer a level of control and connection to the '
              "material that power tools simply can't provide.  They embody the "
              'intersection of craftsmanship, tradition, and the simple joy of '
              'working with wood.\n\n',
        ),
      ]);
    }

    return Container(
      color: Colors.lightBlueAccent,
      alignment: Alignment.center,
      width: double.infinity,
      child: SelectionArea(
        onSelectionChanged: (SelectedContent? value) {
          setState(() {
            selectedContent = value ?? const SelectedContent(plainText: '', fullText: '');
            // debugPrint(
            //     'SET: Selected: ${selectedContent.plainText}\nRange: ${selectedContent.range}\nFullText: ${selectedContent.fullText}');
          });
        },
        contextMenuBuilder: (
          BuildContext context,
          SelectableRegionState selectableRegionState,
        ) {
          return AdaptiveTextSelectionToolbar.buttonItems(
            anchors: selectableRegionState.contextMenuAnchors,
            buttonItems: <ContextMenuButtonItem>[
              ...selectableRegionState.contextMenuButtonItems,
              ContextMenuButtonItem(
                onPressed: () {
                  ContextMenuController.removeAny();
                  _tellMeMore(selectableRegionState);
                },
                label: 'Tell Me More',
              ),
            ],
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text.rich(
            textAlign: TextAlign.start,
            TextSpan(
              children: _spans,
            ),
          ),
        ),
      ),
    );
  }
}

class DetailBox extends StatelessWidget {
  const DetailBox({super.key, required this.children});

  final List<InlineSpan> children;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: 50),
        duration: const Duration(seconds: 1),
        curve: Curves.easeInOut,
        builder: (BuildContext context, double value, Widget? child) {
          return Container(
            decoration: ShapeDecoration(
              color: Colors.orange,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            height: value,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text.rich(
                TextSpan(children: children),
                textAlign: TextAlign.start,
              ),
            ),
          );
        });
  }
}

class DetailSpan extends WidgetSpan {
  DetailSpan({
    required List<InlineSpan> children,
  }) : super(child: DetailBox(children: children));
}
