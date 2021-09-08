import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';

class Configurations extends StatefulWidget {
  @override
  _ConfigurationsState createState() => _ConfigurationsState();
}

class _ConfigurationsState extends State<Configurations> {
  TextEditingController _nameController = TextEditingController();
  File _image;
  String _loggedUserId;
  bool _uploading = false;
  String _imageUrl;

  Future _requestImage(String originImage) async {
    File selectedImage;
    switch (originImage) {
      case "camera":
        selectedImage = await ImagePicker.pickImage(source: ImageSource.camera);
        break;
      case "gallery":
        selectedImage =
            await ImagePicker.pickImage(source: ImageSource.gallery);
        break;
    }

    setState(() {
      _image = selectedImage;
      if (_image != null) {
        _uploading = true;
        _uploadImage();
      }
    });
  }

  Future _uploadImage() async {
    FirebaseStorage storage = FirebaseStorage.instance;
    StorageReference rootFolder = storage.ref();
    StorageReference file =
        rootFolder.child("profile").child(_loggedUserId + ".jpg");

    //Upload da image
    StorageUploadTask task = file.putFile(_image);

    //Controlar progresso do upload
    task.events.listen((StorageTaskEvent storageEvent) {
      if (storageEvent.type == StorageTaskEventType.progress) {
        setState(() {
          _uploading = true;
        });
      }
    });

    //Recuperar url da image
    task.onComplete.then((StorageTaskSnapshot snapshot) {
      _recuperarUrlImagem(snapshot);
    });
  }

  Future _recuperarUrlImagem(StorageTaskSnapshot snapshot) async {
    String url = await snapshot.ref.getDownloadURL();
    _atualizarUrlImagemFirestore(url);

    setState(() {
      _imageUrl = url;
      _uploading = false;
    });
  }

  _updateFirestoreName() {
    String name = _nameController.text;
    Firestore db = Firestore.instance;

    Map<String, dynamic> updateData = {"name": name};

    db.collection("users").document(_loggedUserId).updateData(updateData);

    Navigator.of(context).pop();
  }

  _atualizarUrlImagemFirestore(String url) {
    Firestore db = Firestore.instance;

    Map<String, dynamic> updateData = {"imageUrl": url};

    db.collection("users").document(_loggedUserId).updateData(updateData);
  }

  _requestUserData() async {
    FirebaseAuth auth = FirebaseAuth.instance;
    FirebaseUser loggedUser = await auth.currentUser();
    _loggedUserId = loggedUser.uid;

    Firestore db = Firestore.instance;
    DocumentSnapshot snapshot =
        await db.collection("users").document(_loggedUserId).get();

    Map<String, dynamic> data = snapshot.data;
    _nameController.text = data["name"];

    if (data["imageUrl"] != null) {
      setState(() {
        _imageUrl = data["imageUrl"];
        ;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _requestUserData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Configurations"),
      ),
      body: Container(
        padding: EdgeInsets.all(16),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              children: <Widget>[
                Container(
                  padding: EdgeInsets.all(16),
                  child: _uploading ? CircularProgressIndicator() : Container(),
                ),
                CircleAvatar(
                    radius: 100,
                    backgroundColor: Colors.grey,
                    backgroundImage:
                        _imageUrl != null ? NetworkImage(_imageUrl) : null),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    FlatButton(
                      child: Text("Camera"),
                      onPressed: () {
                        _requestImage("camera");
                      },
                    ),
                    FlatButton(
                      child: Text("Gallery"),
                      onPressed: () {
                        _requestImage("gallery");
                      },
                    )
                  ],
                ),
                Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: TextField(
                    controller: _nameController,
                    autofocus: true,
                    keyboardType: TextInputType.text,
                    style: TextStyle(fontSize: 20),
                    /*onChanged: (text){
                      _updateFirestoreName(text);
                    },*/
                    decoration: InputDecoration(
                        contentPadding: EdgeInsets.fromLTRB(32, 16, 32, 16),
                        hintText: "Name",
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(32))),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(top: 16, bottom: 10),
                  child: RaisedButton(
                      child: Text(
                        "Save",
                        style: TextStyle(color: Colors.white, fontSize: 20),
                      ),
                      color: Colors.green,
                      padding: EdgeInsets.fromLTRB(32, 16, 32, 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(32)),
                      onPressed: () {
                        _updateFirestoreName();
                      }),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
