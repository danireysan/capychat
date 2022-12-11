import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:chat_app/models/message_model.dart';
import 'package:dio/dio.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:video_compress/video_compress.dart';

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
    final urlList =
        useStream(useMemoized(() => contentType(chatMessagelModel.resUrls)));

    if (!urlList.hasData) {
      return const CircularProgressIndicator();
    }

    return GestureDetector(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(
        builder: (context) =>
            GalleryWidget(imageFileList: chatMessagelModel.resUrls!),
      )),
      child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.45,
          child: urlList.hasData
              ? mediaType(urlList.data!)
              : const CircularProgressIndicator()),
    );
  }

  Widget mediaType(List<MediaType> contentList) {
    final listLenght = contentList.length;

    if (listLenght >= 2) {
      return const CircularProgressIndicator();
    }

    if (listLenght == 1 && contentList[0].isVideo) {
      return SingleVideoWidget(
        mediaType: contentList[0],
      );
    }

    return SingleImageWidget(mediaUrl: contentList[0].mediaUrl);
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
  const SingleImageWidget({Key? key, required this.mediaUrl}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(imageUrl: mediaUrl);
  }
}

class SingleVideoWidget extends HookWidget {
  final MediaType mediaType;
  const SingleVideoWidget({Key? key, required this.mediaType})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    downloadVideo() async {
      final path = await getTemporaryDirectory();
      final fullPath = '${path.path}/videos}';
      bool hasFile = (await File(fullPath).exists());

      if (!hasFile) {
        debugPrint("Downloading audio file");
        final response = await Dio().download(mediaType.mediaUrl, fullPath);
        if (response.statusCode == 200) {
          return File(fullPath);
        }
      }
      return File(fullPath);
    }

    getThumbnail(File videoFile) async {
      final thumbnailFile = await VideoCompress.getFileThumbnail(
        videoFile.path,
        quality: 50, // default(100)
        position: -1, // default(-1)
      );
      return thumbnailFile;
    }

    final videoFile = useFuture(useMemoized(
      () => downloadVideo(),
    ));

    if (!videoFile.hasData) {
      return const CircularProgressIndicator();
    }

    final videoThumbnail =
        useFuture(useMemoized(() => getThumbnail(videoFile.data!)));

    if (!videoThumbnail.hasData) {
      return const CircularProgressIndicator();
    }

    return Image(image: FileImage(videoThumbnail.requireData));
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
  const GalleryWidget({Key? key, required this.imageFileList})
      : super(key: key);

  final List<String> imageFileList;
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
              itemCount: imageFileList.length,
              builder: (_, index) {
                return PhotoViewGalleryPageOptions(
                  initialScale: PhotoViewComputedScale.contained * 0.8,
                  minScale: PhotoViewComputedScale.contained * 0.8,
                  maxScale: PhotoViewComputedScale.covered * 1.1,
                  imageProvider: NetworkImage(imageFileList[index]),
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
