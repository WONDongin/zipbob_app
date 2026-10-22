import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/email_verification_service.dart';
import '../services/account_recovery_service.dart';

// 아이디 찾기·비밀번호 재설정 화면
class AccountRecoveryScreen extends StatefulWidget {
  final bool resetPassword;

  const AccountRecoveryScreen({super.key, this.resetPassword = false});

  @override
  State<AccountRecoveryScreen> createState() => _AccountRecoveryScreenState();
}

class _AccountRecoveryScreenState extends State<AccountRecoveryScreen> {
  static const _orange = Color(0xFFEF7544);
  static const _background = Color(0xFFFFFAF5);
  static const _softOrange = Color(0xFFFFEEE5);
  static const _border = Color(0xFFF0E5DC);
  static const _titleColor = Color(0xFF222222);
  static const _bodyColor = Color(0xFF78716B);

  final _id = TextEditingController();
  final _email = TextEditingController();
  final _code = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  final _verification = EmailVerificationService();
  final _recovery = AccountRecoveryService();

  // 인증번호 발송 후 받은 요청 ID
  int? _verificationId;

  // 인증번호 확인 후 받은 인증 증명
  String? _token;

  // 인증 증명 유효시간
  DateTime? _tokenDeadline;

  // 재발송을 허용할 시각
  DateTime? _resendAt;

  // 사용자 안내 또는 오류
  String? _message;

  // 아이디 찾기 결과
  String? _foundId;

  // 요청 진행 여부
  bool _busy = false;

  // 최종 처리 완료 여부
  bool _complete = false;

  String get _title => widget.resetPassword ? '비밀번호 재설정' : '아이디 찾기';

  String get _purpose => widget.resetPassword ? 'RESET_PASSWORD' : 'FIND_ID';

  @override
  void dispose() {
    for (final controller in [_id, _email, _code, _password, _confirm]) {
      controller.dispose();
    }

    super.dispose();
  }

  // 이메일 또는 아이디를 수정하면 화면의 인증 상태 초기화
  void _invalidate(String _) {
    setState(() {
      _verificationId = null;
      _token = null;
      _tokenDeadline = null;
      _code.clear();
      _message = null;
    });
  }

  // 전체 이메일 주소를 기존 API의 두 필드로 분리
  List<String>? _emailParts() {
    final parts = _email.text.trim().toLowerCase().split('@');

    if (parts.length != 2 || parts.any((part) => part.isEmpty)) {
      setState(() {
        _message = '이메일 주소를 확인해 주세요.';
      });

      return null;
    }

    return parts;
  }

  // API 요청 공통 처리
  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;

    FocusScope.of(context).unfocus();

    setState(() {
      _busy = true;
      _message = null;
    });

    try {
      await action();
    } on EmailVerificationException catch (error) {
      if (mounted) {
        setState(() => _message = error.message);
      }
    } on AccountRecoveryException catch (error) {
      if (mounted) {
        setState(() => _message = error.message);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _message = '요청을 완료하지 못했어요. 다시 시도해 주세요.';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  // 1. 인증번호 발송
  Future<void> _send() async {
    if (_busy) return;

    final parts = _emailParts();

    if (parts == null) return;

    if (_resendAt != null && DateTime.now().isBefore(_resendAt!)) {
      setState(() {
        _message = '발송 후 60초가 지나면 다시 요청할 수 있어요.';
      });

      return;
    }

    await _run(() async {
      // 재발송 요청 시 이전 인증 정보를 화면에서 제거
      setState(() {
        _verificationId = null;
        _token = null;
        _tokenDeadline = null;
      });

      _resendAt = DateTime.now().add(const Duration(seconds: 60));

      final sent = await _verification.send(
        email: parts[0],
        emailAdr: parts[1],
        purpose: _purpose,
      );

      if (!mounted) return;

      setState(() {
        _verificationId = sent.id;
        _code.clear();
        _message = '인증번호를 발송했어요. 5분 안에 입력해 주세요.';
      });
    });
  }

  // 2. 인증번호 확인
  Future<void> _verify() async {
    if (_busy || _verificationId == null) return;

    final code = _code.text.trim();

    if (code.length != 6 || !RegExp(r'^[0-9]{6}$').hasMatch(code)) {
      setState(() {
        _message = '인증번호 6자리를 입력해 주세요.';
      });

      return;
    }

    await _run(() async {
      final result = await _verification.confirm(
        emailVerificationId: _verificationId!,
        verificationCode: code,
      );

      if (!mounted) return;

      setState(() {
        _token = result.token;

        _tokenDeadline = DateTime.now().add(
          Duration(seconds: result.expiresInSeconds),
        );

        _message = '이메일 인증을 완료했어요. 10분 안에 진행해 주세요.';
      });
    });
  }

  // 3. 아이디 찾기 또는 비밀번호 변경
  Future<void> _submit() async {
    if (_busy) return;

    final parts = _emailParts();

    if (parts == null) return;

    if (_token == null ||
        _tokenDeadline == null ||
        !DateTime.now().isBefore(_tokenDeadline!)) {
      setState(() {
        _token = null;
        _tokenDeadline = null;
        _verificationId = null;
        _message = '인증번호를 다시 발송하고 인증해 주세요.';
      });

      return;
    }

    if (widget.resetPassword) {
      final pw = _password.text;

      if (_id.text.trim().isEmpty) {
        setState(() {
          _message = '아이디를 입력해 주세요.';
        });

        return;
      }

      if (pw.length < 8 ||
          utf8.encode(pw).length > 72 ||
          !RegExp(r'[A-Za-z]').hasMatch(pw) ||
          !RegExp(r'[0-9]').hasMatch(pw)) {
        setState(() {
          _message =
              '비밀번호는 영문·숫자를 포함해 8자 이상, '
              'UTF-8 기준 72바이트 이하로 입력해 주세요.';
        });

        return;
      }

      if (pw != _confirm.text) {
        setState(() {
          _message = '비밀번호 확인이 일치하지 않아요.';
        });

        return;
      }
    }

    await _run(() async {
      String? foundId;

      if (widget.resetPassword) {
        await _recovery.resetPassword(
          userId: _id.text,
          email: parts[0],
          emailAdr: parts[1],
          verificationToken: _token!,
          userPw: _password.text,
          userPwConfirm: _confirm.text,
        );
      } else {
        foundId = await _recovery.findId(
          email: parts[0],
          emailAdr: parts[1],
          verificationToken: _token!,
        );
      }

      if (!mounted) return;

      setState(() {
        _foundId = foundId;
        _complete = true;
        _token = null;

        _password.clear();
        _confirm.clear();

        _message = widget.resetPassword
            ? '비밀번호가 변경됐어요. 새 비밀번호로 로그인해 주세요.'
            : null;
      });
    });
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white,
      prefixIcon: Icon(icon, size: 20, color: _orange),
      labelStyle: const TextStyle(
        fontSize: 12,
        letterSpacing: -0.4,
        color: _bodyColor,
      ),
      floatingLabelStyle: const TextStyle(fontSize: 12, color: _orange),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _orange, width: 1.5),
      ),
    );
  }

  ButtonStyle _primaryButtonStyle() {
    return FilledButton.styleFrom(
      backgroundColor: _orange,
      foregroundColor: Colors.white,
      minimumSize: const Size.fromHeight(52),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      textStyle: const TextStyle(
        fontFamily: 'GmarketSans',
        fontSize: 14,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
      ),
    );
  }

  // 공통 입력창
  Widget _field(
    TextEditingController controller,
    String label, {
    bool secret = false,
    bool identity = false,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        obscureText: secret,
        keyboardType: keyboardType,
        autocorrect: false,
        enableSuggestions: false,
        onChanged: identity ? _invalidate : null,
        cursorColor: _orange,
        style: const TextStyle(
          fontSize: 14,
          letterSpacing: -0.4,
          color: _titleColor,
        ),
        decoration: _inputDecoration(
          label: label,
          icon: secret
              ? Icons.lock_outline_rounded
              : keyboardType == TextInputType.emailAddress
              ? Icons.mail_outline_rounded
              : Icons.person_outline_rounded,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_busy,
      child: Scaffold(
        backgroundColor: _background,
        appBar: AppBar(
          title: Text(
            _title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w500,
              letterSpacing: -0.5,
            ),
          ),
          centerTitle: true,
          backgroundColor: _background,
          foregroundColor: _titleColor,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
            child: AbsorbPointer(
              absorbing: _busy,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: _softOrange,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            widget.resetPassword
                                ? Icons.lock_reset_rounded
                                : Icons.manage_search_rounded,
                            size: 16,
                            color: _orange,
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            '계정 찾기',
                            style: TextStyle(
                              fontSize: 11,
                              letterSpacing: -0.4,
                              color: Color(0xFFAA512B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: widget.resetPassword
                              ? '비밀번호를\n'
                              : '잊어버린 아이디,\n',
                        ),
                        TextSpan(
                          text: widget.resetPassword ? '다시 설정해요.' : '함께 찾아볼까요?',
                          style: const TextStyle(color: _orange),
                        ),
                      ],
                    ),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      height: 1.45,
                      letterSpacing: -0.9,
                      color: _titleColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '회원가입 시 등록한 이메일로 인증해 주세요.',
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.8,
                      letterSpacing: -0.4,
                      color: _bodyColor,
                    ),
                  ),
                  const SizedBox(height: 26),

                  // 최종 처리 전 입력 화면
                  if (!_complete) ...[
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: _border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: _softOrange,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.verified_user_outlined,
                                  size: 19,
                                  color: _orange,
                                ),
                              ),
                              const SizedBox(width: 10),
                              const Expanded(
                                child: Text(
                                  '이메일 인증',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.5,
                                    color: _titleColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 22),

                          if (widget.resetPassword)
                            _field(_id, '아이디', identity: true),

                          _field(
                            _email,
                            '가입 이메일 (예: zipbob@gmail.com)',
                            identity: true,
                            keyboardType: TextInputType.emailAddress,
                          ),

                          OutlinedButton(
                            onPressed: _busy ? null : _send,
                            style: OutlinedButton.styleFrom(
                              backgroundColor: _background,
                              foregroundColor: const Color(0xFFAA512B),
                              minimumSize: const Size.fromHeight(48),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 14,
                              ),
                              side: const BorderSide(color: _border),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              textStyle: const TextStyle(
                                fontFamily: 'GmarketSans',
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                letterSpacing: -0.4,
                              ),
                            ),
                            child: Text(
                              _verificationId == null ? '인증번호 발송' : '인증번호 재발송',
                            ),
                          ),

                          // 발송 후 인증번호 입력 영역
                          if (_verificationId != null && _token == null) ...[
                            const SizedBox(height: 22),
                            const Divider(height: 1, color: _border),
                            const SizedBox(height: 22),
                            const Text(
                              '이메일로 받은 번호를 입력해 주세요.',
                              style: TextStyle(
                                fontSize: 11,
                                height: 1.7,
                                letterSpacing: -0.4,
                                color: _bodyColor,
                              ),
                            ),
                            const SizedBox(height: 14),
                            TextField(
                              controller: _code,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(6),
                              ],
                              cursorColor: _orange,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 4,
                                color: _titleColor,
                              ),
                              decoration: _inputDecoration(
                                label: '인증번호 6자리',
                                icon: Icons.password_rounded,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: _busy ? null : _verify,
                              style: TextButton.styleFrom(
                                foregroundColor: _orange,
                                minimumSize: const Size.fromHeight(44),
                                textStyle: const TextStyle(
                                  fontFamily: 'GmarketSans',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.4,
                                ),
                              ),
                              child: const Text('인증번호 확인'),
                            ),
                          ],

                          // 인증 완료 후 최종 처리 영역
                          if (_token != null) ...[
                            const SizedBox(height: 20),
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: _softOrange,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Row(
                                children: [
                                  Icon(
                                    Icons.check_circle_outline_rounded,
                                    size: 20,
                                    color: _orange,
                                  ),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      '이메일 인증이 완료되었어요.',
                                      style: TextStyle(
                                        fontSize: 12,
                                        height: 1.6,
                                        letterSpacing: -0.4,
                                        color: Color(0xFFAA512B),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),

                            if (widget.resetPassword) ...[
                              _field(_password, '새 비밀번호', secret: true),
                              _field(_confirm, '새 비밀번호 확인', secret: true),
                            ],

                            FilledButton(
                              onPressed: _busy ? null : _submit,
                              style: _primaryButtonStyle(),
                              child: Text(_title),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],

                  // 요청 중 표시
                  if (_busy)
                    const Padding(
                      padding: EdgeInsets.all(20),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: _orange,
                          strokeWidth: 3,
                        ),
                      ),
                    ),

                  // 아이디 찾기 결과
                  if (_foundId != null) ...[
                    Container(
                      padding: const EdgeInsets.all(26),
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
                        children: [
                          Container(
                            width: 72,
                            height: 72,
                            decoration: const BoxDecoration(
                              color: _softOrange,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.person_outline_rounded,
                              size: 36,
                              color: _orange,
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            '가입한 아이디',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              letterSpacing: -0.4,
                              color: _bodyColor,
                            ),
                          ),
                          const SizedBox(height: 12),
                          SelectableText(
                            _foundId!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 25,
                              height: 1.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.6,
                              color: _orange,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // 안내·오류 메시지
                  if (_message != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Semantics(
                        liveRegion: true,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _softOrange,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFFFDCC9)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Icon(
                                  _complete
                                      ? Icons.check_circle_outline_rounded
                                      : Icons.info_outline_rounded,
                                  size: 20,
                                  color: _orange,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _message!,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    height: 1.8,
                                    letterSpacing: -0.4,
                                    color: Color(0xFFAA512B),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                  // 처리 완료 후 로그인 화면 복귀
                  if (_complete)
                    FilledButton(
                      onPressed: () => Navigator.pop(context),
                      style: _primaryButtonStyle(),
                      child: const Text('로그인으로 돌아가기'),
                    ),

                  const SizedBox(height: 28),
                  const Text(
                    '고민은 짧게, 집밥은 맛있게',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      height: 1.6,
                      letterSpacing: -0.4,
                      color: Color(0xFF99918B),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
