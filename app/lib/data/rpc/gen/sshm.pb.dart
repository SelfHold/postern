// This is a generated file - do not edit.
//
// Generated from sshm.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'sshm.pbenum.dart';

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'sshm.pbenum.dart';

class Empty extends $pb.GeneratedMessage {
  factory Empty() => Empty._();

  Empty._();

  factory Empty.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Empty()..mergeFromBuffer(data, registry);
  factory Empty.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Empty()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Empty',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'sshm.v1'),
      createEmptyInstance: Empty.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Empty clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Empty copyWith(void Function(Empty) updates) =>
      super.copyWith((message) => updates(message as Empty)) as Empty;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use Empty() / Empty.new instead')
  static Empty create() => Empty._();
  static $pb.GeneratedMessage $_createMessage() => Empty._();
  @$core.override
  Empty createEmptyInstance() => Empty._();
  @$core.pragma('dart2js:noInline')
  static Empty getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Empty>(Empty.$_createMessage);
  static Empty? _defaultInstance;
}

class State extends $pb.GeneratedMessage {
  factory State({
    $core.String? coreVersion,
    $core.String? coreBuild,
    $core.String? platform,
    SyncState? sync,
  }) {
    final result = State._();
    if (coreVersion != null) result.coreVersion = coreVersion;
    if (coreBuild != null) result.coreBuild = coreBuild;
    if (platform != null) result.platform = platform;
    if (sync != null) result.sync = sync;
    return result;
  }

  State._();

  factory State.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      State()..mergeFromBuffer(data, registry);
  factory State.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      State()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'State',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'sshm.v1'),
      createEmptyInstance: State.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'coreVersion')
    ..aOS(2, _omitFieldNames ? '' : 'coreBuild')
    ..aOS(3, _omitFieldNames ? '' : 'platform')
    ..aOM<SyncState>(4, _omitFieldNames ? '' : 'sync',
        subBuilder: SyncState.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  State clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  State copyWith(void Function(State) updates) =>
      super.copyWith((message) => updates(message as State)) as State;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use State() / State.new instead')
  static State create() => State._();
  static $pb.GeneratedMessage $_createMessage() => State._();
  @$core.override
  State createEmptyInstance() => State._();
  @$core.pragma('dart2js:noInline')
  static State getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<State>(State.$_createMessage);
  static State? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get coreVersion => $_getSZ(0);
  @$pb.TagNumber(1)
  set coreVersion($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasCoreVersion() => $_has(0);
  @$pb.TagNumber(1)
  void clearCoreVersion() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get coreBuild => $_getSZ(1);
  @$pb.TagNumber(2)
  set coreBuild($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasCoreBuild() => $_has(1);
  @$pb.TagNumber(2)
  void clearCoreBuild() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get platform => $_getSZ(2);
  @$pb.TagNumber(3)
  set platform($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasPlatform() => $_has(2);
  @$pb.TagNumber(3)
  void clearPlatform() => $_clearField(3);

  @$pb.TagNumber(4)
  SyncState get sync => $_getN(3);
  @$pb.TagNumber(4)
  set sync(SyncState value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasSync() => $_has(3);
  @$pb.TagNumber(4)
  void clearSync() => $_clearField(4);
  @$pb.TagNumber(4)
  SyncState ensureSync() => $_ensure(3);
}

class SyncState extends $pb.GeneratedMessage {
  factory SyncState({
    SyncState_Phase? phase,
    $core.bool? enabled,
    $core.bool? available,
    $core.String? pairingCode,
    $core.String? error,
    $core.bool? pending,
    $fixnum.Int64? lastSyncMs,
    $core.String? deviceName,
    $core.bool? sharedServers,
    $core.bool? safeKeys,
  }) {
    final result = SyncState._();
    if (phase != null) result.phase = phase;
    if (enabled != null) result.enabled = enabled;
    if (available != null) result.available = available;
    if (pairingCode != null) result.pairingCode = pairingCode;
    if (error != null) result.error = error;
    if (pending != null) result.pending = pending;
    if (lastSyncMs != null) result.lastSyncMs = lastSyncMs;
    if (deviceName != null) result.deviceName = deviceName;
    if (sharedServers != null) result.sharedServers = sharedServers;
    if (safeKeys != null) result.safeKeys = safeKeys;
    return result;
  }

  SyncState._();

  factory SyncState.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SyncState()..mergeFromBuffer(data, registry);
  factory SyncState.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SyncState()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SyncState',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'sshm.v1'),
      createEmptyInstance: SyncState.$_createMessage)
    ..aE<SyncState_Phase>(1, _omitFieldNames ? '' : 'phase',
        enumValues: SyncState_Phase.values)
    ..aOB(2, _omitFieldNames ? '' : 'enabled')
    ..aOB(3, _omitFieldNames ? '' : 'available')
    ..aOS(4, _omitFieldNames ? '' : 'pairingCode')
    ..aOS(5, _omitFieldNames ? '' : 'error')
    ..aOB(6, _omitFieldNames ? '' : 'pending')
    ..aInt64(7, _omitFieldNames ? '' : 'lastSyncMs')
    ..aOS(8, _omitFieldNames ? '' : 'deviceName')
    ..aOB(9, _omitFieldNames ? '' : 'sharedServers')
    ..aOB(10, _omitFieldNames ? '' : 'safeKeys')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SyncState clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SyncState copyWith(void Function(SyncState) updates) =>
      super.copyWith((message) => updates(message as SyncState)) as SyncState;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use SyncState() / SyncState.new instead')
  static SyncState create() => SyncState._();
  static $pb.GeneratedMessage $_createMessage() => SyncState._();
  @$core.override
  SyncState createEmptyInstance() => SyncState._();
  @$core.pragma('dart2js:noInline')
  static SyncState getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SyncState>(SyncState.$_createMessage);
  static SyncState? _defaultInstance;

  @$pb.TagNumber(1)
  SyncState_Phase get phase => $_getN(0);
  @$pb.TagNumber(1)
  set phase(SyncState_Phase value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasPhase() => $_has(0);
  @$pb.TagNumber(1)
  void clearPhase() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.bool get enabled => $_getBF(1);
  @$pb.TagNumber(2)
  set enabled($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasEnabled() => $_has(1);
  @$pb.TagNumber(2)
  void clearEnabled() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.bool get available => $_getBF(2);
  @$pb.TagNumber(3)
  set available($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasAvailable() => $_has(2);
  @$pb.TagNumber(3)
  void clearAvailable() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get pairingCode => $_getSZ(3);
  @$pb.TagNumber(4)
  set pairingCode($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasPairingCode() => $_has(3);
  @$pb.TagNumber(4)
  void clearPairingCode() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get error => $_getSZ(4);
  @$pb.TagNumber(5)
  set error($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasError() => $_has(4);
  @$pb.TagNumber(5)
  void clearError() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.bool get pending => $_getBF(5);
  @$pb.TagNumber(6)
  set pending($core.bool value) => $_setBool(5, value);
  @$pb.TagNumber(6)
  $core.bool hasPending() => $_has(5);
  @$pb.TagNumber(6)
  void clearPending() => $_clearField(6);

  @$pb.TagNumber(7)
  $fixnum.Int64 get lastSyncMs => $_getI64(6);
  @$pb.TagNumber(7)
  set lastSyncMs($fixnum.Int64 value) => $_setInt64(6, value);
  @$pb.TagNumber(7)
  $core.bool hasLastSyncMs() => $_has(6);
  @$pb.TagNumber(7)
  void clearLastSyncMs() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.String get deviceName => $_getSZ(7);
  @$pb.TagNumber(8)
  set deviceName($core.String value) => $_setString(7, value);
  @$pb.TagNumber(8)
  $core.bool hasDeviceName() => $_has(7);
  @$pb.TagNumber(8)
  void clearDeviceName() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.bool get sharedServers => $_getBF(8);
  @$pb.TagNumber(9)
  set sharedServers($core.bool value) => $_setBool(8, value);
  @$pb.TagNumber(9)
  $core.bool hasSharedServers() => $_has(8);
  @$pb.TagNumber(9)
  void clearSharedServers() => $_clearField(9);

  @$pb.TagNumber(10)
  $core.bool get safeKeys => $_getBF(9);
  @$pb.TagNumber(10)
  set safeKeys($core.bool value) => $_setBool(9, value);
  @$pb.TagNumber(10)
  $core.bool hasSafeKeys() => $_has(9);
  @$pb.TagNumber(10)
  void clearSafeKeys() => $_clearField(10);
}

class Event extends $pb.GeneratedMessage {
  factory Event({
    Event_Kind? kind,
    $core.String? message,
  }) {
    final result = Event._();
    if (kind != null) result.kind = kind;
    if (message != null) result.message = message;
    return result;
  }

  Event._();

  factory Event.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Event()..mergeFromBuffer(data, registry);
  factory Event.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Event()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Event',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'sshm.v1'),
      createEmptyInstance: Event.$_createMessage)
    ..aE<Event_Kind>(1, _omitFieldNames ? '' : 'kind',
        enumValues: Event_Kind.values)
    ..aOS(2, _omitFieldNames ? '' : 'message')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Event clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Event copyWith(void Function(Event) updates) =>
      super.copyWith((message) => updates(message as Event)) as Event;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use Event() / Event.new instead')
  static Event create() => Event._();
  static $pb.GeneratedMessage $_createMessage() => Event._();
  @$core.override
  Event createEmptyInstance() => Event._();
  @$core.pragma('dart2js:noInline')
  static Event getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Event>(Event.$_createMessage);
  static Event? _defaultInstance;

  @$pb.TagNumber(1)
  Event_Kind get kind => $_getN(0);
  @$pb.TagNumber(1)
  set kind(Event_Kind value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasKind() => $_has(0);
  @$pb.TagNumber(1)
  void clearKind() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get message => $_getSZ(1);
  @$pb.TagNumber(2)
  set message($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasMessage() => $_has(1);
  @$pb.TagNumber(2)
  void clearMessage() => $_clearField(2);
}

class Host extends $pb.GeneratedMessage {
  factory Host({
    $core.String? id,
    $core.String? name,
    $core.String? group,
    $core.String? address,
    $core.int? port,
    $core.String? user,
    Host_Auth? auth,
    $core.String? password,
    $core.String? privateKey,
    $core.String? passphrase,
    $core.Iterable<$core.String>? hostKeys,
    $fixnum.Int64? updatedMs,
    $core.String? notes,
    $core.String? startDir,
    $core.String? keyId,
    $core.Iterable<$core.String>? tags,
    $core.String? jumpId,
  }) {
    final result = Host._();
    if (id != null) result.id = id;
    if (name != null) result.name = name;
    if (group != null) result.group = group;
    if (address != null) result.address = address;
    if (port != null) result.port = port;
    if (user != null) result.user = user;
    if (auth != null) result.auth = auth;
    if (password != null) result.password = password;
    if (privateKey != null) result.privateKey = privateKey;
    if (passphrase != null) result.passphrase = passphrase;
    if (hostKeys != null) result.hostKeys.addAll(hostKeys);
    if (updatedMs != null) result.updatedMs = updatedMs;
    if (notes != null) result.notes = notes;
    if (startDir != null) result.startDir = startDir;
    if (keyId != null) result.keyId = keyId;
    if (tags != null) result.tags.addAll(tags);
    if (jumpId != null) result.jumpId = jumpId;
    return result;
  }

  Host._();

  factory Host.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Host()..mergeFromBuffer(data, registry);
  factory Host.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Host()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Host',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'sshm.v1'),
      createEmptyInstance: Host.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'name')
    ..aOS(3, _omitFieldNames ? '' : 'group')
    ..aOS(4, _omitFieldNames ? '' : 'address')
    ..aI(5, _omitFieldNames ? '' : 'port', fieldType: $pb.PbFieldType.OU3)
    ..aOS(6, _omitFieldNames ? '' : 'user')
    ..aE<Host_Auth>(7, _omitFieldNames ? '' : 'auth',
        enumValues: Host_Auth.values)
    ..aOS(8, _omitFieldNames ? '' : 'password')
    ..aOS(9, _omitFieldNames ? '' : 'privateKey')
    ..aOS(10, _omitFieldNames ? '' : 'passphrase')
    ..pPS(11, _omitFieldNames ? '' : 'hostKeys')
    ..aInt64(12, _omitFieldNames ? '' : 'updatedMs')
    ..aOS(13, _omitFieldNames ? '' : 'notes')
    ..aOS(14, _omitFieldNames ? '' : 'startDir')
    ..aOS(15, _omitFieldNames ? '' : 'keyId')
    ..pPS(16, _omitFieldNames ? '' : 'tags')
    ..aOS(17, _omitFieldNames ? '' : 'jumpId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Host clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Host copyWith(void Function(Host) updates) =>
      super.copyWith((message) => updates(message as Host)) as Host;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use Host() / Host.new instead')
  static Host create() => Host._();
  static $pb.GeneratedMessage $_createMessage() => Host._();
  @$core.override
  Host createEmptyInstance() => Host._();
  @$core.pragma('dart2js:noInline')
  static Host getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Host>(Host.$_createMessage);
  static Host? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get name => $_getSZ(1);
  @$pb.TagNumber(2)
  set name($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasName() => $_has(1);
  @$pb.TagNumber(2)
  void clearName() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get group => $_getSZ(2);
  @$pb.TagNumber(3)
  set group($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasGroup() => $_has(2);
  @$pb.TagNumber(3)
  void clearGroup() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get address => $_getSZ(3);
  @$pb.TagNumber(4)
  set address($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasAddress() => $_has(3);
  @$pb.TagNumber(4)
  void clearAddress() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.int get port => $_getIZ(4);
  @$pb.TagNumber(5)
  set port($core.int value) => $_setUnsignedInt32(4, value);
  @$pb.TagNumber(5)
  $core.bool hasPort() => $_has(4);
  @$pb.TagNumber(5)
  void clearPort() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get user => $_getSZ(5);
  @$pb.TagNumber(6)
  set user($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasUser() => $_has(5);
  @$pb.TagNumber(6)
  void clearUser() => $_clearField(6);

  @$pb.TagNumber(7)
  Host_Auth get auth => $_getN(6);
  @$pb.TagNumber(7)
  set auth(Host_Auth value) => $_setField(7, value);
  @$pb.TagNumber(7)
  $core.bool hasAuth() => $_has(6);
  @$pb.TagNumber(7)
  void clearAuth() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.String get password => $_getSZ(7);
  @$pb.TagNumber(8)
  set password($core.String value) => $_setString(7, value);
  @$pb.TagNumber(8)
  $core.bool hasPassword() => $_has(7);
  @$pb.TagNumber(8)
  void clearPassword() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.String get privateKey => $_getSZ(8);
  @$pb.TagNumber(9)
  set privateKey($core.String value) => $_setString(8, value);
  @$pb.TagNumber(9)
  $core.bool hasPrivateKey() => $_has(8);
  @$pb.TagNumber(9)
  void clearPrivateKey() => $_clearField(9);

  @$pb.TagNumber(10)
  $core.String get passphrase => $_getSZ(9);
  @$pb.TagNumber(10)
  set passphrase($core.String value) => $_setString(9, value);
  @$pb.TagNumber(10)
  $core.bool hasPassphrase() => $_has(9);
  @$pb.TagNumber(10)
  void clearPassphrase() => $_clearField(10);

  @$pb.TagNumber(11)
  $pb.PbList<$core.String> get hostKeys => $_getList(10);

  @$pb.TagNumber(12)
  $fixnum.Int64 get updatedMs => $_getI64(11);
  @$pb.TagNumber(12)
  set updatedMs($fixnum.Int64 value) => $_setInt64(11, value);
  @$pb.TagNumber(12)
  $core.bool hasUpdatedMs() => $_has(11);
  @$pb.TagNumber(12)
  void clearUpdatedMs() => $_clearField(12);

  @$pb.TagNumber(13)
  $core.String get notes => $_getSZ(12);
  @$pb.TagNumber(13)
  set notes($core.String value) => $_setString(12, value);
  @$pb.TagNumber(13)
  $core.bool hasNotes() => $_has(12);
  @$pb.TagNumber(13)
  void clearNotes() => $_clearField(13);

  @$pb.TagNumber(14)
  $core.String get startDir => $_getSZ(13);
  @$pb.TagNumber(14)
  set startDir($core.String value) => $_setString(13, value);
  @$pb.TagNumber(14)
  $core.bool hasStartDir() => $_has(13);
  @$pb.TagNumber(14)
  void clearStartDir() => $_clearField(14);

  @$pb.TagNumber(15)
  $core.String get keyId => $_getSZ(14);
  @$pb.TagNumber(15)
  set keyId($core.String value) => $_setString(14, value);
  @$pb.TagNumber(15)
  $core.bool hasKeyId() => $_has(14);
  @$pb.TagNumber(15)
  void clearKeyId() => $_clearField(15);

  @$pb.TagNumber(16)
  $pb.PbList<$core.String> get tags => $_getList(15);

  @$pb.TagNumber(17)
  $core.String get jumpId => $_getSZ(16);
  @$pb.TagNumber(17)
  set jumpId($core.String value) => $_setString(16, value);
  @$pb.TagNumber(17)
  $core.bool hasJumpId() => $_has(16);
  @$pb.TagNumber(17)
  void clearJumpId() => $_clearField(17);
}

class HostList extends $pb.GeneratedMessage {
  factory HostList({
    $core.Iterable<Host>? hosts,
  }) {
    final result = HostList._();
    if (hosts != null) result.hosts.addAll(hosts);
    return result;
  }

  HostList._();

  factory HostList.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      HostList()..mergeFromBuffer(data, registry);
  factory HostList.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      HostList()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'HostList',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'sshm.v1'),
      createEmptyInstance: HostList.$_createMessage)
    ..pPM<Host>(1, _omitFieldNames ? '' : 'hosts',
        subBuilder: Host.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  HostList clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  HostList copyWith(void Function(HostList) updates) =>
      super.copyWith((message) => updates(message as HostList)) as HostList;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use HostList() / HostList.new instead')
  static HostList create() => HostList._();
  static $pb.GeneratedMessage $_createMessage() => HostList._();
  @$core.override
  HostList createEmptyInstance() => HostList._();
  @$core.pragma('dart2js:noInline')
  static HostList getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<HostList>(HostList.$_createMessage);
  static HostList? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<Host> get hosts => $_getList(0);
}

class HostRef extends $pb.GeneratedMessage {
  factory HostRef({
    $core.String? id,
  }) {
    final result = HostRef._();
    if (id != null) result.id = id;
    return result;
  }

  HostRef._();

  factory HostRef.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      HostRef()..mergeFromBuffer(data, registry);
  factory HostRef.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      HostRef()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'HostRef',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'sshm.v1'),
      createEmptyInstance: HostRef.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  HostRef clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  HostRef copyWith(void Function(HostRef) updates) =>
      super.copyWith((message) => updates(message as HostRef)) as HostRef;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use HostRef() / HostRef.new instead')
  static HostRef create() => HostRef._();
  static $pb.GeneratedMessage $_createMessage() => HostRef._();
  @$core.override
  HostRef createEmptyInstance() => HostRef._();
  @$core.pragma('dart2js:noInline')
  static HostRef getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<HostRef>(HostRef.$_createMessage);
  static HostRef? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);
}

/// ProbeHostKey answers with the key the server shows.
class HostKey extends $pb.GeneratedMessage {
  factory HostKey({
    HostKey_Status? status,
    $core.String? key,
    $core.String? fingerprint,
    $core.String? type,
  }) {
    final result = HostKey._();
    if (status != null) result.status = status;
    if (key != null) result.key = key;
    if (fingerprint != null) result.fingerprint = fingerprint;
    if (type != null) result.type = type;
    return result;
  }

  HostKey._();

  factory HostKey.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      HostKey()..mergeFromBuffer(data, registry);
  factory HostKey.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      HostKey()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'HostKey',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'sshm.v1'),
      createEmptyInstance: HostKey.$_createMessage)
    ..aE<HostKey_Status>(1, _omitFieldNames ? '' : 'status',
        enumValues: HostKey_Status.values)
    ..aOS(2, _omitFieldNames ? '' : 'key')
    ..aOS(3, _omitFieldNames ? '' : 'fingerprint')
    ..aOS(4, _omitFieldNames ? '' : 'type')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  HostKey clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  HostKey copyWith(void Function(HostKey) updates) =>
      super.copyWith((message) => updates(message as HostKey)) as HostKey;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use HostKey() / HostKey.new instead')
  static HostKey create() => HostKey._();
  static $pb.GeneratedMessage $_createMessage() => HostKey._();
  @$core.override
  HostKey createEmptyInstance() => HostKey._();
  @$core.pragma('dart2js:noInline')
  static HostKey getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<HostKey>(HostKey.$_createMessage);
  static HostKey? _defaultInstance;

  @$pb.TagNumber(1)
  HostKey_Status get status => $_getN(0);
  @$pb.TagNumber(1)
  set status(HostKey_Status value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasStatus() => $_has(0);
  @$pb.TagNumber(1)
  void clearStatus() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get key => $_getSZ(1);
  @$pb.TagNumber(2)
  set key($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasKey() => $_has(1);
  @$pb.TagNumber(2)
  void clearKey() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get fingerprint => $_getSZ(2);
  @$pb.TagNumber(3)
  set fingerprint($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasFingerprint() => $_has(2);
  @$pb.TagNumber(3)
  void clearFingerprint() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get type => $_getSZ(3);
  @$pb.TagNumber(4)
  set type($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasType() => $_has(3);
  @$pb.TagNumber(4)
  void clearType() => $_clearField(4);
}

class TrustRequest extends $pb.GeneratedMessage {
  factory TrustRequest({
    $core.String? id,
    $core.String? key,
    $core.bool? replace,
  }) {
    final result = TrustRequest._();
    if (id != null) result.id = id;
    if (key != null) result.key = key;
    if (replace != null) result.replace = replace;
    return result;
  }

  TrustRequest._();

  factory TrustRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      TrustRequest()..mergeFromBuffer(data, registry);
  factory TrustRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      TrustRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'TrustRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'sshm.v1'),
      createEmptyInstance: TrustRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'key')
    ..aOB(3, _omitFieldNames ? '' : 'replace')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TrustRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TrustRequest copyWith(void Function(TrustRequest) updates) =>
      super.copyWith((message) => updates(message as TrustRequest))
          as TrustRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use TrustRequest() / TrustRequest.new instead')
  static TrustRequest create() => TrustRequest._();
  static $pb.GeneratedMessage $_createMessage() => TrustRequest._();
  @$core.override
  TrustRequest createEmptyInstance() => TrustRequest._();
  @$core.pragma('dart2js:noInline')
  static TrustRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<TrustRequest>(
          TrustRequest.$_createMessage);
  static TrustRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get key => $_getSZ(1);
  @$pb.TagNumber(2)
  set key($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasKey() => $_has(1);
  @$pb.TagNumber(2)
  void clearKey() => $_clearField(2);

  /// replace = true drops the keys on record (the server's key changed and
  /// the user confirmed it); otherwise the key is added.
  @$pb.TagNumber(3)
  $core.bool get replace => $_getBF(2);
  @$pb.TagNumber(3)
  set replace($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasReplace() => $_has(2);
  @$pb.TagNumber(3)
  void clearReplace() => $_clearField(3);
}

class ShellIn_Open extends $pb.GeneratedMessage {
  factory ShellIn_Open({
    $core.String? hostId,
    $core.int? cols,
    $core.int? rows,
  }) {
    final result = ShellIn_Open._();
    if (hostId != null) result.hostId = hostId;
    if (cols != null) result.cols = cols;
    if (rows != null) result.rows = rows;
    return result;
  }

  ShellIn_Open._();

  factory ShellIn_Open.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ShellIn_Open()..mergeFromBuffer(data, registry);
  factory ShellIn_Open.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ShellIn_Open()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ShellIn.Open',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'sshm.v1'),
      createEmptyInstance: ShellIn_Open.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'hostId')
    ..aI(2, _omitFieldNames ? '' : 'cols', fieldType: $pb.PbFieldType.OU3)
    ..aI(3, _omitFieldNames ? '' : 'rows', fieldType: $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ShellIn_Open clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ShellIn_Open copyWith(void Function(ShellIn_Open) updates) =>
      super.copyWith((message) => updates(message as ShellIn_Open))
          as ShellIn_Open;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ShellIn_Open() / ShellIn_Open.new instead')
  static ShellIn_Open create() => ShellIn_Open._();
  static $pb.GeneratedMessage $_createMessage() => ShellIn_Open._();
  @$core.override
  ShellIn_Open createEmptyInstance() => ShellIn_Open._();
  @$core.pragma('dart2js:noInline')
  static ShellIn_Open getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ShellIn_Open>(
          ShellIn_Open.$_createMessage);
  static ShellIn_Open? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get hostId => $_getSZ(0);
  @$pb.TagNumber(1)
  set hostId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasHostId() => $_has(0);
  @$pb.TagNumber(1)
  void clearHostId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get cols => $_getIZ(1);
  @$pb.TagNumber(2)
  set cols($core.int value) => $_setUnsignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasCols() => $_has(1);
  @$pb.TagNumber(2)
  void clearCols() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get rows => $_getIZ(2);
  @$pb.TagNumber(3)
  set rows($core.int value) => $_setUnsignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasRows() => $_has(2);
  @$pb.TagNumber(3)
  void clearRows() => $_clearField(3);
}

class ShellIn_Resize extends $pb.GeneratedMessage {
  factory ShellIn_Resize({
    $core.int? cols,
    $core.int? rows,
  }) {
    final result = ShellIn_Resize._();
    if (cols != null) result.cols = cols;
    if (rows != null) result.rows = rows;
    return result;
  }

  ShellIn_Resize._();

  factory ShellIn_Resize.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ShellIn_Resize()..mergeFromBuffer(data, registry);
  factory ShellIn_Resize.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ShellIn_Resize()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ShellIn.Resize',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'sshm.v1'),
      createEmptyInstance: ShellIn_Resize.$_createMessage)
    ..aI(1, _omitFieldNames ? '' : 'cols', fieldType: $pb.PbFieldType.OU3)
    ..aI(2, _omitFieldNames ? '' : 'rows', fieldType: $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ShellIn_Resize clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ShellIn_Resize copyWith(void Function(ShellIn_Resize) updates) =>
      super.copyWith((message) => updates(message as ShellIn_Resize))
          as ShellIn_Resize;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ShellIn_Resize() / ShellIn_Resize.new instead')
  static ShellIn_Resize create() => ShellIn_Resize._();
  static $pb.GeneratedMessage $_createMessage() => ShellIn_Resize._();
  @$core.override
  ShellIn_Resize createEmptyInstance() => ShellIn_Resize._();
  @$core.pragma('dart2js:noInline')
  static ShellIn_Resize getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ShellIn_Resize>(
          ShellIn_Resize.$_createMessage);
  static ShellIn_Resize? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get cols => $_getIZ(0);
  @$pb.TagNumber(1)
  set cols($core.int value) => $_setUnsignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasCols() => $_has(0);
  @$pb.TagNumber(1)
  void clearCols() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get rows => $_getIZ(1);
  @$pb.TagNumber(2)
  set rows($core.int value) => $_setUnsignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasRows() => $_has(1);
  @$pb.TagNumber(2)
  void clearRows() => $_clearField(2);
}

enum ShellIn_Msg { open, data, resize, notSet }

class ShellIn extends $pb.GeneratedMessage {
  factory ShellIn({
    ShellIn_Open? open,
    $core.List<$core.int>? data,
    ShellIn_Resize? resize,
  }) {
    final result = ShellIn._();
    if (open != null) result.open = open;
    if (data != null) result.data = data;
    if (resize != null) result.resize = resize;
    return result;
  }

  ShellIn._();

  factory ShellIn.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ShellIn()..mergeFromBuffer(data, registry);
  factory ShellIn.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ShellIn()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, ShellIn_Msg> _ShellIn_MsgByTag = {
    1: ShellIn_Msg.open,
    2: ShellIn_Msg.data,
    3: ShellIn_Msg.resize,
    0: ShellIn_Msg.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ShellIn',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'sshm.v1'),
      createEmptyInstance: ShellIn.$_createMessage)
    ..oo(0, [1, 2, 3])
    ..aOM<ShellIn_Open>(1, _omitFieldNames ? '' : 'open',
        subBuilder: ShellIn_Open.$_createMessage)
    ..a<$core.List<$core.int>>(
        2, _omitFieldNames ? '' : 'data', $pb.PbFieldType.OY)
    ..aOM<ShellIn_Resize>(3, _omitFieldNames ? '' : 'resize',
        subBuilder: ShellIn_Resize.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ShellIn clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ShellIn copyWith(void Function(ShellIn) updates) =>
      super.copyWith((message) => updates(message as ShellIn)) as ShellIn;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ShellIn() / ShellIn.new instead')
  static ShellIn create() => ShellIn._();
  static $pb.GeneratedMessage $_createMessage() => ShellIn._();
  @$core.override
  ShellIn createEmptyInstance() => ShellIn._();
  @$core.pragma('dart2js:noInline')
  static ShellIn getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ShellIn>(ShellIn.$_createMessage);
  static ShellIn? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  @$pb.TagNumber(3)
  ShellIn_Msg whichMsg() => _ShellIn_MsgByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  @$pb.TagNumber(3)
  void clearMsg() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  ShellIn_Open get open => $_getN(0);
  @$pb.TagNumber(1)
  set open(ShellIn_Open value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasOpen() => $_has(0);
  @$pb.TagNumber(1)
  void clearOpen() => $_clearField(1);
  @$pb.TagNumber(1)
  ShellIn_Open ensureOpen() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.List<$core.int> get data => $_getN(1);
  @$pb.TagNumber(2)
  set data($core.List<$core.int> value) => $_setBytes(1, value);
  @$pb.TagNumber(2)
  $core.bool hasData() => $_has(1);
  @$pb.TagNumber(2)
  void clearData() => $_clearField(2);

  @$pb.TagNumber(3)
  ShellIn_Resize get resize => $_getN(2);
  @$pb.TagNumber(3)
  set resize(ShellIn_Resize value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasResize() => $_has(2);
  @$pb.TagNumber(3)
  void clearResize() => $_clearField(3);
  @$pb.TagNumber(3)
  ShellIn_Resize ensureResize() => $_ensure(2);
}

enum ShellOut_Msg { opened, data, closed, notSet }

class ShellOut extends $pb.GeneratedMessage {
  factory ShellOut({
    $core.bool? opened,
    $core.List<$core.int>? data,
    $core.String? closed,
  }) {
    final result = ShellOut._();
    if (opened != null) result.opened = opened;
    if (data != null) result.data = data;
    if (closed != null) result.closed = closed;
    return result;
  }

  ShellOut._();

  factory ShellOut.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ShellOut()..mergeFromBuffer(data, registry);
  factory ShellOut.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ShellOut()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, ShellOut_Msg> _ShellOut_MsgByTag = {
    1: ShellOut_Msg.opened,
    2: ShellOut_Msg.data,
    3: ShellOut_Msg.closed,
    0: ShellOut_Msg.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ShellOut',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'sshm.v1'),
      createEmptyInstance: ShellOut.$_createMessage)
    ..oo(0, [1, 2, 3])
    ..aOB(1, _omitFieldNames ? '' : 'opened')
    ..a<$core.List<$core.int>>(
        2, _omitFieldNames ? '' : 'data', $pb.PbFieldType.OY)
    ..aOS(3, _omitFieldNames ? '' : 'closed')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ShellOut clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ShellOut copyWith(void Function(ShellOut) updates) =>
      super.copyWith((message) => updates(message as ShellOut)) as ShellOut;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ShellOut() / ShellOut.new instead')
  static ShellOut create() => ShellOut._();
  static $pb.GeneratedMessage $_createMessage() => ShellOut._();
  @$core.override
  ShellOut createEmptyInstance() => ShellOut._();
  @$core.pragma('dart2js:noInline')
  static ShellOut getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ShellOut>(ShellOut.$_createMessage);
  static ShellOut? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  @$pb.TagNumber(3)
  ShellOut_Msg whichMsg() => _ShellOut_MsgByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  @$pb.TagNumber(3)
  void clearMsg() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  $core.bool get opened => $_getBF(0);
  @$pb.TagNumber(1)
  set opened($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasOpened() => $_has(0);
  @$pb.TagNumber(1)
  void clearOpened() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.List<$core.int> get data => $_getN(1);
  @$pb.TagNumber(2)
  set data($core.List<$core.int> value) => $_setBytes(1, value);
  @$pb.TagNumber(2)
  $core.bool hasData() => $_has(1);
  @$pb.TagNumber(2)
  void clearData() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get closed => $_getSZ(2);
  @$pb.TagNumber(3)
  set closed($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasClosed() => $_has(2);
  @$pb.TagNumber(3)
  void clearClosed() => $_clearField(3);
}

class Entry extends $pb.GeneratedMessage {
  factory Entry({
    $core.String? name,
    $core.bool? dir,
    $core.bool? link,
    $fixnum.Int64? size,
    $fixnum.Int64? modifiedMs,
    $core.int? mode,
  }) {
    final result = Entry._();
    if (name != null) result.name = name;
    if (dir != null) result.dir = dir;
    if (link != null) result.link = link;
    if (size != null) result.size = size;
    if (modifiedMs != null) result.modifiedMs = modifiedMs;
    if (mode != null) result.mode = mode;
    return result;
  }

  Entry._();

  factory Entry.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Entry()..mergeFromBuffer(data, registry);
  factory Entry.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Entry()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Entry',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'sshm.v1'),
      createEmptyInstance: Entry.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'name')
    ..aOB(2, _omitFieldNames ? '' : 'dir')
    ..aOB(3, _omitFieldNames ? '' : 'link')
    ..aInt64(4, _omitFieldNames ? '' : 'size')
    ..aInt64(5, _omitFieldNames ? '' : 'modifiedMs')
    ..aI(6, _omitFieldNames ? '' : 'mode', fieldType: $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Entry clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Entry copyWith(void Function(Entry) updates) =>
      super.copyWith((message) => updates(message as Entry)) as Entry;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use Entry() / Entry.new instead')
  static Entry create() => Entry._();
  static $pb.GeneratedMessage $_createMessage() => Entry._();
  @$core.override
  Entry createEmptyInstance() => Entry._();
  @$core.pragma('dart2js:noInline')
  static Entry getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Entry>(Entry.$_createMessage);
  static Entry? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get name => $_getSZ(0);
  @$pb.TagNumber(1)
  set name($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasName() => $_has(0);
  @$pb.TagNumber(1)
  void clearName() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.bool get dir => $_getBF(1);
  @$pb.TagNumber(2)
  set dir($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasDir() => $_has(1);
  @$pb.TagNumber(2)
  void clearDir() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.bool get link => $_getBF(2);
  @$pb.TagNumber(3)
  set link($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasLink() => $_has(2);
  @$pb.TagNumber(3)
  void clearLink() => $_clearField(3);

  @$pb.TagNumber(4)
  $fixnum.Int64 get size => $_getI64(3);
  @$pb.TagNumber(4)
  set size($fixnum.Int64 value) => $_setInt64(3, value);
  @$pb.TagNumber(4)
  $core.bool hasSize() => $_has(3);
  @$pb.TagNumber(4)
  void clearSize() => $_clearField(4);

  @$pb.TagNumber(5)
  $fixnum.Int64 get modifiedMs => $_getI64(4);
  @$pb.TagNumber(5)
  set modifiedMs($fixnum.Int64 value) => $_setInt64(4, value);
  @$pb.TagNumber(5)
  $core.bool hasModifiedMs() => $_has(4);
  @$pb.TagNumber(5)
  void clearModifiedMs() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.int get mode => $_getIZ(5);
  @$pb.TagNumber(6)
  set mode($core.int value) => $_setUnsignedInt32(5, value);
  @$pb.TagNumber(6)
  $core.bool hasMode() => $_has(5);
  @$pb.TagNumber(6)
  void clearMode() => $_clearField(6);
}

class DirRequest extends $pb.GeneratedMessage {
  factory DirRequest({
    $core.String? side,
    $core.String? path,
  }) {
    final result = DirRequest._();
    if (side != null) result.side = side;
    if (path != null) result.path = path;
    return result;
  }

  DirRequest._();

  factory DirRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      DirRequest()..mergeFromBuffer(data, registry);
  factory DirRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      DirRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DirRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'sshm.v1'),
      createEmptyInstance: DirRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'side')
    ..aOS(2, _omitFieldNames ? '' : 'path')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DirRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DirRequest copyWith(void Function(DirRequest) updates) =>
      super.copyWith((message) => updates(message as DirRequest)) as DirRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use DirRequest() / DirRequest.new instead')
  static DirRequest create() => DirRequest._();
  static $pb.GeneratedMessage $_createMessage() => DirRequest._();
  @$core.override
  DirRequest createEmptyInstance() => DirRequest._();
  @$core.pragma('dart2js:noInline')
  static DirRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DirRequest>(DirRequest.$_createMessage);
  static DirRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get side => $_getSZ(0);
  @$pb.TagNumber(1)
  set side($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSide() => $_has(0);
  @$pb.TagNumber(1)
  void clearSide() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get path => $_getSZ(1);
  @$pb.TagNumber(2)
  set path($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasPath() => $_has(1);
  @$pb.TagNumber(2)
  void clearPath() => $_clearField(2);
}

class DirListing extends $pb.GeneratedMessage {
  factory DirListing({
    $core.String? path,
    $core.Iterable<Entry>? entries,
  }) {
    final result = DirListing._();
    if (path != null) result.path = path;
    if (entries != null) result.entries.addAll(entries);
    return result;
  }

  DirListing._();

  factory DirListing.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      DirListing()..mergeFromBuffer(data, registry);
  factory DirListing.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      DirListing()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DirListing',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'sshm.v1'),
      createEmptyInstance: DirListing.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'path')
    ..pPM<Entry>(2, _omitFieldNames ? '' : 'entries',
        subBuilder: Entry.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DirListing clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DirListing copyWith(void Function(DirListing) updates) =>
      super.copyWith((message) => updates(message as DirListing)) as DirListing;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use DirListing() / DirListing.new instead')
  static DirListing create() => DirListing._();
  static $pb.GeneratedMessage $_createMessage() => DirListing._();
  @$core.override
  DirListing createEmptyInstance() => DirListing._();
  @$core.pragma('dart2js:noInline')
  static DirListing getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DirListing>(DirListing.$_createMessage);
  static DirListing? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get path => $_getSZ(0);
  @$pb.TagNumber(1)
  set path($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasPath() => $_has(0);
  @$pb.TagNumber(1)
  void clearPath() => $_clearField(1);

  @$pb.TagNumber(2)
  $pb.PbList<Entry> get entries => $_getList(1);
}

class PathRequest extends $pb.GeneratedMessage {
  factory PathRequest({
    $core.String? side,
    $core.String? path,
  }) {
    final result = PathRequest._();
    if (side != null) result.side = side;
    if (path != null) result.path = path;
    return result;
  }

  PathRequest._();

  factory PathRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PathRequest()..mergeFromBuffer(data, registry);
  factory PathRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PathRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PathRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'sshm.v1'),
      createEmptyInstance: PathRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'side')
    ..aOS(2, _omitFieldNames ? '' : 'path')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PathRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PathRequest copyWith(void Function(PathRequest) updates) =>
      super.copyWith((message) => updates(message as PathRequest))
          as PathRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use PathRequest() / PathRequest.new instead')
  static PathRequest create() => PathRequest._();
  static $pb.GeneratedMessage $_createMessage() => PathRequest._();
  @$core.override
  PathRequest createEmptyInstance() => PathRequest._();
  @$core.pragma('dart2js:noInline')
  static PathRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<PathRequest>(
          PathRequest.$_createMessage);
  static PathRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get side => $_getSZ(0);
  @$pb.TagNumber(1)
  set side($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSide() => $_has(0);
  @$pb.TagNumber(1)
  void clearSide() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get path => $_getSZ(1);
  @$pb.TagNumber(2)
  set path($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasPath() => $_has(1);
  @$pb.TagNumber(2)
  void clearPath() => $_clearField(2);
}

class PathsRequest extends $pb.GeneratedMessage {
  factory PathsRequest({
    $core.String? side,
    $core.Iterable<$core.String>? paths,
  }) {
    final result = PathsRequest._();
    if (side != null) result.side = side;
    if (paths != null) result.paths.addAll(paths);
    return result;
  }

  PathsRequest._();

  factory PathsRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PathsRequest()..mergeFromBuffer(data, registry);
  factory PathsRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PathsRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PathsRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'sshm.v1'),
      createEmptyInstance: PathsRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'side')
    ..pPS(2, _omitFieldNames ? '' : 'paths')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PathsRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PathsRequest copyWith(void Function(PathsRequest) updates) =>
      super.copyWith((message) => updates(message as PathsRequest))
          as PathsRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use PathsRequest() / PathsRequest.new instead')
  static PathsRequest create() => PathsRequest._();
  static $pb.GeneratedMessage $_createMessage() => PathsRequest._();
  @$core.override
  PathsRequest createEmptyInstance() => PathsRequest._();
  @$core.pragma('dart2js:noInline')
  static PathsRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<PathsRequest>(
          PathsRequest.$_createMessage);
  static PathsRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get side => $_getSZ(0);
  @$pb.TagNumber(1)
  set side($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSide() => $_has(0);
  @$pb.TagNumber(1)
  void clearSide() => $_clearField(1);

  @$pb.TagNumber(2)
  $pb.PbList<$core.String> get paths => $_getList(1);
}

class RenameRequest extends $pb.GeneratedMessage {
  factory RenameRequest({
    $core.String? side,
    $core.String? from,
    $core.String? to,
  }) {
    final result = RenameRequest._();
    if (side != null) result.side = side;
    if (from != null) result.from = from;
    if (to != null) result.to = to;
    return result;
  }

  RenameRequest._();

  factory RenameRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RenameRequest()..mergeFromBuffer(data, registry);
  factory RenameRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RenameRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RenameRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'sshm.v1'),
      createEmptyInstance: RenameRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'side')
    ..aOS(2, _omitFieldNames ? '' : 'from')
    ..aOS(3, _omitFieldNames ? '' : 'to')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RenameRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RenameRequest copyWith(void Function(RenameRequest) updates) =>
      super.copyWith((message) => updates(message as RenameRequest))
          as RenameRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use RenameRequest() / RenameRequest.new instead')
  static RenameRequest create() => RenameRequest._();
  static $pb.GeneratedMessage $_createMessage() => RenameRequest._();
  @$core.override
  RenameRequest createEmptyInstance() => RenameRequest._();
  @$core.pragma('dart2js:noInline')
  static RenameRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<RenameRequest>(
          RenameRequest.$_createMessage);
  static RenameRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get side => $_getSZ(0);
  @$pb.TagNumber(1)
  set side($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSide() => $_has(0);
  @$pb.TagNumber(1)
  void clearSide() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get from => $_getSZ(1);
  @$pb.TagNumber(2)
  set from($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasFrom() => $_has(1);
  @$pb.TagNumber(2)
  void clearFrom() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get to => $_getSZ(2);
  @$pb.TagNumber(3)
  set to($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasTo() => $_has(2);
  @$pb.TagNumber(3)
  void clearTo() => $_clearField(3);
}

class TransferRequest extends $pb.GeneratedMessage {
  factory TransferRequest({
    $core.String? srcSide,
    $core.Iterable<$core.String>? srcPaths,
    $core.String? dstSide,
    $core.String? dstDir,
    $core.bool? move,
    $core.bool? overwrite,
  }) {
    final result = TransferRequest._();
    if (srcSide != null) result.srcSide = srcSide;
    if (srcPaths != null) result.srcPaths.addAll(srcPaths);
    if (dstSide != null) result.dstSide = dstSide;
    if (dstDir != null) result.dstDir = dstDir;
    if (move != null) result.move = move;
    if (overwrite != null) result.overwrite = overwrite;
    return result;
  }

  TransferRequest._();

  factory TransferRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      TransferRequest()..mergeFromBuffer(data, registry);
  factory TransferRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      TransferRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'TransferRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'sshm.v1'),
      createEmptyInstance: TransferRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'srcSide')
    ..pPS(2, _omitFieldNames ? '' : 'srcPaths')
    ..aOS(3, _omitFieldNames ? '' : 'dstSide')
    ..aOS(4, _omitFieldNames ? '' : 'dstDir')
    ..aOB(5, _omitFieldNames ? '' : 'move')
    ..aOB(6, _omitFieldNames ? '' : 'overwrite')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TransferRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TransferRequest copyWith(void Function(TransferRequest) updates) =>
      super.copyWith((message) => updates(message as TransferRequest))
          as TransferRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use TransferRequest() / TransferRequest.new instead')
  static TransferRequest create() => TransferRequest._();
  static $pb.GeneratedMessage $_createMessage() => TransferRequest._();
  @$core.override
  TransferRequest createEmptyInstance() => TransferRequest._();
  @$core.pragma('dart2js:noInline')
  static TransferRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<TransferRequest>(
          TransferRequest.$_createMessage);
  static TransferRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get srcSide => $_getSZ(0);
  @$pb.TagNumber(1)
  set srcSide($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSrcSide() => $_has(0);
  @$pb.TagNumber(1)
  void clearSrcSide() => $_clearField(1);

  @$pb.TagNumber(2)
  $pb.PbList<$core.String> get srcPaths => $_getList(1);

  @$pb.TagNumber(3)
  $core.String get dstSide => $_getSZ(2);
  @$pb.TagNumber(3)
  set dstSide($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasDstSide() => $_has(2);
  @$pb.TagNumber(3)
  void clearDstSide() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get dstDir => $_getSZ(3);
  @$pb.TagNumber(4)
  set dstDir($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasDstDir() => $_has(3);
  @$pb.TagNumber(4)
  void clearDstDir() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.bool get move => $_getBF(4);
  @$pb.TagNumber(5)
  set move($core.bool value) => $_setBool(4, value);
  @$pb.TagNumber(5)
  $core.bool hasMove() => $_has(4);
  @$pb.TagNumber(5)
  void clearMove() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.bool get overwrite => $_getBF(5);
  @$pb.TagNumber(6)
  set overwrite($core.bool value) => $_setBool(5, value);
  @$pb.TagNumber(6)
  $core.bool hasOverwrite() => $_has(5);
  @$pb.TagNumber(6)
  void clearOverwrite() => $_clearField(6);
}

class TransferProgress extends $pb.GeneratedMessage {
  factory TransferProgress({
    $fixnum.Int64? doneBytes,
    $fixnum.Int64? totalBytes,
    $core.int? doneFiles,
    $core.int? totalFiles,
    $core.String? current,
    $core.bool? finished,
  }) {
    final result = TransferProgress._();
    if (doneBytes != null) result.doneBytes = doneBytes;
    if (totalBytes != null) result.totalBytes = totalBytes;
    if (doneFiles != null) result.doneFiles = doneFiles;
    if (totalFiles != null) result.totalFiles = totalFiles;
    if (current != null) result.current = current;
    if (finished != null) result.finished = finished;
    return result;
  }

  TransferProgress._();

  factory TransferProgress.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      TransferProgress()..mergeFromBuffer(data, registry);
  factory TransferProgress.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      TransferProgress()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'TransferProgress',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'sshm.v1'),
      createEmptyInstance: TransferProgress.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'doneBytes')
    ..aInt64(2, _omitFieldNames ? '' : 'totalBytes')
    ..aI(3, _omitFieldNames ? '' : 'doneFiles')
    ..aI(4, _omitFieldNames ? '' : 'totalFiles')
    ..aOS(5, _omitFieldNames ? '' : 'current')
    ..aOB(6, _omitFieldNames ? '' : 'finished')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TransferProgress clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TransferProgress copyWith(void Function(TransferProgress) updates) =>
      super.copyWith((message) => updates(message as TransferProgress))
          as TransferProgress;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use TransferProgress() / TransferProgress.new instead')
  static TransferProgress create() => TransferProgress._();
  static $pb.GeneratedMessage $_createMessage() => TransferProgress._();
  @$core.override
  TransferProgress createEmptyInstance() => TransferProgress._();
  @$core.pragma('dart2js:noInline')
  static TransferProgress getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<TransferProgress>(
          TransferProgress.$_createMessage);
  static TransferProgress? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get doneBytes => $_getI64(0);
  @$pb.TagNumber(1)
  set doneBytes($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasDoneBytes() => $_has(0);
  @$pb.TagNumber(1)
  void clearDoneBytes() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get totalBytes => $_getI64(1);
  @$pb.TagNumber(2)
  set totalBytes($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasTotalBytes() => $_has(1);
  @$pb.TagNumber(2)
  void clearTotalBytes() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get doneFiles => $_getIZ(2);
  @$pb.TagNumber(3)
  set doneFiles($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasDoneFiles() => $_has(2);
  @$pb.TagNumber(3)
  void clearDoneFiles() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.int get totalFiles => $_getIZ(3);
  @$pb.TagNumber(4)
  set totalFiles($core.int value) => $_setSignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasTotalFiles() => $_has(3);
  @$pb.TagNumber(4)
  void clearTotalFiles() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get current => $_getSZ(4);
  @$pb.TagNumber(5)
  set current($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasCurrent() => $_has(4);
  @$pb.TagNumber(5)
  void clearCurrent() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.bool get finished => $_getBF(5);
  @$pb.TagNumber(6)
  set finished($core.bool value) => $_setBool(5, value);
  @$pb.TagNumber(6)
  $core.bool hasFinished() => $_has(5);
  @$pb.TagNumber(6)
  void clearFinished() => $_clearField(6);
}

class SafeKey extends $pb.GeneratedMessage {
  factory SafeKey({
    $core.String? id,
    $core.String? title,
    $core.String? keyType,
    $core.String? fingerprint,
    $core.String? publicKey,
    $core.String? comment,
  }) {
    final result = SafeKey._();
    if (id != null) result.id = id;
    if (title != null) result.title = title;
    if (keyType != null) result.keyType = keyType;
    if (fingerprint != null) result.fingerprint = fingerprint;
    if (publicKey != null) result.publicKey = publicKey;
    if (comment != null) result.comment = comment;
    return result;
  }

  SafeKey._();

  factory SafeKey.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SafeKey()..mergeFromBuffer(data, registry);
  factory SafeKey.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SafeKey()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SafeKey',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'sshm.v1'),
      createEmptyInstance: SafeKey.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'title')
    ..aOS(3, _omitFieldNames ? '' : 'keyType')
    ..aOS(4, _omitFieldNames ? '' : 'fingerprint')
    ..aOS(5, _omitFieldNames ? '' : 'publicKey')
    ..aOS(6, _omitFieldNames ? '' : 'comment')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SafeKey clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SafeKey copyWith(void Function(SafeKey) updates) =>
      super.copyWith((message) => updates(message as SafeKey)) as SafeKey;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use SafeKey() / SafeKey.new instead')
  static SafeKey create() => SafeKey._();
  static $pb.GeneratedMessage $_createMessage() => SafeKey._();
  @$core.override
  SafeKey createEmptyInstance() => SafeKey._();
  @$core.pragma('dart2js:noInline')
  static SafeKey getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SafeKey>(SafeKey.$_createMessage);
  static SafeKey? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get title => $_getSZ(1);
  @$pb.TagNumber(2)
  set title($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasTitle() => $_has(1);
  @$pb.TagNumber(2)
  void clearTitle() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get keyType => $_getSZ(2);
  @$pb.TagNumber(3)
  set keyType($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasKeyType() => $_has(2);
  @$pb.TagNumber(3)
  void clearKeyType() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get fingerprint => $_getSZ(3);
  @$pb.TagNumber(4)
  set fingerprint($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasFingerprint() => $_has(3);
  @$pb.TagNumber(4)
  void clearFingerprint() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get publicKey => $_getSZ(4);
  @$pb.TagNumber(5)
  set publicKey($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasPublicKey() => $_has(4);
  @$pb.TagNumber(5)
  void clearPublicKey() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get comment => $_getSZ(5);
  @$pb.TagNumber(6)
  set comment($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasComment() => $_has(5);
  @$pb.TagNumber(6)
  void clearComment() => $_clearField(6);
}

class SafeKeyList extends $pb.GeneratedMessage {
  factory SafeKeyList({
    $core.Iterable<SafeKey>? keys,
    $core.String? unavailable,
  }) {
    final result = SafeKeyList._();
    if (keys != null) result.keys.addAll(keys);
    if (unavailable != null) result.unavailable = unavailable;
    return result;
  }

  SafeKeyList._();

  factory SafeKeyList.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SafeKeyList()..mergeFromBuffer(data, registry);
  factory SafeKeyList.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SafeKeyList()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SafeKeyList',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'sshm.v1'),
      createEmptyInstance: SafeKeyList.$_createMessage)
    ..pPM<SafeKey>(1, _omitFieldNames ? '' : 'keys',
        subBuilder: SafeKey.$_createMessage)
    ..aOS(2, _omitFieldNames ? '' : 'unavailable')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SafeKeyList clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SafeKeyList copyWith(void Function(SafeKeyList) updates) =>
      super.copyWith((message) => updates(message as SafeKeyList))
          as SafeKeyList;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use SafeKeyList() / SafeKeyList.new instead')
  static SafeKeyList create() => SafeKeyList._();
  static $pb.GeneratedMessage $_createMessage() => SafeKeyList._();
  @$core.override
  SafeKeyList createEmptyInstance() => SafeKeyList._();
  @$core.pragma('dart2js:noInline')
  static SafeKeyList getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SafeKeyList>(
          SafeKeyList.$_createMessage);
  static SafeKeyList? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<SafeKey> get keys => $_getList(0);

  /// Why the list is empty when it is not available ("" = it is).
  @$pb.TagNumber(2)
  $core.String get unavailable => $_getSZ(1);
  @$pb.TagNumber(2)
  set unavailable($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasUnavailable() => $_has(1);
  @$pb.TagNumber(2)
  void clearUnavailable() => $_clearField(2);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
