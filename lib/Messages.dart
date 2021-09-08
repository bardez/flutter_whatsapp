import 'dart:async';
import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'model/Chat.dart';
import 'model/Message.dart';
import 'model/User.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class Messages extends StatefulWidget {
  User contact;

  Messages(this.contact);

  @override
  _MessagesState createState() => _MessagesState();
}

class _MessagesState extends State<Messages> {
  File _image;
  bool _uploading = false;
  String _loggedUserId;
  String _sentUserId;
  DocumentSnapshot _loggedUser;
  DocumentSnapshot _sentUser;
  Firestore db = Firestore.instance;
  TextEditingController _mesageController = TextEditingController();

  final _controller = StreamController<QuerySnapshot>.broadcast();
  ScrollController _scrollController = ScrollController();

  _sendMessage() {
    String messageText = _mesageController.text;
    if (messageText.isNotEmpty) {
      Message message = Message();
      message.userId = _loggedUserId;
      message.message = messageText;
      message.imageUrl = "";
      message.type = "text";
      message.data = Timestamp.now().toString();

      _saveMessage(_loggedUserId, _sentUserId, message);
      _saveMessage(_sentUserId, _loggedUserId, message);

      _saveChat(message);
    }
  }

  _saveChat(Message msg) {
    Chat cFrom = Chat();
    cFrom.sentId = _loggedUserId;
    cFrom.fromId = _sentUserId;
    cFrom.message = msg.message;
    cFrom.name = _sentUser.data['name'];
    cFrom.photoUrl = _sentUser.data['imageUrl'];
    cFrom.messageType = msg.type;
    cFrom.save();

    Chat cTo = Chat();
    cTo.sentId = _sentUserId;
    cTo.fromId = _loggedUserId;
    cTo.message = msg.message;
    cTo.name = _loggedUser.data['name'];
    cTo.photoUrl = _loggedUser.data['imageUrl'];
    cTo.messageType = msg.type;
    cTo.save();
  }

  _saveMessage(String sentId, String fromId, Message msg) async {
    await db
        .collection("messages")
        .document(sentId)
        .collection(fromId)
        .add(msg.toMap());

    //Limpa text
    _mesageController.clear();
  }

  _sendPhoto() async {
    File selectedImage;
    selectedImage = await ImagePicker.pickImage(source: ImageSource.gallery);

    _uploading = true;
    String imageName = DateTime.now().millisecondsSinceEpoch.toString();
    FirebaseStorage storage = FirebaseStorage.instance;
    StorageReference rootFolder = storage.ref();
    StorageReference file = rootFolder
        .child("messages")
        .child(_loggedUserId)
        .child(imageName + ".jpg");

    //Upload da image
    StorageUploadTask task = file.putFile(selectedImage);

    //Controlar progresso do upload
    task.events.listen((StorageTaskEvent storageEvent) {
      if (storageEvent.type == StorageTaskEventType.progress) {
        setState(() {
          _uploading = true;
        });
      } else if (storageEvent.type == StorageTaskEventType.success) {
        setState(() {
          _uploading = false;
        });
      }
    });

    //Recuperar url da image
    task.onComplete.then((StorageTaskSnapshot snapshot) {
      _requestImageUrl(snapshot);
    });
  }

  Future _requestImageUrl(StorageTaskSnapshot snapshot) async {
    String url = await snapshot.ref.getDownloadURL();

    Message message = Message();
    message.userId = _loggedUserId;
    message.message = "";
    message.imageUrl = url;
    message.type = "image";
    message.data = Timestamp.now().toString();

    _saveMessage(_loggedUserId, _sentUserId, message);
    _saveMessage(_sentUserId, _loggedUserId, message);
  }

  _requestUserData() async {
    FirebaseAuth auth = FirebaseAuth.instance;
    FirebaseUser loggedUser = await auth.currentUser();
    _loggedUserId = loggedUser.uid;
    _sentUserId = widget.contact.userId;

    _sentUser = await db.collection("users").document(_sentUserId).get();
    _loggedUser = await db.collection("users").document(_loggedUserId).get();

    _addMessageListeners();
  }

  Stream<QuerySnapshot> _addMessageListeners() {
    final stream = db
        .collection("messages")
        .document(_loggedUserId)
        .collection(_sentUserId)
        .orderBy("data", descending: false)
        .snapshots();

    stream.listen((data) {
      _controller.add(data);
      Timer(Duration(seconds: 1), () {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      });
    });
  }

  @override
  void initState() {
    super.initState();
    _requestUserData();
  }

  @override
  Widget build(BuildContext context) {
    var messageBox = Container(
      padding: EdgeInsets.all(8),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: 8),
              child: TextField(
                controller: _mesageController,
                autofocus: true,
                keyboardType: TextInputType.text,
                style: TextStyle(fontSize: 20),
                decoration: InputDecoration(
                    contentPadding: EdgeInsets.fromLTRB(32, 8, 32, 8),
                    hintText: "Type a message...",
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(32)),
                    prefixIcon: _uploading
                        ? CircularProgressIndicator()
                        : IconButton(
                            icon: Icon(Icons.camera_alt),
                            onPressed: _sendPhoto)),
              ),
            ),
          ),
          Platform.isIOS
              ? CupertinoButton(
                  child: Text("Send"),
                  onPressed: _sendMessage,
                )
              : FloatingActionButton(
                  backgroundColor: Color(0xff075E54),
                  child: Icon(
                    Icons.send,
                    color: Colors.white,
                  ),
                  mini: true,
                  onPressed: _sendMessage,
                )
        ],
      ),
    );

    var stream = StreamBuilder(
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
            QuerySnapshot querySnapshot = snapshot.data;

            if (snapshot.hasError) {
              return Text("Error loading messages!");
            } else {
              return Expanded(
                child: ListView.builder(
                    controller: _scrollController,
                    itemCount: querySnapshot.documents.length,
                    itemBuilder: (context, indice) {
                      //recupera message
                      List<DocumentSnapshot> messages =
                          querySnapshot.documents.toList();
                      DocumentSnapshot item = messages[indice];

                      double larguraContainer =
                          MediaQuery.of(context).size.width * 0.8;

                      //Define cores e alinhamentos
                      Alignment alinhamento = Alignment.centerRight;
                      Color cor = Color(0xffd2ffa5);
                      if (_loggedUserId != item.data["userId"]) {
                        alinhamento = Alignment.centerLeft;
                        cor = Colors.white;
                      }

                      return Align(
                        alignment: alinhamento,
                        child: Padding(
                          padding: EdgeInsets.all(6),
                          child: Container(
                            width: larguraContainer,
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                                color: cor,
                                borderRadius:
                                    BorderRadius.all(Radius.circular(8))),
                            child: item.data["type"] == "text"
                                ? Text(
                                    item.data["message"],
                                    style: TextStyle(fontSize: 18),
                                  )
                                : Image.network(item.data["imageUrl"]),
                          ),
                        ),
                      );
                    }),
              );
            }

            break;
        }
      },
    );

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: <Widget>[
            CircleAvatar(
                maxRadius: 20,
                backgroundColor: Colors.grey,
                backgroundImage: widget.contact.imageUrl != null
                    ? NetworkImage(widget.contact.imageUrl)
                    : null),
            Padding(
              padding: EdgeInsets.only(left: 8),
              child: Text(widget.contact.name),
            )
          ],
        ),
      ),
      body: Container(
        width: MediaQuery.of(context).size.width,
        decoration: BoxDecoration(
            image: DecorationImage(
                image: AssetImage("images/bg.png"), fit: BoxFit.cover)),
        child: SafeArea(
            child: Container(
          padding: EdgeInsets.all(8),
          child: Column(
            children: <Widget>[
              stream,
              messageBox,
            ],
          ),
        )),
      ),
    );
  }
}
