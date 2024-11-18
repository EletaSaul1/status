import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/status_provider.dart';
import '../screens/status_viewer_screen.dart';
import 'status_item.dart';

class StatusGrid extends StatelessWidget {
  final String mediaType;

  const StatusGrid({
    super.key,
    required this.mediaType,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<StatusProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  provider.error!,
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => provider.loadStatuses(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final statuses = provider.statuses
            .where((status) => status.mediaType == mediaType)
            .toList();

        if (statuses.isEmpty) {
          return Center(
            child: Text(
              'No ${mediaType}s found',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(8),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            childAspectRatio: 1,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            crossAxisCount: 2,
          ),
          itemCount: statuses.length,
          itemBuilder: (context, index) {
            final status = statuses[index];
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => StatusViewerScreen(status: status),
                  ),
                );
              },
              child: StatusItem(status: status),
            );
          },
        );
      },
    );
  }
}
