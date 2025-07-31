import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import '../managers/app_filter_manager.dart';

class ApplyChangesProgressView extends StatefulWidget {
  final AppFilterManager filterManager;
  final ValueChanged<bool> isPresented;

  const ApplyChangesProgressView({
    super.key,
    required this.filterManager,
    required this.isPresented,
  });

  @override
  State<ApplyChangesProgressView> createState() => _ApplyChangesProgressViewState();
}

class _ApplyChangesProgressViewState extends State<ApplyChangesProgressView> {
  double _progress = 0.0;
  String _currentPhase = '';
  String _currentFilterName = '';
  bool _isComplete = false;
  
  // Phase tracking
  bool _isReadingFiles = false;
  bool _isConvertingRules = false;
  bool _isSavingAndBuilding = false;
  bool _isReloadingExtensions = false;
  
  int _processedFilters = 0;
  int _totalFilters = 0;

  @override
  void initState() {
    super.initState();
    _startConversion();
  }

  Future<void> _startConversion() async {
    // Get selected filters count
    _totalFilters = widget.filterManager.filterLists
        .where((filter) => filter.isSelected)
        .length;
    
    if (_totalFilters == 0) {
      setState(() {
        _isComplete = true;
      });
      return;
    }

    // Simulate the conversion process
    // Phase 1: Reading Files (0-25%)
    setState(() {
      _isReadingFiles = true;
      _currentPhase = 'Reading filter files...';
    });
    
    for (int i = 0; i < _totalFilters; i++) {
      setState(() {
        _processedFilters = i + 1;
        _progress = (i + 1) / _totalFilters * 0.25;
      });
      await Future.delayed(const Duration(milliseconds: 100));
    }

    // Phase 2: Converting Rules (25-70%)
    setState(() {
      _isReadingFiles = false;
      _isConvertingRules = true;
      _currentPhase = 'Converting rules...';
    });
    
    final selectedFilters = widget.filterManager.filterLists
        .where((filter) => filter.isSelected)
        .toList();
    
    for (int i = 0; i < selectedFilters.length; i++) {
      setState(() {
        _currentFilterName = selectedFilters[i].name;
        _progress = 0.25 + (i + 1) / selectedFilters.length * 0.45;
      });
      await Future.delayed(const Duration(milliseconds: 200));
    }

    // Phase 3: Saving & Building (70-90%)
    setState(() {
      _isConvertingRules = false;
      _isSavingAndBuilding = true;
      _currentPhase = 'Saving and building engines...';
      _currentFilterName = '';
    });
    
    for (int i = 0; i < 5; i++) {
      setState(() {
        _progress = 0.70 + (i + 1) / 5 * 0.20;
      });
      await Future.delayed(const Duration(milliseconds: 150));
    }

    // Phase 4: Reloading Extensions (90-100%)
    setState(() {
      _isSavingAndBuilding = false;
      _isReloadingExtensions = true;
      _currentPhase = 'Reloading Safari extensions...';
    });
    
    for (int i = 0; i < selectedFilters.length; i++) {
      setState(() {
        _currentFilterName = selectedFilters[i].name;
        _progress = 0.90 + (i + 1) / selectedFilters.length * 0.10;
      });
      await Future.delayed(const Duration(milliseconds: 100));
    }

    // Complete
    setState(() {
      _progress = 1.0;
      _isComplete = true;
      _isReloadingExtensions = false;
      _currentPhase = 'Filter lists applied successfully!';
      _currentFilterName = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    if (Platform.isIOS) {
      return _buildIOSView(context);
    } else {
      return _buildMacOSView(context);
    }
  }

  Widget _buildIOSView(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground.resolveFrom(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          if (!_isComplete || widget.filterManager.lastRuleCount > 0)
            _buildHeader(context),
          Expanded(
            child: _isComplete ? _buildStatistics(context) : _buildProgress(context),
          ),
        ],
      ),
    );
  }

  Widget _buildMacOSView(BuildContext context) {
    return Dialog(
      child: Container(
        width: 450,
        height: 400,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            if (!_isComplete || widget.filterManager.lastRuleCount > 0)
              _buildHeader(context),
            const SizedBox(height: 20),
            Expanded(
              child: _isComplete ? _buildStatistics(context) : _buildProgress(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              const Spacer(),
              Text(
                _isComplete ? 'Filter Lists Applied' : 'Converting Filter Lists',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (_isComplete)
                IconButton(
                  icon: Icon(
                    Platform.isIOS
                        ? CupertinoIcons.xmark_circle_fill
                        : Icons.close,
                    color: Colors.grey,
                  ),
                  onPressed: () => widget.isPresented(false),
                ),
            ],
          ),
          if (!_isComplete && _currentPhase.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              _currentPhase,
              style: TextStyle(
                fontSize: 14,
                color: Platform.isIOS
                    ? CupertinoColors.secondaryLabel.resolveFrom(context)
                    : Theme.of(context).textTheme.bodySmall?.color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          if (!_isComplete) ...[
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: _progress,
              minHeight: 6,
            ),
            const SizedBox(height: 8),
            Text(
              '${(_progress * 100).toInt()}%',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProgress(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildPhaseRow(
          context: context,
          icon: CupertinoIcons.folder_badge_plus,
          title: 'Reading Files',
          detail: _isReadingFiles && _totalFilters > 0
              ? '$_processedFilters/$_totalFilters extensions'
              : null,
          isActive: _isReadingFiles,
          isCompleted: _progress > 0.25,
        ),
        const Divider(indent: 32),
        _buildPhaseRow(
          context: context,
          icon: CupertinoIcons.gear_alt_fill,
          title: 'Converting Rules',
          detail: _isConvertingRules && _currentFilterName.isNotEmpty
              ? 'Processing $_currentFilterName'
              : null,
          isActive: _isConvertingRules,
          isCompleted: _progress > 0.70,
        ),
        const Divider(indent: 32),
        _buildPhaseRow(
          context: context,
          icon: CupertinoIcons.square_arrow_down,
          title: 'Saving & Building',
          detail: _isSavingAndBuilding
              ? 'Writing files and building engines'
              : null,
          isActive: _isSavingAndBuilding,
          isCompleted: _progress > 0.90,
        ),
        const Divider(indent: 32),
        _buildPhaseRow(
          context: context,
          icon: CupertinoIcons.arrow_clockwise,
          title: 'Reloading Extensions',
          detail: _isReloadingExtensions && _currentFilterName.isNotEmpty
              ? 'Reloading $_currentFilterName'
              : null,
          isActive: _isReloadingExtensions,
          isCompleted: _progress >= 1.0,
        ),
      ],
    );
  }

  Widget _buildPhaseRow({
    required BuildContext context,
    required IconData icon,
    required String title,
    String? detail,
    required bool isActive,
    required bool isCompleted,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: isCompleted
                ? Colors.green
                : isActive
                    ? Platform.isIOS
                        ? CupertinoColors.activeBlue
                        : Theme.of(context).primaryColor
                    : Colors.grey,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: isActive ? FontWeight.w500 : FontWeight.normal,
                    color: isCompleted
                        ? Colors.green
                        : isActive
                            ? null
                            : Colors.grey,
                  ),
                ),
                if (detail != null && detail.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    detail,
                    style: TextStyle(
                      fontSize: 12,
                      color: Platform.isIOS
                          ? CupertinoColors.secondaryLabel.resolveFrom(context)
                          : Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: 16), // Maintain consistent height
                ],
              ],
            ),
          ),
          if (isCompleted)
            const Icon(
              CupertinoIcons.checkmark_circle_fill,
              color: Colors.green,
              size: 16,
            )
          else if (isActive)
            Platform.isIOS
                ? const CupertinoActivityIndicator(radius: 8)
                : const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
          else
            const SizedBox(width: 16, height: 16),
        ],
      ),
    );
  }

  Widget _buildStatistics(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildStatisticsSection(
          context: context,
          icon: CupertinoIcons.chart_bar_square,
          title: 'Overall Statistics',
          color: Platform.isIOS ? CupertinoColors.activeBlue : Colors.blue,
          children: [
            _buildStatCard(
              context: context,
              title: 'Safari Rules',
              value: widget.filterManager.lastRuleCount.toString(),
              icon: CupertinoIcons.shield_lefthalf_fill,
              color: Colors.blue,
            ),
            _buildStatCard(
              context: context,
              title: 'Enabled Lists',
              value: widget.filterManager.filterLists
                  .where((f) => f.isSelected)
                  .length
                  .toString(),
              icon: CupertinoIcons.doc_text,
              color: Colors.orange,
            ),
            _buildStatCard(
              context: context,
              title: 'Conversion',
              value: '2.3s',
              icon: CupertinoIcons.clock,
              color: Colors.green,
            ),
            _buildStatCard(
              context: context,
              title: 'Reload',
              value: '0.8s',
              icon: CupertinoIcons.arrow_clockwise,
              color: Colors.purple,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatisticsSection({
    required BuildContext context,
    required IconData icon,
    required String title,
    required Color color,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Platform.isIOS
            ? CupertinoColors.systemGrey6.resolveFrom(context)
            : Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: children,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required BuildContext context,
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Platform.isIOS
            ? CupertinoColors.systemGrey5.resolveFrom(context)
            : Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              color: Platform.isIOS
                  ? CupertinoColors.secondaryLabel.resolveFrom(context)
                  : Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
        ],
      ),
    );
  }
}
