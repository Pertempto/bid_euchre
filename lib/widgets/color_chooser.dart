import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ColorChooser extends StatelessWidget {
  final List<ColorSwatch> colorSwatches = [
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
  final Color selectedColor;

  ColorChooser(this.selectedColor);

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    List<Widget> children = [];
    children.addAll(List.generate(colorSwatches.length, (y) {
      return Row(
        children: List.generate(6, (x) {
          Color color = colorSwatches[y][x * 100 + 400];
          Widget child;
          bool isGoodColor = color.computeLuminance() < 0.5;
          if (color.value == selectedColor.value) {
            child = Icon(
              Icons.check,
              color: Colors.white,
              size: 30,
            );
          }
          if (isGoodColor) {
            return Container(
              height: width / 6,
              width: width / 6,
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
                height: width / 6,
                width: width / 6,
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
