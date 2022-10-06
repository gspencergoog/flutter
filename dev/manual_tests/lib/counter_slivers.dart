// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;
import 'package:flutter/material.dart';

void main() {
  runApp(
    MaterialApp(
      theme: ThemeData.dark(useMaterial3: true),
      home: const FullOfStars(),
    ),
  );
}

class FullOfStars extends StatefulWidget {
  const FullOfStars({super.key});

  @override
  State<FullOfStars> createState() => _FullOfStarsState();
}

class _FullOfStarsState extends State<FullOfStars> {
  GlobalKey<SliverAnimatedGridState> gridKey = GlobalKey<SliverAnimatedGridState>();
  int starCount = 0;

  void _countChanged(int count) {
    if (count != starCount) {
      setState(() {
        starCount = count;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool smallScreen = MediaQuery.of(context).size.width < 600;
    return DefaultTextStyle(
      style: Theme.of(context).textTheme.displayMedium!.copyWith(fontSize: smallScreen ? 20 : null),
      child: CustomScrollView(
        slivers: <Widget>[
          SliverAppBar(
            pinned: true,
            toolbarHeight: 80,
            backgroundColor: Theme.of(context).secondaryHeaderColor.withOpacity(0.5),
            leading: const FlutterLogo(),
            actions: <Widget>[
              _ModifyStarsButton(
                gridKey: gridKey,
                starCount: starCount,
                onCountChanged: _countChanged,
              ),
              _ModifyStarsButton(
                gridKey: gridKey,
                starCount: starCount,
                onCountChanged: _countChanged,
                increment: -1,
                icon: Icons.remove_rounded,
              )
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverAnimatedGrid(
              key: gridKey,
              initialItemCount: starCount,
              gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: MediaQuery.of(context).size.width < 600 ? 60 : 150.0,
                mainAxisSpacing: 20.0,
                crossAxisSpacing: 20.0,
              ),
              itemBuilder: (BuildContext context, int index, Animation<double> animation) =>
                  _StarTile(index, animation),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModifyStarsButton extends StatelessWidget {
  const _ModifyStarsButton({
    required this.gridKey,
    required this.starCount,
    required this.onCountChanged,
    this.icon = Icons.add_rounded,
    this.increment = 1,
  });

  final GlobalKey<SliverAnimatedGridState> gridKey;
  final int starCount;
  final int increment;
  final IconData icon;
  final Function(int count) onCountChanged;

  void _modify() {
    final int newCount = starCount + increment;
    onCountChanged(newCount);
    if (increment < 0) {
      for (int i = starCount - 1; i >= newCount; i -= 1) {
        gridKey.currentState!.removeItem(i, (BuildContext context, Animation<double> animation) {
          return _StarTile(i, animation);
        });
      }
    } else {
      gridKey.currentState!.insertItem(newCount - 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: IconButton(
        onPressed: (starCount + increment) >= 0 ? _modify : null,
        icon: Icon(icon),
      ),
    );
  }
}

class _StarTile extends StatelessWidget {
  const _StarTile(this.index, this.animation);

  final int index;
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (BuildContext context, Widget? child) {
        return Container(
          key: UniqueKey(),
          alignment: Alignment.center,
          decoration: ShapeDecoration(
            shape: StarBorder(
              points: 2 + index * animation.value,
              innerRadiusRatio: 0.5 + math.atan((index - 1) / 10) / math.pi,
              valleyRounding: .2,
              pointRounding: .2,
              side: BorderSide(
                color: HSLColor.fromAHSL(1, index * 10 % 360.0, 1.0, 0.6).toColor(),
                width: MediaQuery.of(context).size.width < 600 ? 2 : 6,
              ),
            ),
            color: HSLColor.fromAHSL(1, index * 10 % 360.0, 1.0, 0.4).toColor(),
          ),
          child: Text('${(index * animation.value).round() + 2}'),
        );
      },
    );
  }
}

/// Demonstrates how to use/create:
/// - MaterialApp w/Material 3
/// - Theming (at least at the app level), with color themes
/// - MediaQuery for adaptive apps
/// - Containers
/// - Padding
/// - Builders, including AnimatedBuilder
/// - Text, with style
/// - Decorations
/// - Building your own stateless widgets
/// - Building your own stateful widgets, including how to use setState.
/// - Slivers
/// - Scrolling (with slivers)
/// - GlobalKeys
/// - How reactive programming works
/// - Private widget classes
