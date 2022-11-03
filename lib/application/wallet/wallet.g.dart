// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wallet.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// ignore_for_file: avoid_private_typedef_functions, non_constant_identifier_names, subtype_of_sealed_class, invalid_use_of_internal_member, unused_element, constant_identifier_names, unnecessary_raw_strings, library_private_types_in_public_api

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

String $_SessionNotifierHash() => r'd8503bab51cb04acb6f61cc18639f4e872be87dd';

/// See also [_SessionNotifier].
final _sessionNotifierProvider = NotifierProvider<_SessionNotifier, Session>(
  _SessionNotifier.new,
  name: r'_sessionNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : $_SessionNotifierHash,
);
typedef _SessionNotifierRef = NotifierProviderRef<Session>;

abstract class _$SessionNotifier extends Notifier<Session> {
  @override
  Session build();
}

String $_archethicWalletKeychainHash() =>
    r'7b944e97107af41e54c05f9f8e86e05bb2b75bfe';

/// See also [_archethicWalletKeychain].
final _archethicWalletKeychainProvider = AutoDisposeFutureProvider<Keychain?>(
  _archethicWalletKeychain,
  name: r'_archethicWalletKeychainProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : $_archethicWalletKeychainHash,
);
typedef _ArchethicWalletKeychainRef = AutoDisposeFutureProviderRef<Keychain?>;
