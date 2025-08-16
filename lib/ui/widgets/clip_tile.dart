import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/clip_item.dart';
import '../../providers.dart';

class ClipTile extends ConsumerWidget {
  final ClipItem item;
  const ClipTile({super.key, required this.item});

  IconData _iconFor(ClipCategory c) {
    switch (c) {
      case ClipCategory.link:
        return Icons.link;
      case ClipCategory.email:
        return Icons.email;
      case ClipCategory.phone:
        return Icons.call;
      case ClipCategory.code:
        return Icons.code;
      case ClipCategory.note:
        return Icons.notes;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final copy = ref.read(copyCommandProvider);
    final toggleFav = ref.read(toggleFavoriteCommandProvider);
    final del = ref.read(deleteClipCommandProvider);

    return ListTile(
      leading: CircleAvatar(child: Icon(_iconFor(item.category))),
      title: Text(
        item.content,
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(height: 1.25),
      ),
      subtitle: Text(
        item.category.name.toUpperCase(),
        style: TextStyle(color: Theme.of(context).colorScheme.primary),
      ),
      trailing: Wrap(
        spacing: 4,
        children: [
          IconButton(
            tooltip: 'Copy',
            icon: const Icon(Icons.copy),
            onPressed: () async {
              await copy(item.content);
              if (context.mounted) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Copied')));
              }
            },
          ),
          IconButton(
            tooltip: item.isFavorite ? 'Unfavorite' : 'Favorite',
            icon: Icon(item.isFavorite ? Icons.star : Icons.star_border),
            onPressed: () => toggleFav(item.id),
          ),
          IconButton(
            tooltip: 'Delete',
            icon: const Icon(Icons.delete_outline),
            onPressed: () => del(item.id),
          ),
        ],
      ),
    );
  }
}
