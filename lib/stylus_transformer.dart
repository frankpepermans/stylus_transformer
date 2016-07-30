import 'dart:io';
import 'dart:async';
import 'dart:convert';

import 'package:barback/barback.dart';
import 'package:path/path.dart' as path;

class StylusTransformer extends Transformer {

  String _pathToBinary;

  StylusTransformer(BarbackSettings settings) : super() {
    const validOptions = const ['stylus_binary'];

    for (var option in settings.configuration.keys) {
      if (validOptions.contains(option)) continue;
      throw 'Invalid option ``$option` supplied to stylus transformer. '
          'The recognized options are ${validOptions.join(' ')}.';
    }

    _pathToBinary = settings.configuration['stylus_binary'] as String;
  }

  StylusTransformer.asPlugin(BarbackSettings settings) : this(settings);

  String get allowedExtensions => ".css .styl";

  classifyPrimary(AssetId id) {
    if (!id.path.endsWith('compc_stylus.css')) return null;

    return path.url.dirname(id.path);
  }

  @override
  Future<dynamic> apply(Transform transform) {
    if (transform.primaryInput.id.path.endsWith('compc_stylus.css')) {
      final Completer<int> completer = new Completer<int>();
      String allCss = '';

      transform.logger.info('Obtaining Stylus binary from: ${path.absolute(_pathToBinary)}');

      Process.start(
          'node',
          [path.absolute(_pathToBinary), '--import', 'styles/_variables.styl', '--compress', '-p', 'styles'],
          workingDirectory: 'web'
      ).then((Process process) {
        process.stdout
            .transform(UTF8.decoder as StreamTransformer<List<int>, dynamic>)
            .listen((String css) {
          allCss += css;
        }, onError: ([Error error]) {
          print('node process failed');

          completer.complete(-1);
        });

        process.exitCode.then((int code) {
          print('node process terminated with code $code');

          transform.addOutput(new Asset.fromString(transform.primaryInput.id, allCss));

          completer.complete(code);
        });
      }, onError: (error) {
        transform.logger.error(error.message);
      });

      return completer.future;
    }

    return new Future.value(0);
  }
}