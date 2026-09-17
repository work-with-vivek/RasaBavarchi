import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/storage/secure_storage_service.dart';

class AuthGate extends ConsumerStatefulWidget {
  const AuthGate({super.key});

  @override
  ConsumerState<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends ConsumerState<AuthGate> {
  @override
  void initState() {
    super.initState();

    Future.microtask(_checkAuthentication);
  }

  Future<void> _checkAuthentication() async {
    try {
      final token = await SecureStorageService.getToken();

      debugPrint(
        'AUTH GATE TOKEN: ${token == null || token.isEmpty ? 'NULL' : 'FOUND'}',
      );

      if (!mounted) {
        return;
      }

      if (token != null && token.isNotEmpty) {
        debugPrint('AUTH GATE: TOKEN FOUND → HOME');
        context.go('/home');
      } else {
        debugPrint('AUTH GATE: NO TOKEN → LOGIN');
        context.go('/login');
      }
    } catch (e, stackTrace) {
      debugPrint('AUTH GATE ERROR: $e');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) {
        return;
      }

      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFFDF8ED),
      body: Center(child: CircularProgressIndicator(color: Color(0xFF00695C))),
    );
  }
}
