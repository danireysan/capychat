import 'package:chat_app/helperfunctions/sharedpreferences_helper.dart';
import 'package:chat_app/services/database.dart';
import 'package:flutter/material.dart';
import 'package:random_string/random_string.dart';

class ChatScreen extends StatefulWidget {
  final String chatwithUsername, name;
  const ChatScreen(
      {Key? key, required this.chatwithUsername, required this.name})
      : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  TextEditingController messageController = TextEditingController();
  String? chatroomId, messageId;
  String? myName, myProfilePic, myUserName, myEmail;

  Stream? messageStream;

  getInfoFromSharePreference() async {
    myName = await SharedPreferencesHelper().getDisplayName();
    myProfilePic = await SharedPreferencesHelper().getUserProfile();
    myUserName = await SharedPreferencesHelper().getUserName();
    myEmail = await SharedPreferencesHelper().getUserEmail();

    chatroomId = getChatRoomId(widget.chatwithUsername, myUserName);
  }

  String getChatRoomId(String? a, String? b) {
    if (a!.substring(0, 1).codeUnitAt(0) > b!.substring(0, 1).codeUnitAt(0)) {
      // ignore: unnecessary_string_escapes
      return "$b\_$a";
    } else {
      // ignore: unnecessary_string_escapes
      return "$a\_$b";
    }
  }

  getAndSetMessage() async {
    
  }

  addMessage(bool sendClicked) {
    if (messageController.text != "") {
      String message = messageController.text;

      var lastMessageTs = DateTime.now();

      Map<String, dynamic> messageInfoMap = {
        "message": message,
        "sendBy": myUserName,
        "ts": lastMessageTs,
        "imgUrl": myProfilePic,
      };

      messageId ??= randomAlphaNumeric(12).toString();

      DatabaseMethods()
          .addMessage(chatroomId!, messageId!, messageInfoMap)
          .then((value) {
        Map<String, dynamic> lastMessageInfo = {
          "lastMessage": message,
          "lastMessageSendTs": lastMessageTs,
          "lastMessageSendBy": myUserName,
        };

        

        DatabaseMethods().updateLastMessageSend(chatroomId!, lastMessageInfo);

        

        if (sendClicked) {
          // remove the text in the message input field
          messageController.text = "";
          // make message id blank to get regenerated on next message send
          messageId = "";
        }
      });
    }
  }

  doThisOnLauch() async {
    await getInfoFromSharePreference();
    getAndSetMessage();
  }

  @override
  void initState() {
    doThisOnLauch();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.name),
      ),
      body: Stack(
        children: [
          Container(
            alignment: Alignment.bottomCenter,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: addMessage(false),
                    controller: messageController,
                    decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: "Type a message",
                        hintStyle: TextStyle(fontWeight: FontWeight.w500)),
                  ),
                ),
                GestureDetector(
                    onTap: () {
                      addMessage(true);
                    },
                    child: const Icon(Icons.send))
              ],
            ),
          )
        ],
      ),
    );
  }
}
