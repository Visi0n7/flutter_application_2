import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _error;
  bool _loading = false;

  Future<void> _login() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final response = await http.post(
      Uri.parse('http://localhost:8000/login'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'username': _usernameController.text,
        'password': _passwordController.text,
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('access_token', data['access_token']);
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      setState(() {
        _error = 'Неверный логин или пароль';
      });
    }

    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 400),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Card(
              elevation: 6,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Вход в систему',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineMedium),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _usernameController,
                      decoration: InputDecoration(
                        labelText: 'Логин',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Пароль',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _loading ? null : _login,
                      icon: Icon(Icons.login),
                      label: Text(_loading ? 'Вход...' : 'Войти'),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        textStyle: TextStyle(fontSize: 16),
                      ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(_error!,
                          style: TextStyle(color: Colors.red),
                          textAlign: TextAlign.center),
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
