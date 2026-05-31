import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/notification_poll_service.dart';
import '../models/app_notification.dart';

/// Wraps any screen and shows a translucent banner at the top whenever a new
/// collaborative absence notification arrives from Google Sheets.
///
/// Usage:
///   NotificationBannerWrapper(child: YourScreen())
class NotificationBannerWrapper extends StatefulWidget {
  final Widget child;
  const NotificationBannerWrapper({super.key, required this.child});

  @override
  State<NotificationBannerWrapper> createState() =>
      _NotificationBannerWrapperState();
}

class _NotificationBannerWrapperState
    extends State<NotificationBannerWrapper> {
  final List<_ActiveBanner> _banners = [];
  int _lastCount = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final svc = context.watch<NotificationPollService>();
    if (svc.pendingNotifications.length > _lastCount) {
      final news = svc.pendingNotifications.sublist(_lastCount);
      _lastCount = svc.pendingNotifications.length;
      for (final n in news) {
        _showBanner(n);
      }
    }
  }

  void _showBanner(AppNotification notif) {
    final key = UniqueKey();
    setState(() {
      _banners.add(_ActiveBanner(key: key, notif: notif));
    });

    // Auto-dismiss after 4 seconds
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) _dismiss(key);
    });
  }

  void _dismiss(Key key) {
    setState(() {
      _banners.removeWhere((b) => b.key == key);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        // Stack banners vertically from top
        Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          left: 16,
          right: 16,
          child: Column(
            children: _banners
                .map((b) => _BannerTile(
                      key: b.key,
                      notif: b.notif,
                      onDismiss: () => _dismiss(b.key!),
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }
}

class _ActiveBanner {
  final Key? key;
  final AppNotification notif;
  _ActiveBanner({this.key, required this.notif});
}

// ── Single banner tile ─────────────────────────────────────────────────────

class _BannerTile extends StatefulWidget {
  final AppNotification notif;
  final VoidCallback onDismiss;
  const _BannerTile({super.key, required this.notif, required this.onDismiss});

  @override
  State<_BannerTile> createState() => _BannerTileState();
}

class _BannerTileState extends State<_BannerTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));

    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  IconData _icon() {
    switch (widget.notif.type) {
      case 'absence_added':
        return Icons.event_busy_rounded;
      case 'absence_archived':
        return Icons.archive_rounded;
      case 'absence_removed':
        return Icons.event_available_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _iconColor() {
    switch (widget.notif.type) {
      case 'absence_added':
        return const Color(0xFFEF4444);
      case 'absence_archived':
        return const Color(0xFFF59E0B);
      case 'absence_removed':
        return const Color(0xFF10B981);
      default:
        return const Color(0xFF0891B2);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SlideTransition(
        position: _slide,
        child: FadeTransition(
          opacity: _fade,
          child: Material(
            color: Colors.transparent,
            child: Container(
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1E293B).withOpacity(0.97)
                    : Colors.white.withOpacity(0.97),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(
                  color: _iconColor().withOpacity(0.3),
                  width: 1.2,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    // Icon circle
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _iconColor().withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(_icon(), color: _iconColor(), size: 20),
                    ),
                    const SizedBox(width: 12),
                    // Text content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.notif.title,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.notif.message,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? Colors.white70
                                  : const Color(0xFF475569),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (widget.notif.author.isNotEmpty) ...[
                            const SizedBox(height: 3),
                            Text(
                              '👤 ${widget.notif.author}',
                              style: TextStyle(
                                fontSize: 11,
                                color: _iconColor(),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    // Close button
                    IconButton(
                      icon: Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: isDark ? Colors.white38 : Colors.black38,
                      ),
                      onPressed: widget.onDismiss,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 28,
                        minHeight: 28,
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
