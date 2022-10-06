// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

void main() {
  runApp(
    MaterialApp(
      theme: ThemeData(
        brightness: Brightness.dark,
        colorSchemeSeed: Colors.deepPurple,
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
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          setState(() {
            gridKey.currentState!.insertItem(starCount);
            starCount += 1;
          });
        },
      ),
      body: CustomScrollView(
        slivers: <Widget>[
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverAnimatedGrid(
              key: gridKey,
              initialItemCount: starCount,
              gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: MediaQuery.of(context).size.width < 600 ? 75 : 150.0,
                mainAxisSpacing: 20.0,
                crossAxisSpacing: 20.0,
              ),
              itemBuilder: (BuildContext context, int index, Animation<double> animation) {
                return _StarTile(index, animation: animation);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _StarTile extends StatelessWidget {
  const _StarTile(this.index, {required this.animation});

  final int index;
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    final bool smallScreen = MediaQuery.of(context).size.width < 600;
    return AnimatedBuilder(
      animation: animation,
      builder: (BuildContext context, Widget? child) {
        return Container(
          key: UniqueKey(),
          alignment: Alignment.center,
          decoration: ShapeDecoration(
            shape: StarBorder.polygon(
              sides: 2 + index * animation.value,
              pointRounding: .2,
              side: BorderSide(
                color: HSLColor.fromAHSL(1, index * 10 % 360.0, 1.0, 0.6).toColor(),
                width: smallScreen ? 2 : 6,
              ),
            ),
            color: HSLColor.fromAHSL(1, index * 10 % 360.0, 1.0, 0.4).toColor(),
          ),
          child: Text(
            '${(index * animation.value).round() + 2}',
            style: TextStyle(fontSize: smallScreen ? 20 : 30),
          ),
        );
      },
    );
  }
}
