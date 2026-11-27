// This is a generated file - do not edit.
//
// Generated from postern.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports
// ignore_for_file: unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use emptyDescriptor instead')
const Empty$json = {
  '1': 'Empty',
};

/// Descriptor for `Empty`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List emptyDescriptor =
    $convert.base64Decode('CgVFbXB0eQ==');

@$core.Deprecated('Use stateDescriptor instead')
const State$json = {
  '1': 'State',
  '2': [
    {'1': 'core_version', '3': 1, '4': 1, '5': 9, '10': 'coreVersion'},
    {'1': 'core_build', '3': 2, '4': 1, '5': 9, '10': 'coreBuild'},
    {'1': 'platform', '3': 3, '4': 1, '5': 9, '10': 'platform'},
    {
      '1': 'sync',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.selfhold.postern.v1.SyncState',
      '10': 'sync'
    },
  ],
};

/// Descriptor for `State`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List stateDescriptor = $convert.base64Decode(
    'CgVTdGF0ZRIhCgxjb3JlX3ZlcnNpb24YASABKAlSC2NvcmVWZXJzaW9uEh0KCmNvcmVfYnVpbG'
    'QYAiABKAlSCWNvcmVCdWlsZBIaCghwbGF0Zm9ybRgDIAEoCVIIcGxhdGZvcm0SMgoEc3luYxgE'
    'IAEoCzIeLnNlbGZob2xkLnBvc3Rlcm4udjEuU3luY1N0YXRlUgRzeW5j');

@$core.Deprecated('Use syncStateDescriptor instead')
const SyncState$json = {
  '1': 'SyncState',
  '2': [
    {
      '1': 'phase',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.selfhold.postern.v1.SyncState.Phase',
      '10': 'phase'
    },
    {'1': 'enabled', '3': 2, '4': 1, '5': 8, '10': 'enabled'},
    {'1': 'available', '3': 3, '4': 1, '5': 8, '10': 'available'},
    {'1': 'pairing_code', '3': 4, '4': 1, '5': 9, '10': 'pairingCode'},
    {'1': 'error', '3': 5, '4': 1, '5': 9, '10': 'error'},
    {'1': 'pending', '3': 6, '4': 1, '5': 8, '10': 'pending'},
    {'1': 'last_sync_ms', '3': 7, '4': 1, '5': 3, '10': 'lastSyncMs'},
    {'1': 'device_name', '3': 8, '4': 1, '5': 9, '10': 'deviceName'},
    {'1': 'shared_servers', '3': 9, '4': 1, '5': 8, '10': 'sharedServers'},
    {'1': 'safe_keys', '3': 10, '4': 1, '5': 8, '10': 'safeKeys'},
  ],
  '4': [SyncState_Phase$json],
};

@$core.Deprecated('Use syncStateDescriptor instead')
const SyncState_Phase$json = {
  '1': 'Phase',
  '2': [
    {'1': 'PHASE_UNSPECIFIED', '2': 0},
    {'1': 'OFF', '2': 1},
    {'1': 'NOT_RUNNING', '2': 2},
    {'1': 'NO_VAULT', '2': 3},
    {'1': 'LOCKED', '2': 4},
    {'1': 'PAIRING', '2': 5},
    {'1': 'OFFLINE', '2': 6},
    {'1': 'SYNCED', '2': 7},
    {'1': 'ERROR', '2': 8},
  ],
};

/// Descriptor for `SyncState`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List syncStateDescriptor = $convert.base64Decode(
    'CglTeW5jU3RhdGUSOgoFcGhhc2UYASABKA4yJC5zZWxmaG9sZC5wb3N0ZXJuLnYxLlN5bmNTdG'
    'F0ZS5QaGFzZVIFcGhhc2USGAoHZW5hYmxlZBgCIAEoCFIHZW5hYmxlZBIcCglhdmFpbGFibGUY'
    'AyABKAhSCWF2YWlsYWJsZRIhCgxwYWlyaW5nX2NvZGUYBCABKAlSC3BhaXJpbmdDb2RlEhQKBW'
    'Vycm9yGAUgASgJUgVlcnJvchIYCgdwZW5kaW5nGAYgASgIUgdwZW5kaW5nEiAKDGxhc3Rfc3lu'
    'Y19tcxgHIAEoA1IKbGFzdFN5bmNNcxIfCgtkZXZpY2VfbmFtZRgIIAEoCVIKZGV2aWNlTmFtZR'
    'IlCg5zaGFyZWRfc2VydmVycxgJIAEoCFINc2hhcmVkU2VydmVycxIbCglzYWZlX2tleXMYCiAB'
    'KAhSCHNhZmVLZXlzIoMBCgVQaGFzZRIVChFQSEFTRV9VTlNQRUNJRklFRBAAEgcKA09GRhABEg'
    '8KC05PVF9SVU5OSU5HEAISDAoITk9fVkFVTFQQAxIKCgZMT0NLRUQQBBILCgdQQUlSSU5HEAUS'
    'CwoHT0ZGTElORRAGEgoKBlNZTkNFRBAHEgkKBUVSUk9SEAg=');

@$core.Deprecated('Use eventDescriptor instead')
const Event$json = {
  '1': 'Event',
  '2': [
    {
      '1': 'kind',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.selfhold.postern.v1.Event.Kind',
      '10': 'kind'
    },
    {'1': 'message', '3': 2, '4': 1, '5': 9, '10': 'message'},
  ],
  '4': [Event_Kind$json],
};

@$core.Deprecated('Use eventDescriptor instead')
const Event_Kind$json = {
  '1': 'Kind',
  '2': [
    {'1': 'KIND_UNSPECIFIED', '2': 0},
    {'1': 'HOSTS', '2': 1},
    {'1': 'SYNC', '2': 2},
  ],
};

/// Descriptor for `Event`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List eventDescriptor = $convert.base64Decode(
    'CgVFdmVudBIzCgRraW5kGAEgASgOMh8uc2VsZmhvbGQucG9zdGVybi52MS5FdmVudC5LaW5kUg'
    'RraW5kEhgKB21lc3NhZ2UYAiABKAlSB21lc3NhZ2UiMQoES2luZBIUChBLSU5EX1VOU1BFQ0lG'
    'SUVEEAASCQoFSE9TVFMQARIICgRTWU5DEAI=');

@$core.Deprecated('Use hostDescriptor instead')
const Host$json = {
  '1': 'Host',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'name', '3': 2, '4': 1, '5': 9, '10': 'name'},
    {'1': 'group', '3': 3, '4': 1, '5': 9, '10': 'group'},
    {'1': 'address', '3': 4, '4': 1, '5': 9, '10': 'address'},
    {'1': 'port', '3': 5, '4': 1, '5': 13, '10': 'port'},
    {'1': 'user', '3': 6, '4': 1, '5': 9, '10': 'user'},
    {
      '1': 'auth',
      '3': 7,
      '4': 1,
      '5': 14,
      '6': '.selfhold.postern.v1.Host.Auth',
      '10': 'auth'
    },
    {'1': 'password', '3': 8, '4': 1, '5': 9, '10': 'password'},
    {'1': 'private_key', '3': 9, '4': 1, '5': 9, '10': 'privateKey'},
    {'1': 'passphrase', '3': 10, '4': 1, '5': 9, '10': 'passphrase'},
    {'1': 'host_keys', '3': 11, '4': 3, '5': 9, '10': 'hostKeys'},
    {'1': 'updated_ms', '3': 12, '4': 1, '5': 3, '10': 'updatedMs'},
    {'1': 'notes', '3': 13, '4': 1, '5': 9, '10': 'notes'},
    {'1': 'start_dir', '3': 14, '4': 1, '5': 9, '10': 'startDir'},
    {'1': 'key_id', '3': 15, '4': 1, '5': 9, '10': 'keyId'},
    {'1': 'tags', '3': 16, '4': 3, '5': 9, '10': 'tags'},
    {'1': 'jump_id', '3': 17, '4': 1, '5': 9, '10': 'jumpId'},
  ],
  '4': [Host_Auth$json],
};

@$core.Deprecated('Use hostDescriptor instead')
const Host_Auth$json = {
  '1': 'Auth',
  '2': [
    {'1': 'AUTH_UNSPECIFIED', '2': 0},
    {'1': 'PASSWORD', '2': 1},
    {'1': 'KEY', '2': 2},
    {'1': 'AGENT', '2': 3},
    {'1': 'SAFE_KEY', '2': 4},
  ],
};

/// Descriptor for `Host`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List hostDescriptor = $convert.base64Decode(
    'CgRIb3N0Eg4KAmlkGAEgASgJUgJpZBISCgRuYW1lGAIgASgJUgRuYW1lEhQKBWdyb3VwGAMgAS'
    'gJUgVncm91cBIYCgdhZGRyZXNzGAQgASgJUgdhZGRyZXNzEhIKBHBvcnQYBSABKA1SBHBvcnQS'
    'EgoEdXNlchgGIAEoCVIEdXNlchIyCgRhdXRoGAcgASgOMh4uc2VsZmhvbGQucG9zdGVybi52MS'
    '5Ib3N0LkF1dGhSBGF1dGgSGgoIcGFzc3dvcmQYCCABKAlSCHBhc3N3b3JkEh8KC3ByaXZhdGVf'
    'a2V5GAkgASgJUgpwcml2YXRlS2V5Eh4KCnBhc3NwaHJhc2UYCiABKAlSCnBhc3NwaHJhc2USGw'
    'oJaG9zdF9rZXlzGAsgAygJUghob3N0S2V5cxIdCgp1cGRhdGVkX21zGAwgASgDUgl1cGRhdGVk'
    'TXMSFAoFbm90ZXMYDSABKAlSBW5vdGVzEhsKCXN0YXJ0X2RpchgOIAEoCVIIc3RhcnREaXISFQ'
    'oGa2V5X2lkGA8gASgJUgVrZXlJZBISCgR0YWdzGBAgAygJUgR0YWdzEhcKB2p1bXBfaWQYESAB'
    'KAlSBmp1bXBJZCJMCgRBdXRoEhQKEEFVVEhfVU5TUEVDSUZJRUQQABIMCghQQVNTV09SRBABEg'
    'cKA0tFWRACEgkKBUFHRU5UEAMSDAoIU0FGRV9LRVkQBA==');

@$core.Deprecated('Use hostListDescriptor instead')
const HostList$json = {
  '1': 'HostList',
  '2': [
    {
      '1': 'hosts',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.selfhold.postern.v1.Host',
      '10': 'hosts'
    },
  ],
};

/// Descriptor for `HostList`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List hostListDescriptor = $convert.base64Decode(
    'CghIb3N0TGlzdBIvCgVob3N0cxgBIAMoCzIZLnNlbGZob2xkLnBvc3Rlcm4udjEuSG9zdFIFaG'
    '9zdHM=');

@$core.Deprecated('Use hostRefDescriptor instead')
const HostRef$json = {
  '1': 'HostRef',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
  ],
};

/// Descriptor for `HostRef`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List hostRefDescriptor =
    $convert.base64Decode('CgdIb3N0UmVmEg4KAmlkGAEgASgJUgJpZA==');

@$core.Deprecated('Use hostKeyDescriptor instead')
const HostKey$json = {
  '1': 'HostKey',
  '2': [
    {
      '1': 'status',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.selfhold.postern.v1.HostKey.Status',
      '10': 'status'
    },
    {'1': 'key', '3': 2, '4': 1, '5': 9, '10': 'key'},
    {'1': 'fingerprint', '3': 3, '4': 1, '5': 9, '10': 'fingerprint'},
    {'1': 'type', '3': 4, '4': 1, '5': 9, '10': 'type'},
  ],
  '4': [HostKey_Status$json],
};

@$core.Deprecated('Use hostKeyDescriptor instead')
const HostKey_Status$json = {
  '1': 'Status',
  '2': [
    {'1': 'STATUS_UNSPECIFIED', '2': 0},
    {'1': 'KNOWN', '2': 1},
    {'1': 'UNKNOWN', '2': 2},
    {'1': 'CHANGED', '2': 3},
  ],
};

/// Descriptor for `HostKey`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List hostKeyDescriptor = $convert.base64Decode(
    'CgdIb3N0S2V5EjsKBnN0YXR1cxgBIAEoDjIjLnNlbGZob2xkLnBvc3Rlcm4udjEuSG9zdEtleS'
    '5TdGF0dXNSBnN0YXR1cxIQCgNrZXkYAiABKAlSA2tleRIgCgtmaW5nZXJwcmludBgDIAEoCVIL'
    'ZmluZ2VycHJpbnQSEgoEdHlwZRgEIAEoCVIEdHlwZSJFCgZTdGF0dXMSFgoSU1RBVFVTX1VOU1'
    'BFQ0lGSUVEEAASCQoFS05PV04QARILCgdVTktOT1dOEAISCwoHQ0hBTkdFRBAD');

@$core.Deprecated('Use trustRequestDescriptor instead')
const TrustRequest$json = {
  '1': 'TrustRequest',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'key', '3': 2, '4': 1, '5': 9, '10': 'key'},
    {'1': 'replace', '3': 3, '4': 1, '5': 8, '10': 'replace'},
  ],
};

/// Descriptor for `TrustRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List trustRequestDescriptor = $convert.base64Decode(
    'CgxUcnVzdFJlcXVlc3QSDgoCaWQYASABKAlSAmlkEhAKA2tleRgCIAEoCVIDa2V5EhgKB3JlcG'
    'xhY2UYAyABKAhSB3JlcGxhY2U=');

@$core.Deprecated('Use shellInDescriptor instead')
const ShellIn$json = {
  '1': 'ShellIn',
  '2': [
    {
      '1': 'open',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.selfhold.postern.v1.ShellIn.Open',
      '9': 0,
      '10': 'open'
    },
    {'1': 'data', '3': 2, '4': 1, '5': 12, '9': 0, '10': 'data'},
    {
      '1': 'resize',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.selfhold.postern.v1.ShellIn.Resize',
      '9': 0,
      '10': 'resize'
    },
  ],
  '3': [ShellIn_Open$json, ShellIn_Resize$json],
  '8': [
    {'1': 'msg'},
  ],
};

@$core.Deprecated('Use shellInDescriptor instead')
const ShellIn_Open$json = {
  '1': 'Open',
  '2': [
    {'1': 'host_id', '3': 1, '4': 1, '5': 9, '10': 'hostId'},
    {'1': 'cols', '3': 2, '4': 1, '5': 13, '10': 'cols'},
    {'1': 'rows', '3': 3, '4': 1, '5': 13, '10': 'rows'},
  ],
};

@$core.Deprecated('Use shellInDescriptor instead')
const ShellIn_Resize$json = {
  '1': 'Resize',
  '2': [
    {'1': 'cols', '3': 1, '4': 1, '5': 13, '10': 'cols'},
    {'1': 'rows', '3': 2, '4': 1, '5': 13, '10': 'rows'},
  ],
};

/// Descriptor for `ShellIn`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List shellInDescriptor = $convert.base64Decode(
    'CgdTaGVsbEluEjcKBG9wZW4YASABKAsyIS5zZWxmaG9sZC5wb3N0ZXJuLnYxLlNoZWxsSW4uT3'
    'BlbkgAUgRvcGVuEhQKBGRhdGEYAiABKAxIAFIEZGF0YRI9CgZyZXNpemUYAyABKAsyIy5zZWxm'
    'aG9sZC5wb3N0ZXJuLnYxLlNoZWxsSW4uUmVzaXplSABSBnJlc2l6ZRpHCgRPcGVuEhcKB2hvc3'
    'RfaWQYASABKAlSBmhvc3RJZBISCgRjb2xzGAIgASgNUgRjb2xzEhIKBHJvd3MYAyABKA1SBHJv'
    'd3MaMAoGUmVzaXplEhIKBGNvbHMYASABKA1SBGNvbHMSEgoEcm93cxgCIAEoDVIEcm93c0IFCg'
    'Ntc2c=');

@$core.Deprecated('Use shellOutDescriptor instead')
const ShellOut$json = {
  '1': 'ShellOut',
  '2': [
    {'1': 'opened', '3': 1, '4': 1, '5': 8, '9': 0, '10': 'opened'},
    {'1': 'data', '3': 2, '4': 1, '5': 12, '9': 0, '10': 'data'},
    {'1': 'closed', '3': 3, '4': 1, '5': 9, '9': 0, '10': 'closed'},
  ],
  '8': [
    {'1': 'msg'},
  ],
};

/// Descriptor for `ShellOut`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List shellOutDescriptor = $convert.base64Decode(
    'CghTaGVsbE91dBIYCgZvcGVuZWQYASABKAhIAFIGb3BlbmVkEhQKBGRhdGEYAiABKAxIAFIEZG'
    'F0YRIYCgZjbG9zZWQYAyABKAlIAFIGY2xvc2VkQgUKA21zZw==');

@$core.Deprecated('Use entryDescriptor instead')
const Entry$json = {
  '1': 'Entry',
  '2': [
    {'1': 'name', '3': 1, '4': 1, '5': 9, '10': 'name'},
    {'1': 'dir', '3': 2, '4': 1, '5': 8, '10': 'dir'},
    {'1': 'link', '3': 3, '4': 1, '5': 8, '10': 'link'},
    {'1': 'size', '3': 4, '4': 1, '5': 3, '10': 'size'},
    {'1': 'modified_ms', '3': 5, '4': 1, '5': 3, '10': 'modifiedMs'},
    {'1': 'mode', '3': 6, '4': 1, '5': 13, '10': 'mode'},
  ],
};

/// Descriptor for `Entry`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List entryDescriptor = $convert.base64Decode(
    'CgVFbnRyeRISCgRuYW1lGAEgASgJUgRuYW1lEhAKA2RpchgCIAEoCFIDZGlyEhIKBGxpbmsYAy'
    'ABKAhSBGxpbmsSEgoEc2l6ZRgEIAEoA1IEc2l6ZRIfCgttb2RpZmllZF9tcxgFIAEoA1IKbW9k'
    'aWZpZWRNcxISCgRtb2RlGAYgASgNUgRtb2Rl');

@$core.Deprecated('Use dirRequestDescriptor instead')
const DirRequest$json = {
  '1': 'DirRequest',
  '2': [
    {'1': 'side', '3': 1, '4': 1, '5': 9, '10': 'side'},
    {'1': 'path', '3': 2, '4': 1, '5': 9, '10': 'path'},
  ],
};

/// Descriptor for `DirRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List dirRequestDescriptor = $convert.base64Decode(
    'CgpEaXJSZXF1ZXN0EhIKBHNpZGUYASABKAlSBHNpZGUSEgoEcGF0aBgCIAEoCVIEcGF0aA==');

@$core.Deprecated('Use dirListingDescriptor instead')
const DirListing$json = {
  '1': 'DirListing',
  '2': [
    {'1': 'path', '3': 1, '4': 1, '5': 9, '10': 'path'},
    {
      '1': 'entries',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.selfhold.postern.v1.Entry',
      '10': 'entries'
    },
  ],
};

/// Descriptor for `DirListing`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List dirListingDescriptor = $convert.base64Decode(
    'CgpEaXJMaXN0aW5nEhIKBHBhdGgYASABKAlSBHBhdGgSNAoHZW50cmllcxgCIAMoCzIaLnNlbG'
    'Zob2xkLnBvc3Rlcm4udjEuRW50cnlSB2VudHJpZXM=');

@$core.Deprecated('Use pathRequestDescriptor instead')
const PathRequest$json = {
  '1': 'PathRequest',
  '2': [
    {'1': 'side', '3': 1, '4': 1, '5': 9, '10': 'side'},
    {'1': 'path', '3': 2, '4': 1, '5': 9, '10': 'path'},
  ],
};

/// Descriptor for `PathRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List pathRequestDescriptor = $convert.base64Decode(
    'CgtQYXRoUmVxdWVzdBISCgRzaWRlGAEgASgJUgRzaWRlEhIKBHBhdGgYAiABKAlSBHBhdGg=');

@$core.Deprecated('Use pathsRequestDescriptor instead')
const PathsRequest$json = {
  '1': 'PathsRequest',
  '2': [
    {'1': 'side', '3': 1, '4': 1, '5': 9, '10': 'side'},
    {'1': 'paths', '3': 2, '4': 3, '5': 9, '10': 'paths'},
  ],
};

/// Descriptor for `PathsRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List pathsRequestDescriptor = $convert.base64Decode(
    'CgxQYXRoc1JlcXVlc3QSEgoEc2lkZRgBIAEoCVIEc2lkZRIUCgVwYXRocxgCIAMoCVIFcGF0aH'
    'M=');

@$core.Deprecated('Use renameRequestDescriptor instead')
const RenameRequest$json = {
  '1': 'RenameRequest',
  '2': [
    {'1': 'side', '3': 1, '4': 1, '5': 9, '10': 'side'},
    {'1': 'from', '3': 2, '4': 1, '5': 9, '10': 'from'},
    {'1': 'to', '3': 3, '4': 1, '5': 9, '10': 'to'},
  ],
};

/// Descriptor for `RenameRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List renameRequestDescriptor = $convert.base64Decode(
    'Cg1SZW5hbWVSZXF1ZXN0EhIKBHNpZGUYASABKAlSBHNpZGUSEgoEZnJvbRgCIAEoCVIEZnJvbR'
    'IOCgJ0bxgDIAEoCVICdG8=');

@$core.Deprecated('Use transferRequestDescriptor instead')
const TransferRequest$json = {
  '1': 'TransferRequest',
  '2': [
    {'1': 'src_side', '3': 1, '4': 1, '5': 9, '10': 'srcSide'},
    {'1': 'src_paths', '3': 2, '4': 3, '5': 9, '10': 'srcPaths'},
    {'1': 'dst_side', '3': 3, '4': 1, '5': 9, '10': 'dstSide'},
    {'1': 'dst_dir', '3': 4, '4': 1, '5': 9, '10': 'dstDir'},
    {'1': 'move', '3': 5, '4': 1, '5': 8, '10': 'move'},
    {'1': 'overwrite', '3': 6, '4': 1, '5': 8, '10': 'overwrite'},
  ],
};

/// Descriptor for `TransferRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List transferRequestDescriptor = $convert.base64Decode(
    'Cg9UcmFuc2ZlclJlcXVlc3QSGQoIc3JjX3NpZGUYASABKAlSB3NyY1NpZGUSGwoJc3JjX3BhdG'
    'hzGAIgAygJUghzcmNQYXRocxIZCghkc3Rfc2lkZRgDIAEoCVIHZHN0U2lkZRIXCgdkc3RfZGly'
    'GAQgASgJUgZkc3REaXISEgoEbW92ZRgFIAEoCFIEbW92ZRIcCglvdmVyd3JpdGUYBiABKAhSCW'
    '92ZXJ3cml0ZQ==');

@$core.Deprecated('Use transferProgressDescriptor instead')
const TransferProgress$json = {
  '1': 'TransferProgress',
  '2': [
    {'1': 'done_bytes', '3': 1, '4': 1, '5': 3, '10': 'doneBytes'},
    {'1': 'total_bytes', '3': 2, '4': 1, '5': 3, '10': 'totalBytes'},
    {'1': 'done_files', '3': 3, '4': 1, '5': 5, '10': 'doneFiles'},
    {'1': 'total_files', '3': 4, '4': 1, '5': 5, '10': 'totalFiles'},
    {'1': 'current', '3': 5, '4': 1, '5': 9, '10': 'current'},
    {'1': 'finished', '3': 6, '4': 1, '5': 8, '10': 'finished'},
  ],
};

/// Descriptor for `TransferProgress`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List transferProgressDescriptor = $convert.base64Decode(
    'ChBUcmFuc2ZlclByb2dyZXNzEh0KCmRvbmVfYnl0ZXMYASABKANSCWRvbmVCeXRlcxIfCgt0b3'
    'RhbF9ieXRlcxgCIAEoA1IKdG90YWxCeXRlcxIdCgpkb25lX2ZpbGVzGAMgASgFUglkb25lRmls'
    'ZXMSHwoLdG90YWxfZmlsZXMYBCABKAVSCnRvdGFsRmlsZXMSGAoHY3VycmVudBgFIAEoCVIHY3'
    'VycmVudBIaCghmaW5pc2hlZBgGIAEoCFIIZmluaXNoZWQ=');

@$core.Deprecated('Use safeKeyDescriptor instead')
const SafeKey$json = {
  '1': 'SafeKey',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'title', '3': 2, '4': 1, '5': 9, '10': 'title'},
    {'1': 'key_type', '3': 3, '4': 1, '5': 9, '10': 'keyType'},
    {'1': 'fingerprint', '3': 4, '4': 1, '5': 9, '10': 'fingerprint'},
    {'1': 'public_key', '3': 5, '4': 1, '5': 9, '10': 'publicKey'},
    {'1': 'comment', '3': 6, '4': 1, '5': 9, '10': 'comment'},
  ],
};

/// Descriptor for `SafeKey`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List safeKeyDescriptor = $convert.base64Decode(
    'CgdTYWZlS2V5Eg4KAmlkGAEgASgJUgJpZBIUCgV0aXRsZRgCIAEoCVIFdGl0bGUSGQoIa2V5X3'
    'R5cGUYAyABKAlSB2tleVR5cGUSIAoLZmluZ2VycHJpbnQYBCABKAlSC2ZpbmdlcnByaW50Eh0K'
    'CnB1YmxpY19rZXkYBSABKAlSCXB1YmxpY0tleRIYCgdjb21tZW50GAYgASgJUgdjb21tZW50');

@$core.Deprecated('Use safeKeyListDescriptor instead')
const SafeKeyList$json = {
  '1': 'SafeKeyList',
  '2': [
    {
      '1': 'keys',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.selfhold.postern.v1.SafeKey',
      '10': 'keys'
    },
    {'1': 'unavailable', '3': 2, '4': 1, '5': 9, '10': 'unavailable'},
  ],
};

/// Descriptor for `SafeKeyList`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List safeKeyListDescriptor = $convert.base64Decode(
    'CgtTYWZlS2V5TGlzdBIwCgRrZXlzGAEgAygLMhwuc2VsZmhvbGQucG9zdGVybi52MS5TYWZlS2'
    'V5UgRrZXlzEiAKC3VuYXZhaWxhYmxlGAIgASgJUgt1bmF2YWlsYWJsZQ==');
