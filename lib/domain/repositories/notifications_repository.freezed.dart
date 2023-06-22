// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'notifications_repository.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#custom-getters-and-methods');

TxSentEvent _$TxSentEventFromJson(Map<String, dynamic> json) {
  return _TxSentEvent.fromJson(json);
}

/// @nodoc
mixin _$TxSentEvent {
  String get txAddress => throw _privateConstructorUsedError;
  String get txChainGenesisAddress => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $TxSentEventCopyWith<TxSentEvent> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TxSentEventCopyWith<$Res> {
  factory $TxSentEventCopyWith(
          TxSentEvent value, $Res Function(TxSentEvent) then) =
      _$TxSentEventCopyWithImpl<$Res, TxSentEvent>;
  @useResult
  $Res call({String txAddress, String txChainGenesisAddress});
}

/// @nodoc
class _$TxSentEventCopyWithImpl<$Res, $Val extends TxSentEvent>
    implements $TxSentEventCopyWith<$Res> {
  _$TxSentEventCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? txAddress = null,
    Object? txChainGenesisAddress = null,
  }) {
    return _then(_value.copyWith(
      txAddress: null == txAddress
          ? _value.txAddress
          : txAddress // ignore: cast_nullable_to_non_nullable
              as String,
      txChainGenesisAddress: null == txChainGenesisAddress
          ? _value.txChainGenesisAddress
          : txChainGenesisAddress // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$_TxSentEventCopyWith<$Res>
    implements $TxSentEventCopyWith<$Res> {
  factory _$$_TxSentEventCopyWith(
          _$_TxSentEvent value, $Res Function(_$_TxSentEvent) then) =
      __$$_TxSentEventCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String txAddress, String txChainGenesisAddress});
}

/// @nodoc
class __$$_TxSentEventCopyWithImpl<$Res>
    extends _$TxSentEventCopyWithImpl<$Res, _$_TxSentEvent>
    implements _$$_TxSentEventCopyWith<$Res> {
  __$$_TxSentEventCopyWithImpl(
      _$_TxSentEvent _value, $Res Function(_$_TxSentEvent) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? txAddress = null,
    Object? txChainGenesisAddress = null,
  }) {
    return _then(_$_TxSentEvent(
      txAddress: null == txAddress
          ? _value.txAddress
          : txAddress // ignore: cast_nullable_to_non_nullable
              as String,
      txChainGenesisAddress: null == txChainGenesisAddress
          ? _value.txChainGenesisAddress
          : txChainGenesisAddress // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$_TxSentEvent extends _TxSentEvent {
  const _$_TxSentEvent(
      {required this.txAddress, required this.txChainGenesisAddress})
      : super._();

  factory _$_TxSentEvent.fromJson(Map<String, dynamic> json) =>
      _$$_TxSentEventFromJson(json);

  @override
  final String txAddress;
  @override
  final String txChainGenesisAddress;

  @override
  String toString() {
    return 'TxSentEvent(txAddress: $txAddress, txChainGenesisAddress: $txChainGenesisAddress)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$_TxSentEvent &&
            (identical(other.txAddress, txAddress) ||
                other.txAddress == txAddress) &&
            (identical(other.txChainGenesisAddress, txChainGenesisAddress) ||
                other.txChainGenesisAddress == txChainGenesisAddress));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode =>
      Object.hash(runtimeType, txAddress, txChainGenesisAddress);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$_TxSentEventCopyWith<_$_TxSentEvent> get copyWith =>
      __$$_TxSentEventCopyWithImpl<_$_TxSentEvent>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$_TxSentEventToJson(
      this,
    );
  }
}

abstract class _TxSentEvent extends TxSentEvent {
  const factory _TxSentEvent(
      {required final String txAddress,
      required final String txChainGenesisAddress}) = _$_TxSentEvent;
  const _TxSentEvent._() : super._();

  factory _TxSentEvent.fromJson(Map<String, dynamic> json) =
      _$_TxSentEvent.fromJson;

  @override
  String get txAddress;
  @override
  String get txChainGenesisAddress;
  @override
  @JsonKey(ignore: true)
  _$$_TxSentEventCopyWith<_$_TxSentEvent> get copyWith =>
      throw _privateConstructorUsedError;
}
