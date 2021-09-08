import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'Register.dart';
import 'Home.dart';
import 'RouteGenerator.dart';
import 'model/User.dart';
import 'package:toast/toast.dart';

class Login extends StatefulWidget {
  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
  TextEditingController _emailController = TextEditingController(text: "");
  TextEditingController _passwordController = TextEditingController(text: "");

  _fildValdations() {
    FocusScopeNode currentFocus = FocusScope.of(context);
    if (!currentFocus.hasPrimaryFocus && currentFocus.focusedChild != null) {
      FocusManager.instance.primaryFocus.unfocus();
    }

    String email = _emailController.text;
    String password = _passwordController.text;

    if (email.isNotEmpty && email.contains("@")) {
      if (password.isNotEmpty) {
        User user = User();
        user.email = email;
        user.password = password;

        _userLogin(user);
      } else {
        Toast.show("Fill password!", context,
            backgroundColor: Colors.red, textColor: Colors.white, duration: 5);
      }
    } else {
      Toast.show("Fill email using @", context,
          backgroundColor: Colors.red, textColor: Colors.white, duration: 5);
    }
  }

  _userLogin(User user) {
    FirebaseAuth auth = FirebaseAuth.instance;

    auth
        .signInWithEmailAndPassword(email: user.email, password: user.password)
        .then((firebaseUser) {
      Navigator.pushReplacementNamed(context, "/home");
    }).catchError((error) {
      Toast.show(
          "User authentication failed, verify email and password and try again",
          context,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          duration: 5);
    });
  }

  Future _verifyLoggedUser() async {
    FirebaseAuth auth = FirebaseAuth.instance;
    FirebaseUser loggedUser = await auth.currentUser();

    if (loggedUser != null) {
      Navigator.pushReplacementNamed(context, "/home");
    }
  }

  @override
  void initState() {
    _verifyLoggedUser();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(color: Color(0xff075E54)),
        padding: EdgeInsets.all(16),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.only(bottom: 32),
                  child: Image.asset(
                    "images/logo.png",
                    width: 200,
                    height: 150,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: TextField(
                    controller: _emailController,
                    autofocus: true,
                    keyboardType: TextInputType.emailAddress,
                    style: TextStyle(fontSize: 20),
                    decoration: InputDecoration(
                        contentPadding: EdgeInsets.fromLTRB(32, 16, 32, 16),
                        hintText: "Email",
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(32))),
                  ),
                ),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  keyboardType: TextInputType.text,
                  style: TextStyle(fontSize: 20),
                  decoration: InputDecoration(
                      contentPadding: EdgeInsets.fromLTRB(32, 16, 32, 16),
                      hintText: "Password",
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(32))),
                ),
                Padding(
                  padding: EdgeInsets.only(top: 16, bottom: 10),
                  child: RaisedButton(
                      child: Text(
                        "Login",
                        style: TextStyle(color: Colors.white, fontSize: 20),
                      ),
                      color: Colors.green,
                      padding: EdgeInsets.fromLTRB(32, 16, 32, 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(32)),
                      onPressed: () {
                        _fildValdations();
                      }),
                ),
                Center(
                  child: GestureDetector(
                    child: Text("Don't have an account? Sign Up Here!",
                        style: TextStyle(color: Colors.white)),
                    onTap: () {
                      Navigator.push(context,
                          MaterialPageRoute(builder: (context) => Register()));
                    },
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
