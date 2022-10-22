import 'package:cached_network_image/cached_network_image.dart';
import 'package:chat_app/globals.dart';
import 'package:chat_app/models/message_model.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/database.dart';


import 'message_types/text_message_widget.dart';
import 'message_types/video_widget.dart';
import 'message_types/audio_message_widget.dart';
import 'chat_input/chat_input_field.dart';
import 'dot_indicator_widget.dart';


final sliderPosition = StateProvider((ref) => 0.0,);
class Body extends HookWidget {
  final List<QueryDocumentSnapshot> querySnapshot;
  final String chatteName;
  const Body({
    Key? key,
    required this.querySnapshot,
    required this.chatteName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          flex: 5,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding),
            child: ListView.builder(
              reverse: true,
              shrinkWrap: true,
              itemCount: querySnapshot.length,
              itemBuilder: (BuildContext context, int index) {
                ChatMesssageModel model =
                    ChatMesssageModel.fromDocument(querySnapshot[index]);
                return Message(
                  chatteeName: chatteName,
                  message: model,
                );
              },
            ),
          ),
        ),
        
        ChatInputField(
          chatteeName: chatteName,
        ),
      ],
    );
  }
}

class Message extends HookWidget {
  final ChatMesssageModel message;
  final String chatteeName;
  const Message({
    Key? key,
    required this.message,
    required this.chatteeName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget messageContent(ChatMesssageModel message) {
      final map = {
        ChatMessageType.text: TextMessage(message: message),
        ChatMessageType.audio: AudioMessage(message: message),
        ChatMessageType.video: const VideoWidget(),
      };
      Widget type = map[message.messageType] ?? const SizedBox();
      return type;
    }

    final chatteFuture =
        useMemoized(() => DatabaseMethods().getUserInfo(chatteeName));

    QuerySnapshot? chatteData = useFuture(chatteFuture).data;

    String? chattePfp = chatteData?.docs[0]["imgUrl"];
  

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: kDefaultPadding / 4),
      child: Row(
        crossAxisAlignment: message.isSender!
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.center,
        mainAxisAlignment:
            message.isSender! ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!message.isSender!) ...[
            Container(
              margin: const EdgeInsets.only(right: kDefaultPadding / 2),
              child: CircleAvatar(
                radius: 12,
                backgroundImage: CachedNetworkImageProvider(chattePfp ?? noImage),
              ),
            )
          ],
          messageContent(message),
          if (message.isSender!)
            MessageStatusDot(
              status: message.messageStatus!,
            ),
        ],
      ),
    );
  }
}
