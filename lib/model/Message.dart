class Message {
  String _userId;
  String _message;
  String _imageUrl;

  //Define o type da message, que pode ser "text" ou "image"
  String _type;

  String _data;

  Message();

  Map<String, dynamic> toMap() {
    Map<String, dynamic> map = {
      "userId": this.userId,
      "message": this.message,
      "imageUrl": this.imageUrl,
      "type": this.type,
      "data": this.data,
    };

    return map;
  }

  String get data => _data;

  set data(String value) {
    _data = value;
  }

  String get type => _type;

  set type(String value) {
    _type = value;
  }

  String get imageUrl => _imageUrl;

  set imageUrl(String value) {
    _imageUrl = value;
  }

  String get message => _message;

  set message(String value) {
    _message = value;
  }

  String get userId => _userId;

  set userId(String value) {
    _userId = value;
  }
}
