import 'package:flutter/material.dart';

void main() {
  runApp(
    MaterialApp(theme: ThemeData(useMaterial3: true), home: const FullOfStars()),
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
        onPressed: () => setState(() {
          gridKey.currentState!.insertItem(starCount);
          starCount += 1;
        }),
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
                return AnimatedBuilder(
                  animation: animation,
                  builder: (BuildContext context, Widget? child) {
                    return Container(
                      key: UniqueKey(),
                      decoration: ShapeDecoration(
                        shape: StarBorder.polygon(sides: 3 + index * animation.value),
                        color: HSLColor.fromAHSL(1, index * 10 % 360.0, 1.0, 0.5).toColor(),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
