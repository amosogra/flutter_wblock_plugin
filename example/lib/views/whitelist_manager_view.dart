import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import '../managers/app_filter_manager.dart';

class WhitelistManagerView extends StatefulWidget {
  final AppFilterManager filterManager;

  const WhitelistManagerView({
    super.key,
    required this.filterManager,
  });

  @override
  State<WhitelistManagerView> createState() => _WhitelistManagerViewState();
}

class _WhitelistManagerViewState extends State<WhitelistManagerView> {
  final TextEditingController _domainController = TextEditingController();
  bool _isEditing = false;
  List<String> _editingDomains = [];

  @override
  void initState() {
    super.initState();
    _editingDomains = List.from(widget.filterManager.whitelistedDomains);
  }

  @override
  void dispose() {
    _domainController.dispose();
    super.dispose();
  }

  void _addDomain() {
    final domain = _domainController.text.trim();
    if (domain.isNotEmpty && !_editingDomains.contains(domain)) {
      setState(() {
        _editingDomains.add(domain);
        _domainController.clear();
      });
    }
  }

  void _removeDomain(String domain) {
    setState(() {
      _editingDomains.remove(domain);
    });
  }

  void _saveChanges() {
    widget.filterManager.updateWhitelistedDomains(_editingDomains);
    setState(() {
      _isEditing = false;
    });
  }

  void _cancelEditing() {
    setState(() {
      _isEditing = false;
      _editingDomains = List.from(widget.filterManager.whitelistedDomains);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (Platform.isIOS) {
      return _buildIOSView();
    } else {
      return _buildMacOSView();
    }
  }

  Widget _buildIOSView() {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Whitelisted Domains'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: Text(_isEditing ? 'Done' : 'Edit'),
          onPressed: () {
            if (_isEditing) {
              _saveChanges();
            } else {
              setState(() {
                _isEditing = true;
              });
            }
          },
        ),
        leading: _isEditing
            ? CupertinoButton(
                padding: EdgeInsets.zero,
                child: const Text('Cancel'),
                onPressed: _cancelEditing,
              )
            : null,
      ),
      child: _buildContent(),
    );
  }

  Widget _buildMacOSView() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Whitelisted Domains'),
        actions: [
          if (_isEditing) ...[
            TextButton(
              onPressed: _cancelEditing,
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: _saveChanges,
              child: const Text('Save'),
            ),
          ] else ...[
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
            ),
          ],
        ],
      ),
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        if (_isEditing) ...[
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Platform.isIOS
                      ? CupertinoTextField(
                          controller: _domainController,
                          placeholder: 'example.com',
                          onSubmitted: (_) => _addDomain(),
                        )
                      : TextField(
                          controller: _domainController,
                          decoration: const InputDecoration(
                            hintText: 'example.com',
                            border: OutlineInputBorder(),
                          ),
                          onSubmitted: (_) => _addDomain(),
                        ),
                ),
                const SizedBox(width: 8),
                Platform.isIOS
                    ? CupertinoButton(
                        onPressed: _addDomain,
                        child: const Icon(CupertinoIcons.add),
                      )
                    : IconButton(
                        onPressed: _addDomain,
                        icon: const Icon(Icons.add),
                      ),
              ],
            ),
          ),
        ],
        Expanded(
          child: _editingDomains.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Platform.isIOS
                            ? CupertinoIcons.list_bullet
                            : Icons.list,
                        size: 48,
                        color: Platform.isIOS
                            ? CupertinoColors.secondaryLabel
                            : Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No whitelisted domains',
                        style: TextStyle(fontSize: 18),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _isEditing
                            ? 'Add domains to whitelist them'
                            : 'Tap Edit to add domains',
                        style: TextStyle(
                          fontSize: 14,
                          color: Platform.isIOS
                              ? CupertinoColors.secondaryLabel
                              : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _editingDomains.length,
                  itemBuilder: (context, index) {
                    final domain = _editingDomains[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Platform.isIOS
                              ? CupertinoColors.systemGrey6.resolveFrom(context)
                              : Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ListTile(
                          title: Text(domain),
                          trailing: _isEditing
                              ? IconButton(
                                  icon: Icon(
                                    Platform.isIOS
                                        ? CupertinoIcons.minus_circle_fill
                                        : Icons.remove_circle,
                                    color: Colors.red,
                                  ),
                                  onPressed: () => _removeDomain(domain),
                                )
                              : null,
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
