import 'dart:io';

import 'dart:math' as math;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../../../../../../core/widgets/animated_icon_button.dart';
import '../../../../../../core/widgets/keyboard_visibility_builder.dart';
import 'media_preview/media_preview_widget.dart';

class MediaMenu extends HookWidget {
  const MediaMenu({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const duration = Duration(milliseconds: 500);

    final menuAnimationController = useAnimationController(
      duration: duration,
    );

    ValueNotifier<bool> showMenu = useState(false);
    if (showMenu.value) menuAnimationController.forward();
    if (!showMenu.value) menuAnimationController.reverse();
    //---------------------------------
    // Show row icons related variables
    //---------------------------------
    final Animation<Offset> rowAnimation = Tween<Offset>(
      begin: const Offset(-2.75, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: menuAnimationController,
      curve: Curves.decelerate,
    ));

    //----------------------------------------
    // Overlay related functions and variables
    //----------------------------------------
    final animationList = useState<List>([]);
    GlobalKey globalKey = GlobalKey();

    final overlayState = useState(Overlay.of(context));

    final overlayPosition = useState<Offset>(Offset.zero);
    final overlaySize = useState<Size>(Size.zero);

    List<Widget> columnButtons = [
      IconButton(
        onPressed: () {},
        icon: const Icon(Icons.insert_drive_file_outlined),
      ),
      IconButton(
        onPressed: () {},
        icon: const Icon(Icons.headphones_outlined),
      ),
      IconButton(
        onPressed: () {},
        icon: const Icon(Icons.attach_file_outlined),
      ),
    ];

    overlayEntryWidget() {
      return OverlayEntry(
        builder: (context) {
          return Positioned(
            left: overlayPosition.value.dx,
            top: overlayPosition.value.dy - overlaySize.value.height * 4.25,
            width: overlaySize.value.width,
            child: Material(
                color: Colors.transparent,
                shadowColor: Colors.transparent,
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: columnButtons.length,
                  itemBuilder: (context, index) {
                    return ScaleTransition(
                      scale: animationList.value[index],
                      child: columnButtons[index],
                    );
                  },
                )),
          );
        },
      );
    }

    final overlayEntry = useState<OverlayEntry?>(null);

    removeOverlay() {
      if (overlayEntry.value == null) return;
      overlayEntry.value!.remove();
      // We set it to null to avoid an assertion error,
      // that's why the overlayEntry variable is not final as well and is nullable as well

      overlayEntry.value = null;
    }

    showOverlayWidget() {
      // We get a renderbox to get the overlay the current size of the widget and offset
      RenderBox? renderBox =
          globalKey.currentContext!.findRenderObject() as RenderBox?;

      overlayPosition.value = renderBox!.localToGlobal(const Offset(-8.0, 0.0));
      overlaySize.value = renderBox.size;

      // We assign an animation to every item of our button list
      for (int i = columnButtons.length; i > 0; i--) {
        animationList.value.add(Tween(begin: 0.0, end: 1.0).animate(
            CurvedAnimation(
                parent: menuAnimationController,
                curve: Interval(0.2 * i, 1.0, curve: Curves.ease))));
      }

      overlayEntry.value = overlayEntryWidget();

      overlayState.value.insert(overlayEntry.value!);

      // When the animation is completed we no longer have to listen
      menuAnimationController.addStatusListener((status) {
        if (status == AnimationStatus.dismissed) removeOverlay();
      });
    }

    useEffect(() => () => overlayEntry.value?.remove(), []);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        KeyboardVisibilityBuilder(
            onPositionChange: (position) {
              RenderBox? renderBox =
                  globalKey.currentContext!.findRenderObject() as RenderBox?;
              final newPosition =
                  renderBox!.localToGlobal(const Offset(-8.0, 0.0));
              overlayPosition.value = newPosition;

              overlayEntry.value?.markNeedsBuild();
            },
            child: AnimatedIconButton(
              key: globalKey,
              startIcon: Icons.arrow_forward_ios_rounded,
              endIcon: Icons.apps_rounded,
              onTap: () {
                showOverlayWidget();
                showMenu.value = !showMenu.value;
              },
              animationController: menuAnimationController,
            ),
            builder: (context, child, isKeyboardVisible) => child),
        // This prevents the animated container from overflowing
        AnimatedContainer(
          height: 48,
          width: showMenu.value ? 104 : 0.0,
          duration: duration,
          curve: showMenu.value ? Curves.elasticOut : Curves.ease,
          child: ClipRect(
            child: Row(
              children: [
                mediaPickerIconButton(rowAnimation, showMenu, context),
                cameraIconButton(rowAnimation, overlayEntry, context),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Flexible cameraIconButton(Animation<Offset> rowAnimation,
      ValueNotifier<OverlayEntry?> overlayEntry, BuildContext context) {
    return Flexible(
      child: SlideTransition(
        position: rowAnimation,
        child: IconButton(
            onPressed: () async {
              overlayEntry.value?.remove();
            },
            icon: const Icon(Icons.camera_alt_outlined)),
      ),
    );
  }

  Widget mediaPickerIconButton(
    Animation<Offset> rowAnimation,
    ValueNotifier<bool> showMenu,
    BuildContext context,
  ) {
    return Flexible(
      child: SlideTransition(
        position: rowAnimation,
        child: IconButton(
          onPressed: () async {
            showMenu.value = false;
            // We remove the overlay because it
            // We initialize a navigator here because this way,
            // we handle that flutter doesn't run any code
            // in an async gap where we don't know if the user has picked any files
            final navigator = Navigator.of(context);
            FilePickerResult? result = await FilePicker.platform.pickFiles(
              allowMultiple: true,
              type: FileType.media,
            );

            if (result == null) return;
            List<File> files = result.paths.map((path) => File(path!)).toList();
            navigator.push(MaterialPageRoute(
              builder: (_) => ImagePreview(imageFileList: files),
            ));
          },
          icon: const Icon(Icons.filter_outlined),
        ),
      ),
    );
  }
}
