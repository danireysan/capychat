import 'package:chat_app/core/utils/custom_getters.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:timeago/timeago.dart' as timeago;

class UserModel {
  String? pfpUrl;
  String? name;
  String? email;
  String? username;
  Timestamp? userActivityTs;
  DateTime? lastSeenDate;

  String dateToString() {
    String? format = timeago.format(lastSeenDate!);
    return format;
  }

  UserModel({
    this.pfpUrl,
    this.name,
    this.email,
    this.username,
    this.userActivityTs,
    this.lastSeenDate,
  });

  UserModel.fromDocument(DocumentSnapshot documentSnapshot) {
    pfpUrl = documentSnapshot.getString('imgUrl');
    name = documentSnapshot.getString('name');
    email = documentSnapshot.getString('email');
    username = documentSnapshot.getString('username');
    userActivityTs = documentSnapshot.getTimeStamp('userActivityTs');
    lastSeenDate = documentSnapshot.getDateFromTs('userActivityTs');
  }
}
