import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../api/layanan_api.dart';
import '../api/models/cart_item.dart';

/// Konstanta terpusat untuk durasi, kurva, dan parameter animasi di ATK Mart.
class MotionConstants {
  // Durasi animasi
  static const Duration fast = Duration(milliseconds: 140);
  static const Duration normal = Duration(milliseconds: 220);
  static const Duration page = Duration(milliseconds: 280);
  static const Duration cartSuccess = Duration(milliseconds: 800);
  static const Duration badgePop = Duration(milliseconds: 300);
  static const Duration shimmer = Duration(milliseconds: 1200);

  // Kurva animasi
  static const Curve easeOut = Curves.easeOut;
  static const Curve easeInOut = Curves.easeInOut;
  static const Curve easeOutCubic = Curves.easeOutCubic;
  static const Curve fastOutSlowIn = Curves.fastOutSlowIn;

  // Staggering list produk
  static const Duration staggerDelay = Duration(milliseconds: 35);
  static const int maxStaggerItems = 8;

  // Nilai scale interaksi
  static const double pressedScale = 0.97;
  static const double badgePopScale = 1.25;

  /// Memeriksa apakah preferensi aksesibilitas mematikan animasi
  static bool animationsDisabled(BuildContext context) {
    return MediaQuery.maybeDisableAnimationsOf(context) ?? false;
  }

  /// Menyesuaikan durasi dengan preferensi aksesibilitas pengguna
  static Duration getDuration(BuildContext context, Duration original) {
    return animationsDisabled(context) ? Duration.zero : original;
  }
}

/// Sinkronisasi state keranjang belanja global (jumlah item untuk badge)
class StateKeranjang {
  static final ValueNotifier<int> countNotifier = ValueNotifier<int>(0);

  static int get count => countNotifier.value;

  static void updateCountFromData(KeranjangData data) {
    final totalQty = data.items.fold<int>(0, (sum, item) => sum + item.jumlah);
    countNotifier.value = totalQty;
  }

  static void updateCount(int newCount) {
    countNotifier.value = newCount < 0 ? 0 : newCount;
  }

  static void increment([int delta = 1]) {
    countNotifier.value = (countNotifier.value + delta).clamp(0, 9999);
  }

  static void decrement([int delta = 1]) {
    countNotifier.value = (countNotifier.value - delta).clamp(0, 9999);
  }

  static Future<void> refresh() async {
    try {
      final data = await LayananApi().fetchKeranjang();
      updateCountFromData(data);
    } catch (_) {
      // Abaikan jika offline atau sesi belum login
    }
  }

  static void reset() {
    countNotifier.value = 0;
  }
}

/// Widget interaktif reusable yang memberikan efek scale ke 0.97 saat ditekan
/// dan kembali halus saat dilepas tanpa menghalangi ripple/InkWell di dalamnya.
class PressableScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final bool enabled;
  final double scale;
  final Duration duration;
  final Curve curve;
  final bool enableHaptic;
  final BoxConstraints? constraints;

  const PressableScale({
    super.key,
    required this.child,
    this.onPressed,
    this.enabled = true,
    this.scale = MotionConstants.pressedScale,
    this.duration = MotionConstants.fast,
    this.curve = MotionConstants.easeOut,
    this.enableHaptic = false,
    this.constraints,
  });

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _isPressed = false;

  void _handleTapDown(TapDownDetails _) {
    if (!widget.enabled) return;
    if (widget.enableHaptic) {
      HapticFeedback.selectionClick();
    }
    setState(() => _isPressed = true);
  }

  void _handleTapUp(TapUpDetails _) {
    if (!widget.enabled) return;
    setState(() => _isPressed = false);
  }

  void _handleTapCancel() {
    if (!widget.enabled) return;
    setState(() => _isPressed = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDisabledByA11y = MotionConstants.animationsDisabled(context);
    final targetScale = (!widget.enabled || isDisabledByA11y || !_isPressed)
        ? 1.0
        : widget.scale;

    Widget result = AnimatedScale(
      scale: targetScale,
      duration: MotionConstants.getDuration(context, widget.duration),
      curve: widget.curve,
      child: widget.child,
    );

    if (widget.constraints != null) {
      result = ConstrainedBox(
        constraints: widget.constraints!,
        child: result,
      );
    }

    if (widget.onPressed != null) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        onTap: widget.enabled ? widget.onPressed : null,
        child: result,
      );
    }

    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) {
        if (!widget.enabled) return;
        if (widget.enableHaptic) {
          HapticFeedback.selectionClick();
        }
        setState(() => _isPressed = true);
      },
      onPointerUp: (_) {
        if (!widget.enabled) return;
        setState(() => _isPressed = false);
      },
      onPointerCancel: (_) {
        if (!widget.enabled) return;
        setState(() => _isPressed = false);
      },
      child: result,
    );
  }
}

/// Icon Keranjang dengan Badge angka Material 3 dan animasi pop scale singkat (300 ms)
class AnimatedCartBadgeIcon extends StatefulWidget {
  final IconData icon;
  final Color? color;
  final double size;

  const AnimatedCartBadgeIcon({
    super.key,
    this.icon = Icons.shopping_cart_outlined,
    this.color,
    this.size = 24,
  });

  @override
  State<AnimatedCartBadgeIcon> createState() => _AnimatedCartBadgeIconState();
}

class _AnimatedCartBadgeIconState extends State<AnimatedCartBadgeIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  int _prevCount = 0;

  @override
  void initState() {
    super.initState();
    _prevCount = StateKeranjang.count;
    _controller = AnimationController(
      vsync: this,
      duration: MotionConstants.badgePop,
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: MotionConstants.badgePopScale)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: MotionConstants.badgePopScale, end: 1.0)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 65,
      ),
    ]).animate(_controller);

    StateKeranjang.countNotifier.addListener(_onCountChanged);
  }

  void _onCountChanged() {
    final current = StateKeranjang.count;
    if (current != _prevCount) {
      _prevCount = current;
      if (mounted) {
        if (!MotionConstants.animationsDisabled(context)) {
          _controller.forward(from: 0.0);
        } else {
          setState(() {});
        }
      }
    }
  }

  @override
  void dispose() {
    StateKeranjang.countNotifier.removeListener(_onCountChanged);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: StateKeranjang.countNotifier,
      builder: (context, count, _) {
        final label = count > 99 ? '99+' : count.toString();
        final badgeWidget = Badge(
          isLabelVisible: count > 0,
          label: Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          backgroundColor: const Color(0xFFE14B4B),
          child: Icon(widget.icon, size: widget.size, color: widget.color),
        );

        if (MotionConstants.animationsDisabled(context)) {
          return badgeWidget;
        }

        return ScaleTransition(
          scale: _scaleAnimation,
          child: badgeWidget,
        );
      },
    );
  }
}

/// Helper transisi perpindahan halaman terpusat dengan Fade + Slide halus (280 ms)
class SlideFadePageRoute<T> extends PageRouteBuilder<T> {
  final WidgetBuilder builder;

  SlideFadePageRoute({
    required this.builder,
    super.settings,
    Duration duration = MotionConstants.page,
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) =>
              builder(context),
          transitionDuration: duration,
          reverseTransitionDuration: duration,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            if (MotionConstants.animationsDisabled(context)) {
              return child;
            }

            final curved = CurvedAnimation(
              parent: animation,
              curve: MotionConstants.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
            );

            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.06, 0.0),
                end: Offset.zero,
              ).animate(curved),
              child: FadeTransition(
                opacity: Tween<double>(begin: 0.0, end: 1.0).animate(curved),
                child: child,
              ),
            );
          },
        );
}

/// Helper navigasi menggunakan SlideFadePageRoute
class AppNav {
  static Future<T?> push<T>(BuildContext context, Widget page) {
    return Navigator.push<T>(
      context,
      SlideFadePageRoute<T>(builder: (_) => page),
    );
  }
}

/// Widget transisi staggered fade + slide up ringan untuk item list produk
class StaggeredListItem extends StatelessWidget {
  final int index;
  final Widget child;

  const StaggeredListItem({
    super.key,
    required this.index,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (MotionConstants.animationsDisabled(context)) {
      return child;
    }

    final clamped = index.clamp(0, MotionConstants.maxStaggerItems);
    final delay = clamped * MotionConstants.staggerDelay.inMilliseconds;

    return TweenAnimationBuilder<double>(
      key: ValueKey('stagger_${index}_$clamped'),
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 240 + delay),
      curve: MotionConstants.easeOutCubic,
      builder: (context, val, animChild) {
        final offset = (1.0 - val) * 14.0;
        return Opacity(
          opacity: val.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, offset),
            child: animChild,
          ),
        );
      },
      child: child,
    );
  }
}

/// Efek Skeleton Shimmer mandiri tanpa dependency tambahan
class SkeletonShimmer extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  const SkeletonShimmer({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius,
  });

  @override
  State<SkeletonShimmer> createState() => _SkeletonShimmerState();
}

class _SkeletonShimmerState extends State<SkeletonShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: MotionConstants.shimmer,
    )..repeat();

    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
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
    if (MotionConstants.animationsDisabled(context)) {
      return Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: const Color(0xFFE8E8EE),
          borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
        ),
      );
    }

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        final val = _animation.value;
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              stops: [
                (val - 0.35).clamp(0.0, 1.0),
                val.clamp(0.0, 1.0),
                (val + 0.35).clamp(0.0, 1.0),
              ],
              colors: const [
                Color(0xFFEEEEF3),
                Color(0xFFF9F9FC),
                Color(0xFFEEEEF3),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Tampilan skeleton loading kartu produk pengganti CircularProgressIndicator
class ProductListSkeleton extends StatelessWidget {
  const ProductListSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.only(top: 4, bottom: 20),
      itemCount: 4,
      itemBuilder: (context, index) {
        return Card(
          color: Colors.white,
          elevation: 0.8,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: Color(0xFFE6E6EC), width: 0.8),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SkeletonShimmer(
                  width: 84,
                  height: 84,
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Expanded(
                            child: SkeletonShimmer(
                              width: double.infinity,
                              height: 16,
                            ),
                          ),
                          SizedBox(width: 10),
                          SkeletonShimmer(width: 64, height: 18),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const SkeletonShimmer(width: 90, height: 12),
                      const SizedBox(height: 10),
                      const SkeletonShimmer(width: 150, height: 12),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: const [
                          SkeletonShimmer(width: 80, height: 18),
                          SkeletonShimmer(width: 58, height: 28),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
