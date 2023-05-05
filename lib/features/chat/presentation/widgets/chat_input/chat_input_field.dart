import 'package:chat_app/features/chat/presentation/widgets/chat_input/recording_widget.dart';
import 'package:chat_app/features/home/presentation/widgets/chat_card.dart';
import 'package:chat_app/features/chat/services/messaging_methods.dart';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../../core/theme/colors.dart';
import '../../../../../core/theme/sizes.dart';
import 'media_menu_widget.dart';

final showMicProvider = StateProvider((ref) => true);
final canAnimateProvider = StateProvider((ref) => false);

class ChatInputField extends HookConsumerWidget {
  const ChatInputField({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ------------------------------
    // Recording Widget related logic
    // ------------------------------
    const duration = Duration.zero;
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    final minutes = duration.inMinutes.remainder(60);
    startRecording() async =>
        await ref.read(recController.notifier).state.record();

    // ---------------------------------------------
    // Custom Send Button Listener related functions
    // ---------------------------------------------
    // We put this functions here because the custom send button gets dropped off the widget tree to do an animation,
    // and riverpod doesn't like when you listen to functions that are in a widget that is no longer in the widget tree
    late final double screenWidth = MediaQuery.of(context).size.width;
    late final double screenHeight = MediaQuery.of(context).size.height;
    late final showMic = ref.watch(showMicProvider);

    void fingerDown(PointerEvent details) {
      if (!showMic) return;
      ref.read(showAudioWidget.notifier).state = true;
      ref.read(canAnimateProvider.notifier).state = false;
      startRecording().then((value) {
        ref.read(isRecording.notifier).state = true;
        ref.read(recordDuration.notifier).state = '$minutes:$seconds';
      });
    }

    void fingerOff(PointerEvent details) {
      if (!showMic) return;
      // If the animation is in progress we don't want to show everything else yet
      if (ref.watch(wasAudioDiscarted)) return;
      ref.read(showAudioWidget.notifier).state = false;
      if (!ref.watch(isRecording)) return;
      if (!ref.watch(showControlRec)) {
        ref.read(isRecording.notifier).state = false;
        MessagingMethods(chatRoomId: ref.watch(chatroomId))
            .sendVoiceMessage(ref);
      }
    }

    void updateLocation(PointerEvent details) {
      ref.read(sliderPosition.notifier).state = details.position.dx;
      // This conditional gives functionality to the slidable widget that is found in the recording widget file
      if (details.position.dx < screenWidth * 0.5) {
        // This will stop the recorderz
        ref.read(recController.notifier).state.stop();
        ref.read(isRecording.notifier).state = false;
        ref.read(wasAudioDiscarted.notifier).state = true;
      }
      // If position.dy is greater than 0.25 of screenHeight, we want to toggle the the playable recording widget
      if (details.position.dy < screenHeight * 0.55) {
        ref.read(showControlRec.notifier).state = true;
      }
    }

    TextEditingController messageController = useTextEditingController();

    // ------------------------------------------------------------
    // Fuction that displays different widgets as app state changes
    // ------------------------------------------------------------
    List<Widget> rowList() {
      if (ref.watch(wasAudioDiscarted) || ref.watch(showControlRec)) {
        return [const RecordingWidget()];
      }

      if (ref.watch(showAudioWidget)) {
        return [
          const RecordingWidget(),
          CustomSendButton(
            fingerDown: fingerDown,
            fingerOff: fingerOff,
            updateLocation: updateLocation,
          )
        ];
      }
      return [
        const MediaMenu(),
        ChatRoomTextField(messageController: messageController),
        CustomSendButton(
          textEditingController: messageController,
          fingerDown: fingerDown,
          fingerOff: fingerOff,
          updateLocation: updateLocation,
        )
      ];
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
            color: const Color(0xFF087949).withOpacity(0.08),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: rowList(),
      ),
    );
  }
}

class CustomSendButton extends HookConsumerWidget {
  const CustomSendButton({
    Key? key,
    this.textEditingController,
    this.updateLocation,
    this.fingerDown,
    this.fingerOff,
  }) : super(key: key);

  // Parameters are optional because the app is not always in "send-message-state"
  final TextEditingController? textEditingController;
  final void Function(PointerEvent)? updateLocation;
  final void Function(PointerEvent)? fingerDown;
  final void Function(PointerEvent)? fingerOff;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final icon = useState(Icons.mic);
    final showMic = ref.watch(showMicProvider);

    final animationController =
        useAnimationController(duration: const Duration(milliseconds: 180));

    late final Animation<Offset> offsetAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(1.5, 0.0),
    ).animate(CurvedAnimation(
      parent: animationController,
      curve: Curves.bounceInOut,
    ));

    if (ref.watch(canAnimateProvider)) {
      animationController.forward();
      if (!ref.watch(showMicProvider)) animationController.forward();
    }

    animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        icon.value = Icons.mic;
        if (!showMic) icon.value = Icons.send;
        animationController.reverse();
      }
    });

    return Listener(
      onPointerUp: fingerOff,
      onPointerDown: fingerDown,
      onPointerMove: updateLocation,
      child: SlideTransition(
        position: offsetAnimation,
        child: IconButton(
          onPressed: showMic
              ? () {}
              : () => MessagingMethods(chatRoomId: ref.watch(chatroomId))
                      .addMessage(
                    textEditingController!,
                  ),
          icon: Icon(icon.value),
        ),
      ),
    );
  }
}

class ChatRoomTextField extends HookConsumerWidget {
  const ChatRoomTextField({
    Key? key,
    required this.messageController,
  }) : super(key: key);

  final TextEditingController messageController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Everytime the user writes we want to switch between the mic and the send button
    void toggle() {
      // The animation triggers when the user types, but also when the widget gets drawn
      // it looks kind of annoying when the animation triggers everytime, so we set the canAnimateProvider when the user types to prevent,
      // this annoying behaviorf
      ref.read(canAnimateProvider.notifier).state = true;
      if (messageController.text.isEmpty) {
        ref.read(showMicProvider.notifier).state = true;
      }
      if (messageController.text.isNotEmpty) {
        ref.read(showMicProvider.notifier).state = false;
      }
    }

    // We listen input to toggle the mic
    useEffect(() {
      messageController.addListener(toggle);
      return () => messageController.removeListener(toggle);
    });

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding * 0.75),
        decoration: BoxDecoration(
          color: kPrimaryColor.withOpacity(0.05),
          borderRadius: BorderRadius.circular(40),
        ),
        child: TextField(
          autofocus: true,
          controller: messageController,
          maxLength: 800,
          minLines: 1,
          maxLines: 5, // This way the textfield grows
          keyboardType: TextInputType.multiline,
          decoration: const InputDecoration(
            // This hides the counter that appears when you set a chat limit
            counterText: "",
            hintText: "Aa",
            border: InputBorder.none,
          ),
        ),
      ),
    );
  }
}
