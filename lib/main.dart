import 'package:flutter/material.dart';

import 'dart:ui' show PointerDeviceKind;

import 'models/user_device_model.dart';
import 'screens/home_screen.dart';
import 'services/user_device_service.dart';
import 'services/auth_service.dart';

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
  final UserDeviceService _service = UserDeviceService();

  late Future<UserDeviceModel> _registration;

  @override
  void initState() {
    super.initState();

    // 화면 생성 시 한 번 호출
    _registration = _initialize();
  }

  void _retry() {
    setState(() {
      _registration = _initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserDeviceModel>(
      future: _registration,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('앱을 시작하지 못했어요.'),
                    const SizedBox(height: 8),
                    const Text('연결을 확인하고 다시 시도해 주세요.'),
                    const SizedBox(height: 16),
                    FilledButton(onPressed: _retry, child: const Text('다시 시도')),
                  ],
                ),
              ),
            ),
          );
        }

        return const HomeScreen();
      },
    );
  }

  Future<UserDeviceModel> _initialize() async {
    final device = await _service.register();

    try {
      await AuthService.instance.restore();
    } catch (_) {
      // 인증 복원에 실패해도 비회원 기능은 이용 가능
    }

    return device;
  }
}
