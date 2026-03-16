import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/constants/colors.dart';
import '../../core/localization/app_localizations.dart';

class LoginTypeScreen extends StatefulWidget {
  const LoginTypeScreen({super.key});

  @override
  State<LoginTypeScreen> createState() => _LoginTypeScreenState();
}

class _LoginTypeScreenState extends State<LoginTypeScreen>
    with SingleTickerProviderStateMixin {
  final List<String> _heroLineKeys = <String>[
    'hero_line_1',
    'hero_line_2',
    'hero_line_3',
  ];
  int _heroIndex = 0;
  Timer? _heroTimer;
  Timer? _logoTapResetTimer;
  int _logoTapCount = 0;
  late final AnimationController _backgroundController;

  @override
  void initState() {
    super.initState();
    _backgroundController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat();
    _heroTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _heroIndex = (_heroIndex + 1) % _heroLineKeys.length;
      });
    });
  }

  @override
  void dispose() {
    _heroTimer?.cancel();
    _logoTapResetTimer?.cancel();
    _backgroundController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/background-img.png',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) {
                return Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF2B1507),
                        Color(0xFF9B5D1F),
                        Color(0xFFEDD7BD),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          _buildBackgroundDecor(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(loc),
                  const SizedBox(height: 20),
                  _buildStatsStrip(),
                  const SizedBox(height: 24),
                  _buildPortalCards(context),
                  const SizedBox(height: 18),
                  _buildFooter(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundDecor() {
    return AnimatedBuilder(
      animation: _backgroundController,
      builder: (context, _) {
        final t = _backgroundController.value * 2 * math.pi;
        return IgnorePointer(
          child: Stack(
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.08),
                        Colors.black.withValues(alpha: 0.03),
                        Colors.black.withValues(alpha: 0.1),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(-0.1, -0.6),
                      radius: 1.2,
                      colors: [
                        const Color(0xFFFFCA8A).withValues(alpha: 0.2),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: -70 + math.sin(t) * 10,
                right: -44 + math.cos(t) * 8,
                child: Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFFFF4E8).withValues(alpha: 0.24),
                  ),
                ),
              ),
              Positioned(
                top: -70 + math.sin(t * 0.85) * 9,
                left: -45 + math.cos(t * 0.65) * 6,
                child: Transform.rotate(
                  angle: -0.32,
                  child: Container(
                    width: 160,
                    height: 300,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(90),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withValues(alpha: 0.08),
                          Colors.white.withValues(alpha: 0.01),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 180 + math.cos(t * 0.9) * 10,
                left: -94 + math.sin(t * 0.75) * 9,
                child: Container(
                  width: 230,
                  height: 230,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(120),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        const Color(0xFFFFE1BC).withValues(alpha: 0.28),
                        Colors.white.withValues(alpha: 0.09),
                        AppColors.green.withValues(alpha: 0.18),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: -72 + math.sin(t * 1.2) * 10,
                right: -22 + math.cos(t * 0.85) * 8,
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(70),
                    color: AppColors.saffron.withValues(alpha: 0.19),
                  ),
                ),
              ),
              Positioned(
                bottom: -95 + math.cos(t * 0.9) * 6,
                right: 76 + math.sin(t * 1.1) * 6,
                child: Transform.rotate(
                  angle: 0.26,
                  child: Container(
                    width: 125,
                    height: 240,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(90),
                      gradient: LinearGradient(
                        colors: [
                          AppColors.saffron.withValues(alpha: 0.16),
                          Colors.white.withValues(alpha: 0.01),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 80 + math.sin(t * 1.4) * 6,
                left: 16 + math.cos(t * 0.8) * 5,
                child: Opacity(
                  opacity: 0.15,
                  child: CustomPaint(
                    size: const Size(120, 120),
                    painter: _AshokaChakraPainter(
                      color: Colors.white.withValues(alpha: 0.65),
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: Align(
                  alignment: const Alignment(0.68, -0.18),
                  child: Opacity(
                    opacity: 0.17,
                    child: ColorFiltered(
                      colorFilter: ColorFilter.mode(
                        const Color(0xFFFFF3E0).withValues(alpha: 0.95),
                        BlendMode.srcATop,
                      ),
                      child: Image.asset(
                        'assets/images/indian_emblem.png',
                        width: 320,
                        height: 320,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.account_balance,
                            size: 240,
                            color: Colors.white.withValues(alpha: 0.75),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 64 + math.cos(t * 1.1) * 5,
                left: 12,
                child: Opacity(
                  opacity: 0.1,
                  child: Text(
                    'INDIA',
                    style: TextStyle(
                      fontSize: 46,
                      letterSpacing: 6,
                      fontWeight: FontWeight.w900,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(AppLocalizations loc) {
    final heroLines = _heroLineKeys.map(loc.translate).toList();
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: Colors.black.withValues(alpha: 0.24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: _handleLogoTap,
                child: Container(
                  width: 74,
                  height: 74,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.saffron.withValues(alpha: 0.35),
                        blurRadius: 22,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(
                      'assets/images/my_logo.png',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) {
                        return const Icon(Icons.image_not_supported_outlined);
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loc.translate('app_title'),
                      style: TextStyle(
                        fontSize: 36,
                        height: 1.02,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 0.4,
                        shadows: [
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.34),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      loc.translate('digital_india_initiative'),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.92),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        shadows: [
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.28),
                            blurRadius: 8,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 360),
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.03, 0),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              );
            },
            child: Text(
              heroLines[_heroIndex],
              key: ValueKey<String>(heroLines[_heroIndex]),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                shadows: [
                  Shadow(
                    color: Colors.black54,
                    blurRadius: 8,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: List<Widget>.generate(_heroLineKeys.length, (index) {
              final active = index == _heroIndex;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 280),
                margin: const EdgeInsets.only(right: 6),
                width: active ? 22 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: active ? Colors.white : Colors.white38,
                  borderRadius: BorderRadius.circular(20),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  void _handleLogoTap() {
    _logoTapResetTimer?.cancel();
    _logoTapCount += 1;
    if (_logoTapCount >= 7) {
      _logoTapCount = 0;
      _showAuthorFullscreen();
      return;
    }
    _logoTapResetTimer = Timer(const Duration(seconds: 2), () {
      _logoTapCount = 0;
    });
  }

  Future<void> _showAuthorFullscreen() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (context) {
          return Scaffold(
            backgroundColor: Colors.black,
            body: SafeArea(
              child: Stack(
                children: [
                  Center(
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).maybePop(),
                      child: Image.asset(
                        'assets/images/author.jpeg',
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.image_not_supported_outlined,
                          color: Colors.white,
                          size: 64,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: IconButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.close, color: Colors.white),
                      tooltip: 'Close',
                    ),
                  ),
                  Positioned(
                    left: 20,
                    right: 20,
                    bottom: 24,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(22),
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFF0B1B2C).withValues(alpha: 0.75),
                                const Color(0xFF1A0F2E).withValues(alpha: 0.7),
                              ],
                            ),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.18),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF39B9FF)
                                    .withValues(alpha: 0.2),
                                blurRadius: 24,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(Icons.auto_awesome,
                                      size: 16, color: Color(0xFFBDE8FF)),
                                  SizedBox(width: 8),
                                  Text(
                                    'Creator & Developer of the App',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Color(0xFFE7F6FF),
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.6,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF3D6)
                                      .withValues(alpha: 0.95),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: const Color(0xFFD6A843),
                                    width: 1.6,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFD6A843)
                                          .withValues(alpha: 0.35),
                                      blurRadius: 12,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                                child: const Text(
                                  'MOHAMMED FAIZAN KHAN',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.1,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatsStrip() {
    return AnimatedBuilder(
      animation: _backgroundController,
      builder: (context, _) {
        final t = _backgroundController.value * 2 * math.pi;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: Colors.black.withValues(alpha: 0.34),
            border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatTile(
                value: '2,736+',
                label: 'FPS Shops',
                offsetY: math.sin(t) * 3.2,
              ),
              const _StatDivider(),
              _StatTile(
                value: '5.4L+',
                label: 'Beneficiaries',
                offsetY: math.sin(t + 1.5) * 3.2,
              ),
              const _StatDivider(),
              _StatTile(
                value: '98%',
                label: 'Distribution',
                offsetY: math.sin(t + 3.0) * 3.2,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPortalCards(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          loc.translate('select_portal'),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          loc.translate('choose_role_continue'),
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: 13,
            shadows: [
              Shadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 8,
                offset: const Offset(0, 1),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _PortalCard(
          icon: Icons.person_outline,
          title: loc.translate('citizen_login'),
          subtitle: loc.translate('access_ration'),
          accent: const Color(0xFF1A9F55),
          onTap: () => Navigator.pushNamed(context, '/citizen-login'),
          delay: 0,
        ),
        const SizedBox(height: 12),
        _PortalCard(
          icon: Icons.storefront_outlined,
          title: loc.translate('fps_dealer'),
          subtitle: loc.translate('manage_stock'),
          accent: const Color(0xFFE8892A),
          onTap: () => Navigator.pushNamed(context, '/fps-login'),
          delay: 80,
        ),
        const SizedBox(height: 12),
        _PortalCard(
          icon: Icons.admin_panel_settings_outlined,
          title: loc.translate('admin_portal'),
          subtitle: loc.translate('secure_authentication'),
          accent: const Color(0xFFD24A43),
          onTap: () => Navigator.pushNamed(context, '/admin-login'),
          delay: 160,
        ),
      ],
    );
  }

  Widget _buildFooter() {
    final loc = AppLocalizations.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.white.withValues(alpha: 0.08),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.verified_user_outlined, color: Colors.white, size: 16),
          const SizedBox(width: 8),
          Text(
            loc.translate('secure_auth_uidai'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              shadows: [
                Shadow(
                  color: Colors.black54,
                  blurRadius: 8,
                  offset: Offset(0, 1),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.value,
    required this.label,
    this.offsetY = 0,
  });

  final String value;
  final String label;
  final double offsetY;

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: Offset(0, offsetY),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
              shadows: [
                Shadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.94),
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              shadows: [
                Shadow(
                  color: Colors.black.withValues(alpha: 0.28),
                  blurRadius: 8,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 34,
      color: Colors.white.withValues(alpha: 0.42),
    );
  }
}

class _PortalCard extends StatelessWidget {
  const _PortalCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.onTap,
    required this.delay,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
  final VoidCallback onTap;
  final int delay;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: 420 + delay),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 14),
            child: child,
          ),
        );
      },
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Ink(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: 0.26),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: LinearGradient(
                      colors: [
                        accent.withValues(alpha: 0.18),
                        accent.withValues(alpha: 0.06),
                      ],
                    ),
                  ),
                  child: Icon(icon, color: accent, size: 28),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded, color: accent, size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AshokaChakraPainter extends CustomPainter {
  const _AshokaChakraPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final rimPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final spokePaint = Paint()
      ..color = color
      ..strokeWidth = 1.2;
    final hubPaint = Paint()..color = color;

    canvas.drawCircle(center, radius * 0.92, rimPaint);
    canvas.drawCircle(center, radius * 0.18, rimPaint);
    canvas.drawCircle(center, radius * 0.05, hubPaint);

    for (int i = 0; i < 24; i++) {
      final angle = (i * math.pi * 2) / 24;
      final start = Offset(
        center.dx + math.cos(angle) * (radius * 0.2),
        center.dy + math.sin(angle) * (radius * 0.2),
      );
      final end = Offset(
        center.dx + math.cos(angle) * (radius * 0.9),
        center.dy + math.sin(angle) * (radius * 0.9),
      );
      canvas.drawLine(start, end, spokePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _AshokaChakraPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
