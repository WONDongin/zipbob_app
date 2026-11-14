import 'dart:async';
import 'dart:convert';
import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'screens/home_screen.dart';
import 'screens/startup_loading_screen.dart';
import 'services/auth_service.dart';
import 'services/user_device_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const ZipbobApp());
}

class ZipbobApp extends StatelessWidget {
  const ZipbobApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '집밥PICK',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'GmarketSans',
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFEF7544)),
        scaffoldBackgroundColor: const Color(0xFFFFFAF5),
      ),

      // 웹에서도 마우스로 누르고 끌어서 스크롤 가능
      scrollBehavior: const MaterialScrollBehavior().copyWith(
        dragDevices: {
          ...const MaterialScrollBehavior().dragDevices,
          PointerDeviceKind.mouse,
        },
      ),

      // 전체 페이지를 모바일 화면 폭으로 제한
      builder: (context, child) {
        return ColoredBox(
          color: const Color(0xFFF0ECE8),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: child ?? const SizedBox.shrink(),
            ),
          ),
        );
      },
      home: const UserDeviceStartup(),
    );
  }
}

class UserDeviceStartup extends StatefulWidget {
  const UserDeviceStartup({super.key});

  @override
  State<UserDeviceStartup> createState() => _UserDeviceStartupState();
}

class _UserDeviceStartupState extends State<UserDeviceStartup> {
  // 서버 연결 확인에 사용할 최대 대기 시간
  static const Duration _maximumWait = Duration(minutes: 3);

  // 연결 확인 요청 한 번의 제한 시간
  static const Duration _requestTimeout = Duration(seconds: 10);

  // 요청 실패 후 다음 요청까지 기다리는 시간
  static const Duration _retryInterval = Duration(seconds: 5);

  final UserDeviceService _service = UserDeviceService();

  late Future<void> _startup;

  http.Client? _activeClient;

  String _statusMessage = '서버에 연결하고 있어요.';

  @override
  void initState() {
    super.initState();

    _startup = _initialize();
  }

  @override
  void dispose() {
    // 화면이 종료되면 진행 중인 연결 확인 요청도 종료
    _activeClient?.close();

    super.dispose();
  }

  void _retry() {
    setState(() {
      _statusMessage = '서버에 연결하고 있어요.';
      _startup = _initialize();
    });
  }

  void _updateStatus(String message) {
    if (!mounted) return;

    setState(() {
      _statusMessage = message;
    });
  }

  Future<void> _initialize() async {
    // 1. 서버가 정상 응답할 때까지 연결 확인
    await _waitForServer();

    if (!mounted) return;

    // 2. 서버 준비 후 기존 기기 등록 실행
    _updateStatus('앱을 시작하고 있어요.');

    await _service.register();

    if (!mounted) return;

    // 3. 저장된 로그인 상태 복원
    _updateStatus('로그인 상태를 확인하고 있어요.');

    try {
      await AuthService.instance.restore();
    } catch (_) {
      // 인증 복원에 실패해도 비회원 기능은 이용 가능
    }
  }

  Future<void> _waitForServer() async {
    final stopwatch = Stopwatch()..start();

    final uri = Uri.parse('${UserDeviceService.serverUrl}/api/codes/category');

    while (mounted) {
      final remaining = _maximumWait - stopwatch.elapsed;

      if (remaining <= Duration.zero) {
        break;
      }

      // 마지막 요청도 최대 대기 시간을 넘기지 않도록 제한
      final timeout = remaining < _requestTimeout ? remaining : _requestTimeout;

      // 요청마다 클라이언트를 만들고 종료해서
      // 시간 초과된 연결 확인 요청이 계속 남지 않도록 처리
      final client = http.Client();
      _activeClient = client;

      try {
        final response = await client.get(uri).timeout(timeout);

        if (!mounted) return;

        if (response.statusCode == 200) {
          final body = jsonDecode(utf8.decode(response.bodyBytes));

          // 기존 카테고리 API는 JSON 배열을 반환
          if (body is! List) {
            throw const _StartupException(
              '서버 응답을 확인하지 못했어요.\n잠시 후 다시 시도해 주세요.',
            );
          }

          return;
        }

        // 일시적인 서버 오류·요청 지연은 자동 재시도
        final retryable =
            response.statusCode == 408 ||
            response.statusCode == 429 ||
            response.statusCode >= 500;

        if (!retryable) {
          throw const _StartupException('서비스에 연결하지 못했어요.\n잠시 후 다시 시도해 주세요.');
        }
      } on TimeoutException {
        // 서버가 준비 중이면 잠시 기다린 후 다시 확인
      } on http.ClientException {
        // 일시적인 연결 실패도 동일하게 다시 확인
      } on FormatException {
        throw const _StartupException('서버 응답을 확인하지 못했어요.\n잠시 후 다시 시도해 주세요.');
      } finally {
        client.close();

        if (identical(_activeClient, client)) {
          _activeClient = null;
        }
      }

      if (!mounted) return;

      final remainingAfterRequest = _maximumWait - stopwatch.elapsed;

      if (remainingAfterRequest <= Duration.zero) {
        break;
      }

      final delay = remainingAfterRequest < _retryInterval
          ? remainingAfterRequest
          : _retryInterval;

      await Future<void>.delayed(delay);
    }

    if (!mounted) return;

    throw const _StartupException(
      '서버 연결이 평소보다 오래 걸리고 있어요.\n'
      '인터넷 연결을 확인하고 다시 시도해 주세요.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _startup,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return StartupLoadingScreen(statusMessage: _statusMessage);
        }

        if (snapshot.hasError) {
          final error = snapshot.error;

          final message = error is _StartupException
              ? error.message
              : '앱을 시작하지 못했어요.\n'
                    '연결을 확인하고 다시 시도해 주세요.';

          return StartupLoadingScreen(
            statusMessage: _statusMessage,
            errorMessage: message,
            onRetry: _retry,
          );
        }

        return const HomeScreen();
      },
    );
  }
}

class _StartupException implements Exception {
  final String message;

  const _StartupException(this.message);
}
