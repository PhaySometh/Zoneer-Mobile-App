import 'package:flutter/material.dart';
import 'package:zoneer_mobile/core/utils/app_colors.dart';
import 'package:zoneer_mobile/presentation/screens/notification/notification_screen.dart';

/// Inserts a self-managing floating notification banner into the root overlay.
/// The banner slides in from the top, shows a depleting progress line,
/// auto-dismisses, and navigates to the notification page on tap.
void showFloatingBanner(
  BuildContext context, {
  required String title,
  required String message,
  Duration displayDuration = const Duration(seconds: 5),
}) {
  // Capture navigator before any navigation happens.
  final navigator = Navigator.of(context, rootNavigator: true);
  final overlay = Overlay.of(context, rootOverlay: true);

  late OverlayEntry entry;
  bool removed = false;

  void removeEntry() {
    if (!removed) {
      removed = true;
      entry.remove();
    }
  }

  entry = OverlayEntry(
    builder: (_) => _FloatingBannerWidget(
      title: title,
      message: message,
      displayDuration: displayDuration,
      onTap: () {
        removeEntry();
        navigator.push(
          MaterialPageRoute(builder: (_) => const NotificationScreen()),
        );
      },
      onDone: removeEntry,
    ),
  );

  overlay.insert(entry);
}

// ---------------------------------------------------------------------------

class _FloatingBannerWidget extends StatefulWidget {
  final String title;
  final String message;
  final Duration displayDuration;
  final VoidCallback onTap;
  final VoidCallback onDone;

  const _FloatingBannerWidget({
    required this.title,
    required this.message,
    required this.displayDuration,
    required this.onTap,
    required this.onDone,
  });

  @override
  State<_FloatingBannerWidget> createState() => _FloatingBannerWidgetState();
}

class _FloatingBannerWidgetState extends State<_FloatingBannerWidget>
    with TickerProviderStateMixin {
  late final AnimationController _slideCtrl;
  late final Animation<Offset> _slideAnim;
  late final Animation<double> _fadeAnim;
  late final AnimationController _progressCtrl;
  bool _dismissed = false;

  @override
  void initState() {
    super.initState();

    // Slide-in animation
    _slideCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, -1.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOutCubic));
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOut),
    );

    // Progress countdown (value: 1.0 → 0.0 over displayDuration)
    _progressCtrl = AnimationController(
      vsync: this,
      duration: widget.displayDuration,
      value: 1.0,
    );

    // Slide in → then start countdown → then slide out
    _slideCtrl.forward().whenComplete(() {
      if (mounted && !_dismissed) {
        _progressCtrl.reverse().whenComplete(() {
          if (mounted && !_dismissed) _dismiss();
        });
      }
    });
  }

  @override
  void dispose() {
    _slideCtrl.dispose();
    _progressCtrl.dispose();
    super.dispose();
  }

  void _dismiss() {
    if (_dismissed) return;
    _dismissed = true;
    _progressCtrl.stop();
    _slideCtrl.reverse().whenComplete(widget.onDone);
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top + 8;

    return Positioned(
      top: top,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _slideAnim,
        child: FadeTransition(
          opacity: _fadeAnim,
          child: Material(
            color: Colors.transparent,
            child: GestureDetector(
              onTap: widget.onTap,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.14),
                      blurRadius: 24,
                      spreadRadius: 1,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ── Main content row ──────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 13, 14, 11),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Icon badge
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.home_work_outlined,
                              size: 22,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Title + message
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  widget.title,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black87,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  widget.message,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.black54,
                                    height: 1.35,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Dismiss ×
                          GestureDetector(
                            onTap: _dismiss,
                            behavior: HitTestBehavior.opaque,
                            child: const Padding(
                              padding: EdgeInsets.all(4),
                              child: Icon(
                                Icons.close,
                                size: 16,
                                color: Colors.black38,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // ── Progress line ─────────────────────────────────────
                    ClipRRect(
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(18),
                        bottomRight: Radius.circular(18),
                      ),
                      child: AnimatedBuilder(
                        animation: _progressCtrl,
                        builder: (_, __) => LinearProgressIndicator(
                          value: _progressCtrl.value,
                          minHeight: 3,
                          backgroundColor: Colors.grey.shade100,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.primary.withValues(alpha: 0.55),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
