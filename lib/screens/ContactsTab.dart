import 'package:flutter/material.dart';
import 'package:whastapp/model/User.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ContactsTabs extends StatefulWidget {
  @override
  _ContactsTabsState createState() => _ContactsTabsState();
}

class _ContactsTabsState extends State<ContactsTabs> {
  String _loggedUserId;
  String _loggedUserEmail;

  Future<List<User>> _requestContacts() async {
    Firestore db = Firestore.instance;

    QuerySnapshot querySnapshot = await db.collection("users").getDocuments();

    List<User> userList = List();
    for (DocumentSnapshot item in querySnapshot.documents) {
      var _data = item.data;
      if (_data["email"] == _loggedUserEmail) continue;

      User user = User();
      user.userId = item.documentID;
      user.email = _data["email"];
      user.name = _data["name"];
      user.imageUrl = _data["imageUrl"];

      userList.add(user);
    }

    return userList;
  }

  _requestUserData() async {
    FirebaseAuth auth = FirebaseAuth.instance;
    FirebaseUser loggedUser = await auth.currentUser();
    _loggedUserId = loggedUser.uid;
    _loggedUserEmail = loggedUser.email;
  }

  @override
  void initState() {
    super.initState();
    _requestUserData();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<User>>(
      future: _requestContacts(),
      builder: (context, snapshot) {
        switch (snapshot.connectionState) {
          case ConnectionState.none:
          case ConnectionState.waiting:
            return Center(
              child: Column(
                children: <Widget>[
                  Text("Loading ..."),
                  CircularProgressIndicator()
                ],
              ),
            );
            break;
          case ConnectionState.active:
          case ConnectionState.done:
            return ListView.builder(
                itemCount: snapshot.data.length,
                itemBuilder: (_, indice) {
                  List<User> listItens = snapshot.data;
                  User usuario = listItens[indice];

                  return ListTile(
                    onTap: () {
                      Navigator.pushNamed(context, "/messages",
                          arguments: usuario);
                    },
                    contentPadding: EdgeInsets.fromLTRB(16, 8, 16, 8),
                    leading: CircleAvatar(
                        maxRadius: 30,
                        backgroundColor: Colors.grey,
                        backgroundImage: usuario.imageUrl != null
                            ? NetworkImage(usuario.imageUrl)
                            : null),
                    title: Text(
                      usuario.name,
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  );
                });
            break;
        }
      },
    );
  }
}
