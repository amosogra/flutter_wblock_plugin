import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:url_launcher/url_launcher.dart';
import '../managers/app_filter_manager.dart';
import '../managers/user_script_manager.dart';
import '../models/filter_list.dart';

enum BlockingLevel {
  minimal('Minimal'),
  recommended('Recommended'),
  complete('Complete');

  final String value;
  const BlockingLevel(this.value);
}

class OnboardingView extends StatefulWidget {
  final AppFilterManager filterManager;
  final UserScriptManager userScriptManager;
  final VoidCallback onComplete;

  const OnboardingView({
    super.key,
    required this.filterManager,
    required this.userScriptManager,
    required this.onComplete,
  });

  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView> {
  BlockingLevel selectedBlockingLevel = BlockingLevel.recommended;
  Set<String> selectedUserScripts = {};
  int step = 0;
  bool isApplying = false;
  double applyProgress = 0.0;

  List<Map<String, String>> get defaultUserScripts {
    return widget.userScriptManager.userScripts.map((script) {
      return {
        'id': script.id,
        'name': script.name,
        'description': script.content.length > 100 
            ? '${script.content.substring(0, 100)}...' 
            : script.content,
      };
    }).toList();
  }

  Map<String, String>? get bypassPaywallsScript {
    try {
      final script = widget.userScriptManager.userScripts.firstWhere(
        (s) => s.name.toLowerCase().contains('bypass paywalls'),
      );
      return {
        'id': script.id,
        'name': script.name,
      };
    } catch (e) {
      return null;
    }
  }

  String? get bypassPaywallsFilterName {
    final candidates = [
      'Bypass Paywalls Filter',
      'Bypass Paywalls',
      'Bypass Paywalls (Custom)',
    ];
    
    for (var filter in widget.filterManager.filterLists) {
      for (var candidate in candidates) {
        if (filter.name.toLowerCase().contains(candidate.toLowerCase())) {
          return filter.name;
        }
      }
    }
    return null;
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
      backgroundColor: CupertinoColors.systemBackground,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: isApplying ? _buildDownloadView() : _buildStepView(),
        ),
      ),
    );
  }

  Widget _buildMacOSView() {
    return Scaffold(
      body: Center(
        child: Container(
          constraints: const BoxConstraints(
            minWidth: 350,
            maxWidth: 500,
            minHeight: 350,
            maxHeight: 600,
          ),
          padding: const EdgeInsets.all(20),
          child: isApplying ? _buildDownloadView() : _buildStepView(),
        ),
      ),
    );
  }

  Widget _buildDownloadView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 300,
          child: LinearProgressIndicator(
            value: applyProgress,
            minHeight: 4,
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Downloading and installing filter lists...',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        const Text(
          'Applying filters...',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          'This may take awhile',
          style: TextStyle(
            fontSize: 12,
            color: Platform.isIOS
                ? CupertinoColors.secondaryLabel
                : Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildStepView() {
    switch (step) {
      case 0:
        return _buildBlockingLevelStep();
      case 1:
        return _buildUserScriptStep();
      case 2:
        return _buildSummaryStep();
      default:
        return Container();
    }
  }

  Widget _buildBlockingLevelStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Welcome to wBlock!',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Choose your preferred blocking level. You can adjust enabled filters later.',
          style: TextStyle(fontSize: 14),
        ),
        const SizedBox(height: 20),
        ...BlockingLevel.values.map((level) => _buildBlockingLevelOption(level)),
        const Spacer(),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (Platform.isIOS)
              CupertinoButton(
                onPressed: () => setState(() => step++),
                child: const Text('Next'),
              )
            else
              ElevatedButton(
                onPressed: () => setState(() => step++),
                child: const Text('Next'),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildBlockingLevelOption(BlockingLevel level) {
    return GestureDetector(
      onTap: () => setState(() => selectedBlockingLevel = level),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(
              selectedBlockingLevel == level
                  ? Platform.isIOS
                      ? CupertinoIcons.largecircle_fill_circle
                      : Icons.radio_button_checked
                  : Platform.isIOS
                      ? CupertinoIcons.circle
                      : Icons.radio_button_unchecked,
              color: selectedBlockingLevel == level
                  ? Platform.isIOS
                      ? CupertinoColors.activeBlue
                      : Theme.of(context).primaryColor
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    level.value,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    _getBlockingLevelDescription(level),
                    style: TextStyle(
                      fontSize: 12,
                      color: Platform.isIOS
                          ? CupertinoColors.secondaryLabel
                          : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getBlockingLevelDescription(BlockingLevel level) {
    switch (level) {
      case BlockingLevel.minimal:
        return 'Only AdGuard Base filter. Lightest protection, best compatibility.';
      case BlockingLevel.recommended:
        return 'Default filters for balanced blocking and compatibility.';
      case BlockingLevel.complete:
        return 'All filters (except foreign languages). May break some sites, so it is not recommended. Use with caution.';
    }
  }

  Widget _buildUserScriptStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Userscripts',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Select any userscripts you want to enable. These add extra features or fixes. You can always add more in the settings later.',
          style: TextStyle(fontSize: 14),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: ListView(
            children: [
              ...defaultUserScripts.map((script) => _buildUserScriptOption(script)),
              if (bypassPaywallsScript != null &&
                  selectedUserScripts.contains(bypassPaywallsScript!['id']) &&
                  bypassPaywallsFilterName != null)
                Container(
                  margin: const EdgeInsets.only(top: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.yellow.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.warning,
                        color: Colors.orange,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'The ${bypassPaywallsScript!['name']} userscript requires the $bypassPaywallsFilterName',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.orange,
                              ),
                            ),
                            const Text(
                              'It will be enabled automatically.',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (Platform.isIOS) ...[
              CupertinoButton(
                onPressed: () => setState(() => step--),
                child: const Text('Back'),
              ),
              CupertinoButton(
                onPressed: () => setState(() => step++),
                child: const Text('Next'),
              ),
            ] else ...[
              TextButton(
                onPressed: () => setState(() => step--),
                child: const Text('Back'),
              ),
              ElevatedButton(
                onPressed: () => setState(() => step++),
                child: const Text('Next'),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildUserScriptOption(Map<String, String> script) {
    final isSelected = selectedUserScripts.contains(script['id']);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          if (Platform.isIOS)
            CupertinoSwitch(
              value: isSelected,
              onChanged: (value) {
                setState(() {
                  if (value) {
                    selectedUserScripts.add(script['id']!);
                  } else {
                    selectedUserScripts.remove(script['id']);
                  }
                });
              },
            )
          else
            Switch(
              value: isSelected,
              onChanged: (value) {
                setState(() {
                  if (value) {
                    selectedUserScripts.add(script['id']!);
                  } else {
                    selectedUserScripts.remove(script['id']);
                  }
                });
              },
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  script['name']!,
                  style: const TextStyle(fontSize: 14),
                ),
                Text(
                  script['description']!,
                  style: TextStyle(
                    fontSize: 12,
                    color: Platform.isIOS
                        ? CupertinoColors.secondaryLabel
                        : Colors.grey,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Summary',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Review your choices and apply settings.',
          style: TextStyle(fontSize: 14),
        ),
        const SizedBox(height: 16),
        const Divider(),
        const SizedBox(height: 8),
        Text('Blocking Level: ${selectedBlockingLevel.value}'),
        const SizedBox(height: 8),
        Text(
          'Userscripts: ${selectedUserScripts.isEmpty ? "None" : selectedUserScripts.map((id) => defaultUserScripts.firstWhere((s) => s['id'] == id)['name']).join(", ")}',
        ),
        const SizedBox(height: 8),
        const Divider(),
        if (selectedBlockingLevel == BlockingLevel.complete) ...[
          const SizedBox(height: 16),
          const Text(
            'Warning: Complete mode may break some websites. Proceed with caution.',
            style: TextStyle(
              color: Colors.red,
              fontSize: 12,
            ),
          ),
        ],
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.yellow.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Platform.isIOS
                        ? CupertinoIcons.exclamationmark_shield_fill
                        : Icons.shield,
                    color: Colors.orange,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'After filters are applied, you must enable all wBlock extensions in Safari\'s extension settings.',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'You can enable them in Safari > Settings > Extensions (on Mac) or Settings > Safari > Extensions (on iPhone/iPad).',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  TextButton(
                    onPressed: () {
                      launchUrl(Uri.parse('https://support.apple.com/guide/iphone/get-extensions-iphab0432bf6/ios'));
                    },
                    child: const Text(
                      'How to enable on iPhone/iPad',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                  const SizedBox(width: 16),
                  TextButton(
                    onPressed: () {
                      launchUrl(Uri.parse('https://support.apple.com/en-us/102343'));
                    },
                    child: const Text(
                      'How to enable on Mac',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const Spacer(),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (Platform.isIOS) ...[
              CupertinoButton(
                onPressed: () => setState(() => step--),
                child: const Text('Back'),
              ),
              CupertinoButton.filled(
                onPressed: _applySettings,
                child: const Text('Apply & Finish'),
              ),
            ] else ...[
              TextButton(
                onPressed: () => setState(() => step--),
                child: const Text('Back'),
              ),
              ElevatedButton(
                onPressed: _applySettings,
                child: const Text('Apply & Finish'),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Future<void> _applySettings() async {
    setState(() {
      isApplying = true;
      applyProgress = 0.0;
    });

    // Simulate progress for filter selection
    await _updateProgress(0.1);
    
    // Apply filter selections based on blocking level
    await _applyFilterSelections();
    await _updateProgress(0.3);

    // Apply userscript selections
    await _applyUserScriptSelections();
    await _updateProgress(0.5);

    // Download and apply the changes
    setState(() {
      applyProgress = 0.6;
    });
    
    // Trigger the actual filter application
    widget.filterManager.setShowingApplyProgressSheet(true);
    await widget.filterManager.checkAndEnableFilters(forceReload: true);
    
    await _updateProgress(1.0);
    
    // Complete onboarding
    widget.onComplete();
  }

  Future<void> _updateProgress(double progress) async {
    setState(() {
      applyProgress = progress;
    });
    await Future.delayed(const Duration(milliseconds: 200));
  }

  Future<void> _applyFilterSelections() async {
    // Get all filters and update their selection state
    final allFilters = widget.filterManager.filterLists;
    
    // First, deselect all filters
    for (var filter in allFilters) {
      if (filter.isSelected) {
        await widget.filterManager.toggleFilterListSelection(filter.id);
      }
    }

    switch (selectedBlockingLevel) {
      case BlockingLevel.minimal:
        // Enable only AdGuard Base Filter
        for (var filter in allFilters) {
          if (filter.name == 'AdGuard Base Filter') {
            await widget.filterManager.toggleFilterListSelection(filter.id);
            break;
          }
        }
        break;

      case BlockingLevel.recommended:
        // Enable recommended filters
        final recommendedFilters = [
          'AdGuard Base Filter',
          'AdGuard Tracking Protection Filter',
          'AdGuard Annoyances Filter',
          'EasyPrivacy',
          'Online Malicious URL Blocklist',
          'd3Host List by d3ward',
          'Anti-Adblock List',
        ];
        
        for (var filter in allFilters) {
          if (recommendedFilters.contains(filter.name)) {
            await widget.filterManager.toggleFilterListSelection(filter.id);
          }
        }
        break;

      case BlockingLevel.complete:
        // Enable all filters except foreign language ones
        for (var filter in allFilters) {
          if (filter.category != FilterListCategory.regional && 
              filter.category != 'foreign') {
            await widget.filterManager.toggleFilterListSelection(filter.id);
          }
        }
        break;
    }

    // If Bypass Paywalls userscript is selected, enable its filter
    if (bypassPaywallsScript != null &&
        selectedUserScripts.contains(bypassPaywallsScript!['id']) &&
        bypassPaywallsFilterName != null) {
      for (var filter in allFilters) {
        if (filter.name == bypassPaywallsFilterName && !filter.isSelected) {
          await widget.filterManager.toggleFilterListSelection(filter.id);
          break;
        }
      }
    }
  }

  Future<void> _applyUserScriptSelections() async {
    for (var script in widget.userScriptManager.userScripts) {
      final shouldBeEnabled = selectedUserScripts.contains(script.id);
      if (script.isEnabled != shouldBeEnabled) {
        await widget.userScriptManager.toggleScript(script.id);
      }
    }
  }
}
