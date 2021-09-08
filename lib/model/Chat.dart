import 'package:cloud_firestore/cloud_firestore.dart';

class Chat {
  String _sentId;
  String _fromId;
  String _name;
  String _message;
  String _photoUrl;
  String _messageType; //text ou image

  Chat();

  save() async {
    Firestore db = Firestore.instance;
    await db
        .collection("chats")
        .document(this.sentId)
        .collection("last_chat")
        .document(this.fromId)
        .setData(this.toMap());
  }

  Map<String, dynamic> toMap() {
    Map<String, dynamic> map = {
      "sentId": this.sentId,
      "fromId": this.fromId,
      "name": this.name,
      "message": this.message,
      "photoUrl": this.photoUrl,
      "messageType": this.messageType,
    };

    return map;
  }

  String get sentId => _sentId;

  set sentId(String value) {
    _sentId = value;
  }

  String get name => _name;

  set name(String value) {
    _name = value;
  }

  String get message => _message;

  String get photoUrl => _photoUrl;

  set photoUrl(String value) {
    _photoUrl = value;
  }

  set message(String value) {
    _message = value;
  }

  String get fromId => _fromId;

  set fromId(String value) {
    _fromId = value;
  }

  String get messageType => _messageType;

  set messageType(String value) {
    _messageType = value;
  }
}
