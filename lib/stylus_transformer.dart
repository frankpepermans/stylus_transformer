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

    String pathToBinaryTmp = settings.configuration['stylus_binary'] as String;

    pathToBinaryTmp.replaceAll(new RegExp(r'[\\\/]{1}'), '|').split('|');

    _pathToBinary = path.joinAll(
        pathToBinaryTmp.replaceAll(new RegExp(r'[\\\/]{1}'), '|').split('|'));
  }

  StylusTransformer.asPlugin(BarbackSettings settings) : this(settings);

  String get allowedExtensions => ".css .styl";

  @override
  Future<dynamic> apply(Transform transform) {
    if (transform.primaryInput.id.path.endsWith('compc_stylus.css')) {
      final Completer<int> completer = new Completer<int>();
      final List<String> params = <String>[
        path.relative('../$_pathToBinary'),
        '--import',
        path.join('styles', '_variables.styl'),
        '--compress',
        '-p',
        'styles'
      ];
      String allCss = '';

      transform.logger.info('starting process: node ${params.join(' ')}');

      Process.start('node', params, workingDirectory: 'web').then(
          (Process process) {
        process.stdout.transform(UTF8.decoder).listen((String css) {
          allCss += css;
        }, onError: ([Error error]) {
          transform.logger.info('node process failed!');

          completer.complete(-1);
        });

        process.exitCode.then((int code) {
          transform.logger.info('node process terminated with code $code');

          transform.addOutput(
              new Asset.fromString(transform.primaryInput.id, allCss));

          completer.complete(code);
        }).catchError((e, [s]) {
          if (e is Error) {
            transform.logger.info(e.stackTrace.toString());
          }
        });
      }, onError: (error) {
        transform.logger.error(error.message);

        if (error is Error) transform.logger.error(error.stackTrace.toString());
      });

      return completer.future;
    } else if (transform.primaryInput.id.path.startsWith('web\\styles\\')) {
      transform.consumePrimary();
    }

    return new Future.value(0);
  }
}
