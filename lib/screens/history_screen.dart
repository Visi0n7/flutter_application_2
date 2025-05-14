import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io' show File;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:universal_html/html.dart' as html;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/analysis_result.dart';

class HistoryScreen extends StatefulWidget {
  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<AnalysisResult> _history = [];
  bool _loading = true;
  bool _exporting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    if (token == null) {
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final response = await http.get(
        Uri.parse('http://localhost:8000/history'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        setState(() {
          _history = data
              .map((e) => AnalysisResult.fromJson(e as Map<String, dynamic>))
              .toList();
        });
      } else {
        setState(() => _error = 'Ошибка: ${response.statusCode}');
      }
    } catch (e) {
      setState(() => _error = 'Ошибка запроса: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  static Future<Uint8List> _buildPdfInIsolate(Map<String, dynamic> data) async {
    final List<AnalysisResult> entries =
        List<AnalysisResult>.from(data['entries']);
    final fontBytes = data['font'] as Uint8List;

    final pdf = pw.Document();
    final font = pw.Font.ttf(ByteData.view(fontBytes.buffer));

    pdf.addPage(
      pw.MultiPage(
        build: (pw.Context context) => [
          pw.Header(
            level: 0,
            child: pw.Text('История анализа кода',
                style: pw.TextStyle(font: font, fontSize: 20)),
          ),
          ...entries.map(
            (entry) => pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 16),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Оценка времени: ${entry.estimatedHours} ч',
                      style: pw.TextStyle(font: font)),
                  pw.Text('Сложность: ${entry.complexityScore}',
                      style: pw.TextStyle(font: font)),
                  pw.Text('Поддерживаемость: ${entry.maintainabilityIndex}',
                      style: pw.TextStyle(font: font)),
                  pw.Text(
                      'Цикломатическая сложность: ${entry.cyclomaticComplexity}',
                      style: pw.TextStyle(font: font)),
                  pw.Text('Функций: ${entry.numFunctions}',
                      style: pw.TextStyle(font: font)),
                  pw.Text('Качество комментариев: ${entry.commentQualityScore}',
                      style: pw.TextStyle(font: font)),
                  pw.Text('Хардкод: ${entry.usesHardcodedDirs ? "да" : "нет"}',
                      style: pw.TextStyle(font: font)),
                  pw.SizedBox(height: 4),
                  pw.Text('— ${entry.summaryComplexity}',
                      style: pw.TextStyle(font: font, fontSize: 10)),
                  pw.Text('— ${entry.summarySupportability}',
                      style: pw.TextStyle(font: font, fontSize: 10)),
                  pw.Text('— ${entry.summaryStructure}',
                      style: pw.TextStyle(font: font, fontSize: 10)),
                  pw.Text('— ${entry.summaryComments}',
                      style: pw.TextStyle(font: font, fontSize: 10)),
                  pw.Text('— ${entry.summaryPaths}',
                      style: pw.TextStyle(font: font, fontSize: 10)),
                  pw.SizedBox(height: 8),
                  pw.Text('Код:',
                      style: pw.TextStyle(font: font, fontSize: 10)),
                  pw.Container(
                    padding: const pw.EdgeInsets.all(4),
                    color: PdfColors.grey200,
                    child: pw.Text(entry.code,
                        style: pw.TextStyle(
                            font: font, fontSize: 8, color: PdfColors.black)),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );

    return pdf.save();
  }

  Future<void> _exportToPdf() async {
    setState(() => _exporting = true);
    await Future.delayed(Duration.zero);

    try {
      final exportEntries = _history.take(100).toList();
      final fontData = await rootBundle.load('assets/fonts/Roboto-Regular.ttf');
      final fontBytes = fontData.buffer.asUint8List();

      final bytes = await compute(_buildPdfInIsolate, {
        'entries': exportEntries,
        'font': fontBytes,
      });

      if (kIsWeb) {
        final blob = html.Blob([bytes]);
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..setAttribute('download', 'history_report.pdf')
          ..click();
        html.Url.revokeObjectUrl(url);
      } else {
        final directory = await getTemporaryDirectory();
        final filePath = '${directory.path}/history_report.pdf';
        final file = File(filePath);
        await file.writeAsBytes(bytes);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ PDF экспорт завершён')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Ошибка PDF: $e')),
      );
    } finally {
      setState(() => _exporting = false);
    }
  }

  Future<void> _exportToJson() async {
    setState(() => _exporting = true);
    await Future.delayed(Duration.zero);

    try {
      final data = _history.map((e) => e.toJson()).toList();
      final jsonString = JsonEncoder.withIndent('  ').convert(data);
      final bytes = utf8.encode(jsonString);

      if (kIsWeb) {
        final blob = html.Blob([bytes]);
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..setAttribute('download', 'history_export.json')
          ..click();
        html.Url.revokeObjectUrl(url);
      } else {
        final directory = await getTemporaryDirectory();
        final filePath = '${directory.path}/history_export.json';
        final file = File(filePath);
        await file.writeAsBytes(bytes);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ JSON экспорт завершён')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Ошибка экспорта JSON: $e')),
      );
    } finally {
      setState(() => _exporting = false);
    }
  }

  Future<void> _clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    if (token == null) return;

    try {
      final response = await http.delete(
        Uri.parse('http://localhost:8000/history'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        setState(() => _history.clear());
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('История успешно очищена')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Не удалось очистить историю')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка при удалении: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
          tooltip: 'Назад',
        ),
        title: Text('История анализов'),
        actions: [
          _exporting
              ? Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Center(
                      child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))),
                )
              : IconButton(
                  icon: Icon(Icons.picture_as_pdf),
                  onPressed: _exportToPdf,
                  tooltip: 'Экспорт PDF',
                ),
          _exporting
              ? SizedBox(width: 48)
              : IconButton(
                  icon: Icon(Icons.download),
                  onPressed: _exportToJson,
                  tooltip: 'Экспорт JSON',
                ),
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: _exporting ? null : _clearHistory,
            tooltip: 'Очистить',
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 1000),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 5,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: _loading
                    ? Center(child: CircularProgressIndicator())
                    : _error != null
                        ? Center(child: Text(_error!))
                        : _history.isEmpty
                            ? Center(child: Text('История пуста'))
                            : ListView.builder(
                                shrinkWrap: true,
                                itemCount: _history.length,
                                itemBuilder: (context, index) {
                                  final r = _history[index];
                                  return ExpansionTile(
                                    leading: Icon(Icons.code),
                                    title: Text('Анализ №${index + 1}'),
                                    subtitle:
                                        Text('Нажмите, чтобы раскрыть детали'),
                                    children: [
                                      ListTile(
                                        title: Text('⏱ Время выполнения:'),
                                        subtitle: Text('${r.estimatedHours} ч'),
                                      ),
                                      ListTile(
                                        title: Text('🧮 Численная сложность:'),
                                        subtitle: Text('${r.complexityScore}'),
                                      ),
                                      ListTile(
                                        title:
                                            Text('🧷 Индекс поддерживаемости:'),
                                        subtitle:
                                            Text('${r.maintainabilityIndex}'),
                                      ),
                                      ListTile(
                                        title: Text(
                                            '🔀 Цикломатическая сложность:'),
                                        subtitle:
                                            Text('${r.cyclomaticComplexity}'),
                                      ),
                                      ListTile(
                                        title: Text('📦 Количество функций:'),
                                        subtitle: Text('${r.numFunctions}'),
                                      ),
                                      ListTile(
                                        title:
                                            Text('💬 Качество комментариев:'),
                                        subtitle:
                                            Text('${r.commentQualityScore}'),
                                      ),
                                      ListTile(
                                        title: Text('📂 Жёсткие пути:'),
                                        subtitle: Text(r.usesHardcodedDirs
                                            ? 'Обнаружены'
                                            : 'Не обнаружены'),
                                      ),
                                      Divider(),
                                      ListTile(
                                        title:
                                            Text('🧮 Пояснение по сложности:'),
                                        subtitle: Text(r.summaryComplexity),
                                      ),
                                      ListTile(
                                        title: Text(
                                            '🧷 Пояснение по поддерживаемости:'),
                                        subtitle: Text(r.summarySupportability),
                                      ),
                                      ListTile(
                                        title: Text(
                                            '💬 Пояснение по комментариям:'),
                                        subtitle: Text(r.summaryComments),
                                      ),
                                      ListTile(
                                        title:
                                            Text('📦 Пояснение по структуре:'),
                                        subtitle: Text(r.summaryStructure),
                                      ),
                                      ListTile(
                                        title: Text('📂 Пояснение по путям:'),
                                        subtitle: Text(r.summaryPaths),
                                      ),
                                      ListTile(
                                        title: Text('Код:'),
                                        subtitle: SingleChildScrollView(
                                          scrollDirection: Axis.horizontal,
                                          child: Text(
                                            r.code,
                                            style: TextStyle(
                                              fontFamily: 'monospace',
                                              fontSize: 14,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurface,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
