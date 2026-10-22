import 'package:flutter/material.dart';

import '../screens/login_screen.dart';

// 집밥PICK 로그인 안내 영역에서 사용하는 색상.
const _primary = Color(0xFFEF7544);
const _background = Color(0xFFFFFAF5);
const _softOrange = Color(0xFFFFEEE5);
const _border = Color(0xFFF0E5DC);
const _titleColor = Color(0xFF222222);
const _bodyColor = Color(0xFF78716B);

// 홈·즐겨찾기 화면에 표시하는 비회원 안내 카드.
class MemberLoginCard extends StatelessWidget {
  const MemberLoginCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _FavoriteIllustration(),
          const SizedBox(height: 20),

          const Text(
            '맛있는 발견을,\n나만의 메뉴로',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.w700,
              height: 1.45,
              letterSpacing: -0.8,
              color: _titleColor,
            ),
          ),
          const SizedBox(height: 12),

          const Text(
            '마음에 드는 메뉴는 저장하고\n'
            '최근 본 레시피는 편하게 다시 찾아보세요.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              height: 1.7,
              letterSpacing: -0.4,
              color: _bodyColor,
            ),
          ),
          const SizedBox(height: 18),

          const Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              _BenefitChip(
                icon: Icons.favorite_outline_rounded,
                label: '내 즐겨찾기',
              ),
              _BenefitChip(icon: Icons.history_rounded, label: '최근 본 레시피'),
            ],
          ),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                Navigator.of(context).push<void>(
                  MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
                );
              },
              style: _loginButtonStyle(),
              child: const Text('로그인 / 회원가입'),
            ),
          ),
          const SizedBox(height: 12),

          const Text(
            '로그인하면 다른 기기에서도 이어서 볼 수 있어요.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, height: 1.6, color: _bodyColor),
          ),
        ],
      ),
    );
  }
}

// 로그인 안내 팝업.
//
// 기존 호출 방식 유지:
// await showMemberLogin(context);
Future<void> showMemberLogin(BuildContext context) async {
  final shouldOpenLogin = await showDialog<bool>(
    context: context,
    barrierColor: const Color(0x66000000),
    builder: (dialogContext) {
      return Dialog(
        backgroundColor: _background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 350),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      tooltip: '닫기',
                      onPressed: () {
                        Navigator.of(dialogContext).pop(false);
                      },
                      icon: const Icon(
                        Icons.close_rounded,
                        size: 22,
                        color: _bodyColor,
                      ),
                    ),
                  ),

                  const _FavoriteIllustration(),
                  const SizedBox(height: 24),

                  const Text(
                    '이 메뉴, 저장해 둘까요?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      height: 1.4,
                      letterSpacing: -0.8,
                      color: _titleColor,
                    ),
                  ),
                  const SizedBox(height: 12),

                  const Text(
                    '즐겨찾기는 로그인 후 이용할 수 있어요.\n'
                    '마음에 드는 메뉴를 나만의 목록에 모아보세요.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.75,
                      letterSpacing: -0.4,
                      color: _bodyColor,
                    ),
                  ),
                  const SizedBox(height: 28),

                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        Navigator.of(dialogContext).pop(true);
                      },
                      style: _loginButtonStyle(),
                      child: const Text('로그인하고 시작하기'),
                    ),
                  ),
                  const SizedBox(height: 8),

                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () {
                        Navigator.of(dialogContext).pop(false);
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: _bodyColor,
                        minimumSize: const Size(0, 44),
                        textStyle: const TextStyle(
                          fontFamily: 'GmarketSans',
                          fontSize: 13,
                          letterSpacing: -0.4,
                        ),
                      ),
                      child: const Text('지금은 둘러볼게요'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );

  if (shouldOpenLogin != true || !context.mounted) {
    return;
  }

  await Navigator.of(context)
      .push<void>(MaterialPageRoute<void>(builder: (_) => const LoginScreen()));
}

// 카드와 팝업에서 함께 사용하는 하트 장식.
class _FavoriteIllustration extends StatelessWidget {
  const _FavoriteIllustration();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 100,
      height: 92,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: const BoxDecoration(
              color: _softOrange,
              shape: BoxShape.circle,
            ),
          ),
          Transform.rotate(
            angle: -0.12,
            child: Container(
              width: 58,
              height: 62,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x18EF7544),
                    blurRadius: 16,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: const Icon(
                Icons.favorite_rounded,
                size: 34,
                color: _primary,
              ),
            ),
          ),
          const Positioned(
            top: 5,
            right: 3,
            child: Icon(Icons.auto_awesome_rounded, size: 20, color: _primary),
          ),
        ],
      ),
    );
  }
}

// 로그인 시 사용할 수 있는 기능 안내.
class _BenefitChip extends StatelessWidget {
  const _BenefitChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: _primary),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              letterSpacing: -0.4,
              color: _bodyColor,
            ),
          ),
        ],
      ),
    );
  }
}

ButtonStyle _loginButtonStyle() {
  return FilledButton.styleFrom(
    backgroundColor: _primary,
    foregroundColor: Colors.white,
    minimumSize: const Size(0, 52),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    elevation: 0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    textStyle: const TextStyle(
      fontFamily: 'GmarketSans',
      fontSize: 15,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.5,
    ),
  );
}
