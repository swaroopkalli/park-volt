import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api.dart';
import '../core/theme.dart';
import 'motion.dart';

/// Renders loading / error / data states for an AsyncValue.
class AsyncView<T> extends StatelessWidget {
  const AsyncView({super.key, required this.value, required this.builder, this.onRetry, this.emptyText, this.isEmpty});
  final AsyncValue<T> value;
  final Widget Function(T data) builder;
  final VoidCallback? onRetry;
  final String? emptyText;
  final bool Function(T data)? isEmpty;

  @override
  Widget build(BuildContext context) {
    return value.when(
      skipLoadingOnRefresh: true,
      skipLoadingOnReload: true,
      loading: () => const SkeletonList(),
      error: (e, _) => ErrorBanner(error: e, onRetry: onRetry),
      data: (d) {
        if (isEmpty != null && isEmpty!(d)) {
          return Center(child: Padding(padding: const EdgeInsets.all(32), child: Text(emptyText ?? 'Nothing here yet', style: const TextStyle(color: AppColors.grey))));
        }
        return builder(d);
      },
    );
  }
}

class ErrorBanner extends StatelessWidget {
  const ErrorBanner({super.key, required this.error, this.onRetry});
  final Object error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final e = error is ApiError ? error as ApiError : ApiError.from(error);
    final down = e.isUnavailable;
    final color = down ? AppColors.orange : AppColors.red;
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), border: Border.all(color: color), borderRadius: BorderRadius.circular(10)),
      child: Row(children: [
        Icon(down ? Icons.cloud_off : Icons.error_outline, color: color),
        const SizedBox(width: 12),
        Expanded(child: Text(e.message, style: TextStyle(color: color.withValues(alpha: 1), fontWeight: FontWeight.w600))),
        if (onRetry != null) TextButton(onPressed: onRetry, child: const Text('Retry')),
      ]),
    );
  }
}

class StatusChip extends StatelessWidget {
  const StatusChip(this.status, {super.key});
  final String status;
  @override
  Widget build(BuildContext context) {
    final c = AppColors.forStatus(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: c.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
      child: Text(status, style: TextStyle(color: c, fontSize: 12, fontWeight: FontWeight.w700)),
    );
  }
}

class StatCard extends StatelessWidget {
  const StatCard({super.key, required this.label, required this.value, required this.icon, this.color = AppColors.blue});
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          CircleAvatar(backgroundColor: color.withValues(alpha: 0.12), child: Icon(icon, color: color)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (int.tryParse(value) != null)
                CountText(value: int.parse(value).toDouble(), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.navy))
              else
                Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.navy)),
              Text(label, style: const TextStyle(color: AppColors.grey)),
            ]),
          ),
        ]),
      ),
    );
  }
}

void showSnack(BuildContext context, String msg, {bool error = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(msg), backgroundColor: error ? AppColors.red : AppColors.navy, behavior: SnackBarBehavior.floating));
}

/// Runs [action], showing success or error snackbars. Returns true on success.
Future<bool> runAction(BuildContext context, Future<void> Function() action, {String? success}) async {
  try {
    await action();
    if (context.mounted && success != null) showSnack(context, success);
    return true;
  } catch (e) {
    if (context.mounted) showSnack(context, ApiError.from(e).message, error: true);
    return false;
  }
}
