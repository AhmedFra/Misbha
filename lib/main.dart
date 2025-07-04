import 'dart:math' as Math;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MisbhaPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MisbhaPage extends StatefulWidget {
  @override
  State<MisbhaPage> createState() => _MisbhaPageState();
}

class _MisbhaPageState extends State<MisbhaPage> with TickerProviderStateMixin {
  int beadCount = 0;
  int roundCount = 0;
  static const int maxBeads = 99;
  static const int visibleBeads = 33; // For visualization
  Color beadColor = Colors.brown;
  Color highlightColor = Colors.green;
  Color backgroundColor = Colors.white;
  int? lastTappedBead;
  String dhikrText = "الله أكبر";
  late AnimationController _counterAnimController;
  late Animation<double> _counterScale;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  final TextEditingController _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _counterAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
      lowerBound: 1.0,
      upperBound: 1.2,
    );
    _counterScale = _counterAnimController.drive(Tween(begin: 1.0, end: 1.2));
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(_fadeController);
    _loadColors();
    _textController.text = dhikrText;
  }

  Future<void> _loadColors() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      beadColor = Color(prefs.getInt('beadColor') ?? Colors.brown.value);
      highlightColor = Color(prefs.getInt('highlightColor') ?? Colors.green.value);
      backgroundColor = Color(prefs.getInt('backgroundColor') ?? Colors.white.value);
    });
  }

  Future<void> _saveColors() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('beadColor', beadColor.value);
    await prefs.setInt('highlightColor', highlightColor.value);
    await prefs.setInt('backgroundColor', backgroundColor.value);
  }

  @override
  void dispose() {
    _counterAnimController.dispose();
    _fadeController.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _incrementBead() async {
    setState(() {
      lastTappedBead = beadCount % visibleBeads;
      beadCount++;
      if (beadCount > maxBeads) {
        beadCount = 0;
        roundCount++;
      }
    });
    _counterAnimController.forward(from: 0.0);

    // Show fading text
    _fadeController.reset();
    _fadeController.forward();

    await Future.delayed(const Duration(milliseconds: 300));
    setState(() {
      lastTappedBead = null;
    });
  }

  void _resetCounters() {
    setState(() {
      beadCount = 0;
      roundCount = 0;
      lastTappedBead = null;
    });
  }

  void _showColorPickerDialog() {
    Color tempBead = beadColor;
    Color tempHighlight = highlightColor;
    Color tempBg = backgroundColor;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Customize Colors'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                const Text('Bead Color'),
                ColorPicker(
                  pickerColor: tempBead,
                  onColorChanged: (color) => tempBead = color,
                  enableAlpha: false,
                  displayThumbColor: true,
                ),
                const SizedBox(height: 8),
                const Text('Highlight Color'),
                ColorPicker(
                  pickerColor: tempHighlight,
                  onColorChanged: (color) => tempHighlight = color,
                  enableAlpha: false,
                  displayThumbColor: true,
                ),
                const SizedBox(height: 8),
                const Text('Background Color'),
                ColorPicker(
                  pickerColor: tempBg,
                  onColorChanged: (color) => tempBg = color,
                  enableAlpha: false,
                  displayThumbColor: true,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: const Text('Save'),
              onPressed: () {
                setState(() {
                  beadColor = tempBead;
                  highlightColor = tempHighlight;
                  backgroundColor = tempBg;
                });
                _saveColors();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showDhikrTextDialog() {
    _textController.text = dhikrText;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set Dhikr Text'),
        content: TextField(
          controller: _textController,
          decoration: const InputDecoration(
            labelText: 'Dhikr Text',
            hintText: 'Enter text (e.g., الله أكبر)',
          ),
          textDirection: TextDirection.rtl,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                dhikrText = _textController.text.trim().isEmpty
                    ? "الله أكبر"
                    : _textController.text.trim();
              });
              Navigator.of(context).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Digital Misbha'),
        backgroundColor: backgroundColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.text_fields),
            onPressed: _showDhikrTextDialog,
            tooltip: 'Set Dhikr Text',
          ),
          IconButton(
            icon: const Icon(Icons.color_lens),
            onPressed: _showColorPickerDialog,
            tooltip: 'Customize Colors',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _resetCounters,
            tooltip: 'Reset Counters',
          ),
        ],
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _incrementBead,
        child: Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ScaleTransition(
                    scale: _counterScale,
                    child: Text(
                      '${beadCount % (maxBeads + 1)}',
                      style: const TextStyle(fontSize: 64, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text('Rounds: $roundCount', style: const TextStyle(fontSize: 28)),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: 350,
                    height: 350,
                    child: CustomPaint(
                      painter: MisbhaPainter(
                        beadCount: beadCount % (maxBeads + 1),
                        visibleBeads: visibleBeads,
                        beadColor: beadColor,
                        highlightColor: highlightColor,
                        lastTappedBead: lastTappedBead,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  const Text('Tap anywhere to count', style: TextStyle(fontSize: 20)),
                ],
              ),
              // Fading Dhikr Text overlay
              FadeTransition(
                opacity: _fadeAnimation,
                child: Text(
                  dhikrText,
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MisbhaPainter extends CustomPainter {
  final int beadCount;
  final int visibleBeads;
  final Color beadColor;
  final Color highlightColor;
  final int? lastTappedBead;

  MisbhaPainter({
    required this.beadCount,
    required this.visibleBeads,
    required this.beadColor,
    required this.highlightColor,
    required this.lastTappedBead,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width/2, size.height/2);
    final radius = size.width/2 - 20;
    final beadRadius = 12.0;

    for (int i = 0; i < visibleBeads; i++) {
      final angle = (2 * Math.pi * i) / visibleBeads;
      final beadCenter = Offset(
        center.dx + radius * Math.cos(angle),
        center.dy + radius * Math.sin(angle),
      );
      final isHighlighted = lastTappedBead == i;
      final paint = Paint()
        ..color = isHighlighted ? highlightColor : beadColor
        ..style = PaintingStyle.fill;
      canvas.drawCircle(beadCenter, beadRadius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant MisbhaPainter oldDelegate) {
    return beadCount != oldDelegate.beadCount ||
        lastTappedBead != oldDelegate.lastTappedBead ||
        beadColor != oldDelegate.beadColor ||
        highlightColor != oldDelegate.highlightColor;
  }
}
