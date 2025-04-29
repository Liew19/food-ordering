import 'dart:html' as html;
import 'dart:convert';

/// Utility class for exporting data to CSV files
class CSVExporter {
  /// Exports data to a CSV file
  ///
  /// [data] is a list of rows, where each row is a list of values
  /// [fileName] is the name of the file to save
  /// Returns the path to the saved file
  static Future<String> exportResults(
    List<List<dynamic>> data,
    String fileName,
  ) async {
    try {
      // Create CSV content
      final csvContent = data.map((row) => row.join(',')).join('\n');

      // Create a Blob containing the CSV data
      final bytes = utf8.encode(csvContent);
      final blob = html.Blob([bytes]);

      // Create a download link and trigger download
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor =
          html.AnchorElement(href: url)
            ..setAttribute('download', fileName)
            ..style.display = 'none';

      html.document.body?.children.add(anchor);
      anchor.click();

      // Clean up
      html.document.body?.children.remove(anchor);
      html.Url.revokeObjectUrl(url);

      print('CSV file downloaded as: $fileName');
      return fileName;
    } catch (e) {
      print('Error exporting CSV: $e');
      return '';
    }
  }
}
