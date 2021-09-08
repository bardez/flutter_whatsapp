import 'dart:async';
import 'package:flutter/material.dart';
import 'package:whastapp/model/Chat.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:whastapp/model/User.dart';

class ChatsTab extends StatefulWidget {
  @override
  _ChatsTabState createState() => _ChatsTabState();
}

class _ChatsTabState extends State<ChatsTab> {
  List<Chat> _listChat = List();
  final _controller = StreamController<QuerySnapshot>.broadcast();
  Firestore db = Firestore.instance;
  String _loggedUserId;

  @override
  void initState() {
    super.initState();
    _requestUserData();
  }

  Stream<QuerySnapshot> _addChatListener() {
    final stream = db
        .collection("chats")
        .document(_loggedUserId)
        .collection("last_chat")
        .snapshots();

    stream.listen((dados) {
      _controller.add(dados);
    });
  }

  _requestUserData() async {
    FirebaseAuth auth = FirebaseAuth.instance;
    FirebaseUser loggedUser = await auth.currentUser();
    _loggedUserId = loggedUser.uid;

    _addChatListener();
  }

  @override
  void dispose() {
    super.dispose();
    _controller.close();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _controller.stream,
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
            if (snapshot.hasError) {
              return Text("Error loading chats!");
            } else {
              QuerySnapshot querySnapshot = snapshot.data;

              if (querySnapshot.documents.length == 0) {
                return Center(
                  child: Text(
                    "You don't have any messages yet :( ",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                );
              }

              List<DocumentSnapshot> chats = querySnapshot.documents.toList();

              return ListView.builder(
                  itemCount: chats.length,
                  itemBuilder: (context, indice) {
                    DocumentSnapshot item = chats[indice];

                    String imageUrl = item["photoUrl"];
                    String type = item["messageType"];
                    String message = item["message"];
                    String name = item["name"];
                    String fromId = item["fromId"];

                    User user = User();
                    user.name = name;
                    user.imageUrl = imageUrl;
                    user.userId = fromId;

                    return ListTile(
                      onTap: () {
                        Navigator.pushNamed(context, "/messages",
                            arguments: user);
                      },
                      contentPadding: EdgeInsets.fromLTRB(16, 8, 16, 8),
                      leading: CircleAvatar(
                        maxRadius: 30,
                        backgroundColor: Colors.grey,
                        backgroundImage:
                            imageUrl != null ? NetworkImage(imageUrl) : null,
                      ),
                      title: Text(
                        name,
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      subtitle: Text(type == "text" ? message : "Image...",
                          style: TextStyle(color: Colors.grey, fontSize: 14)),
                    );
                  });
            }
        }
      },
    );
  }
}
