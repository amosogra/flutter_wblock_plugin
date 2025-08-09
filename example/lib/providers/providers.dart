import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_wblock_plugin_example/managers/app_filter_manager.dart';
import 'package:flutter_wblock_plugin_example/managers/user_script_manager.dart';
import 'package:flutter_wblock_plugin_example/managers/whitelist_view_model.dart';

// Main filter manager provider
final appFilterManagerProvider = ChangeNotifierProvider<AppFilterManager>((ref) {
  return AppFilterManager();
});

// User script manager provider
final userScriptManagerProvider = ChangeNotifierProvider<UserScriptManager>((ref) {
  return UserScriptManager();
});

// Whitelist view model provider
final whitelistViewModelProvider = ChangeNotifierProvider<WhitelistViewModel>((ref) {
  return WhitelistViewModel();
});

// Derived providers for commonly used values
final enabledListsCountProvider = Provider<int>((ref) {
  final filterManager = ref.watch(appFilterManagerProvider);
  return filterManager.filterLists.where((f) => f.isSelected).length;
});

final isLoadingProvider = Provider<bool>((ref) {
  return ref.watch(appFilterManagerProvider).isLoading;
});

final lastRuleCountProvider = Provider<int>((ref) {
  return ref.watch(appFilterManagerProvider).lastRuleCount;
});

// UI state providers
final showOnlyEnabledListsProvider = StateProvider<bool>((ref) => false);

// Sheet visibility providers
final showingAddFilterSheetProvider = StateProvider<bool>((ref) => false);
final showingLogsViewProvider = StateProvider<bool>((ref) => false);
final showingUserScriptsViewProvider = StateProvider<bool>((ref) => false);
final showingWhitelistSheetProvider = StateProvider<bool>((ref) => false);
