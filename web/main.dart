// Copyright 2017, Google Inc.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:html';
import 'dart:typed_data';

import 'package:type_inference_tinker/engine.dart';

Future<Null> main() async {
  final xhr = await HttpRequest.request(
    'sdk.sum',
    responseType: 'arraybuffer',
  );
  final Object result = xhr.response;
  if (result is ByteBuffer) {
    final engine = new TypeInferenceEngine.withSdkSummary(result.asUint8List());
    final DivElement preview = querySelector('#preview');
    final InputElement input = querySelector('#code');
    final stack = <String>[];
    preview.text = 'Ready!';
    input
      ..focus()
      ..onKeyDown.listen((e) {
        if (e.keyCode == 13) {
          stack.insert(0, input.value);
          if (stack.length > 10) {
            stack.removeLast();
          }
          preview.text = engine.infer(input.value).toString();
          input.value = '';
        } else if (e.keyCode == 38) {
          input.value = stack.isNotEmpty ? stack.removeAt(0) : '';
        }
      });
  }
}
