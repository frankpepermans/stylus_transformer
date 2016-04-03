import 'dart:io';
import 'dart:async';
import 'dart:convert';

import 'package:barback/barback.dart';
import 'package:path/path.dart' as p;

class StylusTransformer extends Transformer {

  StylusTransformer.asPlugin();

  String get allowedExtensions => ".css";

  classifyPrimary(AssetId id) {
    if (!id.path.endsWith('compc_stylus.css')) return null;

    return p.url.dirname(id.path);
  }

  @override
  Future<dynamic> apply(Transform transform) {
    final Completer<int> completer = new Completer<int>();
    print('${transform.primaryInput.id.package}:${transform.primaryInput.id.path}');
    Process.start(
        'node',
        ['C:\\Users\\frank\\AppData\\Roaming\\npm\\node_modules\\stylus\\bin\\stylus', '--import', 'styles/_variables.styl', '--compress', '-p', 'styles'],
        workingDirectory: 'web'
    ).then((Process process) {
      process.stdout
        .transform(UTF8.decoder as StreamTransformer<List<int>, dynamic>)
        .listen((String css) {
          print(css);

          transform.addOutput(new Asset.fromString(transform.primaryInput.id, css));
        });

      process.exitCode.then((int code) => completer.complete(code));
    });

    return completer.future;
  }
}