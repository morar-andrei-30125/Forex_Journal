// fisier: lib/screens/pin_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // NOU: Pentru tastatură
import 'package:shared_preferences/shared_preferences.dart';
import 'package:forex_journal_app/main.dart'; 

class PinScreen extends StatefulWidget {
  final bool isSettingPin; 
  final bool isChangingPin;

  const PinScreen({
    super.key, 
    this.isSettingPin = false,
    this.isChangingPin = false,
  });

  @override
  State<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends State<PinScreen> {
  String _enteredPin = '';
  String? _storedPin; 
  String? _newCandidatePin; 
  
  bool _isLoading = true;
  String _message = '';
  int _step = 0; 

  // NOU: FocusNode pentru a asculta tastatura fizică
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _initPinLogic();
    // Cerem focus imediat ce se deschide ecranul pentru a putea tasta direct
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose(); // Curățăm memoria
    super.dispose();
  }

  Future<void> _initPinLogic() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _storedPin = prefs.getString('user_pin');
      _isLoading = false;
      _updateMessage();
    });
  }

  // --- NOU: GESTIONAREA TASTELOR FIZICE ---
  void _handleKeyEvent(KeyEvent event) {
    // Reacționăm doar când tasta este apăsată jos (KeyDown), nu și când o ridici
    if (event is KeyDownEvent) {
      final key = event.logicalKey;

      // Cifrele 0-9 (atât cele de sus, cât și Numpad)
      if (key == LogicalKeyboardKey.digit0 || key == LogicalKeyboardKey.numpad0) _onNumberPress('0');
      else if (key == LogicalKeyboardKey.digit1 || key == LogicalKeyboardKey.numpad1) _onNumberPress('1');
      else if (key == LogicalKeyboardKey.digit2 || key == LogicalKeyboardKey.numpad2) _onNumberPress('2');
      else if (key == LogicalKeyboardKey.digit3 || key == LogicalKeyboardKey.numpad3) _onNumberPress('3');
      else if (key == LogicalKeyboardKey.digit4 || key == LogicalKeyboardKey.numpad4) _onNumberPress('4');
      else if (key == LogicalKeyboardKey.digit5 || key == LogicalKeyboardKey.numpad5) _onNumberPress('5');
      else if (key == LogicalKeyboardKey.digit6 || key == LogicalKeyboardKey.numpad6) _onNumberPress('6');
      else if (key == LogicalKeyboardKey.digit7 || key == LogicalKeyboardKey.numpad7) _onNumberPress('7');
      else if (key == LogicalKeyboardKey.digit8 || key == LogicalKeyboardKey.numpad8) _onNumberPress('8');
      else if (key == LogicalKeyboardKey.digit9 || key == LogicalKeyboardKey.numpad9) _onNumberPress('9');
      
      // Backspace sau Delete
      else if (key == LogicalKeyboardKey.backspace || key == LogicalKeyboardKey.delete) {
        _onDeletePress();
      }
    }
  }

  void _updateMessage() {
    if (widget.isChangingPin) {
      if (_step == 0) _message = 'Introdu PIN-ul actual';
      else if (_step == 1) _message = 'Introdu noul PIN';
      else if (_step == 2) _message = 'Confirmă noul PIN';
    } else if (widget.isSettingPin) {
      if (_step == 0) _message = 'Creează un PIN (4 cifre)';
      else if (_step == 1) _message = 'Confirmă PIN-ul';
    } else {
      _message = 'Introdu codul PIN';
    }
  }

  void _onNumberPress(String number) {
    if (_enteredPin.length < 4) {
      setState(() {
        _enteredPin += number;
      });

      if (_enteredPin.length == 4) {
        Future.delayed(const Duration(milliseconds: 100), () {
          _handlePinComplete();
        });
      }
    }
  }

  void _onDeletePress() {
    if (_enteredPin.isNotEmpty) {
      setState(() {
        _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
      });
    }
  }

  Future<void> _handlePinComplete() async {
    if (widget.isChangingPin) {
      if (_step == 0) {
        if (_enteredPin == _storedPin) {
          _nextStep(); 
        } else {
          _showError('PIN actual incorect');
        }
      } else if (_step == 1) {
        _newCandidatePin = _enteredPin;
        _nextStep(); 
      } else if (_step == 2) {
        if (_enteredPin == _newCandidatePin) {
          await _saveAndFinish();
        } else {
          _showError('PIN-urile nu se potrivesc.');
          setState(() {
            _step = 1;
            _enteredPin = '';
            _newCandidatePin = null;
            _updateMessage();
          });
        }
      }
    }
    else if (widget.isSettingPin) {
      if (_step == 0) {
        _newCandidatePin = _enteredPin;
        _nextStep();
      } else if (_step == 1) {
        if (_enteredPin == _newCandidatePin) {
          await _saveAndFinish();
        } else {
          _showError('Nu se potrivesc. Încearcă din nou.');
          setState(() {
            _step = 0; 
            _enteredPin = '';
            _newCandidatePin = null;
            _updateMessage();
          });
        }
      }
    }
    else {
      if (_enteredPin == _storedPin) {
        if (mounted) {
           MyApp.of(context)?.unlockApp();
        }
      } else {
        _showError('PIN Incorect');
      }
    }
  }

  void _nextStep() {
    setState(() {
      _step++;
      _enteredPin = '';
      _updateMessage();
    });
  }

  void _showError(String msg) async {
    setState(() {
      _enteredPin = '';
      _message = msg;
    });
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      setState(() {
        _updateMessage(); 
      });
    }
  }

  Future<void> _saveAndFinish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_pin', _enteredPin);

    if (mounted) {
      await MyApp.of(context)?.updatePinStatus();
      
      if (widget.isChangingPin && Navigator.canPop(context)) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PIN schimbat cu succes!')),
        );
      } 
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final buttonColor = isDark ? Colors.grey[800] : Colors.grey[200];

    // Îmbrăcăm tot ecranul în KeyboardListener
    return KeyboardListener(
      focusNode: _focusNode,
      onKeyEvent: _handleKeyEvent,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: widget.isChangingPin 
            ? AppBar(
                backgroundColor: Colors.transparent, 
                elevation: 0,
                iconTheme: IconThemeData(color: textColor),
              ) 
            : null,
        body: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline, size: 60, color: Colors.teal),
              const SizedBox(height: 20),
              Text(
                _message,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              
              // Buline
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (index) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    width: 15,
                    height: 15,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: index < _enteredPin.length ? Colors.teal : (isDark ? Colors.grey[700] : Colors.grey[300]),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 50),
      
              // Tastatura Ecran
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildNumberRow(['1', '2', '3'], isDark, textColor, buttonColor),
                    _buildNumberRow(['4', '5', '6'], isDark, textColor, buttonColor),
                    _buildNumberRow(['7', '8', '9'], isDark, textColor, buttonColor),
                    _buildNumberRow([null, '0', 'del'], isDark, textColor, buttonColor), 
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNumberRow(List<dynamic> items, bool isDark, Color textColor, Color? btnColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: items.map((item) {
          if (item == null) return const SizedBox(width: 70, height: 70);
          
          if (item == 'del') {
            return InkWell(
              onTap: _onDeletePress,
              borderRadius: BorderRadius.circular(35),
              child: Container(
                width: 70, height: 70, alignment: Alignment.center,
                child: Icon(Icons.backspace_outlined, size: 28, color: textColor),
              ),
            );
          }
      
          return InkWell(
            onTap: () => _onNumberPress(item),
            borderRadius: BorderRadius.circular(35),
            child: Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: btnColor,
              ),
              alignment: Alignment.center,
              child: Text(
                item,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: textColor),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}