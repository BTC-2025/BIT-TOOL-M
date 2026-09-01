import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:io';
import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/widgets/neumorphic_widgets.dart';

class LensScreen extends StatefulWidget {
  const LensScreen({super.key});

  @override
  State<LensScreen> createState() => _LensScreenState();
}

class _LensScreenState extends State<LensScreen> with SingleTickerProviderStateMixin {
  String _mode = 'Search'; 
  bool _isAnalyzing = false;
  bool _hasScanned = false;
  String _detectedLabel = 'Ready to Scan';
  String _confidence = 'N/A';
  
  List<Map<String, dynamic>> _buyOptions = [];
  
  // Gemini API Configuration
  // Pass --dart-define=GEMINI_API_KEY=your_key or configure your key
  final String _apiKey = const String.fromEnvironment('GEMINI_API_KEY', defaultValue: 'YOUR_GEMINI_API_KEY');
  late final GenerativeModel _model;

  // Camera fields
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  String _cameraErrorMsg = '';

  late AnimationController _scanController;

  @override
  void initState() {
    super.initState();
    // Using the most stable model identifier
    _model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: _apiKey);
    
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        _cameraController = CameraController(
          _cameras![0],
          ResolutionPreset.medium,
          enableAudio: false,
        );
        await _cameraController!.initialize();
        if (mounted) setState(() => _isCameraInitialized = true);
      } else {
        setState(() => _cameraErrorMsg = 'No camera hardware detected.');
      }
    } catch (e) {
      if (mounted) setState(() => _cameraErrorMsg = 'Camera access denied.');
    }
  }

  @override
  void dispose() {
    _scanController.dispose();
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _triggerScan() async {
    if (_isAnalyzing || !_isCameraInitialized) return;

    setState(() {
      _isAnalyzing = true;
      _hasScanned = false;
      _detectedLabel = 'Analyzing...';
    });

    try {
      final XFile image = await _cameraController!.takePicture();
      final bytes = await File(image.path).readAsBytes();

      final content = [
        Content.multi([
          DataPart('image/jpeg', bytes),
          TextPart("""
            Identify the primary product in this image for a shopping application.
            Return a JSON response with:
            {
              "product_name": "Specific brand and model",
              "confidence": "e.g. 98%",
              "buy_options": [
                {"merchant": "Amazon", "title": "Buy on Amazon", "url": "https://amazon.in/s?k=exact+product+name"},
                {"merchant": "Flipkart", "title": "Shop on Flipkart", "url": "https://flipkart.com/search?q=exact+product+name"},
                {"merchant": "Google Shopping", "title": "View Deals", "url": "https://www.google.com/search?q=exact+product+name&tbm=shop"}
              ]
            }
            CRITICAL: Return ONLY raw JSON. Ensure URLs are dynamic and based on the detected product name. 
            No markdown, no preamble.
          """),
        ])
      ];

      late String? responseText;
      try {
        final response = await _model.generateContent(content).timeout(const Duration(seconds: 15));
        responseText = response.text;
      } catch (inner) {
        // Retry with a pro model if flash is "not found"
        if (inner.toString().contains('404')) {
          final proModel = GenerativeModel(model: 'gemini-1.5-pro', apiKey: _apiKey);
          final response = await proModel.generateContent(content).timeout(const Duration(seconds: 15));
          responseText = response.text;
        } else {
          rethrow;
        }
      }

      if (responseText != null) {
        String jsonStr = responseText;
        if (jsonStr.contains('```')) {
          jsonStr = jsonStr.split('```')[1];
          if (jsonStr.startsWith('json')) jsonStr = jsonStr.substring(4);
        }
        jsonStr = jsonStr.trim();

        final Map<String, dynamic> data = json.decode(jsonStr);
        if (mounted) {
          setState(() {
            _detectedLabel = data['product_name'] ?? 'Generic Object';
            _confidence = data['confidence'] ?? '90%';
            _buyOptions = List<Map<String, dynamic>>.from(data['buy_options'] ?? []);
            _isAnalyzing = false;
            _hasScanned = true;
          });
        }
      } else {
        throw Exception('Empty response from AI');
      }
    } catch (e) {
      debugPrint('Lens AI Error: $e');
      
      // --- PURE AI MODE (NO FALLBACKS) ---
      // We no longer show random products. If it fails, we show the real error.
      
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
          _hasScanned = true; 
          _confidence = '0%';
          _detectedLabel = 'Identification Failed';
          _buyOptions = []; // No random products shown here
          
          final String errorStr = e.toString().toLowerCase();
          if (errorStr.contains('403') || errorStr.contains('api key')) {
            _cameraErrorMsg = 'API Key Rejected by Google. Please check your Gemini AI Studio key.';
          } else if (errorStr.contains('404')) {
            _cameraErrorMsg = 'AI Model not found. Attempting to reach standard service...';
          } else {
            _cameraErrorMsg = 'Network or AI Engine error: ${e.toString().split(':').last.trim()}';
          }
        });
      }
    }
  }

  void _resetScan() {
    setState(() {
      _hasScanned = false;
      _isAnalyzing = false;
      _buyOptions = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 24),
          // Mode Tabs
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: ['Search', 'Text'].map((m) {
                final active = _mode == m;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: NeumorphicButton(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                    color: active ? Theme.of(context).primaryColor.withValues(alpha: 0.1) : null,
                    onPressed: () => setState(() => _mode = m),
                    child: Text(m, style: TextStyle(
                      fontSize: 12, 
                      fontWeight: active ? FontWeight.bold : FontWeight.normal,
                      color: active ? Theme.of(context).primaryColor : Colors.grey,
                    )),
                  ),
                );
              }).toList(),
            ),
          ),

          // Camera Viewfinder
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: NeumorphicCard(
              padding: EdgeInsets.zero,
              borderRadius: 28,
              child: AspectRatio(
                aspectRatio: 1.1,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(28),
                        child: _isCameraInitialized && _cameraController != null
                            ? CameraPreview(_cameraController!)
                            : Container(
                                color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                                child: Center(
                                  child: Icon(Icons.camera_alt_outlined, size: 44, color: Colors.grey.withValues(alpha: 0.3)),
                                ),
                              ),
                      ),
                    ),

                    if (!_hasScanned && !_isAnalyzing) ...[
                      _buildTrackNode(0.2, 0.3),
                      _buildTrackNode(0.6, 0.7),
                      _buildTrackNode(0.4, 0.5),
                    ],

                    if (_isAnalyzing)
                      AnimatedBuilder(
                        animation: _scanController,
                        builder: (context, child) {
                          return Positioned(
                            top: _scanController.value * 280,
                            left: 0, right: 0,
                            child: Container(
                              height: 2,
                              decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor,
                                boxShadow: [BoxShadow(color: Theme.of(context).primaryColor, blurRadius: 12, spreadRadius: 3)],
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Main Action
          if (!_hasScanned && !_isAnalyzing)
            Center(
              child: GestureDetector(
                onTap: _triggerScan,
                child: Container(
                  width: 76, height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 6),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10)],
                    color: Theme.of(context).primaryColor,
                  ),
                  child: const Icon(Icons.search, color: Colors.white, size: 30),
                ),
              ),
            )
          else if (_hasScanned)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  NeumorphicButton(
                    onPressed: _resetScan,
                    child: const Row(children: [
                      Icon(Icons.refresh, size: 18, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Retake', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                    ]),
                  ),
                  NeumorphicButton(
                    onPressed: () {},
                    child: const Row(children: [
                      Icon(Icons.share, size: 18),
                      SizedBox(width: 8),
                      Text('Share', style: TextStyle(fontWeight: FontWeight.bold)),
                    ]),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 24),

          // Result Card
          if (_hasScanned || _isAnalyzing)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: NeumorphicCard(
                borderRadius: 24,
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_isAnalyzing ? 'LIVE ANALYSIS' : '$_confidence Visual match', 
                          style: TextStyle(color: _isAnalyzing ? Colors.blue : Colors.green, fontWeight: FontWeight.bold, fontSize: 11)),
                        if (!_isAnalyzing) const Icon(Icons.verified, color: Colors.blue, size: 16),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(_detectedLabel, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
                    const Divider(height: 36),
                    
                    if (_isAnalyzing)
                      const Center(child: Padding(padding: EdgeInsets.all(24.0), child: CircularProgressIndicator()))
                    else ...[
                      const Row(children: [
                        Icon(Icons.shopping_bag_outlined, size: 18, color: Colors.orange),
                        SizedBox(width: 8),
                        Text('Live Shopping Intel', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                      ]),
                      const SizedBox(height: 16),
                      if (_buyOptions.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.red.withValues(alpha: 0.1)),
                          ),
                          child: Column(
                            children: [
                              Text(
                                _cameraErrorMsg,
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 12, color: Colors.redAccent, fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(height: 12),
                              NeumorphicButton(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                onPressed: _triggerScan,
                                child: const Text('Try Again', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              ),
                            ],
                          ),
                        )
                      else
                        ..._buyOptions.map((opt) => _buildBuyTile(opt)),
                    ]
                  ],
                ),
              ),
            ),
          const SizedBox(height: 60),
        ],
      ),
    );
  }

  Widget _buildTrackNode(double top, double left) {
    return Positioned(
      top: top * 280, left: left * 320,
      child: Container(
        width: 10, height: 10,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.8),
          shape: BoxShape.circle,
          border: Border.all(color: Theme.of(context).primaryColor, width: 2),
        ),
      ),
    );
  }

  Widget _buildBuyTile(Map<String, dynamic> opt) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withValues(alpha: 0.04) : Colors.grey.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.08)),
        ),
        child: Row(
          children: [
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(opt['merchant'] ?? 'Merchant', style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(opt['title'] ?? 'Buy Online', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            )),
            NeumorphicButton(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              onPressed: () async {
                final url = Uri.parse(opt['url'] ?? '');
                if (await canLaunchUrl(url)) await launchUrl(url);
              },
              child: const Row(children: [
                Text('Visit', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 13)),
                SizedBox(width: 4),
                Icon(Icons.arrow_outward, size: 14, color: Colors.orange),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}
