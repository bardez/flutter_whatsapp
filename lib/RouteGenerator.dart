import 'package:flutter/material.dart';

import 'Register.dart';
import 'Configurations.dart';
import 'Home.dart';
import 'Login.dart';
import 'Messages.dart';

class RouteGenerator {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    final args = settings.arguments;

    switch (settings.name) {
      case "/":
        return MaterialPageRoute(builder: (_) => Login());
      case "/login":
        return MaterialPageRoute(builder: (_) => Login());
      case "/register":
        return MaterialPageRoute(builder: (_) => Register());
      case "/home":
        return MaterialPageRoute(builder: (_) => Home());
      case "/configurations":
        return MaterialPageRoute(builder: (_) => Configurations());
      case "/messages":
        return MaterialPageRoute(builder: (_) => Messages(args));
      default:
        _erroRota();
    }
  }

  static Route<dynamic> _erroRota() {
    return MaterialPageRoute(builder: (_) {
      return Scaffold(
        appBar: AppBar(
          title: Text("Oops"),
        ),
        body: Center(
          child: Text("View not found!"),
        ),
      );
    });
  }
}
