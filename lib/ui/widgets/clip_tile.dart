import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../models/clip_item.dart';
import '../../providers.dart';

class ClipTile extends ConsumerWidget {
  final ClipItem item;
  const ClipTile({super.key, required this.item});

  IconData _iconFor(ClipCategory c) {
    switch (c) {
      case ClipCategory.link:
        return HugeIcons.strokeRoundedLink04;
      case ClipCategory.email:
        return HugeIcons.strokeRoundedMail02;
      case ClipCategory.phone:
        return HugeIcons.strokeRoundedCall02;
      case ClipCategory.code:
        return HugeIcons.strokeRoundedSourceCode;
      case ClipCategory.note:
        return HugeIcons.strokeRoundedTextIndent;
    }
  }

  Color _categoryColor(ClipCategory c) {
    switch (c) {
      case ClipCategory.code:
        return const Color(0xFF7E57C2);
      case ClipCategory.link:
        return const Color(0xFF42A5F5);
      case ClipCategory.email:
        return const Color(0xFFFF7043);
      case ClipCategory.phone:
        return const Color(0xFF66BB6A);
      case ClipCategory.note:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final copy = ref.read(copyCommandProvider);
    final toggleFav = ref.read(toggleFavoriteCommandProvider);
    final del = ref.read(deleteClipCommandProvider);

    return ListTile(
      leading: Icon(
        _iconFor(item.category),
        color: _categoryColor(item.category),
      ),
      title: Text(
        item.content,
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(height: 1.25),
      ),
      trailing: Wrap(
        spacing: 4,
        children: [
          IconButton(
            tooltip: 'Copy',
            icon: const Icon(HugeIcons.strokeRoundedCopy01),
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
            icon: Icon(
              HugeIcons.strokeRoundedStar,
              color: item.isFavorite ? Colors.amberAccent : Colors.black38,
            ),
            onPressed: () => toggleFav(item.id),
          ),
          IconButton(
            tooltip: 'Delete',
            icon: const Icon(HugeIcons.strokeRoundedDelete02),
            onPressed: () => del(item.id),
          ),
        ],
      ),
    );
  }
}
