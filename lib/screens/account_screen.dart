import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import 'login_screen.dart';

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

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_busy,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('내 정보'),
          centerTitle: true,
          automaticallyImplyLeading: !_busy,
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              FutureBuilder<AuthUser>(
                future: _profile,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  if (snapshot.hasError) {
                    final error = snapshot.error;

                    return Column(
                      children: [
                        Text(
                          error is AuthException
                              ? error.message
                              : '회원 정보를 불러오지 못했어요.',
                          textAlign: TextAlign.center,
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
                          child: Text(_auth.hasSession ? '다시 시도' : '로그인하기'),
                        ),
                      ],
                    );
                  }

                  final user = snapshot.data!;

                  return Card(
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.account_circle_outlined,
                            size: 52,
                            color: Color(0xFFEF7544),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '${user.userName}님',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),

                          // 닉네임 변경 버튼
                          TextButton.icon(
                            onPressed: _busy ? null : () => _editNickname(user),
                            icon: const Icon(Icons.edit_outlined, size: 18),
                            label: const Text('닉네임 변경'),
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFFEF7544),
                            ),
                          ),

                          const SizedBox(height: 18),
                          Text(
                            '아이디  ${user.userId}',
                            style: const TextStyle(fontSize: 14),
                          ),
                          if (user.email != null) ...[
                            const SizedBox(height: 10),
                            Text(
                              '이메일  ${user.email}',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              OutlinedButton(
                onPressed: _busy ? null : _logout,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                ),
                child: _loggingOut
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('로그아웃'),
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
        title: const Text('닉네임 변경'),
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
                    fontSize: 13,
                    color: Colors.black54,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _controller,
                  enabled: !_saving,
                  autofocus: true,
                  maxLength: 20,
                  textInputAction: TextInputAction.done,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  decoration: const InputDecoration(
                    labelText: '닉네임',
                    hintText: '새 닉네임을 입력해 주세요.',
                    border: OutlineInputBorder(),
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
                      fontSize: 13,
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
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: _saving ? null : _save,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFEF7544),
              foregroundColor: Colors.white,
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
