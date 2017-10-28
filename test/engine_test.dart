// Copyright 2017, Google Inc.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:test/test.dart';
import 'package:type_inference_tinker/engine.dart';

void main() {
  TypeInferenceEngine engine;

  setUpAll(() {
    final bytes = new File('web/sdk.sum').readAsBytesSync();
    engine = new TypeInferenceEngine.withSdkSummary(bytes);
  });

  test('should infer a local field', () {
    expect(
      engine.infer(r'''
        void main() {
          var x = [1, 2, 3];
        }
      ''').toString(),
      'List<int>',
    );
  });

  test('should infer a top-level field', () {
    expect(
      engine.infer(r'''
        var x = [1, 2, 3];
      ''').toString(),
      'List<int>',
    );
  });

  test('should infer a class-level field', () {
    expect(
      engine.infer(r'''
        class X {
          var x = [1, 2, 3];
        }
      ''').toString(),
      'List<int>',
    );
  });

  test('should infer a specified variable', () {
    expect(
      engine.infer(r'''
        void main() {
          var x = [1, 2.0, 3];
          var y = x.where((n) => n > 1);
        }
      ''', name: 'y').toString(),
      'Iterable<num>',
    );
  });
}
