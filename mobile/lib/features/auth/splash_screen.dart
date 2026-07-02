import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:meu_personal_ai/core/config/app_config.dart';
import 'package:meu_personal_ai/core/theme/app_theme.dart';
import 'package:meu_personal_ai/features/auth/data/auth_notifier.dart';

/// Tela exibida durante a inicialização do app.
/// Verifica autenticação e navega para Home ou Login.
///
/// Rota: /  (root, definida antes do redirect no GoRouter)
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double>   _scale, _fade;

  @override
  void initState() {
    super.initState();

    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _scale = Tween(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut));
    _fade = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.0, 0.5)));

    _ctrl.forward();

    // Aguarda animação + verificação de auth
    Future.wait([
      Future.delayed(const Duration(milliseconds: 1400)),
      _checkAuth(),
    ]).then((_) {
      if (mounted) _navigate();
    });
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  Future<void> _checkAuth() async {
    // Força o authProvider a resolver antes de navegar
    await ref.read(authProvider.future);
  }

  void _navigate() {
    final auth = ref.read(authProvider).valueOrNull;
    if (auth?.isAuthenticated == true) {
      if (auth!.needsAnamnesis) {
        context.go('/onboarding');
      } else {
        context.go('/home');
      }
    } else {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      body: Center(
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (_, __) => FadeTransition(
            opacity: _fade,
            child: ScaleTransition(
              scale: _scale,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Ícone do app
                  Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.brandPrimary,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Center(
                      child: Text(
                        AppConfig.appInitials,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -1,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Nome do app
                  Text(
                    AppConfig.appName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Tagline
                  Text(
                    AppConfig.appTagline,
                    style: const TextStyle(
                      color: Color(0xFF888888),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
