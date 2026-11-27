// This is a generated file - do not edit.
//
// Generated from sshm.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:async' as $async;
import 'dart:core' as $core;

import 'package:grpc/service_api.dart' as $grpc;
import 'package:protobuf/protobuf.dart' as $pb;

import 'sshm.pb.dart' as $0;

export 'sshm.pb.dart';

@$pb.GrpcServiceName('sshm.v1.Core')
class CoreClient extends $grpc.Client {
  /// The hostname for this service.
  static const $core.String defaultHost = '';

  /// OAuth scopes needed for the client.
  static const $core.List<$core.String> oauthScopes = [
    '',
  ];

  CoreClient(super.channel, {super.options, super.interceptors});

  /// State: versions and CloudSync status.
  $grpc.ResponseFuture<$0.State> getState(
    $0.Empty request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$getState, request, options: options);
  }

  /// Events streams changes (hosts, sync state).
  $grpc.ResponseStream<$0.Event> events(
    $0.Empty request, {
    $grpc.CallOptions? options,
  }) {
    return $createStreamingCall(_$events, $async.Stream.fromIterable([request]),
        options: options);
  }

  /// --- hosts (synced through CloudSync when sync is on) -------------------
  $grpc.ResponseFuture<$0.HostList> listHosts(
    $0.Empty request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$listHosts, request, options: options);
  }

  /// SaveHost creates (id = "") or replaces a host.
  $grpc.ResponseFuture<$0.Host> saveHost(
    $0.Host request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$saveHost, request, options: options);
  }

  $grpc.ResponseFuture<$0.Empty> deleteHost(
    $0.HostRef request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$deleteHost, request, options: options);
  }

  /// ProbeHostKey connects and returns the server's key, compared with the
  /// key the host has on record.
  $grpc.ResponseFuture<$0.HostKey> probeHostKey(
    $0.HostRef request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$probeHostKey, request, options: options);
  }

  /// TrustHostKey records the key (authorized_keys format) on the host.
  $grpc.ResponseFuture<$0.Host> trustHostKey(
    $0.TrustRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$trustHostKey, request, options: options);
  }

  /// --- terminal -------------------------------------------------------
  /// Shell: the first message is `open`; then data and resizes. The core
  /// answers `opened`, then data, and `closed` at the end.
  $grpc.ResponseStream<$0.ShellOut> shell(
    $async.Stream<$0.ShellIn> request, {
    $grpc.CallOptions? options,
  }) {
    return $createStreamingCall(_$shell, request, options: options);
  }

  /// --- files (side "" = this device, otherwise a host id) -------------
  $grpc.ResponseFuture<$0.DirListing> listDir(
    $0.DirRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$listDir, request, options: options);
  }

  $grpc.ResponseFuture<$0.Empty> makeDir(
    $0.PathRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$makeDir, request, options: options);
  }

  $grpc.ResponseFuture<$0.Empty> remove(
    $0.PathsRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$remove, request, options: options);
  }

  $grpc.ResponseFuture<$0.Empty> rename(
    $0.RenameRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$rename, request, options: options);
  }

  /// Transfer copies (or moves) files and folders between two sides and
  /// reports progress; cancelling the call stops it.
  $grpc.ResponseStream<$0.TransferProgress> transfer(
    $0.TransferRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createStreamingCall(
        _$transfer, $async.Stream.fromIterable([request]),
        options: options);
  }

  /// --- CloudSync ------------------------------------------------------
  /// EnableSync asks CloudSync for pairing (if needed) and returns the code
  /// to show; the result comes as a SYNC event.
  $grpc.ResponseFuture<$0.SyncState> enableSync(
    $0.Empty request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$enableSync, request, options: options);
  }

  $grpc.ResponseFuture<$0.SyncState> disableSync(
    $0.Empty request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$disableSync, request, options: options);
  }

  /// SyncNow pushes local changes and pulls remote ones.
  $grpc.ResponseFuture<$0.SyncState> syncNow(
    $0.Empty request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$syncNow, request, options: options);
  }

  /// RequestAccess asks CloudSync (while paired) for the shared server list
  /// and the SSH keys of its safe; the code to show comes back.
  $grpc.ResponseFuture<$0.SyncState> requestAccess(
    $0.Empty request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$requestAccess, request, options: options);
  }

  /// SafeKeys lists the SSH keys of CloudSync's password safe (public part
  /// only); needs sync on and the "ssh_keys" permission in CloudSync.
  $grpc.ResponseFuture<$0.SafeKeyList> safeKeys(
    $0.Empty request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$safeKeys, request, options: options);
  }

  // method descriptors

  static final _$getState = $grpc.ClientMethod<$0.Empty, $0.State>(
      '/sshm.v1.Core/GetState',
      ($0.Empty value) => value.writeToBuffer(),
      $0.State.fromBuffer);
  static final _$events = $grpc.ClientMethod<$0.Empty, $0.Event>(
      '/sshm.v1.Core/Events',
      ($0.Empty value) => value.writeToBuffer(),
      $0.Event.fromBuffer);
  static final _$listHosts = $grpc.ClientMethod<$0.Empty, $0.HostList>(
      '/sshm.v1.Core/ListHosts',
      ($0.Empty value) => value.writeToBuffer(),
      $0.HostList.fromBuffer);
  static final _$saveHost = $grpc.ClientMethod<$0.Host, $0.Host>(
      '/sshm.v1.Core/SaveHost',
      ($0.Host value) => value.writeToBuffer(),
      $0.Host.fromBuffer);
  static final _$deleteHost = $grpc.ClientMethod<$0.HostRef, $0.Empty>(
      '/sshm.v1.Core/DeleteHost',
      ($0.HostRef value) => value.writeToBuffer(),
      $0.Empty.fromBuffer);
  static final _$probeHostKey = $grpc.ClientMethod<$0.HostRef, $0.HostKey>(
      '/sshm.v1.Core/ProbeHostKey',
      ($0.HostRef value) => value.writeToBuffer(),
      $0.HostKey.fromBuffer);
  static final _$trustHostKey = $grpc.ClientMethod<$0.TrustRequest, $0.Host>(
      '/sshm.v1.Core/TrustHostKey',
      ($0.TrustRequest value) => value.writeToBuffer(),
      $0.Host.fromBuffer);
  static final _$shell = $grpc.ClientMethod<$0.ShellIn, $0.ShellOut>(
      '/sshm.v1.Core/Shell',
      ($0.ShellIn value) => value.writeToBuffer(),
      $0.ShellOut.fromBuffer);
  static final _$listDir = $grpc.ClientMethod<$0.DirRequest, $0.DirListing>(
      '/sshm.v1.Core/ListDir',
      ($0.DirRequest value) => value.writeToBuffer(),
      $0.DirListing.fromBuffer);
  static final _$makeDir = $grpc.ClientMethod<$0.PathRequest, $0.Empty>(
      '/sshm.v1.Core/MakeDir',
      ($0.PathRequest value) => value.writeToBuffer(),
      $0.Empty.fromBuffer);
  static final _$remove = $grpc.ClientMethod<$0.PathsRequest, $0.Empty>(
      '/sshm.v1.Core/Remove',
      ($0.PathsRequest value) => value.writeToBuffer(),
      $0.Empty.fromBuffer);
  static final _$rename = $grpc.ClientMethod<$0.RenameRequest, $0.Empty>(
      '/sshm.v1.Core/Rename',
      ($0.RenameRequest value) => value.writeToBuffer(),
      $0.Empty.fromBuffer);
  static final _$transfer =
      $grpc.ClientMethod<$0.TransferRequest, $0.TransferProgress>(
          '/sshm.v1.Core/Transfer',
          ($0.TransferRequest value) => value.writeToBuffer(),
          $0.TransferProgress.fromBuffer);
  static final _$enableSync = $grpc.ClientMethod<$0.Empty, $0.SyncState>(
      '/sshm.v1.Core/EnableSync',
      ($0.Empty value) => value.writeToBuffer(),
      $0.SyncState.fromBuffer);
  static final _$disableSync = $grpc.ClientMethod<$0.Empty, $0.SyncState>(
      '/sshm.v1.Core/DisableSync',
      ($0.Empty value) => value.writeToBuffer(),
      $0.SyncState.fromBuffer);
  static final _$syncNow = $grpc.ClientMethod<$0.Empty, $0.SyncState>(
      '/sshm.v1.Core/SyncNow',
      ($0.Empty value) => value.writeToBuffer(),
      $0.SyncState.fromBuffer);
  static final _$requestAccess = $grpc.ClientMethod<$0.Empty, $0.SyncState>(
      '/sshm.v1.Core/RequestAccess',
      ($0.Empty value) => value.writeToBuffer(),
      $0.SyncState.fromBuffer);
  static final _$safeKeys = $grpc.ClientMethod<$0.Empty, $0.SafeKeyList>(
      '/sshm.v1.Core/SafeKeys',
      ($0.Empty value) => value.writeToBuffer(),
      $0.SafeKeyList.fromBuffer);
}

@$pb.GrpcServiceName('sshm.v1.Core')
abstract class CoreServiceBase extends $grpc.Service {
  $core.String get $name => 'sshm.v1.Core';

  CoreServiceBase() {
    $addMethod($grpc.ServiceMethod<$0.Empty, $0.State>(
        'GetState',
        getState_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.Empty.fromBuffer(value),
        ($0.State value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.Empty, $0.Event>(
        'Events',
        events_Pre,
        false,
        true,
        ($core.List<$core.int> value) => $0.Empty.fromBuffer(value),
        ($0.Event value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.Empty, $0.HostList>(
        'ListHosts',
        listHosts_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.Empty.fromBuffer(value),
        ($0.HostList value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.Host, $0.Host>(
        'SaveHost',
        saveHost_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.Host.fromBuffer(value),
        ($0.Host value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.HostRef, $0.Empty>(
        'DeleteHost',
        deleteHost_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.HostRef.fromBuffer(value),
        ($0.Empty value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.HostRef, $0.HostKey>(
        'ProbeHostKey',
        probeHostKey_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.HostRef.fromBuffer(value),
        ($0.HostKey value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.TrustRequest, $0.Host>(
        'TrustHostKey',
        trustHostKey_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.TrustRequest.fromBuffer(value),
        ($0.Host value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.ShellIn, $0.ShellOut>(
        'Shell',
        shell,
        true,
        true,
        ($core.List<$core.int> value) => $0.ShellIn.fromBuffer(value),
        ($0.ShellOut value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.DirRequest, $0.DirListing>(
        'ListDir',
        listDir_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.DirRequest.fromBuffer(value),
        ($0.DirListing value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.PathRequest, $0.Empty>(
        'MakeDir',
        makeDir_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.PathRequest.fromBuffer(value),
        ($0.Empty value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.PathsRequest, $0.Empty>(
        'Remove',
        remove_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.PathsRequest.fromBuffer(value),
        ($0.Empty value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.RenameRequest, $0.Empty>(
        'Rename',
        rename_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.RenameRequest.fromBuffer(value),
        ($0.Empty value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.TransferRequest, $0.TransferProgress>(
        'Transfer',
        transfer_Pre,
        false,
        true,
        ($core.List<$core.int> value) => $0.TransferRequest.fromBuffer(value),
        ($0.TransferProgress value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.Empty, $0.SyncState>(
        'EnableSync',
        enableSync_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.Empty.fromBuffer(value),
        ($0.SyncState value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.Empty, $0.SyncState>(
        'DisableSync',
        disableSync_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.Empty.fromBuffer(value),
        ($0.SyncState value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.Empty, $0.SyncState>(
        'SyncNow',
        syncNow_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.Empty.fromBuffer(value),
        ($0.SyncState value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.Empty, $0.SyncState>(
        'RequestAccess',
        requestAccess_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.Empty.fromBuffer(value),
        ($0.SyncState value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.Empty, $0.SafeKeyList>(
        'SafeKeys',
        safeKeys_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.Empty.fromBuffer(value),
        ($0.SafeKeyList value) => value.writeToBuffer()));
  }

  $async.Future<$0.State> getState_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.Empty> $request) async {
    return getState($call, await $request);
  }

  $async.Future<$0.State> getState($grpc.ServiceCall call, $0.Empty request);

  $async.Stream<$0.Event> events_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.Empty> $request) async* {
    yield* events($call, await $request);
  }

  $async.Stream<$0.Event> events($grpc.ServiceCall call, $0.Empty request);

  $async.Future<$0.HostList> listHosts_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.Empty> $request) async {
    return listHosts($call, await $request);
  }

  $async.Future<$0.HostList> listHosts(
      $grpc.ServiceCall call, $0.Empty request);

  $async.Future<$0.Host> saveHost_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.Host> $request) async {
    return saveHost($call, await $request);
  }

  $async.Future<$0.Host> saveHost($grpc.ServiceCall call, $0.Host request);

  $async.Future<$0.Empty> deleteHost_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.HostRef> $request) async {
    return deleteHost($call, await $request);
  }

  $async.Future<$0.Empty> deleteHost(
      $grpc.ServiceCall call, $0.HostRef request);

  $async.Future<$0.HostKey> probeHostKey_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.HostRef> $request) async {
    return probeHostKey($call, await $request);
  }

  $async.Future<$0.HostKey> probeHostKey(
      $grpc.ServiceCall call, $0.HostRef request);

  $async.Future<$0.Host> trustHostKey_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.TrustRequest> $request) async {
    return trustHostKey($call, await $request);
  }

  $async.Future<$0.Host> trustHostKey(
      $grpc.ServiceCall call, $0.TrustRequest request);

  $async.Stream<$0.ShellOut> shell(
      $grpc.ServiceCall call, $async.Stream<$0.ShellIn> request);

  $async.Future<$0.DirListing> listDir_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.DirRequest> $request) async {
    return listDir($call, await $request);
  }

  $async.Future<$0.DirListing> listDir(
      $grpc.ServiceCall call, $0.DirRequest request);

  $async.Future<$0.Empty> makeDir_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.PathRequest> $request) async {
    return makeDir($call, await $request);
  }

  $async.Future<$0.Empty> makeDir(
      $grpc.ServiceCall call, $0.PathRequest request);

  $async.Future<$0.Empty> remove_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.PathsRequest> $request) async {
    return remove($call, await $request);
  }

  $async.Future<$0.Empty> remove(
      $grpc.ServiceCall call, $0.PathsRequest request);

  $async.Future<$0.Empty> rename_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.RenameRequest> $request) async {
    return rename($call, await $request);
  }

  $async.Future<$0.Empty> rename(
      $grpc.ServiceCall call, $0.RenameRequest request);

  $async.Stream<$0.TransferProgress> transfer_Pre($grpc.ServiceCall $call,
      $async.Future<$0.TransferRequest> $request) async* {
    yield* transfer($call, await $request);
  }

  $async.Stream<$0.TransferProgress> transfer(
      $grpc.ServiceCall call, $0.TransferRequest request);

  $async.Future<$0.SyncState> enableSync_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.Empty> $request) async {
    return enableSync($call, await $request);
  }

  $async.Future<$0.SyncState> enableSync(
      $grpc.ServiceCall call, $0.Empty request);

  $async.Future<$0.SyncState> disableSync_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.Empty> $request) async {
    return disableSync($call, await $request);
  }

  $async.Future<$0.SyncState> disableSync(
      $grpc.ServiceCall call, $0.Empty request);

  $async.Future<$0.SyncState> syncNow_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.Empty> $request) async {
    return syncNow($call, await $request);
  }

  $async.Future<$0.SyncState> syncNow($grpc.ServiceCall call, $0.Empty request);

  $async.Future<$0.SyncState> requestAccess_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.Empty> $request) async {
    return requestAccess($call, await $request);
  }

  $async.Future<$0.SyncState> requestAccess(
      $grpc.ServiceCall call, $0.Empty request);

  $async.Future<$0.SafeKeyList> safeKeys_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.Empty> $request) async {
    return safeKeys($call, await $request);
  }

  $async.Future<$0.SafeKeyList> safeKeys(
      $grpc.ServiceCall call, $0.Empty request);
}
