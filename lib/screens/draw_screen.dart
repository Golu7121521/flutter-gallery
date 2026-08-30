import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Lets the user draw free-hand marks on top of an image, then export the
/// result as a new PNG file that the caller can save back to the gallery.
class DrawScreen extends StatefulWidget {
  final File imageFile;
  const DrawScreen({super.key, required this.imageFile});

  @override
  State<DrawScreen> createState() => _DrawScreenState();
}

class _StrokePoint {
  final Offset? offset; // null marks end of a stroke
  final Color color;
  final double width;
  _StrokePoint(this.offset, this.color, this.width);
}

class _DrawScreenState extends State<DrawScreen> {
  final GlobalKey _boundaryKey = GlobalKey();
  final List<_StrokePoint> _points = [];
  Color _color = Colors.redAccent;
  double _strokeWidth = 5;
  bool _saving = false;

  final _colors = const [
    Colors.redAccent,
    Colors.yellowAccent,
    Colors.greenAccent,
    Colors.blueAccent,
    Colors.white,
    Colors.black,
  ];

  void _undo() {
    setState(() {
      // Remove the last stroke (up to previous null marker).
      while (_points.isNotEmpty && _points.last.offset == null) {
        _points.removeLast();
      }
      while (_points.isNotEmpty && _points.last.offset != null) {
        _points.removeLast();
      }
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final boundary = _boundaryKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final Uint8List bytes = byteData!.buffer.asUint8List();
      if (mounted) Navigator.pop(context, bytes);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Draw', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(onPressed: _undo, icon: const Icon(Icons.undo_rounded, color: Colors.white)),
          _saving
              ? const Padding(
                  padding: EdgeInsets.all(14),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  ),
                )
              : IconButton(
                  onPressed: _save,
                  icon: const Icon(Icons.check_rounded, color: Colors.white),
                ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: RepaintBoundary(
              key: _boundaryKey,
              child: GestureDetector(
                onPanUpdate: (details) {
                  final box = context.findRenderObject() as RenderBox;
                  final local = box.globalToLocal(details.globalPosition);
                  setState(() {
                    _points.add(_StrokePoint(local, _color, _strokeWidth));
                  });
                },
                onPanEnd: (_) {
                  setState(() {
                    _points.add(_StrokePoint(null, _color, _strokeWidth));
                  });
                },
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.file(widget.imageFile, fit: BoxFit.contain),
                    CustomPaint(painter: _DrawPainter(_points)),
                  ],
                ),
              ),
            ),
          ),
          Container(
            color: const Color(0xFF161616),
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Slider(
                  value: _strokeWidth,
                  min: 2,
                  max: 20,
                  onChanged: (v) => setState(() => _strokeWidth = v),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: _colors.map((c) {
                    final selected = c == _color;
                    return GestureDetector(
                      onTap: () => setState(() => _color = c),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: c,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: selected ? Colors.white : Colors.transparent,
                            width: 3,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawPainter extends CustomPainter {
  final List<_StrokePoint> points;
  _DrawPainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < points.length - 1; i++) {
      final p1 = points[i];
      final p2 = points[i + 1];
      if (p1.offset != null && p2.offset != null) {
        final paint = Paint()
          ..color = p1.color
          ..strokeWidth = p1.width
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(p1.offset!, p2.offset!, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DrawPainter oldDelegate) => true;
}
