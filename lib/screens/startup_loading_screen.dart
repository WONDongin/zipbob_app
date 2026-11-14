import 'dart:math' as math;

import 'package:flutter/material.dart';

class StartupLoadingScreen extends StatelessWidget {
  final String statusMessage;
  final String? errorMessage;
  final VoidCallback? onRetry;

  const StartupLoadingScreen({
    super.key,
    required this.statusMessage,
    this.errorMessage,
    this.onRetry,
  });

  static const Color _primary = Color(0xFFEF7544);
  static const Color _background = Color(0xFFFFFAF5);
  static const Color _textColor = Color(0xFF332C28);
  static const Color _secondaryText = Color(0xFF6D625C);

  @override
  Widget build(BuildContext context) {
    final hasError = errorMessage != null;
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 32,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Semantics(
                        label: '집밥픽',
                        excludeSemantics: true,
                        child: const Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: '집밥',
                                style: TextStyle(color: _textColor),
                              ),
                              TextSpan(
                                text: 'PICK',
                                style: TextStyle(color: _primary),
                              ),
                            ],
                          ),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),

                      // 별도 이미지 파일 없이 그리는 냄비 일러스트
                      const ExcludeSemantics(
                        child: SizedBox(
                          width: 240,
                          height: 220,
                          child: CustomPaint(painter: _CookingPotPainter()),
                        ),
                      ),
                      const SizedBox(height: 32),

                      Text(
                        hasError ? '연결이 잠시\n지연되고 있어요' : '맛있는 한 끼를\n준비하고 있어요',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: _textColor,
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 20),

                      Semantics(
                        liveRegion: true,
                        child: Text(
                          errorMessage ?? statusMessage,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: _secondaryText,
                            fontSize: 15,
                            height: 1.7,
                          ),
                        ),
                      ),

                      if (!hasError) ...[
                        const SizedBox(height: 8),
                        const Text(
                          '첫 접속에는 1~2분 정도\n걸릴 수 있어요.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _secondaryText,
                            fontSize: 14,
                            height: 1.7,
                          ),
                        ),
                      ],
                      const SizedBox(height: 32),

                      if (hasError)
                        FilledButton(
                          onPressed: onRetry,
                          style: FilledButton.styleFrom(
                            backgroundColor: _primary,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(160, 48),
                            shape: const StadiumBorder(),
                            textStyle: const TextStyle(
                              fontFamily: 'GmarketSans',
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          child: const Text('다시 시도'),
                        )
                      else
                        SizedBox(
                          width: 36,
                          height: 36,
                          child: CircularProgressIndicator(
                            // 동작 줄이기 설정 시 정적인 표시 사용
                            value: reduceMotion ? 0.75 : null,
                            strokeWidth: 4,
                            color: _primary,
                            backgroundColor: const Color(0xFFFBE2D5),
                            semanticsLabel: '앱 시작 준비 중',
                          ),
                        ),
                      const SizedBox(height: 40),

                      Text(
                        hasError ? '다시 시도하면 연결 상태를 확인해요.' : '연결되면 자동으로 시작돼요.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: _secondaryText,
                          fontSize: 13,
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _CookingPotPainter extends CustomPainter {
  const _CookingPotPainter();

  static const Color _orange = Color(0xFFEF7544);
  static const Color _darkOrange = Color(0xFFD75D2E);
  static const Color _peach = Color(0xFFFFEBDD);
  static const Color _cream = Color(0xFFFFFAF5);
  static const Color _brown = Color(0xFF594236);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();

    // 240 × 220 좌표를 기준으로 비율 유지
    final scale = math.min(size.width / 240, size.height / 220);

    canvas.translate(
      (size.width - 240 * scale) / 2,
      (size.height - 220 * scale) / 2,
    );
    canvas.scale(scale);

    final paint = Paint()..isAntiAlias = true;

    // 배경
    paint.color = _peach;
    canvas.drawCircle(const Offset(120, 110), 96, paint);

    // 바닥
    paint.color = const Color(0xFFF6D6BF);
    canvas.drawOval(const Rect.fromLTWH(43, 191, 154, 14), paint);

    // 냄비 손잡이
    paint
      ..color = _darkOrange
      ..style = PaintingStyle.stroke
      ..strokeWidth = 11;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(34, 137, 35, 29),
        const Radius.circular(13),
      ),
      paint,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(171, 137, 35, 29),
        const Radius.circular(13),
      ),
      paint,
    );

    // 냄비 몸통
    paint
      ..style = PaintingStyle.fill
      ..color = _orange;

    final body = Path()
      ..moveTo(58, 129)
      ..lineTo(182, 129)
      ..lineTo(176, 177)
      ..quadraticBezierTo(173, 198, 149, 198)
      ..lineTo(91, 198)
      ..quadraticBezierTo(67, 198, 64, 177)
      ..close();

    canvas.drawPath(body, paint);

    // 냄비 입구
    paint.color = _darkOrange;
    canvas.drawOval(const Rect.fromLTWH(58, 116, 124, 29), paint);

    paint.color = _cream;
    canvas.drawOval(const Rect.fromLTWH(65, 121, 110, 18), paint);

    // 냄비 하이라이트
    paint.color = const Color(0xFFFFAB7F);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(76, 150, 8, 31),
        const Radius.circular(4),
      ),
      paint,
    );

    // 살짝 열린 뚜껑
    canvas.save();
    canvas.translate(113, 74);
    canvas.rotate(-0.22);

    paint.color = _orange;
    canvas.drawOval(const Rect.fromLTWH(-67, -10, 134, 25), paint);

    paint.color = _darkOrange;
    canvas.drawArc(
      const Rect.fromLTWH(-67, -10, 134, 25),
      0,
      math.pi,
      true,
      paint,
    );

    paint.color = _brown;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-16, -24, 32, 16),
        const Radius.circular(7),
      ),
      paint,
    );

    canvas.restore();

    // 김
    paint
      ..color = _cream
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    final steamLeft = Path()
      ..moveTo(108, 120)
      ..cubicTo(92, 104, 120, 98, 108, 82);

    final steamRight = Path()
      ..moveTo(137, 116)
      ..cubicTo(122, 100, 149, 92, 138, 77);

    canvas.drawPath(steamLeft, paint);
    canvas.drawPath(steamRight, paint);

    // 당근 잎
    paint
      ..color = const Color(0xFF7B9C4B)
      ..strokeWidth = 7;

    canvas.drawLine(const Offset(190, 179), const Offset(190, 166), paint);

    canvas.drawLine(const Offset(192, 179), const Offset(201, 170), paint);

    // 당근
    paint
      ..style = PaintingStyle.fill
      ..color = const Color(0xFFF4A044);

    final carrot = Path()
      ..moveTo(184, 176)
      ..quadraticBezierTo(199, 172, 201, 185)
      ..quadraticBezierTo(190, 200, 168, 202)
      ..quadraticBezierTo(172, 187, 184, 176)
      ..close();

    canvas.drawPath(carrot, paint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _CookingPotPainter oldDelegate) {
    return false;
  }
}
