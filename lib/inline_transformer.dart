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

  //@override Future<bool> isPrimary(AssetId id) => new Future.value(!id.path.startsWith('web/'));

  @override
  Future<dynamic> apply(Transform transform) {
    final Completer<int> completer = new Completer<int>();

    Process.start(
        'node',
        [path.absolute(_pathToBinary), '--import', 'web/styles/_variables.styl', '--compress', '-p', transform.primaryInput.id.path]
    ).then((Process process) {
      process.stdout
        .transform(UTF8.decoder as StreamTransformer<List<int>, dynamic>)
        .listen((String css) {
          final String newAssetPath = transform.primaryInput.id.path.replaceAll('.styl', '.css');

          transform.logger.info('compiled successfully');

          transform.addOutput(new Asset.fromString(new AssetId(transform.primaryInput.id.package, newAssetPath), css));
        }, onError: ([Error error]) {
          transform.logger.warning('compilation failed');

          completer.complete(-1);
        });

      process.exitCode.then(completer.complete);
    }, onError: (error) {
      transform.logger.error(error.message);
    });

    return completer.future;
  }
}