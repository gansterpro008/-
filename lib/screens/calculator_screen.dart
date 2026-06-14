import 'package:flutter/material.dart';

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});
  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  final _display = TextEditingController(text: '0');
  double _value1 = 0;
  double _value2 = 0;
  String _op = '';
  bool _newNumber = true;

  void _input(String c) {
    setState(() {
      if (c == 'C') {
        _display.text = '0'; _value1 = 0; _value2 = 0; _op = ''; _newNumber = true;
      } else if (c == '+' || c == '-' || c == '*' || c == '/') {
        _value1 = double.tryParse(_display.text) ?? 0; _op = c; _newNumber = true;
      } else if (c == '=') {
        _value2 = double.tryParse(_display.text) ?? 0;
        double result = 0;
        switch (_op) {
          case '+': result = _value1 + _value2; break;
          case '-': result = _value1 - _value2; break;
          case '*': result = _value1 * _value2; break;
          case '/': result = _value2 != 0 ? _value1 / _value2 : 0; break;
        }
        _display.text = result.toStringAsFixed(2);
        _newNumber = true;
      } else {
        if (_newNumber) { _display.text = ''; _newNumber = false; }
        _display.text += c;
      }
    });
  }

  @override
  void dispose() { _display.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Калькулятор')),
      body: Column(children: [
        Container(
          padding: const EdgeInsets.all(24),
          alignment: Alignment.centerRight,
          child: Text(_display.text, style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w300)),
        ),
        Expanded(
          child: GridView.count(
            crossAxisCount: 4,
            padding: const EdgeInsets.all(8),
            childAspectRatio: 1.3,
            children: [
              'C','±','%','/',
              '7','8','9','*',
              '4','5','6','-',
              '1','2','3','+',
              '0','00','.','=',
            ].map((c) => Padding(
              padding: const EdgeInsets.all(4),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: c == '=' ? Theme.of(context).colorScheme.primary : null,
                  foregroundColor: c == '=' ? Theme.of(context).colorScheme.onPrimary : null,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => _input(c),
                child: Text(c, style: const TextStyle(fontSize: 22)),
              ),
            )).toList(),
          ),
        ),
      ]),
    );
  }
}
