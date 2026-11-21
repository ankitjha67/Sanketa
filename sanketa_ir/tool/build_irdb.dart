/// Offline build tool: process Flipper IRDB directory → compact JSON packs.
///
/// Usage:
///   dart run tool/build_irdb.dart <flipper-irdb-path> <output-dir>
///
/// This reads every .ir file under the Flipper IRDB directory, parses them
/// into IrCodeset instances, and writes:
///   1. catalog.json — the searchable index of all codesets
///   2. codesets/<id>.json — individual codeset data files
///
/// The app bundles catalog.json as an asset and loads codeset files lazily.
import 'dart:convert';
import 'dart:io';

import 'package:sanketa_ir/sanketa_ir.dart';

void main(List<String> args) {
  if (args.length < 2) {
    stderr.writeln(
        'Usage: dart run tool/build_irdb.dart <irdb-dir> <output-dir>');
    exit(1);
  }

  final irdbDir = Directory(args[0]);
  final outputDir = Directory(args[1]);

  if (!irdbDir.existsSync()) {
    stderr.writeln('IRDB directory not found: ${irdbDir.path}');
    exit(1);
  }

  outputDir.createSync(recursive: true);
  final codesetsDir = Directory('${outputDir.path}/codesets');
  codesetsDir.createSync(recursive: true);
  // The output directory is generated content. Remove only prior generated
  // JSON codesets so a rebuilt snapshot cannot retain stale entries.
  for (final entity in codesetsDir.listSync()) {
    if (entity is File && entity.path.toLowerCase().endsWith('.json')) {
      entity.deleteSync();
    }
  }

  final catalog = <CatalogEntry>[];
  var processed = 0;
  var skipped = 0;

  final files = irdbDir
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.toLowerCase().endsWith('.ir'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));
  final ids = <String>{};

  for (final file in files) {
    final relativePath = file.path
        .substring(irdbDir.path.length)
        .replaceAll('\\', '/')
        .replaceFirst(RegExp('^/'), '');

    try {
      final content = file.readAsStringSync();
      final codeset = CodesetBuilder.fromFlipperFile(
        relativePath: relativePath,
        content: content,
      );
      if (codeset == null || codeset.keys.isEmpty) {
        skipped++;
        continue;
      }
      if (!ids.add(codeset.id)) {
        throw StateError('duplicate generated codeset id: ${codeset.id}');
      }

      final serialized =
          IrdbCatalog.serializeCodeset(codeset, IrdbSource.flipperIrdb);
      final json =
          const JsonEncoder.withIndent(null).convert(serialized.toJson());
      File('${codesetsDir.path}/${codeset.id}.json').writeAsStringSync(json);

      catalog.add(serialized.entry);
      processed++;
    } on Object catch (e) {
      stderr.writeln('Error processing $relativePath: $e');
      skipped++;
    }
  }

  catalog.sort((a, b) {
    final type = a.deviceType.name.compareTo(b.deviceType.name);
    if (type != 0) return type;
    final brand = a.brand.name.compareTo(b.brand.name);
    if (brand != 0) return brand;
    final name = a.name.compareTo(b.name);
    return name != 0 ? name : a.id.compareTo(b.id);
  });

  final catalogJson = const JsonEncoder.withIndent('  ')
      .convert(catalog.map((e) => e.toJson()).toList());
  File('${outputDir.path}/catalog.json').writeAsStringSync(catalogJson);

  stdout.writeln('Processed: $processed codesets');
  stdout.writeln('Skipped: $skipped files');
  stdout.writeln('Catalog: ${outputDir.path}/catalog.json');
}
