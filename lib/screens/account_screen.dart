import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import 'login_screen.dart';

// 내 정보 화면 : 회원 정보 조회, 로그아웃
class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final _auth = AuthService.instance;

  late Future<AuthUser> _profile;
  bool _loggingOut = false;

  @override
  void initState() {
    super.initState();

    _profile = _auth.getMe();
  }

  Future<void> _logout() async {
    if (_loggingOut) return;

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
      canPop: !_loggingOut,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('내 정보'),
          centerTitle: true,
          automaticallyImplyLeading: !_loggingOut,
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
                          onPressed: _loggingOut
                              ? null
                              : () {
                                  if (_auth.hasSession) {
                                    setState(() => _profile = _auth.getMe());
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
                onPressed: _loggingOut ? null : _logout,
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
