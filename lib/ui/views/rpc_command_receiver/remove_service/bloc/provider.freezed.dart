// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'provider.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$RemoveServiceConfirmationFormState {
  RPCCommand<SendTransactionRequest> get signTransactionCommand =>
      throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $RemoveServiceConfirmationFormStateCopyWith<
          RemoveServiceConfirmationFormState>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RemoveServiceConfirmationFormStateCopyWith<$Res> {
  factory $RemoveServiceConfirmationFormStateCopyWith(
          RemoveServiceConfirmationFormState value,
          $Res Function(RemoveServiceConfirmationFormState) then) =
      _$RemoveServiceConfirmationFormStateCopyWithImpl<$Res,
          RemoveServiceConfirmationFormState>;
  @useResult
  $Res call({RPCCommand<SendTransactionRequest> signTransactionCommand});

  $RPCCommandCopyWith<SendTransactionRequest, $Res> get signTransactionCommand;
}

/// @nodoc
class _$RemoveServiceConfirmationFormStateCopyWithImpl<$Res,
        $Val extends RemoveServiceConfirmationFormState>
    implements $RemoveServiceConfirmationFormStateCopyWith<$Res> {
  _$RemoveServiceConfirmationFormStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? signTransactionCommand = null,
  }) {
    return _then(_value.copyWith(
      signTransactionCommand: null == signTransactionCommand
          ? _value.signTransactionCommand
          : signTransactionCommand // ignore: cast_nullable_to_non_nullable
              as RPCCommand<SendTransactionRequest>,
    ) as $Val);
  }

  @override
  @pragma('vm:prefer-inline')
  $RPCCommandCopyWith<SendTransactionRequest, $Res> get signTransactionCommand {
    return $RPCCommandCopyWith<SendTransactionRequest, $Res>(
        _value.signTransactionCommand, (value) {
      return _then(_value.copyWith(signTransactionCommand: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$RemoveServiceConfirmationFormStateImplCopyWith<$Res>
    implements $RemoveServiceConfirmationFormStateCopyWith<$Res> {
  factory _$$RemoveServiceConfirmationFormStateImplCopyWith(
          _$RemoveServiceConfirmationFormStateImpl value,
          $Res Function(_$RemoveServiceConfirmationFormStateImpl) then) =
      __$$RemoveServiceConfirmationFormStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({RPCCommand<SendTransactionRequest> signTransactionCommand});

  @override
  $RPCCommandCopyWith<SendTransactionRequest, $Res> get signTransactionCommand;
}

/// @nodoc
class __$$RemoveServiceConfirmationFormStateImplCopyWithImpl<$Res>
    extends _$RemoveServiceConfirmationFormStateCopyWithImpl<$Res,
        _$RemoveServiceConfirmationFormStateImpl>
    implements _$$RemoveServiceConfirmationFormStateImplCopyWith<$Res> {
  __$$RemoveServiceConfirmationFormStateImplCopyWithImpl(
      _$RemoveServiceConfirmationFormStateImpl _value,
      $Res Function(_$RemoveServiceConfirmationFormStateImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? signTransactionCommand = null,
  }) {
    return _then(_$RemoveServiceConfirmationFormStateImpl(
      signTransactionCommand: null == signTransactionCommand
          ? _value.signTransactionCommand
          : signTransactionCommand // ignore: cast_nullable_to_non_nullable
              as RPCCommand<SendTransactionRequest>,
    ));
  }
}

/// @nodoc

class _$RemoveServiceConfirmationFormStateImpl
    extends _RemoveServiceConfirmationFormState {
  const _$RemoveServiceConfirmationFormStateImpl(
      {required this.signTransactionCommand})
      : super._();

  @override
  final RPCCommand<SendTransactionRequest> signTransactionCommand;

  @override
  String toString() {
    return 'RemoveServiceConfirmationFormState(signTransactionCommand: $signTransactionCommand)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RemoveServiceConfirmationFormStateImpl &&
            (identical(other.signTransactionCommand, signTransactionCommand) ||
                other.signTransactionCommand == signTransactionCommand));
  }

  @override
  int get hashCode => Object.hash(runtimeType, signTransactionCommand);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$RemoveServiceConfirmationFormStateImplCopyWith<
          _$RemoveServiceConfirmationFormStateImpl>
      get copyWith => __$$RemoveServiceConfirmationFormStateImplCopyWithImpl<
          _$RemoveServiceConfirmationFormStateImpl>(this, _$identity);
}

abstract class _RemoveServiceConfirmationFormState
    extends RemoveServiceConfirmationFormState {
  const factory _RemoveServiceConfirmationFormState(
      {required final RPCCommand<SendTransactionRequest>
          signTransactionCommand}) = _$RemoveServiceConfirmationFormStateImpl;
  const _RemoveServiceConfirmationFormState._() : super._();

  @override
  RPCCommand<SendTransactionRequest> get signTransactionCommand;
  @override
  @JsonKey(ignore: true)
  _$$RemoveServiceConfirmationFormStateImplCopyWith<
          _$RemoveServiceConfirmationFormStateImpl>
      get copyWith => throw _privateConstructorUsedError;
}
