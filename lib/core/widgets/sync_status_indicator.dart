import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/sync_provider.dart';

/// A compact indicator widget showing sync and connectivity status.
/// Can be placed in the AppBar or any header area.
class SyncStatusIndicator extends ConsumerWidget {
  const SyncStatusIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncState = ref.watch(syncProvider);

    return GestureDetector(
      onTap: () => _onTap(context, ref, syncState),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: _backgroundColor(syncState).withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _backgroundColor(syncState).withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildIcon(syncState),
            const SizedBox(width: 4),
            Text(
              _statusText(syncState),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: _backgroundColor(syncState),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIcon(SyncState state) {
    if (state.isSyncing) {
      return SizedBox(
        width: 12,
        height: 12,
        child: CircularProgressIndicator(
          strokeWidth: 1.5,
          color: _backgroundColor(state),
        ),
      );
    }

    return Icon(_icon(state), size: 12, color: _backgroundColor(state));
  }

  IconData _icon(SyncState state) {
    if (!state.isOnline) return Icons.cloud_off_rounded;
    if (state.hasError) return Icons.sync_problem_rounded;
    return Icons.cloud_done_rounded;
  }

  Color _backgroundColor(SyncState state) {
    if (!state.isOnline) return Colors.orange;
    if (state.hasError) return Colors.red;
    if (state.isSyncing) return Colors.blue;
    return Colors.green;
  }

  String _statusText(SyncState state) {
    if (!state.isOnline) return 'Offline';
    if (state.isSyncing) return 'Syncing...';
    if (state.hasError) return 'Sync Error';
    return 'Synced';
  }

  void _onTap(BuildContext context, WidgetRef ref, SyncState state) {
    if (state.isOnline && !state.isSyncing) {
      ref.read(syncProvider.notifier).syncNow();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Syncing...'),
          duration: Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else if (!state.isOnline) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You are offline. Changes will sync when connected.'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
