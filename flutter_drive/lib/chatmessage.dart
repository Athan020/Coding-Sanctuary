import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:firebase_database/firebase_database.dart';


class ChatMessage extends StatelessWidget {
  ChatMessage({this.snapshot, this.animation});
  final DataSnapshot snapshot; // modified
  final Animation animation;
  @override

  //  * The cross axis in flexbox runs across the main axis,
  //  * therefore if your flex-direction and so your main axis
  //  * is row or row-reverse the cross axis runs down the columns.
  Widget build(BuildContext context) {
    return new SizeTransition(
        sizeFactor:
            new CurvedAnimation(parent: animation, curve: Curves.easeOut),
        axisAlignment: 0.0,
        child: new Container(
          margin: const EdgeInsets.symmetric(vertical: 10.0),
          child: new Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              new Container(
                  margin: const EdgeInsets.only(right: 16.0),
                  child: new CircleAvatar(
                      // child: new Text(_name[0])
                      backgroundImage:
                          new NetworkImage(snapshot.value['senderPhotoUrl']))),
              new Expanded(
                child: new Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    new Text(snapshot.value["senderName"],
                        style: Theme.of(context).textTheme.subhead),
                    new Container(
                      margin: const EdgeInsets.only(top: 5.0),
                      child: snapshot.value['imageUrl'] != null
                          ? new Image.network(snapshot.value['imageUrl'],
                              width: 250.0)
                          : new Text(snapshot.value["text"]),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ));
  }
}
