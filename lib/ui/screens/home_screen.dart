import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../models/clip_item.dart';
import '../../providers.dart';
import '../widgets/clip_tile.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with TickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(appBootProvider); // ensures listener setup

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 12,
        bottom: TabBar(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          controller: _tab,
          overlayColor: WidgetStateColor.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return ColorScheme.fromSwatch().onSurface.withOpacity(0.1);
            }
            if (states.contains(WidgetState.hovered)) {
              return ColorScheme.fromSwatch().onSurface.withOpacity(0.05);
            }
            return Colors.transparent;
          }),
          dividerColor: Colors.transparent,
          indicatorColor: Colors.transparent,
          indicatorAnimation: TabIndicatorAnimation.elastic,
          indicator: BoxDecoration(
            color: ColorScheme.fromSwatch().primary.withOpacity(0.1),
            shape: BoxShape.rectangle,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),

          indicatorSize: TabBarIndicatorSize.tab,
          tabs: const [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(HugeIcons.strokeRoundedStopWatch, size: 20),
                  SizedBox(width: 8),
                  Text('History'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(HugeIcons.strokeRoundedStar, size: 20),
                  SizedBox(width: 8),
                  Text('Favorites'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(HugeIcons.strokeRoundedSetting07, size: 20),
                  SizedBox(width: 8),
                  Text('Settings'),
                ],
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: const [_HistoryTab(), _FavoritesTab(), _SettingsTab()],
      ),
      floatingActionButton: _QuickCopyFab(),
    );
  }
}

class _QuickCopyFab extends ConsumerWidget {
  const _QuickCopyFab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref
        .watch(clipsStreamProvider)
        .maybeWhen(data: (d) => d, orElse: () => const []);
    if (items.isEmpty) return const SizedBox.shrink();

    return FloatingActionButton.extended(
      onPressed: () async {
        final cmd = ref.read(copyCommandProvider);
        await cmd(items.first.content);
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Copied latest item')));
        }
      },
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
      icon: const Icon(HugeIcons.strokeRoundedCopy02),
      label: const Text('Copy latest'),
    );
  }
}

class _HistoryTab extends ConsumerWidget {
  const _HistoryTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.read(favoritesOnlyProvider.notifier).state = false;

    return Column(
      children: [
        _FilterBar(showFavoritesSwitch: false),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  ColorScheme.fromSwatch().primary.withOpacity(0.05),
                  ColorScheme.fromSwatch().primary.withOpacity(0.1),
                ],
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: Consumer(
              builder: (context, ref, _) {
                final list = ref.watch(filteredClipsProvider);
                return _ClipList(list: list);
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _FavoritesTab extends ConsumerWidget {
  const _FavoritesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.read(favoritesOnlyProvider.notifier).state = true;

    return Column(
      children: [
        _FilterBar(showFavoritesSwitch: false),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  ColorScheme.fromSwatch().primary.withOpacity(0.05),
                  ColorScheme.fromSwatch().primary.withOpacity(0.1),
                ],
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: Consumer(
              builder: (context, ref, _) {
                final list = ref.watch(filteredClipsProvider);
                return _ClipList(list: list);
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _ClipList extends StatelessWidget {
  final List<dynamic> list;
  const _ClipList({required this.list});

  @override
  Widget build(BuildContext context) {
    if (list.isEmpty) {
      return const Center(child: Text('No items yet. Copy something!'));
    }
    return ListView.builder(
      itemCount: list.length,
      itemBuilder: (context, i) => ClipTile(item: list[i]),
    );
  }
}

class _FilterBar extends ConsumerWidget {
  final bool showFavoritesSwitch;
  const _FilterBar({this.showFavoritesSwitch = true});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cat = ref.watch(categoryFilterProvider);
    final favOnly = ref.watch(favoritesOnlyProvider);
    final controller = TextEditingController(
      text: ref.read(searchQueryProvider),
    );

    Color categoryColor(ClipCategory c) {
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

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(HugeIcons.strokeRoundedSearch01),
                    hintText: 'Search...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    isDense: true,
                  ),
                  onChanged: (v) =>
                      ref.read(searchQueryProvider.notifier).state = v,
                ),
              ),
              const SizedBox(width: 8),
              if (showFavoritesSwitch)
                FilterChip(
                  label: const Text('Favorites'),
                  selected: favOnly,
                  onSelected: (v) =>
                      ref.read(favoritesOnlyProvider.notifier).state = v,
                  avatar: const Icon(Icons.star, size: 18),
                ),
            ],
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _CatChip(
                  label: 'All',
                  color: ColorScheme.of(context).inversePrimary,
                  selected: cat == null,
                  onTap: () {
                    ref.read(categoryFilterProvider.notifier).state = null;
                  },
                ),
                _CatChip(
                  label: 'Links',
                  icon: HugeIcons.strokeRoundedLink04,
                  color: categoryColor(ClipCategory.link),
                  selected: cat == ClipCategory.link,
                  onTap: () {
                    ref.read(categoryFilterProvider.notifier).state =
                        ClipCategory.link;
                  },
                ),
                _CatChip(
                  label: 'Emails',
                  icon: HugeIcons.strokeRoundedMail02,
                  color: categoryColor(ClipCategory.email),
                  selected: cat == ClipCategory.email,
                  onTap: () {
                    ref.read(categoryFilterProvider.notifier).state =
                        ClipCategory.email;
                  },
                ),
                _CatChip(
                  label: 'Phones',
                  icon: HugeIcons.strokeRoundedCall02,
                  color: categoryColor(ClipCategory.phone),
                  selected: cat == ClipCategory.phone,
                  onTap: () {
                    ref.read(categoryFilterProvider.notifier).state =
                        ClipCategory.phone;
                  },
                ),
                _CatChip(
                  label: 'Code',
                  icon: HugeIcons.strokeRoundedSourceCode,
                  color: categoryColor(ClipCategory.code),
                  selected: cat == ClipCategory.code,
                  onTap: () {
                    ref.read(categoryFilterProvider.notifier).state =
                        ClipCategory.code;
                  },
                ),
                _CatChip(
                  label: 'Notes',
                  icon: HugeIcons.strokeRoundedTextIndent,
                  color: categoryColor(ClipCategory.note),
                  selected: cat == ClipCategory.note,
                  onTap: () {
                    ref.read(categoryFilterProvider.notifier).state =
                        ClipCategory.note;
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CatChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;
  final Color color;
  const _CatChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        showCheckmark: false,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        shadowColor: color.withOpacity(0.4),
        color: WidgetStateColor.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return color.withOpacity(0.2);
          }
          if (states.contains(WidgetState.hovered)) {
            return color.withOpacity(0.1);
          }
          return Colors.transparent;
        }),
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) Icon(icon, size: 16, color: color),
            if (icon != null) const SizedBox(width: 4),
            Text(label, style: TextStyle(color: color)),
          ],
        ),
        selected: selected,
        onSelected: (_) => onTap(),
      ),
    );
  }
}

class _SettingsTab extends ConsumerWidget {
  const _SettingsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final limitAsync = ref.watch(historyLimitProvider);

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Row(
          children: [
            const Icon(HugeIcons.strokeRoundedClipboard),
            const SizedBox(width: 8),
            const Text('Clipboard'),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: ColorScheme.fromSwatch().secondary.withOpacity(0.05),
            borderRadius: const BorderRadius.all(Radius.circular(24)),
          ),
          child: Column(
            children: [
              _ListenerTile(),
              Divider(height: 0),
              limitAsync.when(
                data: (limit) => _HistoryLimitTile(current: limit),
                loading: () => const ListTile(title: Text('Loading...')),
                error: (_, __) => const ListTile(title: Text('Error')),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            const Icon(HugeIcons.strokeRoundedDanger),
            const SizedBox(width: 8),
            const Text('Danger Zone'),
          ],
        ),
        const SizedBox(height: 8),
        _DangerZone(),
      ],
    );
  }
}

class _ListenerTile extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsRepo = ref.read(settingsRepoProvider);
    return FutureBuilder<bool>(
      future: settingsRepo.isListenerEnabled(),
      builder: (context, snapshot) {
        final enabled = snapshot.data ?? true;
        return SwitchListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          title: const Text('Clipboard Capture'),
          subtitle: const Text('Automatically capture changes'),
          value: enabled,
          onChanged: (v) async {
            await ref.read(listenerToggleProvider(v).future);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(v ? 'Listener enabled' : 'Listener disabled'),
                ),
              );
            }
          },
        );
      },
    );
  }
}

class _HistoryLimitTile extends ConsumerStatefulWidget {
  final int current;
  const _HistoryLimitTile({required this.current});

  @override
  ConsumerState<_HistoryLimitTile> createState() => _HistoryLimitTileState();
}

class _HistoryLimitTileState extends ConsumerState<_HistoryLimitTile> {
  late double _value;

  @override
  void initState() {
    super.initState();
    _value = widget.current.toDouble();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: DefaultTextStyle(
            style: TextStyle(
              fontSize: 16,
              // fontWeight: FontWeight.bold,
              color: ColorScheme.fromSwatch().onSurface,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('History size (non-favorites)'),
                Text(_value.toInt().toString()),
              ],
            ),
          ),
        ),
        Slider(
          min: 20,
          max: 1000,
          divisions: 49,
          value: _value,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          label: _value.toInt().toString(),
          onChanged: (v) => setState(() => _value = v),
          onChangeEnd: (v) async {
            await ref.read(setHistoryLimitProvider(v.toInt()).future);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('History limit set to ${v.toInt()}')),
              );
            }
          },
        ),
      ],
    );
  }
}

class _DangerZone extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clearNonFavs = ref.read(clearNonFavsCommandProvider);
    final clearAll = ref.read(clearAllCommandProvider);
    return Container(
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.05),
        borderRadius: const BorderRadius.all(Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: FilledButton.tonalIcon(
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                backgroundColor: Theme.of(
                  context,
                ).colorScheme.primary.withOpacity(0.2),
              ),
              onPressed: () async {
                final ok = await _confirm(
                  context,
                  'Delete all non-favorite items?',
                );
                if (ok) {
                  await clearNonFavs();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Cleared non-favorites')),
                    );
                  }
                }
              },
              icon: const Icon(HugeIcons.strokeRoundedClean),
              label: const Text('Clear non-favorites'),
            ),
          ),
          const SizedBox(height: 8),
          Divider(height: 0),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                backgroundColor: Theme.of(
                  context,
                ).colorScheme.error.withOpacity(0.8),
              ),
              onPressed: () async {
                final ok = await _confirm(
                  context,
                  'Delete ALL items (including favorites)?',
                );
                if (ok) {
                  await clearAll();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('All items cleared')),
                    );
                  }
                }
              },
              icon: const Icon(HugeIcons.strokeRoundedDeleteThrow),
              label: const Text('Clear ALL'),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Future<bool> _confirm(BuildContext context, String msg) async {
    final res = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirm'),
        content: Text(msg),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    return res ?? false;
  }
}
