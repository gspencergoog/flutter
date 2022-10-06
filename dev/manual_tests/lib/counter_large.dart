// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;
import 'package:flutter/material.dart';

void main() {
  runApp(
    MaterialApp(
      theme: ThemeData(
        brightness: Brightness.dark,
        colorSchemeSeed: const Color(0xff6750a4),
        useMaterial3: true,
      ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: _StarControls(
        gridKey: gridKey,
        starCount: starCount,
        onCountChanged: (int count) {
          if (count != starCount) {
            setState(() {
              starCount = count;
            });
          }
        },
      ),
      body: _StarView(
        gridKey: gridKey,
        starCount: starCount,
      ),
    );
  }
}

class _StarControls extends StatelessWidget {
  const _StarControls({required this.gridKey, required this.starCount, required this.onCountChanged});

  final GlobalKey<SliverAnimatedGridState> gridKey;
  final int starCount;
  final Function(int count) onCountChanged;

  void _addStar() {
    gridKey.currentState!.insertItem(starCount);
    onCountChanged(starCount + 1);
  }

  void _removeStar() {
    final int newCount = starCount - 1;
    gridKey.currentState!.removeItem(
      newCount,
      (BuildContext context, Animation<double> animation) => _StarTile(newCount, animation),
      duration: const Duration(milliseconds: 200),
    );
    onCountChanged(newCount);
  }

  void _resetStars() {
    for (int i = starCount - 1; i >= 0; i -= 1) {
      gridKey.currentState!.removeItem(
        i,
        (BuildContext context, Animation<double> animation) => _StarTile(i, animation),
        duration: const Duration(milliseconds: 200),
      );
    }
    onCountChanged(0);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: FloatingActionButton(
            onPressed: starCount > 0 ? _resetStars : null,
            child: const Icon(Icons.delete_rounded),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: FloatingActionButton(
            onPressed: _addStar,
            child: const Icon(Icons.add_rounded),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: FloatingActionButton(
            onPressed: starCount > 0 ? _removeStar : null,
            child: const Icon(Icons.remove_rounded),
          ),
        ),
      ],
    );
  }
}

class _StarView extends StatelessWidget {
  const _StarView({required this.gridKey, required this.starCount});

  final GlobalKey<SliverAnimatedGridState> gridKey;
  final int starCount;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: <Widget>[
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
            itemBuilder: (BuildContext context, int index, Animation<double> animation) => _StarTile(index, animation),
          ),
        ),
      ],
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
          child: Text(
            '${(index * animation.value).round() + 2}',
            style: TextStyle(fontSize: MediaQuery.of(context).size.width < 600 ? 20 : 30),
          ),
        );
      },
    );
  }
}
