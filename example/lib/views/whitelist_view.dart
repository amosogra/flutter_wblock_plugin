import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_wblock_plugin_example/managers/whitelist_view_model.dart';

class WhitelistView extends StatefulWidget {
  final WhitelistViewModel viewModel;
  final VoidCallback onDismiss;

  const WhitelistView({
    super.key,
    required this.viewModel,
    required this.onDismiss,
  });

  @override
  State<WhitelistView> createState() => _WhitelistViewState();
}

class _WhitelistViewState extends State<WhitelistView> {
  final _newDomainController = TextEditingController();
  bool _showingAlert = false;
  String _alertMessage = '';

  @override
  void initState() {
    super.initState();
    widget.viewModel.loadWhitelistedDomains();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
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
                child: widget.viewModel.whitelistedDomains.isEmpty
                    ? _buildEmptyState()
                    : _buildDomainsList(),
              ),
              _buildAddDomainSection(),
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
            color: CupertinoColors.secondaryLabel.withOpacity(0.6),
          ),
          const SizedBox(height: 16),
          const Text(
            'No Whitelisted Domains',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: CupertinoColors.label,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Add domains to disable blocking on specific websites',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: CupertinoColors.secondaryLabel,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDomainsList() {
    return CupertinoScrollbar(
      child: ListView.separated(
        itemCount: widget.viewModel.whitelistedDomains.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final domain = widget.viewModel.whitelistedDomains[index];
          return _buildDomainRow(domain);
        },
      ),
    );
  }

  Widget _buildDomainRow(String domain) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          const Icon(
            CupertinoIcons.globe,
            color: CupertinoColors.systemBlue,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              domain,
              style: const TextStyle(
                fontSize: 16,
                color: CupertinoColors.label,
              ),
            ),
          ),
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () => _removeDomain(domain),
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

  Widget _buildAddDomainSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: CupertinoColors.systemBackground,
        border: Border(
          top: BorderSide(
            color: CupertinoColors.separator,
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
              onSubmitted: (_) => _addDomain(),
            ),
          ),
          const SizedBox(width: 12),
          CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: CupertinoColors.systemBlue,
            disabledColor: CupertinoColors.systemGrey4,
            onPressed: _newDomainController.text.isEmpty ? null : _addDomain,
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

  void _addDomain() {
    final result = widget.viewModel.addDomain(_newDomainController.text);
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

  void _removeDomain(String domain) {
    widget.viewModel.removeDomain(domain);
    setState(() {});
  }

  @override
  void dispose() {
    _newDomainController.dispose();
    super.dispose();
  }
}
