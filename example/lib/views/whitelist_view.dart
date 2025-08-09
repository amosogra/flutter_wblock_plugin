import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_wblock_plugin_example/providers/providers.dart';
import 'package:flutter_wblock_plugin_example/theme/app_theme.dart';
import 'dart:io';

class WhitelistView extends ConsumerStatefulWidget {
  final VoidCallback onDismiss;

  const WhitelistView({
    super.key,
    required this.onDismiss,
  });

  @override
  ConsumerState<WhitelistView> createState() => _WhitelistViewState();
}

class _WhitelistViewState extends ConsumerState<WhitelistView> {
  final _newDomainController = TextEditingController();
  bool _showingAlert = false;
  String _alertMessage = '';

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
      // macOS uses WhitelistManagerView instead
      return const SizedBox.shrink();
    }
    
    return CupertinoPageScaffold(
      backgroundColor: AppTheme.backgroundColor,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: AppTheme.cardBackground.withOpacity(0.94),
        middle: const Text('Whitelisted Domains'),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: widget.onDismiss,
          child: const Text('Done'),
        ),
      ),
      child: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: whitelistViewModel.whitelistedDomains.isEmpty
                    ? _buildEmptyState()
                    : _buildDomainsList(whitelistViewModel),
              ),
              _buildAddDomainSection(whitelistViewModel),
            ],
          ),
          if (_showingAlert) _buildAlert(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            CupertinoIcons.list_bullet_indent,
            size: 48,
            color: AppTheme.secondaryLabel.withOpacity(0.6),
          ),
          const SizedBox(height: 16),
          Text(
            'No Whitelisted Domains',
            style: AppTheme.headline,
          ),
          const SizedBox(height: 8),
          Text(
            'Add domains to disable blocking on specific websites',
            textAlign: TextAlign.center,
            style: AppTheme.caption,
          ),
        ],
      ),
    );
  }

  Widget _buildDomainsList(whitelistViewModel) {
    return CupertinoScrollbar(
      child: ListView.separated(
        itemCount: whitelistViewModel.whitelistedDomains.length,
        separatorBuilder: (context, index) => Divider(
          height: 1,
          color: AppTheme.dividerColor,
        ),
        itemBuilder: (context, index) {
          final domain = whitelistViewModel.whitelistedDomains[index];
          return _buildDomainRow(domain, whitelistViewModel);
        },
      ),
    );
  }

  Widget _buildDomainRow(String domain, whitelistViewModel) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(
            CupertinoIcons.globe,
            color: AppTheme.primaryColor,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              domain,
              style: AppTheme.body,
            ),
          ),
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () => _removeDomain(domain, whitelistViewModel),
            child: const Icon(
              CupertinoIcons.minus_circle_fill,
              color: CupertinoColors.destructiveRed,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddDomainSection(whitelistViewModel) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        border: Border(
          top: BorderSide(
            color: AppTheme.dividerColor,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: CupertinoTextField(
              controller: _newDomainController,
              placeholder: 'Enter Domain',
              keyboardType: TextInputType.url,
              textInputAction: TextInputAction.done,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: CupertinoColors.systemGrey6.resolveFrom(context),
                borderRadius: BorderRadius.circular(AppTheme.smallRadius),
              ),
              onSubmitted: (_) => _addDomain(whitelistViewModel),
              onChanged: (_) => setState(() {}),
            ),
          ),
          const SizedBox(width: 12),
          CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: AppTheme.primaryColor,
            disabledColor: CupertinoColors.systemGrey4,
            onPressed: _newDomainController.text.isEmpty 
              ? null 
              : () => _addDomain(whitelistViewModel),
            child: const Icon(
              CupertinoIcons.plus_circle_fill,
              color: CupertinoColors.white,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlert() {
    return Container(
      color: Colors.black.withOpacity(0.3),
      child: Center(
        child: CupertinoAlertDialog(
          title: const Text('Error'),
          content: Text(_alertMessage),
          actions: [
            CupertinoDialogAction(
              onPressed: () {
                setState(() {
                  _showingAlert = false;
                });
              },
              child: const Text('OK'),
            ),
          ],
        ),
      ),
    );
  }

  void _addDomain(whitelistViewModel) {
    final result = whitelistViewModel.addDomain(_newDomainController.text);
    switch (result.isSuccess) {
      case true:
        _newDomainController.clear();
        setState(() {});
        break;
      case false:
        setState(() {
          _alertMessage = result.error!.localizedDescription;
          _showingAlert = true;
        });
        break;
    }
  }

  void _removeDomain(String domain, whitelistViewModel) {
    whitelistViewModel.removeDomain(domain);
    setState(() {});
  }

  @override
  void dispose() {
    _newDomainController.dispose();
    super.dispose();
  }
}
