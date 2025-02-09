// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'primary_currency.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$convertedValueHash() => r'95ca331144d703ff515b6ec618c8a18d7b18e25e';

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

/// See also [_convertedValue].
@ProviderFor(_convertedValue)
const _convertedValueProvider = _ConvertedValueFamily();

/// See also [_convertedValue].
class _ConvertedValueFamily extends Family<double> {
  /// See also [_convertedValue].
  const _ConvertedValueFamily();

  /// See also [_convertedValue].
  _ConvertedValueProvider call({
    required double amount,
    required double tokenPrice,
  }) {
    return _ConvertedValueProvider(
      amount: amount,
      tokenPrice: tokenPrice,
    );
  }

  @override
  _ConvertedValueProvider getProviderOverride(
    covariant _ConvertedValueProvider provider,
  ) {
    return call(
      amount: provider.amount,
      tokenPrice: provider.tokenPrice,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'_convertedValueProvider';
}

/// See also [_convertedValue].
class _ConvertedValueProvider extends AutoDisposeProvider<double> {
  /// See also [_convertedValue].
  _ConvertedValueProvider({
    required double amount,
    required double tokenPrice,
  }) : this._internal(
          (ref) => _convertedValue(
            ref as _ConvertedValueRef,
            amount: amount,
            tokenPrice: tokenPrice,
          ),
          from: _convertedValueProvider,
          name: r'_convertedValueProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$convertedValueHash,
          dependencies: _ConvertedValueFamily._dependencies,
          allTransitiveDependencies:
              _ConvertedValueFamily._allTransitiveDependencies,
          amount: amount,
          tokenPrice: tokenPrice,
        );

  _ConvertedValueProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.amount,
    required this.tokenPrice,
  }) : super.internal();

  final double amount;
  final double tokenPrice;

  @override
  Override overrideWith(
    double Function(_ConvertedValueRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: _ConvertedValueProvider._internal(
        (ref) => create(ref as _ConvertedValueRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        amount: amount,
        tokenPrice: tokenPrice,
      ),
    );
  }

  @override
  AutoDisposeProviderElement<double> createElement() {
    return _ConvertedValueProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is _ConvertedValueProvider &&
        other.amount == amount &&
        other.tokenPrice == tokenPrice;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, amount.hashCode);
    hash = _SystemHash.combine(hash, tokenPrice.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin _ConvertedValueRef on AutoDisposeProviderRef<double> {
  /// The parameter `amount` of this provider.
  double get amount;

  /// The parameter `tokenPrice` of this provider.
  double get tokenPrice;
}

class _ConvertedValueProviderElement extends AutoDisposeProviderElement<double>
    with _ConvertedValueRef {
  _ConvertedValueProviderElement(super.provider);

  @override
  double get amount => (origin as _ConvertedValueProvider).amount;
  @override
  double get tokenPrice => (origin as _ConvertedValueProvider).tokenPrice;
}

String _$convertedValueLabelHash() =>
    r'42367117477e6c1bfa11f61803a167f78a464692';

/// See also [_convertedValueLabel].
@ProviderFor(_convertedValueLabel)
const _convertedValueLabelProvider = _ConvertedValueLabelFamily();

/// See also [_convertedValueLabel].
class _ConvertedValueLabelFamily extends Family<String> {
  /// See also [_convertedValueLabel].
  const _ConvertedValueLabelFamily();

  /// See also [_convertedValueLabel].
  _ConvertedValueLabelProvider call({
    required double amount,
    required double tokenPrice,
    required BuildContext context,
  }) {
    return _ConvertedValueLabelProvider(
      amount: amount,
      tokenPrice: tokenPrice,
      context: context,
    );
  }

  @override
  _ConvertedValueLabelProvider getProviderOverride(
    covariant _ConvertedValueLabelProvider provider,
  ) {
    return call(
      amount: provider.amount,
      tokenPrice: provider.tokenPrice,
      context: provider.context,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'_convertedValueLabelProvider';
}

/// See also [_convertedValueLabel].
class _ConvertedValueLabelProvider extends AutoDisposeProvider<String> {
  /// See also [_convertedValueLabel].
  _ConvertedValueLabelProvider({
    required double amount,
    required double tokenPrice,
    required BuildContext context,
  }) : this._internal(
          (ref) => _convertedValueLabel(
            ref as _ConvertedValueLabelRef,
            amount: amount,
            tokenPrice: tokenPrice,
            context: context,
          ),
          from: _convertedValueLabelProvider,
          name: r'_convertedValueLabelProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$convertedValueLabelHash,
          dependencies: _ConvertedValueLabelFamily._dependencies,
          allTransitiveDependencies:
              _ConvertedValueLabelFamily._allTransitiveDependencies,
          amount: amount,
          tokenPrice: tokenPrice,
          context: context,
        );

  _ConvertedValueLabelProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.amount,
    required this.tokenPrice,
    required this.context,
  }) : super.internal();

  final double amount;
  final double tokenPrice;
  final BuildContext context;

  @override
  Override overrideWith(
    String Function(_ConvertedValueLabelRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: _ConvertedValueLabelProvider._internal(
        (ref) => create(ref as _ConvertedValueLabelRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        amount: amount,
        tokenPrice: tokenPrice,
        context: context,
      ),
    );
  }

  @override
  AutoDisposeProviderElement<String> createElement() {
    return _ConvertedValueLabelProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is _ConvertedValueLabelProvider &&
        other.amount == amount &&
        other.tokenPrice == tokenPrice &&
        other.context == context;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, amount.hashCode);
    hash = _SystemHash.combine(hash, tokenPrice.hashCode);
    hash = _SystemHash.combine(hash, context.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin _ConvertedValueLabelRef on AutoDisposeProviderRef<String> {
  /// The parameter `amount` of this provider.
  double get amount;

  /// The parameter `tokenPrice` of this provider.
  double get tokenPrice;

  /// The parameter `context` of this provider.
  BuildContext get context;
}

class _ConvertedValueLabelProviderElement
    extends AutoDisposeProviderElement<String> with _ConvertedValueLabelRef {
  _ConvertedValueLabelProviderElement(super.provider);

  @override
  double get amount => (origin as _ConvertedValueLabelProvider).amount;
  @override
  double get tokenPrice => (origin as _ConvertedValueLabelProvider).tokenPrice;
  @override
  BuildContext get context => (origin as _ConvertedValueLabelProvider).context;
}

String _$selectedPrimaryCurrencyHash() =>
    r'461c4d91fad8f2c6e7d605148b016131376e1293';

/// See also [_selectedPrimaryCurrency].
@ProviderFor(_selectedPrimaryCurrency)
final _selectedPrimaryCurrencyProvider =
    AutoDisposeProvider<AvailablePrimaryCurrency>.internal(
  _selectedPrimaryCurrency,
  name: r'_selectedPrimaryCurrencyProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$selectedPrimaryCurrencyHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _SelectedPrimaryCurrencyRef
    = AutoDisposeProviderRef<AvailablePrimaryCurrency>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
