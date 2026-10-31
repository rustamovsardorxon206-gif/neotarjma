import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const NeoCipherApp());
}

// ============================================================================
// GLOBAL SOZLAMALAR (Qulf kalitlari va Foydalanuvchi ma'lumotlari)
// ============================================================================
class VaultConfig {
  static String userName = "Sardor";
  static String savedPin = "2026";
  static String savedPattern = "01258"; // 1->2->3->6->9 (Г shakli)
  static String savedPassword = "cyber";
  static String secretCipherKey = "Mening_Shaxsiy_Maxfiy_Kalitim_2026";
}

class NeoCipherApp extends StatelessWidget {
  const NeoCipherApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'NeoTarjima',
      theme: ThemeData.dark(useMaterial3: true).copyWith(
        scaffoldBackgroundColor: Colors.black,
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00FF66),
          secondary: Color(0xFF00B8FF),
        ),
      ),
      home: const SecurityGateScreen(),
    );
  }
}

// ============================================================================
// LOGOTIP VIDJETI (assets/bg.png rasmini yumaloq neon hoshiyada ko'rsatadi)
// ============================================================================
class AppLogoWidget extends StatelessWidget {
  final double size;
  const AppLogoWidget({super.key, this.size = 56});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF00FF66), width: 2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00FF66).withOpacity(0.35),
            blurRadius: 14,
          ),
        ],
      ),
      child: ClipOval(
        child: Image.asset(
          'assets/bg.png',
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.black87,
              child: Icon(
                Icons.shield_outlined,
                size: size * 0.6,
                color: const Color(0xFF00FF66),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ============================================================================
// SHIFRLASH TARIXI VA SAQLANGANLAR MODELI
// ============================================================================
class CipherRecord {
  final String id;
  final String input;
  final String output;
  final bool wasEncrypted;
  final DateTime time;
  bool isStarred;

  CipherRecord({
    required this.id,
    required this.input,
    required this.output,
    required this.wasEncrypted,
    required this.time,
    this.isStarred = false,
  });
}

// ============================================================================
// 1. ORQA FON RASMI (assets/bg.png) + JONLI MATRITSA ANIMATSIYASI
// ============================================================================
class MatrixBackground extends StatefulWidget {
  final Widget child;
  const MatrixBackground({super.key, required this.child});

  @override
  State<MatrixBackground> createState() => _MatrixBackgroundState();
}

class _MatrixBackgroundState extends State<MatrixBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_MatrixColumn> _columns = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < 28; i++) {
      _columns.add(_MatrixColumn(
        x: i * 18.0,
        y: _random.nextDouble() * -500,
        speed: 2.0 + _random.nextDouble() * 4.5,
        length: 8 + _random.nextInt(15),
      ));
    }
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..addListener(() {
        setState(() {
          for (var col in _columns) {
            col.y += col.speed;
            if (col.y > 900) {
              col.y = _random.nextDouble() * -200;
            }
          }
        });
      });
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 1-QATLAM: Siz qo'ygan orqa fon rasmi (assets/bg.png)
        Positioned.fill(
          child: Image.asset(
            'assets/bg.png',
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF050B14), Color(0xFF001A0D), Colors.black],
                ),
              ),
            ),
          ),
        ),
        // 2-QATLAM: Rasm ustidan yarim shaffof qoraytirish (yozuvlar aniq ko'rinishi uchun)
        Positioned.fill(
          child: Container(color: Colors.black.withOpacity(0.58)),
        ),
        // 3-QATLAM: Oqib tushuvchi Matritsa (Matrix Rain)
        Positioned.fill(
          child: CustomPaint(
            painter: _MatrixPainter(_columns, _random),
          ),
        ),
        // 4-QATLAM: Asosiy interfeys
        widget.child,
      ],
    );
  }
}

class _MatrixColumn {
  double x;
  double y;
  double speed;
  int length;
  _MatrixColumn({
    required this.x,
    required this.y,
    required this.speed,
    required this.length,
  });
}

class _MatrixPainter extends CustomPainter {
  final List<_MatrixColumn> columns;
  final Random random;
  final String chars = "01ｱｲｳｴｵｶｷｸｹｺｻｼｽｾｿﾀﾁﾂﾃﾄﾅﾆﾇﾈﾉﾊﾋﾌﾍﾎﾏﾐﾑﾒﾓﾔﾕﾖﾗﾘﾙﾚﾛﾜﾝ@#\$%&*";

  _MatrixPainter(this.columns, this.random);

  @override
  void paint(Canvas canvas, Size size) {
    final colWidth = size.width / columns.length;
    for (int i = 0; i < columns.length; i++) {
      final col = columns[i];
      for (int j = 0; j < col.length; j++) {
        final charY = col.y - (j * 16);
        if (charY < -20 || charY > size.height) continue;

        final isHead = j == 0;
        final opacity = (1.0 - (j / col.length)).clamp(0.05, 0.45);
        final textSpan = TextSpan(
          text: chars[(i * 7 + j + (col.y ~/ 16)) % chars.length],
          style: TextStyle(
            color: isHead
                ? Colors.white.withOpacity(0.75)
                : const Color(0xFF00FF66).withOpacity(opacity),
            fontSize: 13,
            fontWeight: isHead ? FontWeight.bold : FontWeight.normal,
            fontFamily: 'monospace',
          ),
        );
        final tp = TextPainter(
          text: textSpan,
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(i * colWidth, charY));
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ============================================================================
// 2. KIRISH OYNASI: ISM KIRITISH + PIN / CHIZMA / PAROL QULFI
// ============================================================================
enum LockType { pin, pattern, password }

class SecurityGateScreen extends StatefulWidget {
  const SecurityGateScreen({super.key});

  @override
  State<SecurityGateScreen> createState() => _SecurityGateScreenState();
}

class _SecurityGateScreenState extends State<SecurityGateScreen> {
  LockType _selectedLock = LockType.pin;
  late TextEditingController _nameController;

  String _enteredPin = "";
  List<int> _enteredPattern = [];
  final TextEditingController _passController = TextEditingController();
  String _statusMessage = "Ismingizni kiriting va qulfni oching";
  bool _isError = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: VaultConfig.userName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _passController.dispose();
    super.dispose();
  }

  void _unlockSuccess() {
    VaultConfig.userName = _nameController.text.trim().isEmpty
        ? "Sardor"
        : _nameController.text.trim();

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (_, animation, __) => FadeTransition(
          opacity: animation,
          child: const CipherWorkspaceScreen(),
        ),
      ),
    );
  }

  void _triggerError(String msg) {
    setState(() {
      _isError = true;
      _statusMessage = msg;
      _enteredPin = "";
      _enteredPattern = [];
      _passController.clear();
    });
  }

  void _onPinKeyPress(String digit) {
    if (_enteredPin.length < 4) {
      setState(() {
        _isError = false;
        _enteredPin += digit;
      });
      if (_enteredPin.length == 4) {
        Future.delayed(const Duration(milliseconds: 150), () {
          if (_enteredPin == VaultConfig.savedPin) {
            _unlockSuccess();
          } else {
            _triggerError("Xato PIN-kod! (Standart: ${VaultConfig.savedPin})");
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MatrixBackground(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  width: 360,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.72),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: _isError
                          ? Colors.redAccent
                          : const Color(0xFF00FF66).withOpacity(0.55),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const AppLogoWidget(size: 70),
                      const SizedBox(height: 10),
                      const Text(
                        "NEOTARJIMA VAULT",
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                          color: Color(0xFF00FF66),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _statusMessage,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: _isError ? Colors.redAccent : Colors.grey[300],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // ISM KIRITISH MAYDONI
                      SizedBox(
                        height: 44,
                        child: TextField(
                          controller: _nameController,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          decoration: InputDecoration(
                            labelText: "Ismingiz",
                            prefixIcon: const Icon(
                              Icons.person_outline,
                              color: Color(0xFF00FF66),
                              size: 20,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.06),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Qulf turini tanlash
                      SegmentedButton<LockType>(
                        segments: const [
                          ButtonSegment(
                            value: LockType.pin,
                            label: Text("PIN"),
                            icon: Icon(Icons.dialpad, size: 16),
                          ),
                          ButtonSegment(
                            value: LockType.pattern,
                            label: Text("Chizma"),
                            icon: Icon(Icons.gesture, size: 16),
                          ),
                          ButtonSegment(
                            value: LockType.password,
                            label: Text("Parol"),
                            icon: Icon(Icons.password, size: 16),
                          ),
                        ],
                        selected: {_selectedLock},
                        onSelectionChanged: (val) {
                          setState(() {
                            _selectedLock = val.first;
                            _isError = false;
                            _statusMessage = "Qulfni oching";
                          });
                        },
                      ),
                      const SizedBox(height: 18),

                      if (_selectedLock == LockType.pin) _buildPinPad(),
                      if (_selectedLock == LockType.pattern) _buildPatternLock(),
                      if (_selectedLock == LockType.password) _buildPasswordLock(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPinPad() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(4, (index) {
            final filled = index < _enteredPin.length;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 8),
              width: 15,
              height: 15,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: filled ? const Color(0xFF00FF66) : Colors.transparent,
                border: Border.all(color: const Color(0xFF00FF66), width: 2),
              ),
            );
          }),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16,
          runSpacing: 10,
          alignment: WrapAlignment.center,
          children: [
            for (var i = 1; i <= 9; i++) _pinButton("$i"),
            const SizedBox(width: 64, height: 48),
            _pinButton("0"),
            SizedBox(
              width: 64,
              height: 48,
              child: IconButton(
                onPressed: () {
                  if (_enteredPin.isNotEmpty) {
                    setState(() {
                      _enteredPin =
                          _enteredPin.substring(0, _enteredPin.length - 1);
                    });
                  }
                },
                icon: const Icon(Icons.backspace_outlined),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _pinButton(String digit) {
    return SizedBox(
      width: 64,
      height: 48,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: const Color(0xFF00FF66).withOpacity(0.45)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        onPressed: () => _onPinKeyPress(digit),
        child: Text(
          digit,
          style: const TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildPatternLock() {
    const double boxSize = 210;
    return Column(
      children: [
        GestureDetector(
          onPanStart: (details) {
            setState(() {
              _enteredPattern = [];
              _isError = false;
            });
            _checkPatternHit(details.localPosition, boxSize);
          },
          onPanUpdate: (details) {
            _checkPatternHit(details.localPosition, boxSize);
          },
          onPanEnd: (_) {
            if (_enteredPattern.join() == VaultConfig.savedPattern) {
              _unlockSuccess();
            } else {
              _triggerError("Xato chizma! (Standart: 1->2->3->6->9)");
            }
          },
          child: Container(
            width: boxSize,
            height: boxSize,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(16),
            ),
            child: CustomPaint(
              painter: _PatternPainter(_enteredPattern),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          "Nuqtalarni birlashtiring (Standart: 1-2-3-6-9)",
          style: TextStyle(fontSize: 11, color: Colors.grey[400]),
        ),
      ],
    );
  }

  void _checkPatternHit(Offset pos, double size) {
    final step = size / 3;
    for (int i = 0; i < 9; i++) {
      final row = i ~/ 3;
      final col = i % 3;
      final center = Offset(col * step + step / 2, row * step + step / 2);
      if ((pos - center).distance < 28) {
        if (!_enteredPattern.contains(i)) {
          setState(() {
            _enteredPattern.add(i);
          });
        }
      }
    }
  }

  Widget _buildPasswordLock() {
    return Column(
      children: [
        TextField(
          controller: _passController,
          obscureText: true,
          decoration: InputDecoration(
            hintText: "Maxfiy parolni kiriting",
            prefixIcon: const Icon(Icons.key, color: Color(0xFF00FF66)),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onSubmitted: (_) => _verifyPassword(),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 46,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00FF66),
              foregroundColor: Colors.black,
            ),
            onPressed: _verifyPassword,
            icon: const Icon(Icons.lock_open),
            label: const Text(
              "Kirish",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  void _verifyPassword() {
    if (_passController.text.trim() == VaultConfig.savedPassword) {
      _unlockSuccess();
    } else {
      _triggerError("Parol noto'g'ri! (Standart: ${VaultConfig.savedPassword})");
    }
  }
}

class _PatternPainter extends CustomPainter {
  final List<int> selected;
  _PatternPainter(this.selected);

  @override
  void paint(Canvas canvas, Size size) {
    final step = size.width / 3;
    final linePaint = Paint()
      ..color = const Color(0xFF00FF66)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    Offset getCenter(int index) {
      final r = index ~/ 3;
      final c = index % 3;
      return Offset(c * step + step / 2, r * step + step / 2);
    }

    for (int i = 0; i < selected.length - 1; i++) {
      canvas.drawLine(
        getCenter(selected[i]),
        getCenter(selected[i + 1]),
        linePaint,
      );
    }

    for (int i = 0; i < 9; i++) {
      final center = getCenter(i);
      final isSelected = selected.contains(i);
      canvas.drawCircle(
        center,
        isSelected ? 11 : 6,
        Paint()
          ..color = isSelected
              ? const Color(0xFF00FF66)
              : Colors.grey.withOpacity(0.5),
      );
      if (isSelected) {
        canvas.drawCircle(
          center,
          18,
          Paint()..color = const Color(0xFF00FF66).withOpacity(0.2),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ============================================================================
// 3. ASOSIY OYNA: GOOGLE TARJIMA DIZAYNI + TARIX VA SAQLANGANLAR
// ============================================================================
class CipherWorkspaceScreen extends StatefulWidget {
  const CipherWorkspaceScreen({super.key});

  @override
  State<CipherWorkspaceScreen> createState() => _CipherWorkspaceScreenState();
}

class _CipherWorkspaceScreenState extends State<CipherWorkspaceScreen>
    with SingleTickerProviderStateMixin {
  bool isEncryptMode = true;
  bool autoTranslateMode = true;

  final TextEditingController leftCtrl = TextEditingController();
  final TextEditingController rightCtrl = TextEditingController();
  late AnimationController _swapRotationCtrl;

  final List<CipherRecord> _history = [];

  @override
  void initState() {
    super.initState();
    _swapRotationCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
  }

  @override
  void dispose() {
    _swapRotationCtrl.dispose();
    leftCtrl.dispose();
    rightCtrl.dispose();
    super.dispose();
  }

  // Dinamik Salt + Stream-XOR + Base64Url shifrlash
  String _encrypt(String plainText) {
    if (plainText.isEmpty) return "";
    final keyBytes = utf8.encode(VaultConfig.secretCipherKey);
    final textBytes = utf8.encode(plainText);
    final rng = Random.secure();
    final salt = List<int>.generate(4, (_) => rng.nextInt(256));

    final out = <int>[...salt];
    for (int i = 0; i < textBytes.length; i++) {
      final k = keyBytes[i % keyBytes.length];
      final s = salt[i % 4];
      out.add(textBytes[i] ^ k ^ s ^ (i & 0xFF));
    }
    return base64UrlEncode(out);
  }

  String _decrypt(String cipherText) {
    if (cipherText.isEmpty) return "";
    try {
      final raw = base64Url.decode(cipherText.trim());
      if (raw.length < 4) return "Xato: Shifr juda qisqa!";
      final salt = raw.sublist(0, 4);
      final data = raw.sublist(4);
      final keyBytes = utf8.encode(VaultConfig.secretCipherKey);

      final out = <int>[];
      for (int i = 0; i < data.length; i++) {
        final k = keyBytes[i % keyBytes.length];
        final s = salt[i % 4];
        out.add(data[i] ^ k ^ s ^ (i & 0xFF));
      }
      return utf8.decode(out);
    } catch (_) {
      return "⚠️ Shifrni ochib bo'lmadi (Kalit yoki matn xato)";
    }
  }

  void _runCipher({bool saveToHistory = false}) {
    final input = leftCtrl.text.trim();
    if (input.isEmpty) {
      setState(() => rightCtrl.clear());
      return;
    }

    final result = isEncryptMode ? _encrypt(input) : _decrypt(input);
    setState(() {
      rightCtrl.text = result;
      if (saveToHistory &&
          !result.startsWith("⚠️") &&
          !result.startsWith("Xato:")) {
        if (_history.isEmpty || _history.first.input != input) {
          _history.insert(
            0,
            CipherRecord(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              input: input,
              output: result,
              wasEncrypted: isEncryptMode,
              time: DateTime.now(),
            ),
          );
        }
      }
    });
  }

  bool get _isCurrentStarred {
    final input = leftCtrl.text.trim();
    if (input.isEmpty) return false;
    return _history.any((r) => r.input == input && r.isStarred);
  }

  void _toggleCurrentStar() {
    final input = leftCtrl.text.trim();
    final output = rightCtrl.text.trim();
    if (input.isEmpty || output.isEmpty || output.startsWith("⚠️")) return;

    setState(() {
      final existingIndex = _history.indexWhere((r) => r.input == input);
      if (existingIndex != -1) {
        _history[existingIndex].isStarred = !_history[existingIndex].isStarred;
      } else {
        _history.insert(
          0,
          CipherRecord(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            input: input,
            output: output,
            wasEncrypted: isEncryptMode,
            time: DateTime.now(),
            isStarred: true,
          ),
        );
      }
    });
  }

  void _swapSides() {
    _swapRotationCtrl.forward(from: 0);
    setState(() {
      isEncryptMode = !isEncryptMode;
      if (rightCtrl.text.isNotEmpty && !rightCtrl.text.startsWith("⚠️")) {
        leftCtrl.text = rightCtrl.text;
        _runCipher(saveToHistory: true);
      } else {
        final tmp = leftCtrl.text;
        leftCtrl.text = rightCtrl.text;
        rightCtrl.text = tmp;
      }
    });
  }

  void _openRecordsSheet({required bool onlyStarred}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF12161F),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final list = onlyStarred
                ? _history.where((r) => r.isStarred).toList()
                : _history;

            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            onlyStarred ? Icons.star : Icons.history,
                            color: const Color(0xFF00FF66),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            onlyStarred
                                ? "Saqlanganlar (${list.length})"
                                : "Shifrlash tarixi (${list.length})",
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      if (!onlyStarred && list.isNotEmpty)
                        TextButton.icon(
                          onPressed: () {
                            setState(() => _history.clear());
                            setModalState(() {});
                          },
                          icon: const Icon(
                            Icons.delete_sweep,
                            color: Colors.redAccent,
                          ),
                          label: const Text(
                            "Tozalash",
                            style: TextStyle(color: Colors.redAccent),
                          ),
                        ),
                    ],
                  ),
                  const Divider(color: Colors.white12),
                  Expanded(
                    child: list.isEmpty
                        ? Center(
                            child: Text(
                              onlyStarred
                                  ? "Saqlangan shifrlar yo'q.\nNatija katagidagi ⭐ tugmasini bosing."
                                  : "Tarix bo'sh. Matn yozib 'Shifrlash'ni bosing.",
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey[500]),
                            ),
                          )
                        : ListView.builder(
                            itemCount: list.length,
                            itemBuilder: (_, i) {
                              final item = list[i];
                              return Card(
                                color: Colors.black54,
                                margin: const EdgeInsets.symmetric(vertical: 6),
                                child: ListTile(
                                  onTap: () {
                                    setState(() {
                                      isEncryptMode = item.wasEncrypted;
                                      leftCtrl.text = item.input;
                                      rightCtrl.text = item.output;
                                    });
                                    Navigator.pop(context);
                                  },
                                  title: Text(
                                    item.input,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  subtitle: Text(
                                    item.output,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Color(0xFF00FF66),
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                  trailing: IconButton(
                                    icon: Icon(
                                      item.isStarred
                                          ? Icons.star
                                          : Icons.star_border,
                                      color: item.isStarred
                                          ? Colors.amber
                                          : Colors.grey,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        item.isStarred = !item.isStarred;
                                      });
                                      setModalState(() {});
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Sozlamalar: Maxfiy kalit, PIN va Parolni o'zgartirish oynasi
  void _showSettingsDialog() {
    final keyCtrl = TextEditingController(text: VaultConfig.secretCipherKey);
    final pinCtrl = TextEditingController(text: VaultConfig.savedPin);
    final passCtrl = TextEditingController(text: VaultConfig.savedPassword);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text("Xavfsizlik va Kalit Sozlamalari"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: keyCtrl,
                decoration: const InputDecoration(
                  labelText: "Shifrlash maxfiy kaliti",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: pinCtrl,
                maxLength: 4,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Kirish PIN-kodi (4 ta raqam)",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: passCtrl,
                decoration: const InputDecoration(
                  labelText: "Kirish Paroli",
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Bekor qilish"),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                if (keyCtrl.text.trim().isNotEmpty) {
                  VaultConfig.secretCipherKey = keyCtrl.text.trim();
                }
                if (pinCtrl.text.trim().length == 4) {
                  VaultConfig.savedPin = pinCtrl.text.trim();
                }
                if (passCtrl.text.trim().isNotEmpty) {
                  VaultConfig.savedPassword = passCtrl.text.trim();
                }
                _runCipher(saveToHistory: true);
              });
              Navigator.pop(context);
            },
            child: const Text("Saqlash"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final initialLetter = VaultConfig.userName.isNotEmpty
        ? VaultConfig.userName[0].toUpperCase()
        : "S";
    final starredCount = _history.where((e) => e.isStarred).length;

    return Scaffold(
      body: MatrixBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1) YUQORI PANEL
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        AppLogoWidget(size: 36),
                        SizedBox(width: 10),
                        Text(
                          "Neo",
                          style: TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF00FF66),
                          ),
                        ),
                        Text(
                          "Tarjima",
                          style: TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.w400,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Text(
                          "Salom, ${VaultConfig.userName}",
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.white70,
                          ),
                        ),
                        IconButton(
                          tooltip: "Sozlamalar",
                          icon: const Icon(Icons.settings_outlined, size: 22),
                          onPressed: _showSettingsDialog,
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                builder: (_) => const SecurityGateScreen(),
                              ),
                            );
                          },
                          child: CircleAvatar(
                            radius: 17,
                            backgroundColor: const Color(0xFFE91E63),
                            child: Text(
                              initialLetter,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // 2) YUQORI "PILL" TUGMALAR
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _topPillButton(
                        icon: Icons.translate,
                        label: "Matn",
                        active: true,
                        onTap: () {},
                      ),
                      const SizedBox(width: 8),
                      _topPillButton(
                        icon: Icons.bolt,
                        label: autoTranslateMode
                            ? "Avto-shifr: YOQ"
                            : "Avto-shifr: O'CH",
                        active: autoTranslateMode,
                        onTap: () {
                          setState(
                              () => autoTranslateMode = !autoTranslateMode);
                        },
                      ),
                      const SizedBox(width: 8),
                      _topPillButton(
                        icon: Icons.vpn_key_outlined,
                        label: "Kalit va PIN",
                        active: false,
                        onTap: _showSettingsDialog,
                      ),
                      const SizedBox(width: 8),
                      _topPillButton(
                        icon: Icons.cleaning_services_outlined,
                        label: "Tozalash",
                        active: false,
                        onTap: () {
                          setState(() {
                            leftCtrl.clear();
                            rightCtrl.clear();
                          });
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // 3) ALMASHTIRISH QATORI (Asl matn ⇄ Shifrlangan matn)
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey[900]!.withOpacity(0.82),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: const BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color: Color(0xFF00FF66),
                                    width: 3,
                                  ),
                                ),
                              ),
                              child: Text(
                                isEncryptMode
                                    ? "Asl matn (Kiritish)"
                                    : "Shifrlangan kod",
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Color(0xFF00FF66),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13.5,
                                ),
                              ),
                            ),
                          ),
                          RotationTransition(
                            turns: Tween(begin: 0.0, end: 0.5)
                                .animate(_swapRotationCtrl),
                            child: IconButton(
                              onPressed: _swapSides,
                              icon: const Icon(
                                Icons.swap_horiz,
                                color: Colors.white,
                                size: 26,
                              ),
                              tooltip: "Almashtirish",
                            ),
                          ),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: const BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color: Color(0xFF00B8FF),
                                    width: 3,
                                  ),
                                ),
                              ),
                              child: Text(
                                isEncryptMode
                                    ? "Shifrlangan matn"
                                    : "Ochilgan asl matn",
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Color(0xFF00B8FF),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13.5,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // 4) YONMA-YON CHAP VA O'NG KATAKLAR
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // CHAP KATAK
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.68),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color:
                                      const Color(0xFF00FF66).withOpacity(0.45),
                                ),
                              ),
                              child: Column(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: leftCtrl,
                                      maxLines: null,
                                      expands: true,
                                      onChanged: (_) {
                                        if (autoTranslateMode) {
                                          _runCipher(saveToHistory: false);
                                        }
                                      },
                                      style: const TextStyle(fontSize: 15.5),
                                      decoration: InputDecoration(
                                        hintText: isEncryptMode
                                            ? "Matnni kiriting..."
                                            : "Shifrni tashlang...",
                                        border: InputBorder.none,
                                        contentPadding:
                                            const EdgeInsets.all(14),
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: const BoxDecoration(
                                      border: Border(
                                        top: BorderSide(color: Colors.white12),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        IconButton(
                                          icon:
                                              const Icon(Icons.clear, size: 19),
                                          onPressed: () {
                                            leftCtrl.clear();
                                            rightCtrl.clear();
                                          },
                                        ),
                                        TextButton.icon(
                                          onPressed: () async {
                                            final data =
                                                await Clipboard.getData(
                                                    Clipboard.kTextPlain);
                                            if (data?.text != null) {
                                              leftCtrl.text = data!.text!;
                                              _runCipher(saveToHistory: true);
                                            }
                                          },
                                          icon:
                                              const Icon(Icons.paste, size: 16),
                                          label: const Text("Qo'yish"),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),

                      // O'NG KATAK
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Container(
                              decoration: BoxDecoration(
                                color:
                                    const Color(0xFF161B22).withOpacity(0.85),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color:
                                      const Color(0xFF00B8FF).withOpacity(0.45),
                                ),
                              ),
                              child: Column(
                                children: [
                                  Align(
                                    alignment: Alignment.topRight,
                                    child: IconButton(
                                      icon: Icon(
                                        _isCurrentStarred
                                            ? Icons.star
                                            : Icons.star_border,
                                        color: _isCurrentStarred
                                            ? Colors.amber
                                            : Colors.white54,
                                        size: 22,
                                      ),
                                      onPressed: _toggleCurrentStar,
                                    ),
                                  ),
                                  Expanded(
                                    child: TextField(
                                      controller: rightCtrl,
                                      readOnly: true,
                                      maxLines: null,
                                      expands: true,
                                      style: const TextStyle(
                                        fontSize: 15.5,
                                        color: Color(0xFF00FF66),
                                        fontFamily: 'monospace',
                                      ),
                                      decoration: InputDecoration(
                                        hintText: isEncryptMode
                                            ? "Shifrlanishi..."
                                            : "Asl matn...",
                                        border: InputBorder.none,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                          horizontal: 14,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: const BoxDecoration(
                                      border: Border(
                                        top: BorderSide(color: Colors.white12),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        TextButton.icon(
                                          onPressed: () {
                                            if (rightCtrl.text.isEmpty) return;
                                            _runCipher(saveToHistory: true);
                                            Clipboard.setData(
                                              ClipboardData(
                                                  text: rightCtrl.text),
                                            );
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  "✅ Nusxalandi va tarixga saqlandi!",
                                                ),
                                                duration: Duration(seconds: 1),
                                              ),
                                            );
                                          },
                                          icon:
                                              const Icon(Icons.copy, size: 16),
                                          label: const Text("Nusxalash"),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // 5) PASTKI DOIRA TUGMALAR: TARIX | SHIFRLASH | SAQLANGANLAR
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _bottomCircleButton(
                      icon: Icons.history,
                      label: "Tarix",
                      badgeCount: _history.length,
                      onTap: () => _openRecordsSheet(onlyStarred: false),
                    ),
                    const SizedBox(width: 24),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00FF66),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 22,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      onPressed: () => _runCipher(saveToHistory: true),
                      icon: Icon(
                        isEncryptMode
                            ? Icons.enhanced_encryption
                            : Icons.lock_open,
                        size: 20,
                      ),
                      label: Text(
                        isEncryptMode ? "SHIFRLASH" : "OCHISH",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    const SizedBox(width: 24),
                    _bottomCircleButton(
                      icon: Icons.star_border,
                      label: "Saqlanganlar",
                      badgeCount: starredCount,
                      onTap: () => _openRecordsSheet(onlyStarred: true),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _bottomCircleButton({
    required IconData icon,
    required String label,
    required int badgeCount,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey[900]!.withOpacity(0.85),
                  border: Border.all(color: Colors.white24, width: 1.5),
                ),
                child: Icon(icon, color: Colors.white70, size: 25),
              ),
              if (badgeCount > 0)
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: const BoxDecoration(
                      color: Color(0xFF00FF66),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      "$badgeCount",
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 11.5, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _topPillButton({
    required IconData icon,
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: active
              ? const Color(0xFF00FF66).withOpacity(0.2)
              : Colors.grey[900]!.withOpacity(0.75),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? const Color(0xFF00FF66) : Colors.white24,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: active ? const Color(0xFF00FF66) : Colors.white70,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: active ? const Color(0xFF00FF66) : Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
