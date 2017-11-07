import 'dart:io';
import 'dart:async';
import 'dart:convert';

import 'package:barback/barback.dart';
import 'package:path/path.dart' as path;

class InlineTransformer extends Transformer {
  String _pathToBinary;

  InlineTransformer(BarbackSettings settings) : super() {
    const validOptions = const ['stylus_binary'];

    for (var option in settings.configuration.keys) {
      if (validOptions.contains(option)) continue;
      throw 'Invalid option ``$option` supplied to stylus transformer. '
          'The recognized options are ${validOptions.join(' ')}.';
    }

    _pathToBinary = settings.configuration['stylus_binary'] as String;
  }

  InlineTransformer.asPlugin(BarbackSettings settings) : this(settings);

  String get allowedExtensions => ".styl";

  classifyPrimary(AssetId id) {
    if (id.path.startsWith(new RegExp(r'web[\\/]{1}'))) return null;

    return path.url.dirname(id.path);
  }

  @override
  Future<dynamic> apply(Transform transform) {
    final Completer<int> completer = new Completer<int>();

    transform.consumePrimary();

    transform.logger.info('node ${path.relative(_pathToBinary)} --import styles\\_variables.styl --compress -p styles');

    Process.start('node', [
      path.relative(_pathToBinary),
      '--import',
      'web\\styles\\_variables.styl',
      '--compress',
      '-p',
      transform.primaryInput.id.path
    ]).then((Process process) {
      process.stdout.transform(UTF8.decoder).listen((String css) {
        final String newAssetPath =
            transform.primaryInput.id.path.replaceAll('.styl', '.css');

        transform.logger.info('compiled successfully');

        transform.addOutput(new Asset.fromString(
            new AssetId(transform.primaryInput.id.package, newAssetPath), css));
      }, onError: ([Error error]) {
        transform.logger.warning('compilation failed');

        completer.complete(-1);
      });

      process.exitCode.then(completer.complete).catchError((e, [s]) {
        if (e is Error) {
          print(e.stackTrace);
        }
      });
    }, onError: (error) {
      transform.logger.error(error.message);

      if (error is Error) transform.logger.error(error.stackTrace.toString());
    });

    return completer.future;
  }
}
