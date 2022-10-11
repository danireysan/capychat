import 'package:animate_icons/animate_icons.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import 'package:random_string/random_string.dart';

import '../../../globals.dart';
import '../../../services/database.dart';

class ChatInputField extends HookWidget {
  final String chatteeName;
  const ChatInputField({
    Key? key,
    required this.chatteeName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String messageId = "";
    String? chatterPfp = FirebaseAuth.instance.currentUser?.photoURL;
    TextEditingController messageController = useTextEditingController();
    String chatRoomId = getChatRoomIdByUsernames(chatteeName, chatterUsername!);

    // This controls whether the media menu is display or not
    ValueNotifier<bool> showMenu = useValueNotifier(false);

    // This controls whether the mic icon is show or not
    ValueNotifier<bool> showMic = useValueNotifier(true);

    // We track input to toggle the mic
    void toggle() {
      if (messageController.text == "") showMic.value = true;
      // To avoid the var being constantly called
      var length = messageController.text.length;
      if (length > 0 && length < 2) showMic.value = false;
    }

    useEffect(() {
      messageController.addListener(toggle);
      return () => messageController.removeListener(toggle);
    });

    addMessage(bool sendClicked) {
      if (messageController.text != "") {
        String message = messageController.text;

        var lastMessageTs = DateTime.now();

        Map<String, dynamic> messageInfoMap = {
          "message": message,
          "sendBy": chatterUsername,
          "ts": lastMessageTs,
          "imgUrl": chatterPfp,
          "messageType": "text",
        };

        //messageId
        if (messageId == "") {
          messageId = randomAlphaNumeric(12);
        }

        DatabaseMethods()
            .addMessage(chatRoomId, messageId, messageInfoMap)
            .then(
          (value) {
            Map<String, dynamic> lastMessageInfoMap = {
              "lastMessage": message,
              "lastMessageSendTs": lastMessageTs,
              "lastMessageSendBy": chatterUsername,
            };

            DatabaseMethods()
                .updateLastMessageSend(chatRoomId, lastMessageInfoMap);

            if (sendClicked) {
              messageController.text = "";
              messageId = "";
            }
          },
        );
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: kDefaultPadding,
        vertical: kDefaultPadding / 2,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
              offset: const Offset(0, 4),
              blurRadius: 32,
              color: const Color(0xFF087949).withOpacity(0.08)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          mediaMenu(showMenu),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: kDefaultPadding * 0.75),
              decoration: BoxDecoration(
                color: kPrimaryColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(40),
              ),
              child: TextField(
                controller: messageController,
                maxLength: 800,
                minLines: 1,
                maxLines: 5, // This way the textfield grows
                keyboardType: TextInputType.multiline,
                decoration: const InputDecoration(
                  // This hides the counter that appears when you set a chat limit
                  counterText: "",
                  hintText: "Type a message",
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          HookBuilder(
            builder: (context) {
              final toggle = useValueListenable(showMic);
              if (toggle) {
                return IconButton(
                    onPressed: () {}, icon: const Icon(Icons.mic));
              }
              return IconButton(
                onPressed: () => addMessage(true),
                icon: const Icon(Icons.send),
              );
            },
          )
        ],
      ),
    );
  }

  Widget mediaMenu(ValueNotifier<bool> toggle) {
    final controller = AnimateIconController();
    const duration = Duration(milliseconds: 500);

    return HookBuilder(
      builder: (BuildContext context) {
        bool isSelected = useValueListenable(toggle);
        final animationController = useAnimationController(duration: duration);
        late final Animation<Offset> offsetAnimation = Tween<Offset>(
          begin: const Offset(-2.75, 1),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animationController,
          curve: Curves.decelerate,
        ));

        if (isSelected) animationController.forward();
        if (!isSelected) animationController.reverse();

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimateIcons(
              duration: duration,
              startIcon: Icons.arrow_forward_ios_rounded,
              endIcon: Icons.apps_rounded,
              onStartIconPress: () {
                debugPrint("mediaMenu: Shrink");
                toggle.value = !toggle.value;
                return true;
              },
              onEndIconPress: () {
                debugPrint("mediaMenu: Grow");
                toggle.value = !toggle.value;
                return true;
              },
              controller: controller,
            ),
            // This prevents the animated container from overflowing
            ClipRect(
              child: AnimatedContainer(
                height: 48,
                width: isSelected ? 104 : 0.0,
                duration: duration,
                curve: isSelected ? Curves.elasticOut : Curves.ease,
                child: ClipRect(
                  child: Row(
                    children: [
                      Flexible(
                        child: SlideTransition(
                          position: offsetAnimation,
                          child: IconButton(
                              onPressed: () {},
                              icon: const Icon(Icons.attach_file)),
                        ),
                      ),
                      Flexible(
                        child: SlideTransition(
                          position: offsetAnimation,
                          child: IconButton(
                              onPressed: () {},
                              icon: const Icon(Icons.filter_outlined)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}