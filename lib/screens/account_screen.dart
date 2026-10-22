import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import 'login_screen.dart';

const _primary = Color(0xFFEF7544);
const _background = Color(0xFFFFFAF5);
const _softOrange = Color(0xFFFFEEE5);
const _border = Color(0xFFF0E5DC);
const _titleColor = Color(0xFF222222);
const _bodyColor = Color(0xFF78716B);

// 내 정보: 회원 정보 조회·닉네임 변경·로그아웃
class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final _auth = AuthService.instance;

  late Future<AuthUser> _profile;

  bool _loggingOut = false;
  bool _editingNickname = false;

  bool get _busy => _loggingOut || _editingNickname;

  @override
  void initState() {
    super.initState();

    _profile = _auth.getMe();
  }

  // 닉네임 변경창 열기
  Future<void> _editNickname(AuthUser user) async {
    if (_busy) return;

    setState(() => _editingNickname = true);

    try {
      final updatedUser = await showDialog<AuthUser>(
        context: context,
        barrierDismissible: false,
        builder: (_) => _NicknameDialog(initialNickname: user.userName),
      );

      if (!mounted || updatedUser == null) return;

      // 서버에서 받은 변경된 회원 정보로 화면 갱신
      setState(() {
        _profile = Future<AuthUser>.value(updatedUser);
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('닉네임을 변경했어요.')));
    } finally {
      if (mounted) {
        setState(() => _editingNickname = false);
      }
    }
  }

  // 로그아웃
  Future<void> _logout() async {
    if (_busy) return;

    setState(() => _loggingOut = true);

    try {
      final message = await _auth.logout();

      if (!mounted) return;

      setState(() => _loggingOut = false);

      await WidgetsBinding.instance.endOfFrame;

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));

      Navigator.pop(context);
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('로그아웃을 완료하지 못했어요. 다시 시도해 주세요.')),
      );
    } finally {
      if (mounted) {
        setState(() => _loggingOut = false);
      }
    }
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: _background,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 19, color: _primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  height: 1.5,
                  letterSpacing: -0.4,
                  color: _bodyColor,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.6,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.4,
                  color: _titleColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_busy,
      child: Scaffold(
        backgroundColor: _background,
        appBar: AppBar(
          title: const Text(
            '내 정보',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w500,
              letterSpacing: -0.5,
            ),
          ),
          centerTitle: true,
          automaticallyImplyLeading: !_busy,
          backgroundColor: _background,
          foregroundColor: _titleColor,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
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
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.person_outline_rounded,
                        size: 15,
                        color: _primary,
                      ),
                      SizedBox(width: 6),
                      Text(
                        '나의 집밥PICK',
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
              const Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: '맛있는 일상,\n'),
                    TextSpan(
                      text: '함께하고 있어요.',
                      style: TextStyle(color: _primary),
                    ),
                  ],
                ),
                style: TextStyle(
                  fontSize: 27,
                  height: 1.45,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.9,
                  color: _titleColor,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                '내 정보를 확인하고 닉네임을 변경할 수 있어요.',
                style: TextStyle(
                  fontSize: 12,
                  height: 1.7,
                  letterSpacing: -0.4,
                  color: _bodyColor,
                ),
              ),
              const SizedBox(height: 26),
              FutureBuilder<AuthUser>(
                future: _profile,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: _primary,
                          strokeWidth: 3,
                        ),
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    final error = snapshot.error;

                    return Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: _border),
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.info_outline_rounded,
                            size: 38,
                            color: _primary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            error is AuthException
                                ? error.message
                                : '회원 정보를 불러오지 못했어요.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 13,
                              height: 1.7,
                              color: _bodyColor,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: _busy
                                ? null
                                : () {
                                    if (_auth.hasSession) {
                                      setState(() {
                                        _profile = _auth.getMe();
                                      });
                                    } else {
                                      Navigator.pushReplacement<void, void>(
                                        context,
                                        MaterialPageRoute<void>(
                                          builder: (_) => const LoginScreen(),
                                        ),
                                      );
                                    }
                                  },
                            style: TextButton.styleFrom(
                              foregroundColor: _primary,
                            ),
                            child: Text(_auth.hasSession ? '다시 시도' : '로그인하기'),
                          ),
                        ],
                      ),
                    );
                  }

                  final user = snapshot.data!;

                  return Card(
                    margin: EdgeInsets.zero,
                    color: Colors.white,
                    surfaceTintColor: Colors.transparent,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                      side: const BorderSide(color: _border),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Center(
                            child: Container(
                              width: 84,
                              height: 84,
                              decoration: const BoxDecoration(
                                color: _softOrange,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.person_rounded,
                                size: 44,
                                color: _primary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            '${user.userName}님',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 23,
                              height: 1.4,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.7,
                              color: _titleColor,
                            ),
                          ),
                          const SizedBox(height: 8),

                          // 닉네임 변경 버튼
                          Center(
                            child: TextButton.icon(
                              onPressed: _busy
                                  ? null
                                  : () => _editNickname(user),
                              icon: const Icon(Icons.edit_outlined, size: 15),
                              label: const Text(
                                '닉네임 변경',
                                style: TextStyle(
                                  fontSize: 11,
                                  letterSpacing: -0.4,
                                ),
                              ),
                              style: TextButton.styleFrom(
                                foregroundColor: const Color(0xFFAA512B),
                                backgroundColor: _background,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),
                          const Divider(height: 1, color: _border),
                          const SizedBox(height: 24),
                          _buildInfoItem(
                            icon: Icons.badge_outlined,
                            label: '아이디',
                            value: user.userId,
                          ),
                          if (user.email != null) ...[
                            const SizedBox(height: 22),
                            _buildInfoItem(
                              icon: Icons.mail_outline_rounded,
                              label: '이메일',
                              value: user.email!,
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
              OutlinedButton(
                onPressed: _busy ? null : _logout,
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: _bodyColor,
                  minimumSize: const Size(double.infinity, 52),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 16,
                  ),
                  side: const BorderSide(color: _border),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _loggingOut
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: _primary,
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.logout_rounded, size: 18),
                          SizedBox(width: 8),
                          Text(
                            '로그아웃',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              letterSpacing: -0.4,
                            ),
                          ),
                        ],
                      ),
              ),
              const SizedBox(height: 26),
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
    );
  }
}

// 닉네임 변경 입력창
class _NicknameDialog extends StatefulWidget {
  final String initialNickname;

  const _NicknameDialog({required this.initialNickname});

  @override
  State<_NicknameDialog> createState() => _NicknameDialogState();
}

class _NicknameDialogState extends State<_NicknameDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _controller;

  bool _saving = false;
  String? _errorMessage;

  static final _nicknamePattern = RegExp(r'^[가-힣A-Za-z0-9_]{2,20}$');

  @override
  void initState() {
    super.initState();

    // 기존 닉네임을 입력창에 표시
    _controller = TextEditingController(text: widget.initialNickname);
  }

  @override
  void dispose() {
    _controller.dispose();

    super.dispose();
  }

  // 닉네임 입력 검증
  String? _validateNickname(String? value) {
    final nickname = value?.trim() ?? '';

    if (nickname.isEmpty) {
      return '닉네임을 입력해 주세요.';
    }

    if (!_nicknamePattern.hasMatch(nickname)) {
      return '한글, 영문, 숫자, 밑줄로 2~20자 입력해 주세요.';
    }

    return null;
  }

  // 닉네임 저장
  Future<void> _save() async {
    if (_saving) return;

    setState(() => _errorMessage = null);

    if (!_formKey.currentState!.validate()) return;

    final nickname = _controller.text.trim();

    if (nickname == widget.initialNickname) {
      setState(() {
        _errorMessage = '현재 닉네임과 같아요. 다른 닉네임을 입력해 주세요.';
      });
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() => _saving = true);

    try {
      final updatedUser = await AuthService.instance.updateNickname(nickname);

      if (!mounted) return;

      // 뒤로 이동 제한을 해제한 뒤 입력창 닫기
      setState(() => _saving = false);

      await WidgetsBinding.instance.endOfFrame;

      if (!mounted) return;

      // 변경된 회원 정보를 내 정보 화면으로 반환
      Navigator.of(context).pop(updatedUser);
    } on AuthException catch (error) {
      if (!mounted) return;

      setState(() {
        _saving = false;
        _errorMessage = error.message;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _saving = false;
        _errorMessage = '닉네임을 변경하지 못했어요. 잠시 후 다시 시도해 주세요.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_saving,
      child: AlertDialog(
        backgroundColor: _background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        titlePadding: const EdgeInsets.fromLTRB(24, 26, 24, 0),
        contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
        actionsPadding: const EdgeInsets.fromLTRB(24, 8, 24, 22),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _softOrange,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.edit_outlined, size: 23, color: _primary),
            ),
            const SizedBox(height: 18),
            const Text(
              '닉네임 변경',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.7,
                color: _titleColor,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '한글, 영문, 숫자, 밑줄을 사용해\n'
                  '2~20자로 입력해 주세요.',
                  style: TextStyle(
                    fontSize: 12,
                    color: _bodyColor,
                    height: 1.8,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _controller,
                  enabled: !_saving,
                  autofocus: true,
                  maxLength: 20,
                  textInputAction: TextInputAction.done,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  cursorColor: _primary,
                  style: const TextStyle(
                    fontSize: 14,
                    letterSpacing: -0.4,
                    color: _titleColor,
                  ),
                  decoration: InputDecoration(
                    labelText: '닉네임',
                    hintText: '새 닉네임을 입력해 주세요.',
                    filled: true,
                    fillColor: Colors.white,
                    labelStyle: const TextStyle(
                      fontSize: 13,
                      color: _bodyColor,
                    ),
                    floatingLabelStyle: const TextStyle(color: _primary),
                    hintStyle: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFFAAA097),
                    ),
                    counterStyle: const TextStyle(
                      fontSize: 10,
                      color: _bodyColor,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 17,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: _border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: _border),
                    ),
                    disabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: _border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: _primary, width: 1.5),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.error,
                        width: 1.5,
                      ),
                    ),
                    errorMaxLines: 3,
                  ),
                  validator: _validateNickname,
                  onChanged: (_) {
                    if (_errorMessage != null) {
                      setState(() {
                        _errorMessage = null;
                      });
                    }
                  },
                  onFieldSubmitted: (_) => _save(),
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _errorMessage!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontSize: 12,
                      height: 1.6,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: _saving ? null : () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              foregroundColor: _bodyColor,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            ),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: _saving ? null : _save,
            style: FilledButton.styleFrom(
              backgroundColor: _primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('저장'),
          ),
        ],
      ),
    );
  }
}
