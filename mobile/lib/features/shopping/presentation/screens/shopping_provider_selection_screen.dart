import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mobile/features/shopping/domain/entities/shopping_provider.dart';
import 'package:mobile/features/shopping/presentation/providers/shopping_provider.dart';

class ShoppingProviderSelectionScreen extends ConsumerWidget {
  const ShoppingProviderSelectionScreen({
    super.key,
    required this.onProviderSelected,
  });

  final ValueChanged<ShoppingProvider> onProviderSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final providersState = ref.watch(shoppingProvidersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Choose Delivery Provider')),
      body: providersState.when(
        loading: () {
          return const Center(child: CircularProgressIndicator());
        },
        error: (error, stackTrace) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 56),
                  const SizedBox(height: 16),
                  const Text(
                    'Could not load delivery providers.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () {
                      ref.invalidate(shoppingProvidersProvider);
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        },
        data: (providers) {
          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: providers.length,
            separatorBuilder: (_, _) {
              return const SizedBox(height: 12);
            },
            itemBuilder: (context, index) {
              final provider = providers[index];

              return _ProviderCard(
                provider: provider,
                onTap: () {
                  onProviderSelected(provider);
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _ProviderCard extends StatelessWidget {
  const _ProviderCard({required this.provider, required this.onTap});

  final ShoppingProvider provider;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                Icons.local_shipping_outlined,
                color: theme.colorScheme.primary,
                size: 30,
              ),
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    provider.name,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Row(
                    children: [
                      Icon(
                        Icons.schedule_outlined,
                        size: 16,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        provider.deliveryTime,
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  Text(
                    provider.deliveryFee == 0
                        ? 'Free delivery'
                        : 'Delivery ₹${provider.deliveryFee.toStringAsFixed(0)}',
                    style: TextStyle(
                      color: provider.deliveryFee == 0
                          ? Colors.green.shade700
                          : Colors.grey.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}
