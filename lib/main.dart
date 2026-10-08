import 'package:flutter/material.dart';

import 'models/user_device_model.dart';
import 'screens/home_screen.dart';
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
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFEF7544)),
        scaffoldBackgroundColor: const Color(0xFFFFFAF5),
      ),
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
    _registration = _service.register();
  }

  void _retry() {
    setState(() {
      _registration = _service.register();
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
}
