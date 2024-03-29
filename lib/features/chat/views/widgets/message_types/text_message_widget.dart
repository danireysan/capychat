import 'package:chat_app/core/theme/sizes.dart';
import 'package:chat_app/features/chat/models/message_model.dart';
import 'package:flutter/material.dart';

import '../../../../../core/theme/colors.dart';

class TextMessage extends StatelessWidget {
  const TextMessage(this.message, {Key? key}) : super(key: key);

  final ChatMessageModel message;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
          maxHeight: double.infinity,
          maxWidth: MediaQuery.of(context).size.width * 0.4),
      padding: const EdgeInsets.symmetric(
        horizontal: kDefaultPadding * 0.75,
        vertical: kDefaultPadding / 2,
      ),
      decoration: BoxDecoration(
        color: kPrimaryColor.withOpacity(message.isSender ? 1 : 0.1),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        message.message,
        softWrap: true,
        style: TextStyle(
          fontSize: 12,
          color: message.isSender
              ? Colors.white
              : Theme.of(context).textTheme.bodyLarge?.color,
        ),
      ),
    );
  }
}
