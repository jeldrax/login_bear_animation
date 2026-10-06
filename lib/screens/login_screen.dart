import 'dart:async'; //3.1 importar el timer para el delay de la animacion(de detenga un tiempo y luego cambie de estado)

import 'package:flutter/material.dart';
import 'package:rive/rive.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _obscureText = true;

  // Variables para ADA 9: Remember Me y Control Anti-Spam
  bool _rememberMe = false;
  bool _isAnimatingToggle = false; // Bandera para bloquear toques rápidos
  Timer? _toggleLockTimer; // Timer para liberar el bloqueo tras la animación

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

  //4.1 controller que manipula lo que el usuario escribe
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  //Errores para monstarlo en la interfaz gráfica
  String? emailError;
  String? passError;

  //4.3 validadores
  bool isValidEmail(String email) {
    // Expresión regular para validar el formato del correo electrónico
    final re = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    return re.hasMatch(email);
  }

  bool isValidPassword(String pass) {
    final re = RegExp(
      r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^A-Za-z0-9]).{8,}$',
    );
    // Verifica que la contraseña tenga al menos 6 caracteres
    return re.hasMatch(pass);
  }

  //4.4 Validar los campos de texto
  void _onLogin() {
    //4.5 De lo que escribio el usuario, quitar los espacios en blanco al inicio y al final
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text;

    //4.6 Validar el correo electrónico si cumple con el formato correcto
    final eError = isValidEmail(email) ? null : 'Invalid email format';
    final pError = isValidPassword(pass) ? null : 'Invalid password';

    //4.7 Avisamos que bhubo cambio
    setState(() {
      emailError = eError;
      passError = pError;
    });

    //4.8 Cerrar el teclado y bajar las manos del oso
    FocusScope.of(context).unfocus(); //quita el foco
    _typingDebunce
        ?.cancel(); //detener el timer si esta activo de que esta mirando
    _isChecking?.change(false); //mirada neutra
    _isHandsUp?.change(false); //bajar las manos del oso
    _numLook?.value = 50.0; //mirada neutra

    //4.9 activar triggers
    if (eError == null && pError == null) {
      _trigSuccess?.fire();
    } else {
      _trigFail?.fire();
    }
  }

  // Función para manejar la interacción de Remember Me evitando Spam Clicks
  void _onToggleRememberMe(bool? value) {
    // Si la animación está corriendo, ignoramos los clics
    if (_isAnimatingToggle) return;

    setState(() {
      _isAnimatingToggle = true; // Bloquear interacción inmediatamente
      _rememberMe = value ?? false;
    });

    // Reacción visual del oso
    FocusScope.of(context).unfocus();
    _isHandsUp?.change(false);
    _isChecking?.change(true);
    _numLook?.value = 50.0;

    _typingDebunce?.cancel();
    _typingDebunce = Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      _isChecking?.change(false);
    });

    // Simular tiempo de animación para liberar el bloqueo anti-spam
    _toggleLockTimer?.cancel();
    _toggleLockTimer = Timer(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      setState(() {
        _isAnimatingToggle = false; // Liberar bloqueo
      });
    });
  }

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
      body: SingleChildScrollView(
        child: SafeArea(
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
                  //4.10 enlazar controller
                  controller: _emailCtrl,

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
                    final look = (value.length / 80.0 * 100.0).clamp(
                      0.0,
                      100.0,
                    );
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
                    //4.12 mostrar error
                    errorText: emailError,
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
                  //4.10 enlazar controller
                  controller: _passCtrl,
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
                    //4.12 mostrar error
                    errorText: passError,
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
                SizedBox(height: 10),

                // Fila con Remember Me y Forgot Password
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // AbsorbPointer absorbe los toques mientras _isAnimatingToggle sea true (Anti-Spam)
                    AbsorbPointer(
                      absorbing: _isAnimatingToggle,
                      child: GestureDetector(
                        onTap: () => _onToggleRememberMe(!_rememberMe),
                        child: Row(
                          children: [
                            Checkbox(
                              value: _rememberMe,
                              activeColor: Colors.pinkAccent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                              onChanged: _onToggleRememberMe,
                            ),
                            const Text('Remember me'),
                          ],
                        ),
                      ),
                    ),
                    const Text(
                      'Forgot Password?',
                      style: TextStyle(
                        decoration: TextDecoration.underline,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                //boton de login
                MaterialButton(
                  minWidth: size.width,
                  height: 50,
                  color: Colors.pinkAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      25,
                    ), // Ajusta este número a tu gusto
                  ),
                  onPressed: _onLogin,
                  child: Text('Login', style: TextStyle(color: Colors.white)),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: size.width,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Don't have an account?"),
                      TextButton(
                        onPressed: () {},
                        // Handle sign up action},
                        child: const Text(
                          "Sign Up",
                          style: TextStyle(
                            color: Colors.pinkAccent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    //4.15liberar los controladores
    _emailCtrl.dispose();
    _passCtrl.dispose();
    //2.4 Liberar memoria de los focus
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _typingDebunce?.cancel(); //3.9 eliminar el timer
    _toggleLockTimer?.cancel(); // Liberar memoria del timer anti-spam
    _controller?.dispose();
    super.dispose();
  }
}
