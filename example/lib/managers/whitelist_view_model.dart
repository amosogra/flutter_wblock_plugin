import 'package:flutter/foundation.dart';
import 'package:flutter_wblock_plugin/flutter_wblock_plugin.dart';

enum WhitelistError {
  invalidDomain,
  duplicateDomain,
  unknown;
  
  String get localizedDescription {
    switch (this) {
      case WhitelistError.invalidDomain:
        return 'The domain is invalid. Please enter a valid domain name.';
      case WhitelistError.duplicateDomain:
        return 'This domain is already in the whitelist.';
      case WhitelistError.unknown:
        return 'An unknown error occurred.';
    }
  }
}

class WhitelistViewModel extends ChangeNotifier {
  List<String> _whitelistedDomains = [];
  bool _isLoading = false;

  // Getters
  List<String> get whitelistedDomains => _whitelistedDomains;
  bool get isLoading => _isLoading;

  // Setter for updating domains directly
  set whitelistedDomains(List<String> domains) {
    _whitelistedDomains = domains;
    notifyListeners();
  }

  WhitelistViewModel() {
    loadWhitelistedDomains();
  }

  Future<void> loadWhitelistedDomains() async {
    try {
      _isLoading = true;
      notifyListeners();

      final domains = await FlutterWblockPlugin.getWhitelistedDomains();
      _whitelistedDomains = domains;
    } catch (e) {
      debugPrint('Error loading whitelisted domains: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Result<void, WhitelistError> addDomain(String domain) {
    final trimmedDomain = domain.trim().toLowerCase();
    
    // Basic validation
    if (trimmedDomain.isEmpty || !_isValidDomain(trimmedDomain)) {
      return Result.failure(WhitelistError.invalidDomain);
    }
    
    // Check for duplicates
    if (_whitelistedDomains.contains(trimmedDomain)) {
      return Result.failure(WhitelistError.duplicateDomain);
    }
    
    try {
      // Add to native side
      FlutterWblockPlugin.addWhitelistedDomain(trimmedDomain);
      
      // Update local state
      _whitelistedDomains.add(trimmedDomain);
      notifyListeners();
      
      return Result.success(null);
    } catch (e) {
      debugPrint('Error adding whitelisted domain: $e');
      return Result.failure(WhitelistError.unknown);
    }
  }

  Future<void> removeDomain(String domain) async {
    try {
      await FlutterWblockPlugin.removeWhitelistedDomain(domain);
      
      _whitelistedDomains.remove(domain);
      notifyListeners();
    } catch (e) {
      debugPrint('Error removing whitelisted domain: $e');
    }
  }

  Future<void> updateDomains(List<String> domains) async {
    try {
      await FlutterWblockPlugin.updateWhitelistedDomains(domains);
      _whitelistedDomains = domains;
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating whitelisted domains: $e');
    }
  }

  bool _isValidDomain(String domain) {
    // Basic domain validation
    final domainRegex = RegExp(r'^[a-zA-Z0-9][a-zA-Z0-9-]*[a-zA-Z0-9]*\.?[a-zA-Z]{0,}$');
    return domainRegex.hasMatch(domain) && domain.length > 1;
  }
}

// Result type to match Swift's Result type
abstract class Result<T, E> {
  const Result();
  
  factory Result.success(T value) = Success<T, E>;
  factory Result.failure(E error) = Failure<T, E>;
  
  bool get isSuccess => this is Success<T, E>;
  bool get isFailure => this is Failure<T, E>;
  
  T? get value => isSuccess ? (this as Success<T, E>).value : null;
  E? get error => isFailure ? (this as Failure<T, E>).error : null;
}

class Success<T, E> extends Result<T, E> {
  final T value;
  const Success(this.value);
}

class Failure<T, E> extends Result<T, E> {
  final E error;
  const Failure(this.error);
}
