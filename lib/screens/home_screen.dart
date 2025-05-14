import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/analysis_service.dart';
import '../models/analysis_result.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _codeController = TextEditingController();
  AnalysisResult? _result;
  bool _isLoading = false;
  String? _error;
  int _selectedChartIndex = 0;
  final List<String> _chartTypes = ['Столбчатая', 'Круговая'];

  Future<void> _analyzeCode() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    if (token == null) {
      setState(() => _error = 'Нет токена, авторизуйтесь заново');
      return;
    }

    try {
      final result = await AnalysisService.analyzeCode(
        _codeController.text,
        token,
      );
      setState(() {
        _result = result;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _openHistory() {
    Navigator.pushNamed(context, '/history');
  }

  void _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    Navigator.pushReplacementNamed(context, '/login');
  }

  Widget buildChart(AnalysisResult result) {
    final reference = {
      'estimatedHours': result.refEstimatedHours,
      'complexityScore': result.refComplexityScore,
      'maintainabilityIndex': result.refMaintainabilityIndex,
      'commentQualityScore': result.refCommentQualityScore * 100,
    };

    if (_selectedChartIndex == 0) {
      return BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceEvenly,
          maxY: 100,
          barTouchData: BarTouchData(enabled: true),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, _) {
                  switch (value.toInt()) {
                    case 0:
                      return Text('Часы');
                    case 1:
                      return Text('Сложн.');
                    case 2:
                      return Text('Поддерж.');
                    case 3:
                      return Text('Коммент.');
                  }
                  return Text('');
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: true, reservedSize: 32),
            ),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          barGroups: [
            BarChartGroupData(x: 0, barRods: [
              BarChartRodData(
                  toY: result.estimatedHours.clamp(0, 100),
                  color: Colors.blue,
                  width: 12),
              BarChartRodData(
                  toY: reference['estimatedHours']!.clamp(0, 100),
                  color: Colors.grey.shade400,
                  width: 12),
            ]),
            BarChartGroupData(x: 1, barRods: [
              BarChartRodData(
                  toY: result.complexityScore.clamp(0, 100),
                  color: Colors.orange,
                  width: 12),
              BarChartRodData(
                  toY: reference['complexityScore']!.clamp(0, 100),
                  color: Colors.grey.shade400,
                  width: 12),
            ]),
            BarChartGroupData(x: 2, barRods: [
              BarChartRodData(
                  toY: result.maintainabilityIndex.clamp(0, 100),
                  color: Colors.green,
                  width: 12),
              BarChartRodData(
                  toY: reference['maintainabilityIndex']!.clamp(0, 100),
                  color: Colors.grey.shade400,
                  width: 12),
            ]),
            BarChartGroupData(x: 3, barRods: [
              BarChartRodData(
                  toY: (result.commentQualityScore * 100).clamp(0, 100),
                  color: Colors.purple,
                  width: 12),
              BarChartRodData(
                  toY: reference['commentQualityScore']!.clamp(0, 100),
                  color: Colors.grey.shade400,
                  width: 12),
            ]),
          ],
          gridData: FlGridData(show: true),
          borderData: FlBorderData(show: false),
        ),
      );
    } else {
      return PieChart(
        PieChartData(
          sections: [
            PieChartSectionData(
              value: result.maintainabilityIndex,
              title: 'Поддерж.',
              color: Colors.green,
              radius: 60,
            ),
            PieChartSectionData(
              value: result.complexityScore,
              title: 'Сложность',
              color: Colors.redAccent,
              radius: 60,
            ),
          ],
          sectionsSpace: 4,
          centerSpaceRadius: 30,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Оценка трудозатрат кода'),
        actions: [
          IconButton(
            icon: Icon(Icons.history),
            onPressed: _openHistory,
            tooltip: 'История',
          ),
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Выход',
          )
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 1400),
          child: SingleChildScrollView(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 6,
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('Введите код для анализа:',
                            style: Theme.of(context).textTheme.headlineMedium),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _codeController,
                          maxLines: 8,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(),
                            hintText:
                                'Например: Функция Пример() Возврат 1 КонецФункции;',
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _isLoading ? null : _analyzeCode,
                          icon: Icon(Icons.search),
                          label: Text(_isLoading ? 'Анализ...' : 'Оценить'),
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 14),
                            textStyle: TextStyle(fontSize: 16),
                          ),
                        ),
                        const SizedBox(height: 24),
                        if (_error != null)
                          Text('Ошибка: $_error',
                              style: TextStyle(color: Colors.red)),
                        if (_result != null) ...[
                          Divider(height: 32),
                          Text('Результат анализа:',
                              style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 12),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 3,
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    ExpansionTile(
                                      title: Text(
                                          '⏱ Время: ${_result!.estimatedHours} ч (эталон: ${_result!.refEstimatedHours})'),
                                      children: [
                                        Padding(
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 16),
                                          child:
                                              Text(_result!.summaryStructure),
                                        ),
                                      ],
                                    ),
                                    ExpansionTile(
                                      title: Text(
                                          '🧮 Сложность: ${_result!.complexityScore} (эталон: ${_result!.refComplexityScore})'),
                                      children: [
                                        Padding(
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 16),
                                          child:
                                              Text(_result!.summaryComplexity),
                                        ),
                                      ],
                                    ),
                                    ExpansionTile(
                                      title: Text(
                                          '🧷 Поддерживаемость: ${_result!.maintainabilityIndex} (эталон: ${_result!.refMaintainabilityIndex})'),
                                      children: [
                                        Padding(
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 16),
                                          child: Text(
                                              _result!.summarySupportability),
                                        ),
                                      ],
                                    ),
                                    ExpansionTile(
                                      title: Text(
                                          '🔀 Цикломатическая сложность: ${_result!.cyclomaticComplexity}'),
                                      children: [
                                        Padding(
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 16),
                                          child: Text(
                                              'Чем выше показатель, тем больше ветвлений в коде.'),
                                        ),
                                      ],
                                    ),
                                    ExpansionTile(
                                      title: Text(
                                          '📦 Функции: ${_result!.numFunctions}'),
                                      children: [
                                        Padding(
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 16),
                                          child:
                                              Text(_result!.summaryStructure),
                                        ),
                                      ],
                                    ),
                                    ExpansionTile(
                                      title: Text(
                                          '💬 Комментарии: ${_result!.commentQualityScore} (эталон: ${_result!.refCommentQualityScore})'),
                                      children: [
                                        Padding(
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 16),
                                          child: Text(_result!.summaryComments),
                                        ),
                                      ],
                                    ),
                                    ExpansionTile(
                                      title: Text(
                                          '📂 Хардкод: ${_result!.usesHardcodedDirs ? "обнаружен" : "не обнаружен"}'),
                                      children: [
                                        Padding(
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 16),
                                          child: Text(_result!.summaryPaths),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 24),
                              Expanded(
                                flex: 2,
                                child: Column(
                                  children: [
                                    Text('📊 Диаграмма:',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: List.generate(
                                          _chartTypes.length, (index) {
                                        return Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 4),
                                          child: ChoiceChip(
                                            label: Text(_chartTypes[index]),
                                            selected:
                                                _selectedChartIndex == index,
                                            onSelected: (_) {
                                              setState(() =>
                                                  _selectedChartIndex = index);
                                            },
                                          ),
                                        );
                                      }),
                                    ),
                                    const SizedBox(height: 8),
                                    SizedBox(
                                        height: 260,
                                        child: buildChart(_result!)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                        ]
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
