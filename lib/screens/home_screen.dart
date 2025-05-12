import 'package:flutter/material.dart';
import '../services/analysis_service.dart';
import '../models/analysis_result.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _codeController = TextEditingController();
  AnalysisResult? _result;
  bool _isLoading = false;
  String? _error;

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
          constraints: BoxConstraints(maxWidth: 800),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              elevation: 6,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
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
                        hintText: 'Например, def example(): return 42',
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
                      const SizedBox(height: 8),
                      Text('Оценка времени: ${_result!.estimatedHours} ч'),
                      Text('Сложность: ${_result!.complexity}'),
                      Text('Комментарий: ${_result!.summary}')
                    ]
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
