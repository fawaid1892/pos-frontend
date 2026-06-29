import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/sync_provider.dart';
import '../services/electric_service.dart';
import '../utils/responsive.dart';

/// Sync status icon with badge showing connection state.
/// Placed in the AppBar to show sync state at a glance.
class SyncStatusIcon extends StatelessWidget {
  const SyncStatusIcon({super.key});

  @override
  Widget build(BuildContext context) {
    final syncProvider = context.watch<SyncProvider>();
    final isConnected = syncProvider.isConnected;
    final isSyncing = syncProvider.isSyncing;

    Widget icon;

    if (isSyncing) {
      icon = const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    } else if (!isConnected) {
      icon = const Icon(Icons.cloud_off, color: Colors.orange);
    } else {
      icon = const Icon(Icons.cloud_done, color: Colors.green);
    }

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: icon,
    );
  }
}

/// Sync status card widget showing detailed Electric sync information.
class SyncStatusCard extends StatelessWidget {
  const SyncStatusCard({super.key});

  @override
  Widget build(BuildContext context) {
    final syncProvider = context.watch<SyncProvider>();
    final isConnected = syncProvider.isConnected;
    final isSyncing = syncProvider.isSyncing;
    final shapeCount = syncProvider.shapeCount;
    final lastError = syncProvider.lastError;

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  isConnected ? Icons.wifi : Icons.wifi_off,
                  color: isConnected ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(
                  isConnected ? 'Connected' : 'Disconnected',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isConnected ? Colors.green : Colors.red,
                  ),
                ),
                const Spacer(),
                if (isSyncing)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            Divider(color: colorScheme.outlineVariant),
            _buildRow('Electric Sync', isConnected ? 'Active' : 'Offline', colorScheme),
            _buildRow('Shapes subscribed', '$shapeCount', colorScheme),
            if (lastError != null) ...[
              const SizedBox(height: 4),
              Text(
                lastError,
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.error,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(color: colorScheme.onSurfaceVariant)),
          Text(value,
              style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

/// Full sync status screen showing Electric service state.
class SyncStatusScreen extends StatefulWidget {
  const SyncStatusScreen({super.key});

  @override
  State<SyncStatusScreen> createState() => _SyncStatusScreenState();
}

class _SyncStatusScreenState extends State<SyncStatusScreen> {
  @override
  Widget build(BuildContext context) {
    final syncProvider = context.watch<SyncProvider>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sync Status'),
      ),
      body: ListView(
        children: [
          const SyncStatusCard(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              'ElectricSQL handles synchronization automatically via shape subscriptions.',
              style: TextStyle(
                fontSize: 13,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text(
                      'Subscribed Shapes',
                      style: theme.textTheme.titleSmall,
                    ),
                  ),
                  ...ElectricService.shapes.map((shape) => ListTile(
                    dense: true,
                    leading: Icon(
                      Icons.table_chart_outlined,
                      size: 20,
                      color: syncProvider.isConnected
                          ? Colors.green
                          : Colors.grey,
                    ),
                    title: Text(shape),
                    subtitle: Text('Electric shape'),
                  )),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'ElectricSQL handles: offline-first sync, conflict resolution, '
                'and incremental data sync automatically.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
