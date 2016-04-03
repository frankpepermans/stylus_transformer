import 'dart:io';
import 'dart:async';
import 'dart:convert';

import 'package:barback/barback.dart';
import 'package:path/path.dart' as p;

class StylusTransformer extends Transformer {

  StylusTransformer.asPlugin();

  String get allowedExtensions => ".html";

  classifyPrimary(AssetId id) {
    if (!id.path.endsWith('index.html')) return null;

    return p.url.dirname(id.path);
  }

  @override
  Future<dynamic> apply(Transform transform) {
    final Completer<int> completer = new Completer<int>();
    final File cssFile = new File('web/styles/compc_stylus.css');

    if (!cssFile.existsSync()) cssFile.createSync();

    cssFile.writeAsStringSync('', mode:FileMode.WRITE);

    Process.start(
        'node',
        ['C:\\Users\\frank\\AppData\\Roaming\\npm\\node_modules\\stylus\\bin\\stylus', '--import', 'styles/_variables.styl', '--compress', '-p', 'styles'],
        workingDirectory: 'web'
    ).then((Process process) {
      process.stdout
          .transform(UTF8.decoder as StreamTransformer<List<int>, dynamic>)
          .listen((String css) => cssFile.writeAsStringSync(css, mode:FileMode.APPEND));

      process.exitCode.then((int code) => completer.complete(code));
    });

    return completer.future;
  }
}