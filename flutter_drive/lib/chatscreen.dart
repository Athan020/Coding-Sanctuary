import 'package:firebase_database/ui/firebase_animated_list.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/cupertino.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:io';
import './chatmessage.dart';
import 'dart:math';
import 'dart:async';


final FirebaseAuth _auth = FirebaseAuth.instance;
final googleSignIn = new GoogleSignIn();
final analytics = new FirebaseAnalytics();
final ref = FirebaseDatabase.instance.reference().child("messages"); 

class ChatScreen extends StatefulWidget {
  @override
  State createState() => new ChatScreenState();
}

class ChatScreenState extends State<ChatScreen> {
  final TextEditingController _textController = new TextEditingController();
  bool _isComposing = false;

  Future<Null> _ensureLoggedIn() async {
    GoogleSignInAccount user = googleSignIn.currentUser;
    if (user == null) user = await googleSignIn.signInSilently();
    if (user == null) {
      await googleSignIn.signIn();
      analytics.logLogin();
    }
    if (await _auth.currentUser() == null) {
      GoogleSignInAuthentication credentials =
          await googleSignIn.currentUser.authentication;
      await _auth.signInWithGoogle(
        idToken: credentials.idToken,
        accessToken: credentials.accessToken,
      );
    }
  }

  Widget _buildTextComposer() {
    return new IconTheme(
        //gives The Icon The color of the theme
        //**Requred**
        data: new IconThemeData(color: Theme.of(context).accentColor),
        //Text Box Starts Here
        child: new Container(
            //similar to padding but horizontally
            /** Edge inset values are applied to a rectangle to shrink or expand the area 
             * represented by that rectangle. Typically, edge insets are used during view 
             * layout to modify the view’s frame. Positive values cause the frame to be inset 
             * (or shrunk) by the specified amount. Negative values cause the frame to be outset 
             * (or expanded) by the specified amount.*/
            margin: const EdgeInsets.symmetric(horizontal: 8.0),

            //Input field in the same Row to align them

            /**To be notified about changes to the text as the user interacts with the field,
             *  pass an onChanged callback to the TextField constructor. TextField calls this 
             * method whenever its value changes with the current value of the field. In your
             *  onChanged callback, call setState() to change the value of _isComposing to true
             *  when the field contains some text. */
            child: new Row(
              children: <Widget>[
                new Container(
                    margin: new EdgeInsets.symmetric(horizontal: 4.0),
                    child: new IconButton(
                      icon: new Icon(Icons.photo_camera),
                      onPressed: () async {
                        await _ensureLoggedIn();
                        File imageFile = await ImagePicker.pickImage();
                        int random = new Random().nextInt(100000); //new
                        StorageReference ref = //new
                            FirebaseStorage.instance
                                .ref()
                                .child("image_$random.jpg"); //new
                        StorageUploadTask uploadTask = ref.put(imageFile); //new
                        Uri downloadUrl = (await uploadTask.future).downloadUrl;
                        _sendMessage(imageUrl: downloadUrl.toString());
                      },
                    )),
                new Flexible(
                  child: new TextField(
                    controller: _textController,
                    onSubmitted: _handleSubmitted,
                    onChanged: (String text) {
                      setState(() {
                        _isComposing = text.length > 0 && text != " ";
                      });
                    },
                    decoration: new InputDecoration.collapsed(
                        hintText: "Send a message"),
                  ),
                ),
                new Container(
                  margin: new EdgeInsets.symmetric(horizontal: 4.0),
                  child: Theme.of(context).platform == TargetPlatform.iOS
                      ? new CupertinoButton(
                          child: new Text("Send"),
                          onPressed: _isComposing
                              ? () => _handleSubmitted(_textController.text)
                              : null,
                        )
                      : new IconButton(
                          icon: new Icon(Icons.send),
                          onPressed: _isComposing
                              ? () => _handleSubmitted(_textController.text)
                              : null,
                        ),
                ),
              ],
            )));
  }
// //  _isEmpty(String text): Boolean{
// //    String
// //    for(int i= 0; i < text.length ; i++){

// //    }

//  }

  Future<Null> _handleSubmitted(String text) async {
    _textController.clear();
    setState(() {
      _isComposing = false;
    });

    await _ensureLoggedIn();
    _sendMessage(text: text);
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
          title: new Text("Friendly Chat"),
          elevation:
              Theme.of(context).platform == TargetPlatform.iOS ? 0.0 : 0.4),
      body: new Container(
          child: new Column(
            children: <Widget>[
              new Flexible(
                child: new FirebaseAnimatedList(
                  query: ref,
                  sort: (a, b) => b.key.compareTo(a.key),
                  padding: new EdgeInsets.all(8.0),
                  reverse: true,
                  itemBuilder: (_, DataSnapshot snapshot,
                      Animation<double> animation, int index) {
                    return new ChatMessage(
                      snapshot: snapshot,
                      animation: animation,
                    );
                  },
                  // itemBuilder:
                  //     (_, DataSnapshot snapshot, Animation<double> animation) {
                  //   return new ChatMessage(
                  //       snapshot: snapshot, animation: animation);
                  // },
                ),
              ),
              new Divider(height: 1.0),
              new Container(
                decoration:
                    new BoxDecoration(color: Theme.of(context).cardColor),
                child: _buildTextComposer(),
              ),
            ],
          ),
          decoration: Theme.of(context).platform == TargetPlatform.iOS
              ? new BoxDecoration(
                  border: new Border(
                    top: new BorderSide(color: Colors.grey[200]),
                  ),
                )
              : null),
    );
  }

  void _sendMessage({String text, String imageUrl}) {
    ref.push().set({
      'text': text,
      'imageUrl': imageUrl,
      'senderName': googleSignIn.currentUser.displayName,
      'senderPhotoUrl': googleSignIn.currentUser.photoUrl,
    });
    /** Only synchronous operations should be performed in setState(),
           * because otherwise the framework could rebuild the widgets before 
           * the operation finishes. */

    analytics.logEvent(name: 'send_message');
  }
}
