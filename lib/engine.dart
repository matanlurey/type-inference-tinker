// Copyright 2017, Google Inc.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Sorry, there is no other public API to do this.
// ignore_for_file: implementation_imports

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/visitor.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/memory_file_system.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/summary/summary_sdk.dart';

/// Represents a narrow API over `package:analyzer` to perform type inference.
class TypeInferenceEngine {
  static const _sdkPath = '/sdk.sum';
  static final _strongMode = new AnalysisOptionsImpl()..strongMode = true;

  final AnalysisContext _context;
  final MemoryResourceProvider _resources;
  File _scratch;

  /// Create a new inference engine, initializing the Dart SDK from [bytes].
  factory TypeInferenceEngine.withSdkSummary(List<int> bytes) {
    final resources = new MemoryResourceProvider();
    if (bytes == null || bytes.isEmpty) {
      throw new ArgumentError.value(bytes, 'bytes');
    }
    resources.newFileWithBytes(_sdkPath, bytes);
    return new TypeInferenceEngine._(
      AnalysisEngine.instance.createAnalysisContext()
        ..analysisOptions = _strongMode
        ..sourceFactory = new SourceFactory([
          new DartUriResolver(new SummaryBasedDartSdk(
            _sdkPath,
            true,
            resourceProvider: resources,
          )),
        ], null, resources),
      resources,
    );
  }

  TypeInferenceEngine._(this._context, this._resources);

  /// Creates an in-memory file representing a library with [sourceCode].
  Source _library(String sourceCode) {
    // TODO: Choose a better naming/scratch file strategy.
    final name = '${sourceCode.hashCode}-${new DateTime.now().millisecond}';
    _scratch?.delete();
    _scratch = _resources.newFile('/$name.dart', sourceCode);
    return _scratch.createSource();
  }

  /// Returns the result of running type inference on [sourceCode].
  ///
  /// ```dart
  /// void example(TypeInferenceEngine engine) {
  ///   // Returns DartType { Iterable<int> }.
  ///   engine.infer('''
  ///     void test() {
  ///       var y = [1, 2, 3];
  ///       var x = y.where((n) => n > 1);
  ///     }
  ///   ''', name: 'x');
  /// }
  /// ```
  ///
  /// If [name] is not provided, the first type is resolved is returned:
  ///
  /// ```dart
  /// void example(TypeInferenceEngine engine) {
  ///   // Returns DartType { String }.
  ///   engine.infer('''
  ///     void test() {
  ///       var x = 'Hello World';
  ///     }
  ///   ''');
  /// }
  /// ```
  DartType infer(String sourceCode, {String name}) {
    final library = _context.computeLibraryElement(_library(sourceCode));
    final results = <VariableElement>[];
    final visitor = new _ElementVisitor(results);
    library.accept(visitor);
    if (name == null) {
      return results.first.type;
    }
    return results.firstWhere((e) => e.name == name).type;
  }
}

class _ElementVisitor extends GeneralizingElementVisitor<Null> {
  final List<VariableElement> _results;

  _ElementVisitor(this._results);

  @override
  visitVariableElement(VariableElement element) {
    _results.add(element);
    return super.visitVariableElement(element);
  }
}
