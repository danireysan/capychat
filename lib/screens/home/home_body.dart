import 'package:chat_app/globals.dart';
import 'package:chat_app/screens/messages/messages_screen.dart';
import 'package:chat_app/services/database.dart';
import 'package:chat_app/screens/home/filledout_button.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:timeago/timeago.dart' as timeago;

class Body extends HookWidget {
  const Body({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var future = useMemoized(() => DatabaseMethods().getChatRooms());

    Stream<QuerySnapshot>? chatroomStream = useFuture(future).data;

    // This variable was created to filter chatroom stream data and toggle buttons

    ValueNotifier<bool> isActive = useState(false);
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(
            kDefaultPadding,
            0,
            kDefaultPadding,
            kDefaultPadding,
          ),
          color: kPrimaryColor,
          child: Row(
            children: [
              FillOutlineButton(
                press: () => isActive.value = !isActive.value,
                text: "Recent Messages",
                isFilled: !isActive.value,
              ),
              const SizedBox(width: kDefaultPadding),
              FillOutlineButton(
                press: () => isActive.value = !isActive.value,
                text: "Active",
                isFilled: isActive.value,
              ),
            ],
          ),
        ),
        StreamBuilder(
          stream: chatroomStream,
          builder:
              (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
            bool isWaiting =
                snapshot.connectionState == ConnectionState.waiting;
            if (isWaiting) {
              return const LinearProgressIndicator();
            }

            bool isRecent = snapshot.hasData && !isActive.value;
            if (isRecent) {
              // TODO: Add conditional that filters if users are active or not
              List<DocumentSnapshot> documentList = snapshot.data!.docs;
              return chatroomLb(documentList);
            }

            bool isAvailable = snapshot.hasData && isActive.value;
            if (isAvailable) {
              List<DocumentSnapshot> documentList = snapshot.data!.docs;
              return chatroomLb(documentList);
            }

            // TODO: Make an error screen
            return const Text("Something went wrong");
          },
        ),
      ],
    );
  }

  Widget chatroomLb(List<DocumentSnapshot> documentList) {
    return Expanded(
      child: ListView.builder(
        itemCount: documentList.length,
        itemBuilder: (BuildContext context, int index) {
          DocumentSnapshot documentSnapshot = documentList[index];
          return ChatCard(
            documentSnapshot: documentSnapshot,
          );
        },
      ),
    );
  }
}

class ChatCard extends StatelessWidget {
  final DocumentSnapshot documentSnapshot;
  const ChatCard({
    Key? key,
    required this.documentSnapshot,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // This variables are used on the future builder to fill data into the card itself
    String profilePicUrl = "",
        name = "",
        username = "",
        lastMessage = "",
        date = "";

    /* This variable is used to exclude the chatter name from a document id 
    (the chat document id is formed as a combination between the chatte and chatter username) 
    to get the chatte name and fetch the chatte info from a method
    */
    String? chatterUsername =
        FirebaseAuth.instance.currentUser?.email!.replaceAll("@gmail.com", "");

    Future<QuerySnapshot> getThisUserInfo() async {
      username = documentSnapshot.id
          .replaceAll(chatterUsername!, "")
          .replaceAll("_", "");
      return await DatabaseMethods().getUserInfo(username);
    }

    /* The idea of this variable was to check if the chatte is active but
    I don't have a clear idea of how to implement it yet, I might create a provider  */
    // DateTime fiveMinAgo = DateTime.now().subtract(const Duration(minutes: 5));
    return FutureBuilder(
        future: getThisUserInfo(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          bool hasData = snapshot.hasData;
          if (hasData) {
            profilePicUrl = snapshot.data!.docs[0]["imgUrl"];
            name = snapshot.data!.docs[0]["name"];
            username = snapshot.data!.docs[0]['username'];
            lastMessage = documentSnapshot["lastMessage"];
            DateTime dt =
                (documentSnapshot['lastMessageSendTs'] as Timestamp).toDate();
            date = timeago.format(dt);

            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MessagesScreen(
                      chatterName: chatterUsername!,
                      chatteeName: username,
                    ),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: kDefaultPadding,
                    vertical: kDefaultPadding * 0.75),
                child: Row(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundImage: NetworkImage(profilePicUrl),
                        ),
                        // TODO: add conditional to check if user is active

                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            height: 16,
                            width: 16,
                            decoration: BoxDecoration(
                              color: kPrimaryColor,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color:
                                    Theme.of(context).scaffoldBackgroundColor,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: kDefaultPadding),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 8),
                            Opacity(
                              opacity: 0.64,
                              child: Text(
                                lastMessage,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                    Opacity(
                      opacity: 0.64,
                      child: Text(date),
                    )
                  ],
                ),
              ),
            );
          }

          return const LinearProgressIndicator();
        });
  }
}