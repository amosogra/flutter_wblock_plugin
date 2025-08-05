import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:flutter_wblock_plugin/flutter_wblock_plugin.dart';
import 'package:flutter_wblock_plugin_example/managers/app_filter_manager.dart';
import 'package:flutter_wblock_plugin_example/managers/user_script_manager.dart';
import 'package:flutter_wblock_plugin_example/models/filter_list.dart';
import 'package:flutter_wblock_plugin_example/models/user_script.dart';
import 'dart:io';
import 'package:url_launcher/url_launcher.dart';

enum BlockingLevel {
  minimal,
  recommended,
  complete;

  String get rawValue {
    switch (this) {
      case BlockingLevel.minimal:
        return 'Minimal';
      case BlockingLevel.recommended:
        return 'Recommended';
      case BlockingLevel.complete:
        return 'Complete';
    }
  }
}

class OnboardingView extends StatefulWidget {
  final AppFilterManager filterManager;
  final UserScriptManager userScriptManager;
  final VoidCallback? onComplete;

  const OnboardingView({
    super.key,
    required this.filterManager,
    required this.userScriptManager,
    this.onComplete,
  });

  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView> {
  BlockingLevel _selectedBlockingLevel = BlockingLevel.recommended;
  final Set<String> _selectedUserscripts = <String>{};
  int _step = 0;
  bool _isApplying = false;
  double _applyProgress = 0.0;

  List<UserScript> get defaultUserScripts => widget.userScriptManager.userScripts;

  UserScript? get bypassPaywallsScript {
    try {
      return widget.userScriptManager.userScripts.where((script) => script.name.toLowerCase().contains('bypass paywalls')).first;
    } catch (e) {
      return null;
    }
  }

  String? get bypassPaywallsFilterName {
    final candidates = ['Bypass Paywalls Filter', 'Bypass Paywalls', 'Bypass Paywalls (Custom)'];

    try {
      return widget.filterManager.filterLists
          .where((filter) => candidates.any((candidate) => filter.name.toLowerCase().contains(candidate.toLowerCase())))
          .first
          .name;
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Platform.isMacOS ? MacosColors.windowBackgroundColor : CupertinoColors.systemBackground,
      child: Center(
        child: Container(
          width: Platform.isMacOS ? 500 : double.infinity,
          height: Platform.isMacOS ? 600 : double.infinity,
          padding: const EdgeInsets.all(30),
          child: _isApplying ? _buildDownloadView() : _buildStepView(),
        ),
      ),
    );
  }

  Widget _buildDownloadView() {
    return OnboardingDownloadView(progress: _applyProgress);
  }

  Widget _buildStepView() {
    switch (_step) {
      case 0:
        return _buildBlockingLevelStep();
      case 1:
        return _buildUserscriptStep();
      case 2:
        return _buildSummaryStep();
      default:
        return _buildBlockingLevelStep();
    }
  }

  Widget _buildBlockingLevelStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Welcome to wBlock!',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Platform.isMacOS ? MacosColors.labelColor : CupertinoColors.label,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Choose your preferred blocking level. You can adjust enabled filters later.',
          style: TextStyle(
            fontSize: 16,
            color: Platform.isMacOS ? MacosColors.secondaryLabelColor : CupertinoColors.secondaryLabel,
          ),
        ),
        const SizedBox(height: 32),
        ...BlockingLevel.values.map((level) => _buildBlockingLevelOption(level)),
        const Spacer(),
        Row(
          children: [
            const Spacer(),
            Platform.isMacOS
                ? PushButton(
                    controlSize: ControlSize.large,
                    onPressed: () => setState(() => _step = 1),
                    child: const Text('Next'),
                  )
                : CupertinoButton.filled(
                    onPressed: () => setState(() => _step = 1),
                    child: const Text('Next'),
                  ),
          ],
        ),
      ],
    );
  }

  Widget _buildBlockingLevelOption(BlockingLevel level) {
    final isSelected = _selectedBlockingLevel == level;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedBlockingLevel = level;
          });
        },
        child: Row(
          children: [
            Icon(
              isSelected ? CupertinoIcons.largecircle_fill_circle : CupertinoIcons.circle,
              color: isSelected
                  ? (Platform.isMacOS ? MacosColors.systemBlueColor : CupertinoColors.systemBlue)
                  : (Platform.isMacOS ? MacosColors.secondaryLabelColor : CupertinoColors.secondaryLabel),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    level.rawValue,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Platform.isMacOS ? MacosColors.labelColor : CupertinoColors.label,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _blockingLevelDescription(level),
                    style: TextStyle(
                      fontSize: 12,
                      color: Platform.isMacOS ? MacosColors.secondaryLabelColor : CupertinoColors.secondaryLabel,
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

  String _blockingLevelDescription(BlockingLevel level) {
    switch (level) {
      case BlockingLevel.minimal:
        return 'Only AdGuard Base filter. Lightest protection, best compatibility.';
      case BlockingLevel.recommended:
        return 'Default filters for balanced blocking and compatibility.';
      case BlockingLevel.complete:
        return 'All filters (except foreign languages). May break some sites, so it is not recommended. Use with caution.';
    }
  }

  Widget _buildUserscriptStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Userscripts',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Platform.isMacOS ? MacosColors.labelColor : CupertinoColors.label,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Select any userscripts you want to enable. These add extra features or fixes. You can always add more in the settings later.',
          style: TextStyle(
            fontSize: 16,
            color: Platform.isMacOS ? MacosColors.secondaryLabelColor : CupertinoColors.secondaryLabel,
          ),
        ),
        const SizedBox(height: 32),
        Expanded(
          child: ListView(
            children: [
              ...defaultUserScripts.map((script) => _buildUserscriptOption(script)),
              if (bypassPaywallsScript != null && _selectedUserscripts.contains(bypassPaywallsScript!.id) && bypassPaywallsFilterName != null)
                _buildBypassPaywallsNote(),
            ],
          ),
        ),
        Row(
          children: [
            Platform.isMacOS
                ? PushButton(
                    controlSize: ControlSize.large,
                    onPressed: () => setState(() => _step = 0),
                    child: const Text('Back'),
                  )
                : CupertinoButton(
                    onPressed: () => setState(() => _step = 0),
                    child: const Text('Back'),
                  ),
            const Spacer(),
            Platform.isMacOS
                ? PushButton(
                    controlSize: ControlSize.large,
                    onPressed: () => setState(() => _step = 2),
                    child: const Text('Next'),
                  )
                : CupertinoButton.filled(
                    onPressed: () => setState(() => _step = 2),
                    child: const Text('Next'),
                  ),
          ],
        ),
      ],
    );
  }

  Widget _buildUserscriptOption(UserScript script) {
    final isSelected = _selectedUserscripts.contains(script.id);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GestureDetector(
        onTap: () {
          setState(() {
            if (isSelected) {
              _selectedUserscripts.remove(script.id);
            } else {
              _selectedUserscripts.add(script.id);
            }
          });
        },
        child: Row(
          children: [
            Platform.isMacOS
                ? MacosCheckbox(
                    value: isSelected,
                    onChanged: (value) {
                      setState(() {
                        if (value == true) {
                          _selectedUserscripts.add(script.id);
                        } else {
                          _selectedUserscripts.remove(script.id);
                        }
                      });
                    },
                  )
                : Icon(
                    isSelected ? CupertinoIcons.checkmark_square_fill : CupertinoIcons.square,
                    color: isSelected
                        ? (Platform.isMacOS ? MacosColors.systemBlueColor : CupertinoColors.systemBlue)
                        : (Platform.isMacOS ? MacosColors.secondaryLabelColor : CupertinoColors.secondaryLabel),
                  ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    script.name,
                    style: TextStyle(
                      fontSize: 16,
                      color: Platform.isMacOS ? MacosColors.labelColor : CupertinoColors.label,
                    ),
                  ),
                  if (script.description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      script.description,
                      style: TextStyle(
                        fontSize: 12,
                        color: Platform.isMacOS ? MacosColors.secondaryLabelColor : CupertinoColors.secondaryLabel,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBypassPaywallsNote() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.yellow.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.yellow.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            CupertinoIcons.exclamationmark_triangle_fill,
            color: Colors.yellow,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'The ${bypassPaywallsScript!.name} userscript requires the $bypassPaywallsFilterName',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.orange,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'It will be enabled automatically.',
                  style: TextStyle(
                    fontSize: 11,
                    color: Platform.isMacOS ? MacosColors.secondaryLabelColor : CupertinoColors.secondaryLabel,
                  ),
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
        Text(
          'Summary',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Platform.isMacOS ? MacosColors.labelColor : CupertinoColors.label,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Review your choices and apply settings.',
          style: TextStyle(
            fontSize: 16,
            color: Platform.isMacOS ? MacosColors.secondaryLabelColor : CupertinoColors.secondaryLabel,
          ),
        ),
        const SizedBox(height: 32),
        const Divider(),
        const SizedBox(height: 16),
        Text(
          'Blocking Level: ${_selectedBlockingLevel.rawValue}',
          style: TextStyle(
            fontSize: 16,
            color: Platform.isMacOS ? MacosColors.labelColor : CupertinoColors.label,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Userscripts: ${_selectedUserscripts.isEmpty ? "None" : _getSelectedUserscriptNames()}',
          style: TextStyle(
            fontSize: 16,
            color: Platform.isMacOS ? MacosColors.labelColor : CupertinoColors.label,
          ),
        ),
        const SizedBox(height: 16),
        const Divider(),
        const SizedBox(height: 16),
        if (_selectedBlockingLevel == BlockingLevel.complete) ...[
          const Text(
            'Warning: Complete mode may break some websites. Proceed with caution.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.red,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
        ],
        _buildSafariExtensionReminder(),
        const Spacer(),
        Row(
          children: [
            Platform.isMacOS
                ? PushButton(
                    controlSize: ControlSize.large,
                    onPressed: () => setState(() => _step = 1),
                    child: const Text('Back'),
                  )
                : CupertinoButton(
                    onPressed: () => setState(() => _step = 1),
                    child: const Text('Back'),
                  ),
            const Spacer(),
            Platform.isMacOS
                ? PushButton(
                    controlSize: ControlSize.large,
                    onPressed: _applySettings,
                    child: const Text('Apply & Finish'),
                  )
                : CupertinoButton.filled(
                    onPressed: _applySettings,
                    child: const Text('Apply & Finish'),
                  ),
          ],
        ),
      ],
    );
  }

  Widget _buildSafariExtensionReminder() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.yellow.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.yellow.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                CupertinoIcons.exclamationmark_shield_fill,
                color: Colors.yellow,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'After filters are applied, you must enable all wBlock extensions in Safari\'s extension settings.',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Platform.isMacOS ? MacosColors.labelColor : CupertinoColors.label,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'You can enable them in Safari > Settings > Extensions (on Mac) or Settings > Safari > Extensions (on iPhone/iPad).',
                      style: TextStyle(
                        fontSize: 12,
                        color: Platform.isMacOS ? MacosColors.secondaryLabelColor : CupertinoColors.secondaryLabel,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (Platform.isMacOS) ...[
            Row(
              children: [
                _buildHelpLink(
                  'How to enable on Mac',
                  'https://support.apple.com/en-us/102343',
                ),
                const SizedBox(width: 16),
                _buildHelpLink(
                  'How to enable on iPhone/iPad',
                  'https://support.apple.com/guide/iphone/get-extensions-iphab0432bf6/ios',
                ),
              ],
            ),
          ] else ...[
            _buildHelpLink(
              'How to enable on iPhone/iPad',
              'https://support.apple.com/guide/iphone/get-extensions-iphab0432bf6/ios',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHelpLink(String text, String url) {
    return GestureDetector(
      onTap: () {
        // TODO: Open URL
        launchUrl(Uri.parse(url));
      },
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          color: Colors.blue,
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }

  String _getSelectedUserscriptNames() {
    final names = <String>[];
    for (final id in _selectedUserscripts) {
      try {
        final script = defaultUserScripts.firstWhere((script) => script.id == id);
        names.add(script.name);
      } catch (e) {
        // Script not found, skip
      }
    }
    return names.join(', ');
  }

  Future<void> _applySettings() async {
    setState(() {
      _isApplying = true;
      _applyProgress = 0.0;
    });

    try {
      // 1. Set filter selection based on chosen blocking level
      var updatedFilters = List<FilterList>.from(widget.filterManager.filterLists);

      switch (_selectedBlockingLevel) {
        case BlockingLevel.minimal:
          for (int i = 0; i < updatedFilters.length; i++) {
            updatedFilters[i] = updatedFilters[i].copyWith(
              isSelected: updatedFilters[i].name == 'AdGuard Base Filter',
            );
          }
          break;
        case BlockingLevel.recommended:
          // Disable all filters first
          for (int i = 0; i < updatedFilters.length; i++) {
            updatedFilters[i] = updatedFilters[i].copyWith(isSelected: false);
          }
          // Enable only the recommended filters
          final recommendedFilters = [
            'AdGuard Base Filter',
            'AdGuard Tracking Protection Filter',
            'AdGuard Annoyances Filter',
            'EasyPrivacy',
            'Online Malicious URL Blocklist',
            'd3Host List by d3ward',
            'Anti-Adblock List'
          ];
          for (int i = 0; i < updatedFilters.length; i++) {
            if (recommendedFilters.contains(updatedFilters[i].name)) {
              updatedFilters[i] = updatedFilters[i].copyWith(isSelected: true);
            }
          }
          break;
        case BlockingLevel.complete:
          for (int i = 0; i < updatedFilters.length; i++) {
            updatedFilters[i] = updatedFilters[i].copyWith(
              isSelected: updatedFilters[i].category != FilterListCategory.foreign,
            );
          }
          break;
      }

      // If Bypass Paywalls userscript is selected, also enable the required filter list
      if (bypassPaywallsScript != null && _selectedUserscripts.contains(bypassPaywallsScript!.id) && bypassPaywallsFilterName != null) {
        for (int i = 0; i < updatedFilters.length; i++) {
          if (updatedFilters[i].name == bypassPaywallsFilterName) {
            updatedFilters[i] = updatedFilters[i].copyWith(isSelected: true);
          }
        }
      }

      widget.filterManager.filterLists = updatedFilters;
      widget.filterManager.saveFilterLists();

      setState(() {
        _applyProgress = 0.3;
      });

      // 2. Enable/disable userscripts based on onboarding selection
      for (final script in widget.userScriptManager.userScripts) {
        final shouldEnable = _selectedUserscripts.contains(script.id);
        if (script.isEnabled != shouldEnable) {
          await widget.userScriptManager.toggleUserScript(script);
        }
      }

      setState(() {
        _applyProgress = 0.6;
      });

      // 3. Download and apply enabled filter lists
      final enabledFilters = widget.filterManager.filterLists.where((f) => f.isSelected).toList();
      await widget.filterManager.downloadAndApplyFilters(
        enabledFilters,
        progress: (progress) {
          setState(() {
            _applyProgress = 0.6 + (progress * 0.4); // 60% to 100%
          });
        },
      );

      // Mark onboarding as completed
      await FlutterWblockPlugin.setOnboardingCompleted(true);

      // Call the completion callback
      widget.onComplete?.call();
    } catch (e) {
      print('Error applying onboarding settings: $e');
    }
  }
}

class OnboardingDownloadView extends StatelessWidget {
  final double progress;

  const OnboardingDownloadView({
    super.key,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 300,
          child: Platform.isMacOS
              ? LinearProgressIndicator(
                  value: progress,
                  backgroundColor: MacosColors.quaternaryLabelColor,
                  valueColor: const AlwaysStoppedAnimation<Color>(MacosColors.systemBlueColor),
                )
              : LinearProgressIndicator(
                  value: progress,
                  backgroundColor: CupertinoColors.systemGrey4,
                  valueColor: const AlwaysStoppedAnimation<Color>(CupertinoColors.systemBlue),
                ),
        ),
        const SizedBox(height: 24),
        Column(
          children: [
            Text(
              'Downloading and installing filter lists...',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Platform.isMacOS ? MacosColors.labelColor : CupertinoColors.label,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Applying filters...',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Platform.isMacOS ? MacosColors.labelColor : CupertinoColors.label,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              'This may take awhile',
              style: TextStyle(
                fontSize: 12,
                color: Platform.isMacOS ? MacosColors.secondaryLabelColor : CupertinoColors.secondaryLabel,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
