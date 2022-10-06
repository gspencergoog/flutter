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
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: FloatingActionButton(
              child: const Icon(Icons.add),
              onPressed: () => setState(() {
                gridKey.currentState!.insertItem(starCount);
                starCount += 1;
              }),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: FloatingActionButton(
              onPressed: starCount > 0
                  ? () => setState(
                        () {
                          starCount -= 1;
                          gridKey.currentState!.removeItem(
                            starCount,
                            (BuildContext context, Animation<double> animation) =>
                                StarTile(starCount, animation: animation),
                            duration: const Duration(milliseconds: 200),
                          );
                        },
                      )
                  : null,
              child: const Icon(Icons.remove),
            ),
          ),
        ],
      ),
      body: CustomScrollView(
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
              itemBuilder: (BuildContext context, int index, Animation<double> animation) =>
                  StarTile(index, animation: animation),
            ),
          ),
        ],
      ),
    );
  }
}

class StarTile extends StatelessWidget {
  const StarTile(
    this.index, {
    this.animation,
    super.key,
  });

  final int index;
  final Animation<double>? animation;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation ?? const AlwaysStoppedAnimation<double>(1.0),
      builder: (BuildContext context, Widget? child) {
        return Container(
          key: UniqueKey(),
          alignment: Alignment.center,
          decoration: ShapeDecoration(
            shape: StarBorder(
              points: 2 + index * animation!.value,
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
            '${(index * animation!.value).round() + 2}',
            style: TextStyle(fontSize: MediaQuery.of(context).size.width < 600 ? 20 : 30),
          ),
        );
      },
    );
  }
}
