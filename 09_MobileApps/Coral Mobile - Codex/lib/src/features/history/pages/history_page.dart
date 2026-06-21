import 'dart:io';

import 'package:flutter/material.dart';

import '../../../core/app_routes.dart';
import '../../../core/app_theme.dart';
import '../../../shared/bottom_nav.dart';
import '../../../shared/coral_visuals.dart';
import '../../../shared/glass_card.dart';
import '../../../shared/modern_scroll_indicator.dart';
import '../../../shared/tab_page_scaffold.dart';
import '../data/history_repository.dart';
import '../models/history_record.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  String _selectedFilter = 'All';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  late Future<List<HistoryRecord>> _recordsFuture;

  bool _isSelectionMode = false;
  final Set<String> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  void _loadRecords() {
    setState(() {
      _recordsFuture = HistoryRepository().getAllRecords();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _clearAllFilters() {
    setState(() {
      _selectedFilter = 'All';
      _searchQuery = '';
      _searchController.clear();
    });
  }

  Widget _buildFloatingSelectionBar(List<HistoryRecord> filteredItems) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final allSelected = filteredItems.isNotEmpty && _selectedIds.length == filteredItems.length;

    return Material(
      type: MaterialType.transparency,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF0E1A33).withValues(alpha: 0.96)
            : Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? const Color(0xFF1E2F4D).withValues(alpha: 0.8)
              : AppColors.line.withValues(alpha: 0.8),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.35)
                : const Color(0x182362A7),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.close_rounded, color: AppColors.muted),
                onPressed: () {
                  setState(() {
                    _isSelectionMode = false;
                    _selectedIds.clear();
                  });
                },
                tooltip: 'Cancel',
              ),
              const SizedBox(width: 4),
              Text(
                'Selected: ${_selectedIds.length}',
                style: TextStyle(
                  color: isDark ? const Color(0xFFF1F5F9) : AppColors.ink,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          Row(
            children: [
              TextButton(
                onPressed: () {
                  setState(() {
                    if (allSelected) {
                      _selectedIds.clear();
                    } else {
                      _selectedIds.addAll(filteredItems.map((item) => item.id));
                    }
                  });
                },
                child: Text(
                  allSelected ? 'Deselect All' : 'Select All',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (_selectedIds.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: AppColors.dead),
                  onPressed: () => _confirmDeleteSelected(filteredItems),
                  tooltip: 'Delete Selected',
                ),
            ],
          ),
        ],
      ),
    ));
  }

  void _confirmDeleteSelected(List<HistoryRecord> filteredItems) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Delete ${_selectedIds.length} item(s)?'),
          content: const Text('Are you sure you want to permanently delete the selected coral assessment logs? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await _deleteSelectedRecords(filteredItems);
              },
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteSelectedRecords(List<HistoryRecord> filteredItems) async {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );

    try {
      final repo = HistoryRepository();
      final toDelete = filteredItems.where((item) => _selectedIds.contains(item.id)).toList();
      for (final record in toDelete) {
        await repo.deleteRecord(record);
      }
    } catch (e) {
      debugPrint('Error deleting selected records: $e');
    }

    if (mounted) {
      Navigator.pop(context);
    }

    setState(() {
      _isSelectionMode = false;
      _selectedIds.clear();
      _loadRecords();
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selected assessments deleted successfully.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<HistoryRecord>>(
      future: _recordsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const TabPageScaffold(
            activeTab: MainTab.history,
            children: [
              Center(
                  child: CircularProgressIndicator(color: AppColors.primary)),
            ],
          );
        }

        final allRecords = snapshot.data ?? const <HistoryRecord>[];
        final latestRecord = allRecords.isNotEmpty ? allRecords.first : null;
        final highConfidenceCount =
            allRecords.where((item) => item.confidencePercent >= 90).length;

        final filteredItems = allRecords.where((item) {
          final matchesFilter =
              _selectedFilter == 'All' || item.label == _selectedFilter;
          final searchBlob = [
            item.id,
            item.label,
            item.model,
            item.date,
            item.notes,
          ].join(' ').toLowerCase();
          final matchesSearch = _searchQuery.isEmpty ||
              searchBlob.contains(_searchQuery.toLowerCase());
          return matchesFilter && matchesSearch;
        }).toList();

        return Stack(
          children: [
            TabPageScaffold(
              activeTab: MainTab.history,
              showTopBar: true,
              children: [
                _HistoryOverview(
                  totalRecords: allRecords.length,
                  filteredRecords: filteredItems.length,
                  latestRecord: latestRecord,
                  highConfidenceCount: highConfidenceCount,
                ),
                const SizedBox(height: 16),
                if (allRecords.isNotEmpty) ...[
                  _SearchBox(
                    controller: _searchController,
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val;
                      });
                    },
                    onClear: () {
                      setState(() {
                        _searchQuery = '';
                        _searchController.clear();
                      });
                    },
                  ),
                  const SizedBox(height: 14),
                  _FilterRow(
                    selectedFilter: _selectedFilter,
                    onChanged: (value) => setState(() => _selectedFilter = value),
                    showChecklistButton: true,
                    isSelectionMode: _isSelectionMode,
                    onToggleSelectionMode: () {
                      setState(() {
                        _isSelectionMode = !_isSelectionMode;
                        _selectedIds.clear();
                      });
                    },
                  ),
                  const SizedBox(height: 18),
                ],
                if (filteredItems.isEmpty)
                  _EmptyState(
                    query: _searchQuery.isNotEmpty ? _searchQuery : _selectedFilter,
                    onClear: _clearAllFilters,
                    isGlobalEmpty: allRecords.isEmpty,
                  )
                else
                  _HistoryList(
                    items: filteredItems,
                    onReload: _loadRecords,
                    isSelectionMode: _isSelectionMode,
                    selectedIds: _selectedIds,
                    onToggleSelection: (id) {
                      setState(() {
                        if (_selectedIds.contains(id)) {
                          _selectedIds.remove(id);
                        } else {
                          _selectedIds.add(id);
                        }
                      });
                    },
                    onLongPress: (id) {
                      setState(() {
                        _isSelectionMode = true;
                        _selectedIds.add(id);
                      });
                    },
                  ),
              ],
            ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOutCubic,
              left: 20,
              right: 20,
              bottom: _isSelectionMode ? 116 : -100,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 250),
                opacity: _isSelectionMode ? 1.0 : 0.0,
                child: _buildFloatingSelectionBar(filteredItems),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _HistoryOverview extends StatelessWidget {
  const _HistoryOverview({
    required this.totalRecords,
    required this.filteredRecords,
    required this.latestRecord,
    required this.highConfidenceCount,
  });

  final int totalRecords;
  final int filteredRecords;
  final HistoryRecord? latestRecord;
  final int highConfidenceCount;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GlassCard(
      padding: const EdgeInsets.all(20),
      borderRadius: 30,
      backgroundColor:
          isDark ? const Color(0xFF08162E) : const Color(0xFFF6FBFF),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Assessment History',
            style: TextStyle(
              color: AppColors.ink,
              fontSize: 28,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.8,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'A clear archive of scans, confidence, and visual evidence.',
            style: TextStyle(
              color: isDark ? const Color(0xFFB7C4DD) : AppColors.muted,
              fontSize: 15,
              fontWeight: FontWeight.w600,
              height: 1.45,
            ),
          ),
          if (filteredRecords != totalRecords) ...[
            const SizedBox(height: 10),
            Text(
              '$filteredRecords result${filteredRecords == 1 ? '' : 's'} shown',
              style: TextStyle(
                color: isDark ? const Color(0xFF9FB0CF) : AppColors.muted,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}



class _SearchBox extends StatelessWidget {
  const _SearchBox({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark 
            ? const Color(0xFF0F1A2E).withValues(alpha: 0.6) 
            : const Color(0xFFF1F5F9).withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark 
              ? const Color(0xFF1E2F4D).withValues(alpha: 0.5) 
              : AppColors.line.withValues(alpha: 0.5),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Icon(
            Icons.search_rounded,
            color: isDark ? const Color(0xFF8E9DBE) : AppColors.muted,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              textInputAction: TextInputAction.search,
              style: TextStyle(
                color: isDark ? const Color(0xFFF1F5F9) : AppColors.ink,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                hintText: 'Search by label, model, ID...',
                hintStyle: TextStyle(
                  color: isDark
                      ? const Color(0xFF8E9DBE).withValues(alpha: 0.6)
                      : AppColors.muted.withValues(alpha: 0.6),
                  fontSize: 14.5,
                  fontWeight: FontWeight.w500,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          if (controller.text.isNotEmpty)
            IconButton(
              icon: const Icon(
                Icons.close_rounded,
                color: AppColors.muted,
                size: 18,
              ),
              onPressed: onClear,
              splashRadius: 18,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              tooltip: 'Clear search',
            ),
        ],
      ),
    );
  }
}

class _FilterRow extends StatefulWidget {
  const _FilterRow({
    required this.selectedFilter,
    required this.onChanged,
    required this.showChecklistButton,
    required this.isSelectionMode,
    required this.onToggleSelectionMode,
  });

  final String selectedFilter;
  final ValueChanged<String> onChanged;
  final bool showChecklistButton;
  final bool isSelectionMode;
  final VoidCallback onToggleSelectionMode;

  @override
  State<_FilterRow> createState() => _FilterRowState();
}

class _FilterRowState extends State<_FilterRow> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  double get _scrollProgress {
    if (!_scrollController.hasClients) return 0.0;
    final maxScroll = _scrollController.position.maxScrollExtent;
    if (maxScroll <= 0) return 0.0;
    return (_scrollController.offset / maxScroll).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scrollController,
      builder: (context, child) {
        final progress = _scrollProgress;
        final double leftFadeStop = (progress * 0.1).clamp(0.0, 0.1);
        final double rightFadeStop =
            1.0 - ((1.0 - progress) * 0.1).clamp(0.0, 0.1);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ShaderMask(
              shaderCallback: (Rect bounds) {
                return LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: const [
                    Colors.transparent,
                    Colors.white,
                    Colors.white,
                    Colors.transparent,
                  ],
                  stops: [0.0, leftFadeStop, rightFadeStop, 1.0],
                ).createShader(bounds);
              },
              blendMode: BlendMode.dstIn,
              child: SingleChildScrollView(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                child: Row(
                  children: [
                    _FilterChip(
                      icon: Icons.grid_view_rounded,
                      label: 'All',
                      active: widget.selectedFilter == 'All',
                      color: AppColors.primary,
                      onTap: () => widget.onChanged('All'),
                    ),
                    const SizedBox(width: 12),
                    _FilterChip(
                      imageAsset: 'assets/images/health.png',
                      label: 'Healthy',
                      active: widget.selectedFilter == 'Healthy',
                      color: AppColors.healthy,
                      onTap: () => widget.onChanged('Healthy'),
                    ),
                    const SizedBox(width: 12),
                    _FilterChip(
                      imageAsset: 'assets/images/bleach.png',
                      label: 'Bleached',
                      active: widget.selectedFilter == 'Bleached',
                      color: AppColors.bleached,
                      onTap: () => widget.onChanged('Bleached'),
                    ),
                    const SizedBox(width: 12),
                    _FilterChip(
                      imageAsset: 'assets/images/dead.png',
                      label: 'Dead',
                      active: widget.selectedFilter == 'Dead',
                      color: AppColors.dead,
                      onTap: () => widget.onChanged('Dead'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            ModernScrollIndicator(
              controller: _scrollController,
              trackWidth: 40.0,
              pillWidth: 14.0,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'RECENT SCANS',
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF8E9DBE)
                        : AppColors.muted,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
                if (widget.showChecklistButton)
                  _HistoryRoundIconButton(
                    icon: widget.isSelectionMode
                        ? Icons.close_rounded
                        : Icons.checklist_rounded,
                    onPressed: widget.onToggleSelectionMode,
                  ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _HistoryRoundIconButton extends StatelessWidget {
  const _HistoryRoundIconButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      width: 46,
      height: 46,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0E1A33) : Colors.white,
          shape: BoxShape.circle,
          border: Border.all(
            color: isDark ? const Color(0xFF1E2F4D) : AppColors.line,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.15)
                  : const Color(0x142362A7),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: IconButton(
          padding: EdgeInsets.zero,
          icon: Icon(
            icon,
            color: onPressed == null
                ? AppColors.muted
                : (isDark ? const Color(0xFFF1F5F9) : AppColors.ink),
          ),
          onPressed: onPressed,
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    this.icon,
    this.imageAsset,
    required this.label,
    required this.color,
    required this.onTap,
    this.active = false,
  });

  final IconData? icon;
  final String? imageAsset;
  final String label;
  final Color color;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
        decoration: BoxDecoration(
          color: active
              ? null
              : (isDark
                  ? const Color(0xFF0E1A33).withValues(alpha: 0.9)
                  : Colors.white.withValues(alpha: 0.9)),
          gradient: active
              ? LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF0F2E57), const Color(0xFF08111F)]
                      : [Colors.white, const Color(0xFFF1F8FF)],
                )
              : null,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: active
                ? color
                : (isDark ? const Color(0xFF1E2F4D) : AppColors.line),
            width: active ? 2 : 1,
          ),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: isDark
                        ? Colors.black.withValues(alpha: 0.15)
                        : const Color(0x220057E6),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            if (imageAsset != null)
              Image.asset(imageAsset!, width: 22, height: 22, fit: BoxFit.contain)
            else if (icon != null)
              Icon(icon, color: color, size: 22),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: active
                    ? color
                    : (isDark ? const Color(0xFFF1F5F9) : AppColors.ink),
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryList extends StatelessWidget {
  const _HistoryList({
    required this.items,
    required this.onReload,
    required this.isSelectionMode,
    required this.selectedIds,
    required this.onToggleSelection,
    required this.onLongPress,
  });

  final List<HistoryRecord> items;
  final VoidCallback onReload;
  final bool isSelectionMode;
  final Set<String> selectedIds;
  final ValueChanged<String> onToggleSelection;
  final ValueChanged<String> onLongPress;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final item in items) ...[
          _HistoryCard(
            item: item,
            isSelectionMode: isSelectionMode,
            isSelected: selectedIds.contains(item.id),
            onLongPress: () => onLongPress(item.id),
            onTap: () async {
              if (isSelectionMode) {
                onToggleSelection(item.id);
              } else {
                await Navigator.of(context).pushNamed(
                  AppRoutes.historyDetail,
                  arguments: item,
                );
                onReload();
              }
            },
          ),
          const SizedBox(height: 14),
        ],
      ],
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({
    required this.item,
    required this.onTap,
    required this.isSelectionMode,
    required this.isSelected,
    required this.onLongPress,
  });

  final HistoryRecord item;
  final VoidCallback onTap;
  final bool isSelectionMode;
  final bool isSelected;
  final VoidCallback onLongPress;

  Widget _buildCheckbox(bool isSelected, Color activeColor) {
    return Container(
      width: 22,
      height: 22,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isSelected ? activeColor : Colors.transparent,
        border: Border.all(
          color: isSelected ? activeColor : AppColors.muted.withValues(alpha: 0.5),
          width: 2,
        ),
      ),
      child: isSelected
          ? const Icon(
              Icons.check_rounded,
              color: Colors.white,
              size: 13,
            )
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F1A2E).withValues(alpha: 0.5) : Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isDark 
                ? const Color(0xFF1E2F4D).withValues(alpha: 0.6) 
                : AppColors.line.withValues(alpha: 0.5),
          ),
          boxShadow: [
            BoxShadow(
              color: item.color.withValues(alpha: isDark ? 0.04 : 0.03),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (isSelectionMode)
              _buildCheckbox(isSelected, item.color),
            Container(
              padding: const EdgeInsets.all(2.5),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: item.color.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: ClipOval(
                child: item.imagePath != null
                    ? Image.file(
                        File(item.imagePath!),
                        width: 62,
                        height: 62,
                        fit: BoxFit.cover,
                      )
                    : CoralThumbnail(
                        size: 62,
                        variant: item.variant,
                        showNetwork: true,
                      ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: item.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        item.label.toUpperCase(),
                        style: TextStyle(
                          color: item.color,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${item.label} Coral Scan',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: isDark ? const Color(0xFFF1F5F9) : AppColors.ink,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: item.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    item.score,
                    style: TextStyle(
                      color: item.color,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: isDark ? const Color(0xFF8E9DBE) : AppColors.muted,
                  size: 13,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}



class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.query,
    required this.onClear,
    this.isGlobalEmpty = false,
  });

  final String query;
  final VoidCallback onClear;
  final bool isGlobalEmpty;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      width: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.muted.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isGlobalEmpty ? Icons.inbox_rounded : Icons.search_off_rounded,
              size: 48,
              color: AppColors.muted,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            isGlobalEmpty ? 'No recent scans' : 'No results found',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: isDark ? const Color(0xFFF1F5F9) : AppColors.ink,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            isGlobalEmpty
                ? 'You haven\'t run any coral assessments yet.\nTap below to start your first scan.'
                : 'We couldn\'t find any assessments matching "$query".\nTry searching for "Healthy", "Bleached", or "Dead".',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.muted,
                  height: 1.5,
                ),
          ),
          const SizedBox(height: 24),
          if (isGlobalEmpty)
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pushNamed(AppRoutes.upload);
              },
              icon: const Icon(Icons.add_a_photo_rounded, size: 18),
              label: const Text('Run Assessment'),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? AppColors.cyan : AppColors.primary,
                foregroundColor: isDark ? const Color(0xFF040D21) : Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
            )
          else
            ElevatedButton.icon(
              onPressed: onClear,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Clear Search & Filters'),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? AppColors.cyan : AppColors.primary,
                foregroundColor: isDark ? const Color(0xFF040D21) : Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
            ),
        ],
      ),
    );
  }
}
