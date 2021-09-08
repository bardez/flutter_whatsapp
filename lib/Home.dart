import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:whastapp/screens/ContactsTab.dart';
import 'package:whastapp/screens/ChatsTab.dart';
import 'dart:io';
import 'Login.dart';

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> with SingleTickerProviderStateMixin {
  TabController _tabController;
  List<String> menuItems = ["Configurations", "Logout"];
  String _userEmail = "";

  Future _requestUserData() async {
    FirebaseAuth auth = FirebaseAuth.instance;
    FirebaseUser loggedUser = await auth.currentUser();

    setState(() {
      _userEmail = loggedUser.email;
    });
  }

  Future _verificarloggedUser() async {
    FirebaseAuth auth = FirebaseAuth.instance;

    FirebaseUser loggedUser = await auth.currentUser();

    if (loggedUser == null) {
      Navigator.pushReplacementNamed(context, "/login");
    }
  }

  @override
  void initState() {
    super.initState();
    _verificarloggedUser();
    _requestUserData();
    _tabController = TabController(length: 2, vsync: this);
  }

  _escolhaMenuItem(String itemEscolhido) {
    switch (itemEscolhido) {
      case "Configurations":
        Navigator.pushNamed(context, "/configurations");
        break;
      case "Logout":
        _logoutUser();
        break;
    }
  }

  _logoutUser() async {
    FirebaseAuth auth = FirebaseAuth.instance;
    await auth.signOut();

    Navigator.pushReplacementNamed(context, "/login");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("WhatsApp"),
        elevation: Platform.isIOS ? 0 : 4,
        bottom: TabBar(
          indicatorWeight: 4,
          labelStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          controller: _tabController,
          indicatorColor: Platform.isIOS ? Colors.grey[400] : Colors.white,
          tabs: <Widget>[
            Tab(
              text: "Chat",
            ),
            Tab(
              text: "Contacts",
            )
          ],
        ),
        actions: <Widget>[
          PopupMenuButton<String>(
            onSelected: _escolhaMenuItem,
            itemBuilder: (context) {
              return menuItems.map((String item) {
                return PopupMenuItem<String>(
                  value: item,
                  child: Text(item),
                );
              }).toList();
            },
          )
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: <Widget>[ChatsTab(), ContactsTabs()],
      ),
    );
  }
}
