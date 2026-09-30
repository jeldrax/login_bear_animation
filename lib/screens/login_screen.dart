import 'package:flutter/material.dart';
import 'package:rive/rive.dart';

import 'dart:async'; //3.1 importar el timer para el delay de la animacion(de detenga un tiempo y luego cambie de estado)

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _obscureText = true;

  //1.1 Crear el cerebro de la animacion
  StateMachineController? _controller;
  //SMI: State Machine Input / entrada de maquina de estado
  SMIBool? _isChecking;
  SMIBool? _isHandsUp;
  SMITrigger? _trigSuccess;
  SMITrigger? _trigFail;
  SMINumber? _numLook;

  //3.3 Timer para detener la mirada al terminar de escribir y luego cambiar de estado
  Timer? _typingDebunce;

  //Paso 2.1 Crear las variables para focus
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  //2.2 listeners(oyente/chismosos)
  @override
  void initState() {
    super.initState();
    _emailFocus.addListener(() {
      if (_emailFocus.hasFocus) {
        //verificar que no sea nulo
        if (_isHandsUp != null) {
          //manos abajo en el emial
          _isHandsUp?.change(false);
          //3.4 Detener el timer si esta activo(mirada neutra)
          _numLook?.value = 50.0;
        }
      }
    });

    _passwordFocus.addListener(() {
      //verificar que no sea nulo
      if (_isHandsUp != null) {
        _isHandsUp?.change(_passwordFocus.hasFocus);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Para obtener el tamaño de la pantalla
    final Size size = MediaQuery.of(context).size;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              SizedBox(
                width: size.width,
                height: 200,
                child: RiveAnimation.asset(
                  'assets/login-bear.riv',
                  stateMachines: ['Login Machine'],

                  //
                  onInit: (artboart) {
                    _controller = StateMachineController.fromArtboard(
                      artboart,
                      'Login Machine',
                    );

                    //1.3 Verificar
                    if (_controller == null) return;
                    //agrega controlador a escenario
                    artboart.addController(_controller!);
                    //vinculamos variables
                    _isChecking = _controller!.findSMI('isChecking');
                    _isHandsUp = _controller!.findSMI('isHandsUp');
                    _trigSuccess = _controller!.findSMI('trigSuccess');
                    _trigFail = _controller!.findSMI('trigFail');
                    //3.5 Vincular la variable de mirada
                    _numLook = _controller!.findSMI('numLook');
                  },
                ),
              ),

              //para separar espacios
              SizedBox(height: 10),

              //Campo de texto para el email
              TextField(
                //2.3 asignar foco al campo de texto
                focusNode: _emailFocus,
                onChanged: (value) {
                  if (_isHandsUp != null) {
                    //No tapes los ojos al ver email
                    //_isHandsUp!.change(false);
                  }
                  //Si isChecking es nulo
                  if (_isChecking == null) return;
                  //Activar el modo chismoso
                  _isChecking!.change(true);

                  //3.6 Inicializar la variable de mirada (implementar numlook)
                  //agustes de los limites de la mirada del 0 al 100
                  //80 es la medida calibracion
                  final look = (value.length / 80.0 * 100.0).clamp(0.0, 100.0);
                  //clamp es el rango (abrazadera)
                  _numLook?.value = look;
                  //3.7 DEbounce si vulve a teclear, reiniciar el contador
                  //primero cancelar cualquier timer existente
                  _typingDebunce?.cancel();
                  //crear un nuevo timer
                  _typingDebunce = Timer(const Duration(seconds: 3), () {
                    //si se cierra la pantalla, quita el contador
                    if (!mounted) return;
                    //mirada neutra
                    _isChecking?.change(false);
                  });
                },

                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: 'Email',
                  prefixIcon: const Icon(Icons.email),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              SizedBox(height: 10),
              //Campo de texto para la contraseña
              TextField(
                //2.3 asignar foco al campo de texto
                focusNode: _passwordFocus,
                onChanged: (value) {
                  if (_isChecking != null) {
                    //No tapes los ojos al ver email
                    //_isChecking!.change(false);
                  }
                  //Si isChecking es nulo
                  if (_isHandsUp == null) return;
                  //Activar el modo chismoso
                  _isHandsUp!.change(true);
                },
                obscureText: _obscureText,
                decoration: InputDecoration(
                  hintText: 'Password',
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    //IF terniario
                    icon: Icon(
                      _obscureText ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      //Refrescar el icono
                      setState(() {
                        _obscureText = !_obscureText;
                      });
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    //2.4 Liberar memoria de los focus
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _typingDebunce?.cancel(); //3.9 eliminar el timer
    super.dispose();
  }
}
