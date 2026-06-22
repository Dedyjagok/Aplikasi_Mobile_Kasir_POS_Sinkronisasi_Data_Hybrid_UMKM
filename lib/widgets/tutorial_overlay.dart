import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Satu langkah tutorial yang menjelaskan area tertentu di layar.
class TutorialStep {
  /// Teks panduan yang akan ditampilkan dengan efek mengetik.
  final String message;

  /// GlobalKey dari widget yang akan di-highlight.
  /// Null berarti tidak ada highlight (pesan umum).
  final GlobalKey? targetKey;

  /// Posisi horizontal karakter: 'left' atau 'right'.
  final String characterPosition;

  /// Posisi vertikal karakter: 'bottom' atau 'top'.
  final String verticalPosition;

  /// Apakah highlight interaktif (tembus klik).
  final bool isInteractive;

  /// Apakah tombol "Lanjut" / "Selesai" harus ditampilkan.
  final bool showNextButton;

  /// Callback yang dipanggil saat langkah ini mulai ditampilkan.
  final Future<void> Function()? onStart;

  const TutorialStep({
    required this.message,
    this.targetKey,
    this.characterPosition = 'left',
    this.verticalPosition = 'bottom',
    this.isInteractive = false,
    this.showNextButton = true,
    this.onStart,
  });
}

/// Overlay tutorial interaktif dengan karakter maskot RO Man.
///
/// Fitur:
/// - Animasi teks "mengetik" (typewriter effect)
/// - Klik layar untuk mempercepat teks
/// - Highlight pada widget target
/// - Tombol Skip untuk melewati seluruh tutorial
/// - Tombol Lanjut untuk berpindah langkah
class TutorialOverlay extends StatefulWidget {
  /// Daftar langkah-langkah tutorial.
  final List<TutorialStep> steps;

  /// Callback saat seluruh langkah tutorial selesai.
  final VoidCallback onComplete;

  /// Callback saat user melewati seluruh tutorial.
  final VoidCallback? onSkip;

  /// Key unik untuk SharedPreferences (agar tutorial tidak terulang).
  final String tutorialKey;

  const TutorialOverlay({
    super.key,
    required this.steps,
    required this.onComplete,
    this.onSkip,
    required this.tutorialKey,
  });

  /// Cek apakah tutorial dengan key tertentu sudah pernah ditampilkan.
  static Future<bool> hasBeenShown(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('tutorial_$key') ?? false;
  }

  /// Tandai tutorial sudah pernah ditampilkan.
  static Future<void> markAsShown(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('tutorial_$key', true);
  }

  /// Reset flag tutorial (untuk testing atau menu pengaturan).
  static Future<void> reset(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('tutorial_$key');
  }

  @override
  State<TutorialOverlay> createState() => _TutorialOverlayState();
}

class _TutorialOverlayState extends State<TutorialOverlay>
    with TickerProviderStateMixin {
  int _currentStep = 0;
  String _displayedText = '';
  int _charIndex = 0;
  Timer? _typeTimer;
  bool _isTypingComplete = false;
  bool _isSkipping = false;
  Rect? _targetRect;

  // Animasi masuk karakter
  late AnimationController _characterController;
  late Animation<Offset> _characterSlide;
  late Animation<double> _characterFade;

  // Animasi speech bubble
  late AnimationController _bubbleController;
  late Animation<double> _bubbleScale;

  // Animasi highlight pulse
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Kecepatan mengetik (ms per karakter)
  int _typingSpeed = 35;
  static const int _fastTypingSpeed = 8;
  static const int _normalTypingSpeed = 35;

  @override
  void initState() {
    super.initState();

    _characterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _characterSlide = Tween<Offset>(
      begin: const Offset(-1.5, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _characterController,
      curve: Curves.elasticOut,
    ));
    _characterFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _characterController,
        curve: const Interval(0, 0.5, curve: Curves.easeIn),
      ),
    );

    _bubbleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _bubbleScale = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _bubbleController, curve: Curves.easeOutBack),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _startStep();
  }

  @override
  void dispose() {
    _typeTimer?.cancel();
    _characterController.dispose();
    _bubbleController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _startStep() async {
    _typeTimer?.cancel();
    if (!mounted) return;
    
    // Tunggu onStart selesai (misal: scroll ke target) agar bounding box valid
    if (widget.steps[_currentStep].onStart != null) {
      await widget.steps[_currentStep].onStart!();
    }
    
    if (!mounted) return;
    setState(() {
      _displayedText = '';
      _charIndex = 0;
      _isTypingComplete = false;
      _typingSpeed = _normalTypingSpeed;
      _targetRect = _getTargetRect(); // Langsung ambil di sini agar tidak flicker
    });

    // Animasikan karakter masuk
    _characterController.reset();
    _bubbleController.reset();
    _characterController.forward().then((_) {
      if (!mounted) return;
      // Setelah karakter muncul, tampilkan bubble
      _bubbleController.forward().then((_) {
        if (!mounted) return;
        _startTyping();
      });
    });
  }

  void _startTyping() {
    final fullText = widget.steps[_currentStep].message;
    _typeTimer = Timer.periodic(Duration(milliseconds: _typingSpeed), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_charIndex < fullText.length) {
        setState(() {
          _charIndex++;
          _displayedText = fullText.substring(0, _charIndex);
        });
      } else {
        timer.cancel();
        setState(() => _isTypingComplete = true);
      }
    });
  }

  void _onTapScreen() {
    final step = widget.steps[_currentStep];
    if (_isTypingComplete) {
      // Teks sudah selesai, lanjut ke step berikutnya jika diizinkan
      if (step.showNextButton) {
        _nextStep();
      }
    } else {
      // Percepat pengetikan
      _typeTimer?.cancel();
      if (!mounted) return;
      setState(() => _typingSpeed = _fastTypingSpeed);
      _startTyping();
    }
  }

  void _nextStep() {
    if (_currentStep < widget.steps.length - 1) {
      if (!mounted) return;
      setState(() => _currentStep++);
      _startStep();
    } else {
      _completeTutorial();
    }
  }

  void _completeTutorial() async {
    if (_isSkipping) return;
    _isSkipping = true;
    await TutorialOverlay.markAsShown(widget.tutorialKey);
    if (mounted) widget.onComplete();
  }

  void _skipTutorial() async {
    if (_isSkipping) return;
    _isSkipping = true;
    await TutorialOverlay.markAsShown(widget.tutorialKey);
    if (mounted) {
      if (widget.onSkip != null) {
        widget.onSkip!();
      } else {
        widget.onComplete();
      }
    }
  }

  Rect? _getTargetRect() {
    final key = widget.steps[_currentStep].targetKey;
    if (key == null) return null;
    final renderBox =
        key.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.attached) return null;
    final position = renderBox.localToGlobal(Offset.zero);
    return position & renderBox.size;
  }

  @override
  Widget build(BuildContext context) {
    final step = widget.steps[_currentStep];
    final isLeft = step.characterPosition == 'left';
    final isTop = step.verticalPosition == 'top';

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final newRect = _getTargetRect();
        if (newRect != _targetRect) {
          setState(() {
            _targetRect = newRect;
          });
        }
      }
    });

    final targetRect = _targetRect;
    final holeRect = step.isInteractive && targetRect != null
        ? targetRect.inflate(8.0)
        : null;

    return Material(
      color: Colors.transparent,
      child: HoleHitTestWidget(
        holeRect: holeRect,
        child: GestureDetector(
          onTap: _onTapScreen,
          child: SizedBox.expand(
            child: Stack(
            children: [
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return CustomPaint(
                    size: Size.infinite,
                    painter: _HighlightPainter(
                      targetRect: targetRect,
                      overlayOpacity: 0.0,
                      pulseValue: _pulseAnimation.value,
                    ),
                  );
                },
              ),
            ),

            // ── Karakter Maskot ───────────────────────────────
            Positioned(
              bottom: isTop ? null : 24,
              top: isTop ? MediaQuery.of(context).padding.top + 16 : null,
              left: isLeft ? 8 : null,
              right: isLeft ? null : 8,
              child: SlideTransition(
                position: _characterSlide,
                child: FadeTransition(
                  opacity: _characterFade,
                  child: SizedBox(
                    width: 110,
                    height: 140,
                    child: Image.asset(
                      'assets/images/RO_man_TheGuide.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ),

            // ── Speech Bubble ─────────────────────────────────
            Positioned(
              bottom: isTop ? null : 170,
              top: isTop ? MediaQuery.of(context).padding.top + 165 : null,
              left: 16,
              right: 16,
              child: ScaleTransition(
                scale: _bubbleScale,
                alignment: isTop
                    ? (isLeft ? Alignment.topLeft : Alignment.topRight)
                    : (isLeft ? Alignment.bottomLeft : Alignment.bottomRight),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0097A7).withValues(alpha: 0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Nama karakter
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0097A7),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '💧 RO Man',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${_currentStep + 1} / ${widget.steps.length}',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // Teks dengan animasi mengetik
                      Text(
                        _displayedText,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          height: 1.5,
                          color: Colors.black87,
                        ),
                      ),
                      if (!_isTypingComplete)
                        Text(
                          '▌',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: const Color(0xFF0097A7),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      const SizedBox(height: 12),
                      // Tombol aksi
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            onPressed: _skipTutorial,
                            style: TextButton.styleFrom(
                              minimumSize: const Size(60, 32),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              'Skip Tutorial',
                              style: GoogleFonts.poppins(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          if (_isTypingComplete)
                            if (step.showNextButton)
                              ElevatedButton.icon(
                                onPressed: _nextStep,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0097A7),
                                  minimumSize: const Size(80, 36),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                icon: Icon(
                                  _currentStep < widget.steps.length - 1
                                      ? Icons.arrow_forward
                                      : Icons.check,
                                  size: 16,
                                  color: Colors.white,
                                ),
                                label: Text(
                                  _currentStep < widget.steps.length - 1
                                      ? 'Lanjut'
                                      : 'Selesai',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              )
                            else
                              const SizedBox.shrink()
                          else
                            Text(
                              'Ketuk untuk percepat ▸',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: Colors.grey.shade400,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  ),
);
  }
}

/// Custom painter yang menggambar overlay gelap dengan "lubang" di area target.
class _HighlightPainter extends CustomPainter {
  final Rect? targetRect;
  final double overlayOpacity;
  final double pulseValue;

  _HighlightPainter({
    this.targetRect,
    this.overlayOpacity = 0.7,
    this.pulseValue = 0.5,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final overlayPaint = Paint()
      ..color = Colors.black.withValues(alpha: overlayOpacity);

    // Gambar seluruh layar gelap
    final fullRect = Rect.fromLTWH(0, 0, size.width, size.height);

    if (targetRect != null) {
      // Buat lubang transparan di area target
      final padding = 8.0;
      final highlightRect = targetRect!.inflate(padding);
      final highlightRRect =
          RRect.fromRectAndRadius(highlightRect, const Radius.circular(12));

      // Path overlay = seluruh layar - lubang target
      final path = Path()
        ..addRect(fullRect)
        ..addRRect(highlightRRect);
      path.fillType = PathFillType.evenOdd;
      canvas.drawPath(path, overlayPaint);

      // Gambar border glow di sekitar highlight
      final glowPaint = Paint()
        ..color = Colors.red.withValues(alpha: pulseValue)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4;
      canvas.drawRRect(highlightRRect, glowPaint);
    } else {
      canvas.drawRect(fullRect, overlayPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _HighlightPainter old) =>
      old.targetRect != targetRect || old.pulseValue != pulseValue;
}

/// Widget helper yang memungkinkan deteksi sentuhan (hit-test) diteruskan ke widget di bawahnya
/// jika sentuhan tersebut berada di dalam area `holeRect` (lubang highlight).
class HoleHitTestWidget extends SingleChildRenderObjectWidget {
  final Rect? holeRect;

  const HoleHitTestWidget({
    super.key,
    required this.holeRect,
    required super.child,
  });

  @override
  RenderObject createRenderObject(BuildContext context) {
    return RenderHoleHitTest(holeRect: holeRect);
  }

  @override
  void updateRenderObject(
      BuildContext context, covariant RenderHoleHitTest renderObject) {
    renderObject.holeRect = holeRect;
  }
}

class RenderHoleHitTest extends RenderProxyBox {
  Rect? holeRect;

  RenderHoleHitTest({required this.holeRect});

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    // Jika koordinat klik berada di dalam area lubang target, return false agar klik tembus ke bawah
    if (holeRect != null && holeRect!.contains(position)) {
      return false;
    }
    return super.hitTest(result, position: position);
  }
}
