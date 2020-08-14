import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ColorChooser extends StatelessWidget {
  static const List<ColorSwatch> COLOR_SWATCHES = [
    Colors.blue,
    Colors.lightBlue,
    Colors.cyan,
    Colors.teal,
    Colors.green,
    Colors.lightGreen,
    Colors.lime,
    Colors.yellow,
    Colors.amber,
    Colors.orange,
    Colors.deepOrange,
    Colors.red,
    Colors.pink,
    Colors.purple,
    Colors.deepPurple,
    Colors.indigo,
    Colors.blueGrey,
    Colors.brown,
  ];
  static const int NUM_SHADES = 5;
  final Color selectedColor;

  ColorChooser(this.selectedColor);

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    List<Widget> children = [];
    children.addAll(List.generate(COLOR_SWATCHES.length, (y) {
      return Row(
        children: List.generate(NUM_SHADES, (x) {
          Color color = COLOR_SWATCHES[y][x * 100 + (1000 - NUM_SHADES * 100)];
          Widget child;
          if (color.value == selectedColor.value) {
            child = Icon(
              Icons.check,
              color: Colors.white,
              size: 30,
            );
          }
          if (isValidColor(color)) {
            return Container(
              height: width / NUM_SHADES,
              width: width / NUM_SHADES,
              child: Material(
                color: color,
                child: InkWell(
                  child: child,
                  onTap: () {
                    Navigator.pop(context, color);
                  },
                ),
              ),
            );
          } else {
            return CustomPaint(
              painter: ExPainter(color),
              child: Container(
                height: width / NUM_SHADES,
                width: width / NUM_SHADES,
              ),
            );
          }
        }),
      );
    }));
    return Scaffold(
      appBar: AppBar(
        title: Text('Choose Color'),
      ),
      body: ListView(
        children: children,
      ),
    );
  }

  static Color generateRandomColor() {
    Random rnd = Random();
    while (true) {
      int index = rnd.nextInt(COLOR_SWATCHES.length);
      ColorSwatch swatch = COLOR_SWATCHES[index];
      int x = rnd.nextInt(NUM_SHADES);
      Color color = swatch[x * 100 + (1000 - NUM_SHADES * 100)];
      if (isValidColor(color)) {
        return color;
      }
    }
  }

  static bool isValidColor(Color color) {
    return color.computeLuminance() < 0.5;
  }
}

class ExPainter extends CustomPainter {
  final Color color;

  ExPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    Paint backgroundPaint = Paint();
    backgroundPaint.color = color;

    Paint linePaint = Paint();
    linePaint.color = Colors.red[900];
    linePaint.strokeWidth = 1;

    canvas.drawRect(Rect.fromPoints(Offset(0, 0), Offset(size.width, size.height)), backgroundPaint);
    canvas.drawLine(Offset(0, 0), Offset(size.width, size.height), linePaint);
    canvas.drawLine(Offset(size.width, 0), Offset(0, size.height), linePaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}
