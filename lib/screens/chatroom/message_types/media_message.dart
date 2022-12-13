import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:chat_app/models/message_model.dart';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

class MediaType {
  final String mediaUrl;
  final bool isVideo;

  MediaType(this.mediaUrl, this.isVideo);
}

class MediaMessageWidget extends HookWidget {
  const MediaMessageWidget(this.chatMessagelModel, {Key? key})
      : super(key: key);

  final ChatMesssageModel chatMessagelModel;

  @override
  Widget build(BuildContext context) {
    final urlList = useStream(useMemoized(
      () => contentType(chatMessagelModel.resUrls),
    ));

    return GestureDetector(
      // onTap: () => Navigator.of(context).push(MaterialPageRoute(
      //   builder: (context) =>
      //       GalleryWidget(
      //         contentType: urlList.requireData,
      //       ),
      // )),
      child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.45,
          child: urlList.hasData
              ? mediaType(urlList.data!)
              : const CircularProgressIndicator()),
    );
  }

  Widget mediaType(List<MediaType> contentList) {
    final listLenght = contentList.length;

    bool isASingleVideo = listLenght == 1 && contentList.first.isVideo;
    if (isASingleVideo) {
      return SingleImageWidget(chatMessagelModel.thumnailUrls!.first, true);
    }

    bool isASingleImage = listLenght == 1 && !contentList.first.isVideo;
    if (isASingleImage) {
      return SingleImageWidget(contentList.first.mediaUrl, false);
    }
    return const CircularProgressIndicator();
  }

  urlContainsVideo(url) async {
    final storageRef = FirebaseStorage.instance;
    final metadata = await storageRef.refFromURL(url).getMetadata();
    final contentType = metadata.contentType;
    if (contentType!.isEmpty) {
      throw "There is no available metadata";
    }
    final isVideo = contentType.contains("video");

    return isVideo;
  }

  // This stream checks if the content of url is either a video or simple image, the purpose of this
  // is not sending a video file to an image widget which makes the app crash.
  Stream<List<MediaType>> contentType(List<String>? urlList) async* {
    List<MediaType> contentList = [];

    if (urlList == null) throw "Your list is null";

    for (var i = 0; i < urlList.length; i++) {
      final mediaUrl = urlList[i];
      final isVideo = await urlContainsVideo(mediaUrl);

      contentList.add(MediaType(mediaUrl, isVideo));

      yield contentList;
    }
  }
}

class SingleImageWidget extends StatelessWidget {
  final String mediaUrl;
  final bool isVideoThumnail;
  const SingleImageWidget(this.mediaUrl, this.isVideoThumnail, {Key? key})
      : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CachedNetworkImage(imageUrl: mediaUrl),
        isVideoThumnail ? const Icon(Icons.play_arrow) : const SizedBox()
      ],
    );
  }
}

class MultimediaWidget extends StatelessWidget {
  final ChatMesssageModel chatMesssageModel;
  const MultimediaWidget({Key? key, required this.chatMesssageModel})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}

class GalleryWidget extends StatelessWidget {
  const GalleryWidget({Key? key, required this.messageModel, required this.contentType})
      : super(key: key);

  final List<ContentType> contentType;
  final List<ChatMesssageModel> messageModel;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            flex: 5,
            child: PhotoViewGallery.builder(
              backgroundDecoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor),
              itemCount: contentType.length,
              builder: (_, index) {
                return PhotoViewGalleryPageOptions.customChild(
                  initialScale: PhotoViewComputedScale.contained * 0.8,
                  minScale: PhotoViewComputedScale.contained * 0.8,
                  maxScale: PhotoViewComputedScale.covered * 1.1,
                  child: SizedBox(),
                );
              },
              loadingBuilder: (_, __) => const Center(
                child: CircularProgressIndicator(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
