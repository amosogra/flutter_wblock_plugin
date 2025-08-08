import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_wblock_plugin_example/providers/providers.dart';
import 'package:flutter_wblock_plugin_example/theme/app_theme.dart';
import 'dart:math' as math;
import 'dart:io';

class WhitelistManagerView extends ConsumerStatefulWidget {
  final VoidCallback onDismiss;

  const WhitelistManagerView({
    super.key,
    required this.onDismiss,
  });

  @override
  ConsumerState<WhitelistManagerView> createState() => _WhitelistManagerViewState();
}

class _WhitelistManagerViewState extends ConsumerState<WhitelistManagerView> {
  final _newDomainController = TextEditingController();
  Set<String> _selectedDomains = <String>{};
  bool _showError = false;
  String _errorMessage = '';
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    final whitelistViewModel = ref.read(whitelistViewModelProvider);
    whitelistViewModel.loadWhitelistedDomains();
  }

  @override
  Widget build(BuildContext context) {
    final whitelistViewModel = ref.watch(whitelistViewModelProvider);
    
    if (Platform.isMacOS) {
      return _buildMacOSView(whitelistViewModel);
    } else {
      return _buildIOSView(whitelistViewModel);
    }
  }

  Widget _buildMacOSView(whitelistViewModel) {
    return Container(
      color: Colors.black.withOpacity(0.5),
      child: Center(
        child: Container(
          width: 400,
          height: 400,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.cardBackground,
            borderRadius: BorderRadius.circular(AppTheme.defaultRadius),
            boxShadow: [AppTheme.cardShadow],
          ),
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: _buildDomainsList(whitelistViewModel),
              ),
              _buildAddDomainSection(whitelistViewModel),
              if (_showError) _buildErrorMessage(),
              if (_isProcessing) _buildProgressIndicator(),
              _buildActionButtons(whitelistViewModel),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIOSView(whitelistViewModel) {
    return CupertinoPageScaffold(
      backgroundColor: AppTheme.backgroundColor,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: AppTheme.cardBackground.withOpacity(0.94),
        middle: const Text('Whitelisted Domains'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: widget.onDismiss,
          child: const Icon(CupertinoIcons.xmark_circle_fill),
        ),
      ),
      child: Column(
        children: [
          Expanded(
            child: _buildDomainsList(whitelistViewModel),
          ),
          _buildAddDomainSection(whitelistViewModel),
          if (_showError) _buildErrorMessage(),
          if (_isProcessing) _buildProgressIndicator(),
          _buildActionButtons(whitelistViewModel),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Text(
          'Whitelisted Domains',
          style: AppTheme.headline,
        ),
        const Spacer(),
        MacosIconButton(
          icon: const MacosIcon(CupertinoIcons.xmark_circle_fill),
          onPressed: widget.onDismiss,
        ),
      ],
    );
  }

  Widget _buildDomainsList(whitelistViewModel) {
    List<String> whitelistedDomains = whitelistViewModel.whitelistedDomains;
    
    // Create a padded list to ensure minimum 10 rows for better UX
    List<String> paddedDomains = whitelistedDomains.toList();
    final padding = List.filled(math.max(0, 10 - paddedDomains.length), '');
    paddedDomains = paddedDomains + padding;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      height: 250, // Fixed height to prevent jumping
      decoration: BoxDecoration(
        color: Platform.isMacOS 
          ? MacosColors.controlBackgroundColor 
          : CupertinoColors.secondarySystemBackground,
        borderRadius: BorderRadius.circular(AppTheme.smallRadius),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: ListView.builder(
        itemCount: paddedDomains.length,
        itemBuilder: (context, index) {
          final domain = paddedDomains[index];
          if (domain.isEmpty) {
            return const SizedBox(height: 24); // Empty row placeholder
          }
          return _buildDomainRow(domain, index);
        },
      ),
    );
  }

  Widget _buildDomainRow(String domain, int index) {
    final isSelected = _selectedDomains.contains(domain);

    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          Platform.isMacOS
              ? MacosCheckbox(
                  value: isSelected,
                  onChanged: (checked) {
                    setState(() {
                      if (checked == true) {
                        _selectedDomains.add(domain);
                      } else {
                        _selectedDomains.remove(domain);
                      }
                    });
                  },
                )
              : CupertinoCheckbox(
                  value: isSelected,
                  onChanged: (checked) {
                    setState(() {
                      if (checked == true) {
                        _selectedDomains.add(domain);
                      } else {
                        _selectedDomains.remove(domain);
                      }
                    });
                  },
                ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              domain,
              style: AppTheme.body.copyWith(fontSize: 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddDomainSection(whitelistViewModel) {
    return Row(
      children: [
        Expanded(
          child: Platform.isMacOS
              ? MacosTextField(
                  controller: _newDomainController,
                  placeholder: 'Add domain (e.g. example.com)',
                  onSubmitted: (_) => _addDomain(whitelistViewModel),
                )
              : CupertinoTextField(
                  controller: _newDomainController,
                  placeholder: 'Add domain (e.g. example.com)',
                  padding: const EdgeInsets.all(12),
                  onSubmitted: (_) => _addDomain(whitelistViewModel),
                ),
        ),
        const SizedBox(width: 12),
        Platform.isMacOS
            ? PushButton(
                controlSize: ControlSize.large,
                color: AppTheme.primaryColor,
                onPressed: (_newDomainController.text.trim().isEmpty || _isProcessing) 
                  ? null 
                  : () => _addDomain(whitelistViewModel),
                child: const Text('Add'),
              )
            : CupertinoButton.filled(
                onPressed: (_newDomainController.text.trim().isEmpty || _isProcessing) 
                  ? null 
                  : () => _addDomain(whitelistViewModel),
                child: const Text('Add'),
              ),
      ],
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      child: Text(
        _errorMessage,
        style: AppTheme.caption.copyWith(
          color: Colors.red,
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          LinearProgressIndicator(
            backgroundColor: Platform.isMacOS 
              ? MacosColors.quaternaryLabelColor 
              : CupertinoColors.systemGrey4,
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
          ),
          const SizedBox(height: 4),
          Text(
            'Processing...',
            style: AppTheme.caption,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(whitelistViewModel) {
    List<String> whitelistedDomains = whitelistViewModel.whitelistedDomains;
    
    return Container(
      margin: const EdgeInsets.only(top: 12),
      child: Row(
        children: [
          Platform.isMacOS
              ? PushButton(
                  controlSize: ControlSize.large,
                  onPressed: (whitelistedDomains.isEmpty || _isProcessing) 
                    ? null 
                    : () => _selectAllDomains(whitelistedDomains),
                  child: const Text('Select All'),
                )
              : CupertinoButton(
                  onPressed: (whitelistedDomains.isEmpty || _isProcessing) 
                    ? null 
                    : () => _selectAllDomains(whitelistedDomains),
                  child: const Text('Select All'),
                ),
          const SizedBox(width: 16),
          Platform.isMacOS
              ? PushButton(
                  controlSize: ControlSize.large,
                  onPressed: (_selectedDomains.isEmpty || _isProcessing) 
                    ? null 
                    : () => _deleteSelectedDomains(whitelistViewModel),
                  child: const Text('Delete Selected'),
                )
              : CupertinoButton(
                  color: CupertinoColors.destructiveRed,
                  onPressed: (_selectedDomains.isEmpty || _isProcessing) 
                    ? null 
                    : () => _deleteSelectedDomains(whitelistViewModel),
                  child: const Text(
                    'Delete Selected',
                    style: TextStyle(color: CupertinoColors.white),
                  ),
                ),
          const Spacer(),
        ],
      ),
    );
  }

  void _addDomain(whitelistViewModel) {
    final trimmed = _newDomainController.text.trim();
    if (trimmed.isEmpty) return;

    setState(() {
      _isProcessing = true;
      _showError = false;
    });

    // Simulate async operation
    Future.delayed(const Duration(milliseconds: 500), () {
      final result = whitelistViewModel.addDomain(trimmed);

      setState(() {
        _isProcessing = false;
        if (result.isSuccess) {
          _newDomainController.clear();
        } else {
          _showError = true;
          _errorMessage = result.error!.localizedDescription;
        }
      });
    });
  }

  void _selectAllDomains(List<String> whitelistedDomains) {
    setState(() {
      _selectedDomains = Set<String>.from(whitelistedDomains);
    });
  }

  void _deleteSelectedDomains(whitelistViewModel) {
    if (_selectedDomains.isEmpty) return;

    setState(() {
      _isProcessing = true;
    });

    // Simulate async operation
    Future.delayed(const Duration(milliseconds: 500), () {
      for (final domain in _selectedDomains) {
        whitelistViewModel.removeDomain(domain);
      }

      setState(() {
        _selectedDomains.clear();
        _isProcessing = false;
      });
    });
  }

  @override
  void dispose() {
    _newDomainController.dispose();
    super.dispose();
  }
}
