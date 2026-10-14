import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/auth_service.dart';
import 'signup_screen.dart';

// 로그인 화면 : 아이디·비밀번호 입력, 로그인 요청, 회원가입 이동
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const _orange = Color(0xFFEF7544);
  static const _background = Color(0xFFFFFAF5);

  final _formKey = GlobalKey<FormState>();
  final _idController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _hidePassword = true;
  bool _submitting = false;

  String? _error;

  @override
  void dispose() {
    _idController.dispose();
    _passwordController.dispose();

    super.dispose();
  }

  void _onEdited(String _) {
    if (_error != null) {
      setState(() => _error = null);
    }
  }

  Future<void> _submit() async {
    if (_submitting || !_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      await AuthService.instance.login(
        userId: _idController.text,
        userPw: _passwordController.text,
      );

      if (!mounted) return;

      setState(() => _submitting = false);

      // 뒤로 이동 허용 상태가 반영된 뒤 화면 닫기
      await WidgetsBinding.instance.endOfFrame;

      if (!mounted) return;

      TextInput.finishAutofillContext();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${AuthService.instance.user!.userName}님, 반가워요!'),
        ),
      );

      Navigator.pop(context);
    } on AuthException catch (error) {
      if (mounted) {
        setState(() => _error = error.message);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = '로그인을 완료하지 못했어요. 잠시 후 다시 시도해 주세요.');
      }
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  Future<void> _openSignup() async {
    final completed = await Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(builder: (_) => const SignupScreen()),
    );

    if (!mounted || completed != true) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('회원가입이 완료됐어요. 가입한 계정으로 로그인해 주세요.')),
    );
  }

  InputDecoration _decoration(String hint, IconData icon, {Widget? suffix}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF999999)),
      filled: true,
      fillColor: Colors.white,
      prefixIcon: Icon(icon, size: 21, color: _orange),
      suffixIcon: suffix,
      errorMaxLines: 3,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFECE6E0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _orange, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_submitting,
      child: Scaffold(
        backgroundColor: _background,
        appBar: AppBar(
          title: const Text(
            '로그인',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w500),
          ),
          centerTitle: true,
          backgroundColor: _background,
          surfaceTintColor: Colors.transparent,
          scrolledUnderElevation: 0,
          leading: IconButton(
            tooltip: '뒤로',
            onPressed: _submitting ? null : () => Navigator.maybePop(context),
            icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
            child: AbsorbPointer(
              absorbing: _submitting,
              child: AutofillGroup(
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
                      const SizedBox(height: 28),
                      const Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(text: '다시 만나서\n'),
                            TextSpan(
                              text: '반가워요!',
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
                      const SizedBox(height: 10),
                      const Text(
                        '오늘도 맛있는 한 끼, 집밥PICK과 함께해요.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF777777),
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 36),
                      const Text(
                        '아이디',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _idController,
                        autofillHints: const [AutofillHints.username],
                        autocorrect: false,
                        enableSuggestions: false,
                        textInputAction: TextInputAction.next,
                        style: const TextStyle(fontSize: 14),
                        decoration: _decoration(
                          '아이디를 입력해 주세요.',
                          Icons.person_outline_rounded,
                        ),
                        onChanged: _onEdited,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return '아이디를 입력해 주세요.';
                          }

                          return null;
                        },
                      ),
                      const SizedBox(height: 22),
                      const Text(
                        '비밀번호',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _passwordController,
                        autofillHints: const [AutofillHints.password],
                        obscureText: _hidePassword,
                        autocorrect: false,
                        enableSuggestions: false,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _submit(),
                        style: const TextStyle(fontSize: 14),
                        decoration: _decoration(
                          '비밀번호를 입력해 주세요.',
                          Icons.lock_outline_rounded,
                          suffix: IconButton(
                            tooltip: _hidePassword ? '비밀번호 표시' : '비밀번호 숨기기',
                            onPressed: () {
                              setState(() => _hidePassword = !_hidePassword);
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
                        onChanged: _onEdited,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return '비밀번호를 입력해 주세요.';
                          }

                          if (utf8.encode(value).length > 72) {
                            return '비밀번호는 UTF-8 기준 72바이트 이하로 입력해 주세요.';
                          }

                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      if (_error != null) ...[
                        Semantics(
                          liveRegion: true,
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFEEE5),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _error!,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFFB74726),
                                height: 1.6,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      FilledButton(
                        onPressed: _submitting ? null : _submit,
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
                                '로그인',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                      ),
                      const SizedBox(height: 18),
                      Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          const Text(
                            '아직 집밥 친구가 아니신가요?',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF777777),
                            ),
                          ),
                          TextButton(
                            onPressed: _submitting ? null : _openSignup,
                            style: TextButton.styleFrom(
                              foregroundColor: _orange,
                            ),
                            child: const Text(
                              '회원가입',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 36),
                      const Text(
                        '고민은 짧게, 집밥은 맛있게',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF999999),
                        ),
                      ),
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
}
