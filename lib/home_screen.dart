import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:screenshot/screenshot.dart';
import 'dart:typed_data';
import 'dart:ui' as ui;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Uint8List? _imageBytes;
  double _brightness = 0;
  double _contrast = 0;
  double _saturation = 0;
  double _highlights = 0;
  double _shadows = 0;
  double _warmth = 0;
  double _sharpness = 0;
  double _vignette = 0;
  String _selectedTool = 'adjust';
  bool _isSaving = false;

  final ImagePicker _picker = ImagePicker();
  final ScreenshotController _screenshotController = ScreenshotController();

  Future<void> _pickImage() async {
    final XFile? file = await _picker.pickImage(source: ImageSource.gallery);
    if (file != null) {
      final bytes = await file.readAsBytes();
      setState(() {
        _imageBytes = bytes;
      });
    }
  }

  Future<void> _saveImage() async {
    if (_imageBytes == null) return;
    setState(() => _isSaving = true);
    try {
      final Uint8List? capturedBytes = await _screenshotController.capture(
        pixelRatio: 3.0,
      );
      if (capturedBytes != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Photo saved successfully!'),
              backgroundColor: Color(0xFF6C63FF),
            ),
          );
        }
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _applyFilterPreset(String preset) {
    setState(() {
      switch (preset) {
        case 'none':
          _brightness = 0;
          _contrast = 0;
          _saturation = 0;
          _highlights = 0;
          _shadows = 0;
          _warmth = 0;
          _sharpness = 0;
          _vignette = 0;
          break;
        case 'bw':
          _saturation = -1;
          break;
        case 'warm':
          _brightness = 0.05;
          _saturation = 0.3;
          _warmth = 0.4;
          break;
        case 'cool':
          _brightness = -0.05;
          _saturation = -0.1;
          _warmth = -0.4;
          break;
        case 'vivid':
          _contrast = 0.3;
          _saturation = 0.5;
          break;
        case 'soft':
          _contrast = -0.2;
          _brightness = 0.1;
          _vignette = 0.2;
          break;
      }
    });
  }

  List<double> _buildColorMatrix() {
    double b = _brightness;
    double c = _contrast + 1;
    double s = _saturation + 1;
    double w = _warmth;

    double sr = (1 - s) * 0.2126;
    double sg = (1 - s) * 0.7152;
    double sb = (1 - s) * 0.0722;

    double t = (1 - c) / 2 + b;

    double warmRed = 1 + (w * 0.3);
    double warmBlue = 1 - (w * 0.3);

    return [
      (sr + s) * c * warmRed, sg * c,       sb * c,            0, t * 255,
      sr * c,       (sg + s) * c, sb * c,            0, t * 255,
      sr * c,       sg * c,       (sb + s) * c * warmBlue, 0, t * 255,
      0,            0,            0,                 1, 0,
    ];
  }

  Float64List _buildSharpnessMatrix(double strength) {
    double s = strength * 2;
    return Float64List.fromList([
      0,  -s,       0, 0, 0,
      -s, 1 + 4*s, -s, 0, 0,
      0,  -s,       0, 0, 0,
      0,   0,       0, 1, 0,
    ]);
  }

  Widget _buildVignette() {
    if (_vignette == 0) return const SizedBox.shrink();
    return Positioned.fill(
      child: IgnorePointer(
        child: Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 1.0,
              colors: [
                Colors.transparent,
                Colors.black.withOpacity(_vignette * 0.85),
              ],
              stops: const [0.5, 1.0],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Nestpave',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Row(
                    children: [
                      if (_imageBytes != null)
                        GestureDetector(
                          onTap: _isSaving ? null : _saveImage,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            margin: const EdgeInsets.only(right: 10),
                            decoration: BoxDecoration(
                              color: _isSaving
                                  ? Colors.white24
                                  : const Color(0xFF6C63FF),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _isSaving
                                      ? Icons.hourglass_empty
                                      : Icons.download,
                                  color: Colors.white,
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _isSaving ? 'Saving...' : 'Save',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6C63FF),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'v0.2',
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Image area
            Expanded(
              child: _imageBytes == null
                  ? Center(
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          width: 260,
                          height: 260,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: const Color(0xFF6C63FF),
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            color: const Color(0xFF1A1A2E),
                          ),
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_photo_alternate_outlined,
                                size: 64,
                                color: Color(0xFF6C63FF),
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Tap to add photo',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 16,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Start editing',
                                style: TextStyle(
                                  color: Color(0xFF6C63FF),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  : Stack(
                      children: [
                        Center(
                          child: Screenshot(
                            controller: _screenshotController,
                            child: ImageFiltered(
                              imageFilter: _sharpness > 0
                                  ? ui.ImageFilter.matrix(
                                      _buildSharpnessMatrix(_sharpness),
                                      filterQuality: FilterQuality.high,
                                    )
                                  : ui.ImageFilter.blur(
                                      sigmaX: 0, sigmaY: 0),
                              child: ColorFiltered(
                                colorFilter: ColorFilter.matrix(
                                    _buildColorMatrix()),
                                child: Image.memory(
                                  _imageBytes!,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ),
                        ),
                        _buildVignette(),
                        Positioned(
                          top: 10,
                          right: 10,
                          child: GestureDetector(
                            onTap: _pickImage,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF6C63FF),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.photo_library,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
            ),

            // Tool panel
            if (_imageBytes != null) _buildToolPanel(),

            // Bottom tools bar
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: const BoxDecoration(
                color: Color(0xFF1A1A2E),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _ToolButton(
                    icon: Icons.tune,
                    label: 'Adjust',
                    isActive: _selectedTool == 'adjust',
                    onTap: () => setState(() => _selectedTool = 'adjust'),
                  ),
                  _ToolButton(
                    icon: Icons.filter,
                    label: 'Filter',
                    isActive: _selectedTool == 'filter',
                    onTap: () => setState(() => _selectedTool = 'filter'),
                  ),
                  _ToolButton(
                    icon: Icons.crop,
                    label: 'Crop',
                    isActive: _selectedTool == 'crop',
                    onTap: () => setState(() => _selectedTool = 'crop'),
                  ),
                  _ToolButton(
                    icon: Icons.text_fields,
                    label: 'Text',
                    isActive: _selectedTool == 'text',
                    onTap: () => setState(() => _selectedTool = 'text'),
                  ),
                  _ToolButton(
                    icon: Icons.video_library,
                    label: 'Video',
                    isActive: _selectedTool == 'video',
                    onTap: () => setState(() => _selectedTool = 'video'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolPanel() {
    if (_selectedTool == 'adjust') {
      return SizedBox(
        height: 220,
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildSlider('Brightness', _brightness, -1, 1, (v) {
                setState(() => _brightness = v);
              }),
              _buildSlider('Contrast', _contrast, -1, 1, (v) {
                setState(() => _contrast = v);
              }),
              _buildSlider('Saturation', _saturation, -1, 1, (v) {
                setState(() => _saturation = v);
              }),
              _buildSlider('Highlights', _highlights, -1, 1, (v) {
                setState(() => _highlights = v);
              }),
              _buildSlider('Shadows', _shadows, -1, 1, (v) {
                setState(() => _shadows = v);
              }),
              _buildSlider('Warmth', _warmth, -1, 1, (v) {
                setState(() => _warmth = v);
              }),
              _buildSlider('Sharpness', _sharpness, 0, 1, (v) {
                setState(() => _sharpness = v);
              }),
              _buildSlider('Vignette', _vignette, 0, 1, (v) {
                setState(() => _vignette = v);
              }),
            ],
          ),
        ),
      );
    }

    if (_selectedTool == 'filter') {
      return SizedBox(
        height: 90,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: [
            _filterChip('Original', 'none'),
            _filterChip('B & W', 'bw'),
            _filterChip('Warm', 'warm'),
            _filterChip('Cool', 'cool'),
            _filterChip('Vivid', 'vivid'),
            _filterChip('Soft', 'soft'),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Text(
        '${_selectedTool[0].toUpperCase()}${_selectedTool.substring(1)} — coming soon',
        style: const TextStyle(color: Colors.white38, fontSize: 13),
      ),
    );
  }

  Widget _filterChip(String label, String preset) {
    return GestureDetector(
      onTap: () => _applyFilterPreset(preset),
      child: Container(
        width: 70,
        margin: const EdgeInsets.only(right: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF2A2A40)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.auto_awesome,
                color: Color(0xFF6C63FF), size: 20),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlider(
    String label,
    double value,
    double min,
    double max,
    ValueChanged<double> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ),
          Expanded(
            child: Slider(
              value: value,
              min: min,
              max: max,
              activeColor: const Color(0xFF6C63FF),
              inactiveColor: const Color(0xFF1A1A2E),
              onChanged: onChanged,
            ),
          ),
          SizedBox(
            width: 36,
            child: Text(
              value.toStringAsFixed(1),
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToolButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _ToolButton({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive ? const Color(0xFF6C63FF) : Colors.white70;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: isActive ? const Color(0xFF6C63FF) : Colors.white54,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}