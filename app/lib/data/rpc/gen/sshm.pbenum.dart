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

import 'package:protobuf/protobuf.dart' as $pb;

class SyncState_Phase extends $pb.ProtobufEnum {
  static const SyncState_Phase PHASE_UNSPECIFIED =
      SyncState_Phase._(0, _omitEnumNames ? '' : 'PHASE_UNSPECIFIED');
  static const SyncState_Phase OFF =
      SyncState_Phase._(1, _omitEnumNames ? '' : 'OFF');
  static const SyncState_Phase NOT_RUNNING =
      SyncState_Phase._(2, _omitEnumNames ? '' : 'NOT_RUNNING');
  static const SyncState_Phase NO_VAULT =
      SyncState_Phase._(3, _omitEnumNames ? '' : 'NO_VAULT');
  static const SyncState_Phase LOCKED =
      SyncState_Phase._(4, _omitEnumNames ? '' : 'LOCKED');
  static const SyncState_Phase PAIRING =
      SyncState_Phase._(5, _omitEnumNames ? '' : 'PAIRING');
  static const SyncState_Phase OFFLINE =
      SyncState_Phase._(6, _omitEnumNames ? '' : 'OFFLINE');
  static const SyncState_Phase SYNCED =
      SyncState_Phase._(7, _omitEnumNames ? '' : 'SYNCED');
  static const SyncState_Phase ERROR =
      SyncState_Phase._(8, _omitEnumNames ? '' : 'ERROR');

  static const $core.List<SyncState_Phase> values = <SyncState_Phase>[
    PHASE_UNSPECIFIED,
    OFF,
    NOT_RUNNING,
    NO_VAULT,
    LOCKED,
    PAIRING,
    OFFLINE,
    SYNCED,
    ERROR,
  ];

  static final $core.List<SyncState_Phase?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 8);
  static SyncState_Phase? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const SyncState_Phase._(super.value, super.name);
}

class Event_Kind extends $pb.ProtobufEnum {
  static const Event_Kind KIND_UNSPECIFIED =
      Event_Kind._(0, _omitEnumNames ? '' : 'KIND_UNSPECIFIED');
  static const Event_Kind HOSTS =
      Event_Kind._(1, _omitEnumNames ? '' : 'HOSTS');
  static const Event_Kind SYNC = Event_Kind._(2, _omitEnumNames ? '' : 'SYNC');

  static const $core.List<Event_Kind> values = <Event_Kind>[
    KIND_UNSPECIFIED,
    HOSTS,
    SYNC,
  ];

  static final $core.List<Event_Kind?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 2);
  static Event_Kind? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const Event_Kind._(super.value, super.name);
}

class Host_Auth extends $pb.ProtobufEnum {
  static const Host_Auth AUTH_UNSPECIFIED =
      Host_Auth._(0, _omitEnumNames ? '' : 'AUTH_UNSPECIFIED');
  static const Host_Auth PASSWORD =
      Host_Auth._(1, _omitEnumNames ? '' : 'PASSWORD');
  static const Host_Auth KEY = Host_Auth._(2, _omitEnumNames ? '' : 'KEY');
  static const Host_Auth AGENT = Host_Auth._(3, _omitEnumNames ? '' : 'AGENT');
  static const Host_Auth SAFE_KEY =
      Host_Auth._(4, _omitEnumNames ? '' : 'SAFE_KEY');

  static const $core.List<Host_Auth> values = <Host_Auth>[
    AUTH_UNSPECIFIED,
    PASSWORD,
    KEY,
    AGENT,
    SAFE_KEY,
  ];

  static final $core.List<Host_Auth?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 4);
  static Host_Auth? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const Host_Auth._(super.value, super.name);
}

class HostKey_Status extends $pb.ProtobufEnum {
  static const HostKey_Status STATUS_UNSPECIFIED =
      HostKey_Status._(0, _omitEnumNames ? '' : 'STATUS_UNSPECIFIED');
  static const HostKey_Status KNOWN =
      HostKey_Status._(1, _omitEnumNames ? '' : 'KNOWN');
  static const HostKey_Status UNKNOWN =
      HostKey_Status._(2, _omitEnumNames ? '' : 'UNKNOWN');
  static const HostKey_Status CHANGED =
      HostKey_Status._(3, _omitEnumNames ? '' : 'CHANGED');

  static const $core.List<HostKey_Status> values = <HostKey_Status>[
    STATUS_UNSPECIFIED,
    KNOWN,
    UNKNOWN,
    CHANGED,
  ];

  static final $core.List<HostKey_Status?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 3);
  static HostKey_Status? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const HostKey_Status._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
