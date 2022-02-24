import 'package:chat_app/services/auth.dart';
import 'package:chat_app/services/database.dart';
import 'package:chat_app/views/chat_screen.dart';
import 'package:chat_app/views/signin.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool isSearching = false;

  Stream<QuerySnapshot>? usersStream;

  TextEditingController searchUsername = TextEditingController();

  onSearch() async {
    isSearching = true;
    usersStream =
        await DatabaseMethods().getUserByUsername(searchUsername.text);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("Capybara chat"),
          actions: [
            // May change to icon button
            InkWell(
              onTap: () {
                AuthMethods().signOut().then((_) {
                  Navigator.pushReplacement(context,
                      MaterialPageRoute(builder: (_) => const SignIn()));
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: const Icon(Icons.exit_to_app),
              ),
            )
          ],
        ),
        body: Column(
          children: [
            Row(
              children: [_searchEraseBtn(), _searchBar()],
            ),
            isSearching ? _searchUsersList() : _chatRoomList()
          ],
        ));
  }

  Widget _searchEraseBtn() {
    return isSearching
        ? Container(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () {
                isSearching = false;
                searchUsername.text = "";
                setState(() {});
              },
              child: const Icon(Icons.arrow_back),
            ),
          )
        : Container();
  }

  Widget _searchBar() {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
            border: Border.all(
              color: Colors.grey,
              width: 1.0,
              style: BorderStyle.solid,
            ),
            borderRadius: BorderRadius.circular(24)),
        child: TextField(
          controller: searchUsername,
          decoration: InputDecoration(
            border: InputBorder.none,
            hintText: "username",
            suffixIcon: GestureDetector(
              onTap: () {
                setState(() {
                  if (searchUsername.text != "") {
                    onSearch();
                  }
                });
              },
              child: const Icon(Icons.search),
            ),
          ),
        ),
      ),
    );
  }

  Widget _userTile(DocumentSnapshot ds) {
    return ListTile(
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(40),
        child: Image.network(
          ds["imgUrl"],
          height: 30,
          width: 30,
        ),
      ),
      title: Text(ds["name"]),
      subtitle: Text(ds["username"]),
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatScreen()));
      },
    );
  }

  Widget _searchUsersList() {
    return StreamBuilder<QuerySnapshot>(
      stream: usersStream,
      builder: (_, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.hasData) {
          return ListView.builder(
              shrinkWrap: true,
              itemCount: snapshot.data!.size,
              itemBuilder: (BuildContext context, int index) {
                DocumentSnapshot ds = snapshot.data!.docs[index];
                return _userTile(ds);
              });
        } else {
          return const CircularProgressIndicator();
        }
      },
    );
  }

  Widget _chatRoomList() {
    return Container();
  }
}
