import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'components/retry_panel.dart';
import 'dependencies.dart';
import 'src/domain/entities/failure.dart';
import 'src/presentation/pages/registration_page.dart';
import 'src/presentation/widgets/messages.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  registerBackgroundHandler();
  runApp(const RegistrationApp());
}

class RegistrationApp extends StatefulWidget {
  const RegistrationApp({super.key});
  @override
  State<RegistrationApp> createState() => _RegistrationAppState();
}

class _RegistrationAppState extends State<RegistrationApp> {
  late Future<AppDependencies> boot = configureDependencies();
  @override
  void dispose() {
    unawaited(boot.then<void>((d) => d.dispose(), onError: (_) {}));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Регистрация',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff3455db)),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
      ),
    ),
    home: FutureBuilder<AppDependencies>(
      future: boot,
      builder: (c, s) {
        if (s.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final deps = s.data;
        if (deps != null) {
          return BlocProvider(
            create: (_) => deps.createCubit(),
            child: const RegistrationPage(),
          );
        }
        final error = s.error;
        return Scaffold(
          body: Center(
            child: RetryPanel(
              failureMessage(error is Failure ? error : const UnknownFailure()),
              () => setState(() => boot = configureDependencies()),
            ),
          ),
        );
      },
    ),
  );
}
