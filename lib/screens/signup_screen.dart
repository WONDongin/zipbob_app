import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import '../services/user_service.dart';
import '../services/email_verification_service.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  static const _orange = Color(0xFFEF7544);
  static const _background = Color(0xFFFFFAF5);
  static const _border = Color(0xFFECE6E0);

  final _formKey = GlobalKey<FormState>();

  final _service = UserService();
  final _verificationService = EmailVerificationService();

  final _codeController = TextEditingController();
  final _idController = TextEditingController();
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _emailController = TextEditingController();
  final _domainController = TextEditingController();

  bool _hidePassword = true;
  bool _hideConfirm = true;

  bool _submitting = false;
  bool _sending = false;
  bool _confirming = false;

  String? _serverError;
  String? _verificationMessage;

  bool _verificationError = false;

  // 현재 확인할 인증 요청 ID
  int? _verificationId;
  // 현재 확인할 인증 증명 토큰
  String? _verificationToken;
  // 인증번호·인증 증명·재발송 대기 시간
  DateTime? _codeDeadline;
  // 인증 증명 유효시간
  DateTime? _tokenDeadline;
  // 재발송 대기 시간
  DateTime? _resendDeadline;

  Timer? _verificationTimer;

  int _emailGeneration = 0;

  String _lastEmailText = '';
  String _lastDomainText = '';

  // 회원가입·발송·확인 중 하나라도 진행 중인지
  bool get _busy => _submitting || _sending || _confirming;

  // 인증 증명이 있고 화면 기준 유효시간이 남아 있는지
  bool get _verified =>
      _verificationToken != null && _seconds(_tokenDeadline) > 0;

  // 만료 시각까지 남은 초 계산
  int _seconds(DateTime? deadline) {
    if (deadline == null) {
      return 0;
    }

    final milliseconds = deadline.difference(DateTime.now()).inMilliseconds;

    return milliseconds <= 0 ? 0 : (milliseconds / 1000).ceil();
  }

  // 남은 시간을 분:초로 표시
  String _timeLeft(DateTime? deadline) {
    final seconds = _seconds(deadline);

    return '${seconds ~/ 60}:'
        '${(seconds % 60).toString().padLeft(2, '0')}';
  }

  @override
  void initState() {
    super.initState();

    // 직접 입력과 도메인 칩 선택 모두 감지
    _emailController.addListener(_onEmailEdited);
    _domainController.addListener(_onEmailEdited);
  }

  // 이메일 변경 시 기존 인증 상태 초기화
  void _onEmailEdited() {
    // 커서 이동·선택 영역 변경만으로는 초기화하지 않음
    if (_lastEmailText == _emailController.text &&
        _lastDomainText == _domainController.text) {
      return;
    }

    _lastEmailText = _emailController.text;
    _lastDomainText = _domainController.text;

    _emailGeneration++;

    _verificationTimer?.cancel();
    _codeController.clear();

    setState(() {
      _verificationId = null;
      _verificationToken = null;

      _codeDeadline = null;
      _tokenDeadline = null;

      // 발송 대기는 이메일을 바꿔도 유지
      // 실제 재발송 허용 여부는 백엔드에서도 검증
      _verificationMessage = null;
      _verificationError = false;
      _serverError = null;
    });

    _startTimer();
  }

  // 인증번호·인증 증명·재발송 대기 시간 갱신
  void _startTimer() {
    _verificationTimer?.cancel();

    _verificationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        if (_verificationToken != null && _seconds(_tokenDeadline) == 0) {
          _verificationToken = null;
          _verificationMessage = '인증 유효시간이 지났어요. 다시 발송해 주세요.';
          _verificationError = true;
        } else if (_verificationToken == null &&
            _verificationId != null &&
            _seconds(_codeDeadline) == 0) {
          _verificationId = null;
          _verificationMessage = '인증번호가 만료됐어요. 다시 발송해 주세요.';
          _verificationError = true;
        }
      });

      if (_seconds(_codeDeadline) == 0 &&
          _seconds(_tokenDeadline) == 0 &&
          _seconds(_resendDeadline) == 0) {
        timer.cancel();
      }
    });
  }

  // 인증번호 발송
  Future<void> _sendVerification() async {
    if (_busy || _seconds(_resendDeadline) > 0) {
      return;
    }

    FocusScope.of(context).unfocus();

    // 인증번호 발송에서는 이메일 항목만 검사
    final error =
        _validateEmail(_emailController.text) ??
        _validateDomain(_domainController.text);

    if (error != null) {
      setState(() {
        _verificationMessage = error;
        _verificationError = true;
      });

      return;
    }

    final generation = _emailGeneration;
    final watch = Stopwatch()..start();

    setState(() {
      _sending = true;

      _verificationId = null;
      _verificationToken = null;

      _codeDeadline = null;
      _tokenDeadline = null;

      _verificationMessage = null;
      _serverError = null;

      _codeController.clear();

      // 응답이 없어도 서버에서는 발송했을 가능성이 있음
      _resendDeadline = DateTime.now().add(const Duration(seconds: 60));
    });

    _startTimer();

    try {
      final result = await _verificationService.send(
        email: _emailController.text,
        emailAdr: _domainController.text,
      );

      if (!mounted || generation != _emailGeneration) {
        return;
      }

      setState(() {
        _verificationId = result.id;

        // 응답 대기 시간을 보수적으로 차감
        _codeDeadline = DateTime.now()
            .add(Duration(seconds: result.expiresInSeconds))
            .subtract(watch.elapsed);

        _verificationMessage = '인증번호를 발송했어요. 메일함과 스팸함을 확인해 주세요.';
        _verificationError = false;
      });
    } on EmailVerificationException catch (error) {
      if (!mounted || generation != _emailGeneration) {
        return;
      }

      setState(() {
        _verificationMessage = error.message;
        _verificationError = true;
      });
    } catch (_) {
      if (!mounted || generation != _emailGeneration) {
        return;
      }

      setState(() {
        _verificationMessage = '인증번호 발송 중 오류가 발생했어요. 다시 시도해 주세요.';
        _verificationError = true;
      });
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  // 인증번호 확인
  Future<void> _confirmVerification() async {
    if (_busy) {
      return;
    }

    final id = _verificationId;
    final code = _codeController.text;

    if (id == null ||
        _seconds(_codeDeadline) == 0 ||
        !RegExp(r'^[0-9]{6}$').hasMatch(code)) {
      setState(() {
        _verificationMessage = '유효시간 내에 인증번호 6자리를 입력해 주세요.';
        _verificationError = true;
      });

      return;
    }

    final generation = _emailGeneration;
    final watch = Stopwatch()..start();

    setState(() => _confirming = true);

    try {
      final result = await _verificationService.confirm(
        emailVerificationId: id,
        verificationCode: code,
      );

      if (!mounted || generation != _emailGeneration) {
        return;
      }

      setState(() {
        _verificationToken = result.token;

        _tokenDeadline = DateTime.now()
            .add(Duration(seconds: result.expiresInSeconds))
            .subtract(watch.elapsed);

        // 인증 완료 후 번호 입력 단계 정리
        _verificationId = null;
        _codeDeadline = null;
        _codeController.clear();

        _verificationMessage = '이메일 인증을 완료했어요.';
        _verificationError = false;
        _serverError = null;
      });

      _startTimer();
    } on EmailVerificationException catch (error) {
      if (!mounted || generation != _emailGeneration) {
        return;
      }

      setState(() {
        _verificationMessage = error.message;
        _verificationError = true;
      });
    } catch (_) {
      if (!mounted || generation != _emailGeneration) {
        return;
      }

      setState(() {
        _verificationMessage = '인증 확인 중 오류가 발생했어요. 다시 시도해 주세요.';
        _verificationError = true;
      });
    } finally {
      if (mounted) {
        setState(() => _confirming = false);
      }
    }
  }

  // 이메일 인증 화면 영역
  Widget _verificationSection() {
    final resendSeconds = _seconds(_resendDeadline);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedButton.icon(
          onPressed: _busy || resendSeconds > 0 ? null : _sendVerification,
          icon: _sending
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.mark_email_read_outlined, size: 20),
          label: Text(
            _sending
                ? '발송 중…'
                : resendSeconds > 0
                ? '재발송 가능까지 $resendSeconds초'
                : _verificationId != null || _verificationToken != null
                ? '인증번호 재발송'
                : '인증번호 발송',
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: _orange,
            minimumSize: const Size(double.infinity, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),

        // 발송 성공 후 인증번호 입력 영역 표시
        if (_verificationId != null && !_verified) ...[
          const SizedBox(height: 14),
          TextField(
            controller: _codeController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            maxLength: 6,
            enabled: !_busy,
            decoration: InputDecoration(
              labelText: '인증번호',
              hintText: '메일로 받은 숫자 6자리',
              filled: true,
              fillColor: Colors.white,
              suffixText: _timeLeft(_codeDeadline),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: _busy || _seconds(_codeDeadline) == 0
                ? null
                : _confirmVerification,
            style: FilledButton.styleFrom(
              backgroundColor: _orange,
              foregroundColor: Colors.white,
            ),
            child: Text(_confirming ? '확인 중…' : '인증 확인'),
          ),
        ],

        // 발송·확인 결과 안내
        if (_verificationMessage != null) ...[
          const SizedBox(height: 10),
          Text(
            _verificationMessage!,
            style: TextStyle(
              fontSize: 12,
              height: 1.6,
              color: _verificationError
                  ? const Color(0xFFB74726)
                  : const Color(0xFF287344),
            ),
          ),
        ],

        // 인증 완료 후 회원가입까지 남은 시간 표시
        if (_verified) ...[
          const SizedBox(height: 6),
          Text(
            '인증 완료 · 가입 가능 시간 ${_timeLeft(_tokenDeadline)}',
            style: const TextStyle(fontSize: 12, color: Color(0xFF287344)),
          ),
        ],

        const SizedBox(height: 22),
      ],
    );
  }

  @override
  void dispose() {
    _verificationTimer?.cancel();

    _emailController.removeListener(_onEmailEdited);
    _domainController.removeListener(_onEmailEdited);

    _codeController.dispose();
    _idController.dispose();
    _nameController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _emailController.dispose();
    _domainController.dispose();

    super.dispose();
  }

  // 입력을 수정하면 이전 서버 오류 안내 제거
  void _onEdited(String _) {
    if (_serverError != null) {
      setState(() => _serverError = null);
    }
  }

  String? _validateId(String? value) {
    final text = value?.trim() ?? '';

    if (text.isEmpty) {
      return '아이디를 입력해 주세요.';
    }

    if (!RegExp(r'^[A-Za-z0-9_]{4,50}$').hasMatch(text)) {
      return '영문, 숫자, 밑줄로 4~50자 입력해 주세요.';
    }

    return null;
  }

  String? _validateName(String? value) {
    final text = value?.trim() ?? '';

    if (text.isEmpty) {
      return '닉네임을 입력해 주세요.';
    }

    if (!RegExp(r'^[가-힣A-Za-z0-9_]{2,20}$').hasMatch(text)) {
      return '한글, 영문, 숫자, 밑줄로 2~20자 입력해 주세요.';
    }

    return null;
  }

  String? _validatePassword(String? value) {
    final text = value ?? '';

    if (text.length < 8) {
      return '비밀번호는 8자 이상 입력해 주세요.';
    }

    if (utf8.encode(text).length > 72) {
      return '비밀번호는 UTF-8 기준 72바이트 이하여야 해요.';
    }

    if (!RegExp(r'[A-Za-z]').hasMatch(text) ||
        !RegExp(r'[0-9]').hasMatch(text)) {
      return '영문과 숫자를 포함해 주세요.';
    }

    return null;
  }

  String? _validateConfirm(String? value) {
    if (value == null || value.isEmpty) {
      return '비밀번호를 한 번 더 입력해 주세요.';
    }

    if (value != _passwordController.text) {
      return '비밀번호가 일치하지 않아요.';
    }

    return null;
  }

  String? _validateEmail(String? value) {
    final text = (value ?? '').trim().toLowerCase();

    if (text.isEmpty) {
      return '이메일 아이디를 입력해 주세요.';
    }

    final pattern = RegExp(
      r"^[a-z0-9!#$%&'*+/=?^_`{|}~-]+"
      r"(?:\.[a-z0-9!#$%&'*+/=?^_`{|}~-]+)*$",
    );

    if (text.length > 50 || !pattern.hasMatch(text)) {
      return '이메일 @ 앞부분을 확인해 주세요.';
    }

    return null;
  }

  String? _validateDomain(String? value) {
    final text = (value ?? '').trim().toLowerCase();

    if (text.isEmpty) {
      return '이메일 도메인을 입력해 주세요.';
    }

    final pattern = RegExp(
      r'^[a-z0-9](?:[a-z0-9-]*[a-z0-9])?'
      r'(?:\.[a-z0-9](?:[a-z0-9-]*[a-z0-9])?)+$',
    );

    if (text.length > 50 || !pattern.hasMatch(text)) {
      return 'gmail.com 같은 도메인을 입력해 주세요.';
    }

    return null;
  }

  // 회원가입
  Future<void> _submit() async {
    if (_busy) {
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() => _serverError = null);

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_verified) {
      setState(() {
        _serverError = '이메일 인증을 완료해 주세요.';
      });

      return;
    }

    setState(() => _submitting = true);

    String? successMessage;
    String? errorMessage;

    try {
      successMessage = await _service.signup(
        userId: _idController.text,
        userPw: _passwordController.text,
        userPwConfirm: _confirmController.text,
        userName: _nameController.text,
        email: _emailController.text,
        emailAdr: _domainController.text,
        verificationToken: _verificationToken!,
      );
    } on SignupException catch (error) {
      errorMessage = error.message;
    } on TimeoutException {
      errorMessage = '응답이 지연되고 있어요. 가입이 완료됐을 수도 있으니 상태를 확인해 주세요.';
    } on http.ClientException {
      errorMessage = '서버에 연결하지 못했어요. 연결 상태를 확인해 주세요.';
    } catch (_) {
      errorMessage = '요청 처리 중 오류가 발생했어요. 잠시 후 다시 시도해 주세요.';
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _submitting = false;
      _serverError = errorMessage;
    });

    if (successMessage == null) {
      // 오류가 있어도 입력값 유지
      return;
    }

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: _background,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text('집밥PICK에 오신 걸 환영해요!'),
          content: Text(successMessage!),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('확인', style: TextStyle(color: _orange)),
            ),
          ],
        );
      },
    );

    if (!mounted) {
      return;
    }

    // 회원가입 완료 후 이전 화면으로 결과 전달
    Navigator.pop(context, true);
  }

  // 공통 입력창
  Widget _field({
    required String label,
    required String hint,
    required TextEditingController controller,
    required String? Function(String?) validator,
    required IconData icon,
    bool obscureText = false,
    Widget? suffix,
    TextInputType keyboardType = TextInputType.text,
    bool autocorrect = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF222222),
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            validator: validator,
            onChanged: _onEdited,
            obscureText: obscureText,
            keyboardType: keyboardType,
            autocorrect: autocorrect,
            enableSuggestions: false,
            textInputAction: TextInputAction.next,
            style: const TextStyle(fontSize: 14),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(
                fontSize: 12,
                color: Color(0xFF999999),
              ),
              filled: true,
              fillColor: Colors.white,
              prefixIcon: Icon(icon, size: 21, color: _orange),
              suffixIcon: suffix,
              errorMaxLines: 3,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 17,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _orange, width: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // 요청 중 뒤로 가기로 화면을 닫는 상황 방지
      canPop: !_busy,
      child: Scaffold(
        backgroundColor: _background,
        appBar: AppBar(
          title: const Text(
            '회원가입',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w500),
          ),
          centerTitle: true,
          backgroundColor: _background,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            tooltip: '뒤로',
            onPressed: _busy ? null : () => Navigator.maybePop(context),
            icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            child: AbsorbPointer(
              absorbing: _busy,
              child: Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Image.asset(
                        'assets/images/logo/zipbob_pick_logo.png',
                        width: 150,
                        height: 48,
                        fit: BoxFit.contain,
                        semanticLabel: '집밥PICK',
                      ),
                    ),
                    const SizedBox(height: 22),
                    const Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(text: '반가워요,\n'),
                          TextSpan(
                            text: '집밥 친구!',
                            style: TextStyle(color: _orange),
                          ),
                        ],
                      ),
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.8,
                        height: 1.4,
                        color: Color(0xFF222222),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '오늘의 한 끼, 집밥PICK과 함께 시작해요.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF777777),
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 30),

                    _field(
                      label: '아이디',
                      hint: '영문, 숫자, 밑줄 4~50자',
                      controller: _idController,
                      validator: _validateId,
                      icon: Icons.person_outline_rounded,
                    ),

                    _field(
                      label: '닉네임',
                      hint: '집밥PICK에서 사용할 이름',
                      controller: _nameController,
                      validator: _validateName,
                      icon: Icons.face_outlined,
                    ),

                    _field(
                      label: '비밀번호',
                      hint: '영문과 숫자를 포함해 8자 이상',
                      controller: _passwordController,
                      validator: _validatePassword,
                      icon: Icons.lock_outline_rounded,
                      obscureText: _hidePassword,
                      suffix: IconButton(
                        tooltip: _hidePassword ? '비밀번호 표시' : '비밀번호 숨기기',
                        onPressed: () {
                          setState(() {
                            _hidePassword = !_hidePassword;
                          });
                        },
                        icon: Icon(
                          _hidePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          size: 20,
                          color: const Color(0xFF888888),
                        ),
                      ),
                    ),

                    _field(
                      label: '비밀번호 확인',
                      hint: '비밀번호를 한 번 더 입력해 주세요.',
                      controller: _confirmController,
                      validator: _validateConfirm,
                      icon: Icons.lock_outline_rounded,
                      obscureText: _hideConfirm,
                      suffix: IconButton(
                        tooltip: _hideConfirm ? '비밀번호 확인 표시' : '비밀번호 확인 숨기기',
                        onPressed: () {
                          setState(() {
                            _hideConfirm = !_hideConfirm;
                          });
                        },
                        icon: Icon(
                          _hideConfirm
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          size: 20,
                          color: const Color(0xFF888888),
                        ),
                      ),
                    ),

                    _field(
                      label: '이메일 아이디',
                      hint: '이메일의 @ 앞부분',
                      controller: _emailController,
                      validator: _validateEmail,
                      icon: Icons.mail_outline_rounded,
                      keyboardType: TextInputType.emailAddress,
                    ),

                    _field(
                      label: '이메일 도메인',
                      hint: 'gmail.com',
                      controller: _domainController,
                      validator: _validateDomain,
                      icon: Icons.alternate_email_rounded,
                      keyboardType: TextInputType.emailAddress,
                    ),

                    // 좁은 화면에서는 자동 줄바꿈
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final domain in [
                          'gmail.com',
                          'naver.com',
                          'daum.net',
                        ])
                          ActionChip(
                            label: Text(
                              domain,
                              style: const TextStyle(fontSize: 11),
                            ),
                            backgroundColor: Colors.white,
                            side: const BorderSide(color: _border),
                            onPressed: () {
                              _domainController.text = domain;
                              _onEdited(domain);
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: 22),

                    // 추가된 이메일 인증 영역
                    _verificationSection(),

                    if (_serverError != null) ...[
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFEEE5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.info_outline,
                              color: Color(0xFFB74726),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _serverError!,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFFB74726),
                                  height: 1.6,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    FilledButton(
                      onPressed: _busy || !_verified ? null : _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: _orange,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 56),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _submitting
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              '회원가입',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      '고민은 짧게, 집밥은 맛있게',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: Color(0xFF999999)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
