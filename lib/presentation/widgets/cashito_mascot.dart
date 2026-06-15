import 'package:flutter/material.dart';

/// Widget reutilizable para mostrar al mascota Cashito en diferentes contextos
class CashitoMascot extends StatelessWidget {
  final CashitoMood mood;
  final double size;
  final String? message;
  final bool showBubble;
  final MainAxisAlignment alignment;

  const CashitoMascot({
    super.key,
    required this.mood,
    this.size = 120,
    this.message,
    this.showBubble = false,
    this.alignment = MainAxisAlignment.center,
  });

  String get _imagePath {
    switch (mood) {
      case CashitoMood.greeting:
        return 'assets/images/cat-saludando.png';
      case CashitoMood.welcome:
        return 'assets/images/cat-bienvenida.png';
      case CashitoMood.happy:
        return 'assets/images/cat-ilusionado.png';
      case CashitoMood.veryHappy:
        return 'assets/images/cat-ilusionado-2.png';
      case CashitoMood.sad:
        return 'assets/images/cat-triste.png';
      case CashitoMood.loading:
        return 'assets/images/cat-cargando.png';
      case CashitoMood.money:
        return 'assets/images/cat-dinero-billetes.png';
      case CashitoMood.savings:
        return 'assets/images/cat-alcancia.png';
      case CashitoMood.goals:
        return 'assets/images/cat-metas.png';
      case CashitoMood.goalsAlt:
        return 'assets/images/cat-metas-2.png';
      case CashitoMood.stats:
        return 'assets/images/cat-estadisticas.png';
      case CashitoMood.statsAlt:
        return 'assets/images/cat-estadisticas-2.png';
      case CashitoMood.statsLow:
        return 'assets/images/cat-estadisticas-bajas.png';
      case CashitoMood.income:
        return 'assets/images/cat-dashboard-ingresos.png';
      case CashitoMood.receipts:
        return 'assets/images/cat-recibos.png';
      case CashitoMood.warning:
        return 'assets/images/cat-cono.png';
      case CashitoMood.alert1:
        return 'assets/images/cat-alerta-inteligente-1.png';
      case CashitoMood.alert2:
        return 'assets/images/cat-alerta-inteligente-2.png';
      case CashitoMood.alert3:
        return 'assets/images/cat-alerta-inteligente-3.png';
      case CashitoMood.notifications:
        return 'assets/images/cat-con-notificaciones.png';
      case CashitoMood.noNotifications:
        return 'assets/images/cat-sin-notificaciones.png';
      case CashitoMood.auth:
        return 'assets/images/cat-auth.png';
      case CashitoMood.edit:
        return 'assets/images/cat-editar.png';
      case CashitoMood.theme:
        return 'assets/images/cat-color-tema.png';
      case CashitoMood.chatbot:
        return 'assets/images/cat-chatbot.png';
    }
  }

  @override
  Widget build(BuildContext context) {
    final mascotImage = Image.asset(
      _imagePath,
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return SizedBox(
          width: size,
          height: size,
          child: const Icon(Icons.pets, size: 48, color: Colors.grey),
        );
      },
    );

    if (message == null && !showBubble) {
      return mascotImage;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: alignment,
      children: [
        mascotImage,
        if (message != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              message!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Estados de ánimo del mascota Cashito
enum CashitoMood {
  greeting,      // Saludando - para bienvenidas
  welcome,       // Bienvenida - pantalla inicial
  happy,         // Ilusionado - logros, metas cercanas
  veryHappy,     // Muy feliz - metas completadas
  sad,           // Triste - errores, metas canceladas
  loading,       // Cargando - estados de carga
  money,         // Con billetes - ingresos
  savings,       // Con alcancía - ahorros
  goals,         // Metas - pantalla de metas
  goalsAlt,      // Metas alternativo
  stats,         // Estadísticas - reportes
  statsAlt,      // Estadísticas alternativo
  statsLow,      // Estadísticas bajas - pocos gastos
  income,        // Dashboard ingresos
  receipts,      // Recibos - transacciones
  warning,       // Advertencia - con cono
  alert1,        // Alerta inteligente 1
  alert2,        // Alerta inteligente 2
  alert3,        // Alerta inteligente 3
  notifications, // Con notificaciones
  noNotifications, // Sin notificaciones
  auth,          // Autenticación
  edit,          // Editando
  theme,         // Tema/colores
  chatbot,       // Chatbot/asistente
}

/// Widget para estados vacíos con Cashito
class CashitoEmptyState extends StatelessWidget {
  final CashitoMood mood;
  final String title;
  final String? subtitle;
  final Widget? action;
  final double mascotSize;

  const CashitoEmptyState({
    super.key,
    required this.mood,
    required this.title,
    this.subtitle,
    this.action,
    this.mascotSize = 140,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CashitoMascot(mood: mood, size: mascotSize),
            const SizedBox(height: 24),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: 24),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

/// Widget de carga con Cashito
class CashitoLoading extends StatefulWidget {
  final String? message;
  final double size;

  const CashitoLoading({
    super.key,
    this.message,
    this.size = 100,
  });

  @override
  State<CashitoLoading> createState() => _CashitoLoadingState();
}

class _CashitoLoadingState extends State<CashitoLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat(reverse: true);

    _bounceAnimation = Tween<double>(begin: 0, end: -10).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _bounceAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, _bounceAnimation.value),
                child: child,
              );
            },
            child: CashitoMascot(
              mood: CashitoMood.loading,
              size: widget.size,
            ),
          ),
          const SizedBox(height: 16),
          if (widget.message != null)
            Text(
              widget.message!,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
        ],
      ),
    );
  }
}
