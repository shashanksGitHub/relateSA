import 'dart:io';
import 'dart:math';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:hookup4u/Screens/Chat/largeImage.dart';
import 'package:hookup4u/Screens/Information.dart';
import 'package:hookup4u/Screens/reportUser.dart';
import 'package:hookup4u/ads/ads.dart';
import 'package:hookup4u/models/user_model.dart';
import 'package:hookup4u/util/color.dart';
import 'package:hookup4u/util/snackbar.dart';
import 'package:image_picker/image_picker.dart';

import 'package:permission_handler/permission_handler.dart';
import 'package:easy_localization/easy_localization.dart';

import '../Calling/dial.dart';

class ChatPage extends StatefulWidget {
  final User sender;
  final String chatId;
  final User second;
  ChatPage({required this.sender, required this.chatId, required this.second});
  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  InterstitialAd? _interstitialAd;
  bool _isInterstitialAdReady = false;

  // final BannerAd myBanner = BannerAd(
  //   adUnitId: AdHelper.bannerAdUnitId,
  //   size: AdSize.banner,
  //   request: AdRequest(),
  //   listener: BannerAdListener(),
  // );
  // late AdWidget adWidget;

  // final AdSize adSize = AdSize(
  //   height: 50,
  //   width: 320,
  // );
  bool isBlocked = false;
  final db = FirebaseFirestore.instance;
  late CollectionReference chatReference;
  final TextEditingController _textController = new TextEditingController();
  bool _isWritting = false;
  bool isTyping = false;
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  // Ads _ads = new Ads();

  @override
  void initState() {
    _isTyping();
    InterstitialAd.load(
        adUnitId: AdHelper.interstitialAdUnitId,
        request: AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (InterstitialAd ad) {
            // Keep a reference to the ad so you can show it later.
            this._interstitialAd = ad;
          },
          onAdFailedToLoad: (LoadAdError error) {
            print('InterstitialAd failed to load: $error');
          },
        ));

    _loadInterstitialAd();
    Future.delayed(const Duration(milliseconds: 5000), () {
// Here you can write your code

      setState(() {
        // Here you can write your code for open new view
        if (_isInterstitialAdReady) {
          _interstitialAd?.show();
        }
      });
    });

    //adWidget = AdWidget(ad: myBanner);

    super.initState();
    //myBanner.load();
    //  _ad
    chatReference =
        db.collection("chats").doc(widget.chatId).collection('messages');
    checkblock();
  }

  @override
  void dispose() {
    _interstitialAd?.dispose();

    super.dispose();
  }

  Future<bool> _willPopCallback() async {
    _setTyper(widget.sender.id!, 'no');
    return Future.value(true);
  }

  var blockedBy;
  checkblock() {
    chatReference.doc('blocked').snapshots().listen((onData) {
      if (true) {
        // (onData.data != null) {
        blockedBy = onData.get('blockedBy');
        if (onData.get('isBlocked')) {
          isBlocked = true;
        } else {
          isBlocked = false;
        }

        if (mounted) setState(() {});
      }
      // print(onData.data['blockedBy']);
    });
  }

  List<Widget> generateSenderLayout(DocumentSnapshot documentSnapshot) {
    return <Widget>[
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            Container(
              child: documentSnapshot.get('image_url') != ''
                  ? InkWell(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: <Widget>[
                          new Container(
                            margin: EdgeInsets.only(
                                top: 2.0, bottom: 2.0, right: 15),
                            child: Stack(
                              children: <Widget>[
                                CachedNetworkImage(
                                  placeholder: (context, url) => Center(
                                    child: CupertinoActivityIndicator(
                                      radius: 10,
                                    ),
                                  ),
                                  errorWidget: (context, url, error) =>
                                      Icon(Icons.error),
                                  height:
                                      MediaQuery.of(context).size.height * .65,
                                  width: MediaQuery.of(context).size.width * .9,
                                  imageUrl:
                                      documentSnapshot.get('image_url') ?? '',
                                  fit: BoxFit.fitWidth,
                                ),
                                Container(
                                  alignment: Alignment.bottomRight,
                                  child: documentSnapshot.get('isRead') == false
                                      ? Icon(
                                          Icons.done,
                                          color: secondryColor,
                                          size: 15,
                                        )
                                      : Icon(
                                          Icons.done_all,
                                          color: primaryColor,
                                          size: 15,
                                        ),
                                )
                              ],
                            ),
                            height: 150,
                            width: 150.0,
                            color: secondryColor.withOpacity(.5),
                            padding: EdgeInsets.all(5),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: Text(
                                documentSnapshot.get("time") != null
                                    ? DateFormat.yMMMd('en_US')
                                        .add_jm()
                                        .format(documentSnapshot
                                            .get("time")
                                            .toDate())
                                        .toString()
                                    : "",
                                style: TextStyle(
                                  color: secondryColor,
                                  fontSize: 13.0,
                                  fontWeight: FontWeight.w600,
                                )),
                          )
                        ],
                      ),
                      onTap: () {
                        Navigator.of(context).push(
                          CupertinoPageRoute(
                            builder: (context) => LargeImage(
                              documentSnapshot.get('image_url'),
                            ),
                          ),
                        );
                      },
                    )
                  : Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 15.0, vertical: 10.0),
                      width: MediaQuery.of(context).size.width * 0.65,
                      margin: EdgeInsets.only(
                          top: 8.0, bottom: 8.0, left: 20.0, right: 5),
                      decoration: BoxDecoration(
                          color: primaryColor.withOpacity(.1),
                          borderRadius: BorderRadius.circular(20)),
                      child: Column(
                        children: <Widget>[
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              Expanded(
                                child: Container(
                                  child: Text(
                                    documentSnapshot.get('text'),
                                    style: TextStyle(
                                      color: Colors.black87,
                                      fontSize: 15.0,
                                      // fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: <Widget>[
                                  Text(
                                    documentSnapshot.get("time") != null
                                        ? DateFormat.MMMd('en_US')
                                            .add_jm()
                                            .format(documentSnapshot
                                                .get("time")
                                                .toDate())
                                            .toString()
                                        : "",
                                    style: TextStyle(
                                      color: secondryColor,
                                      fontSize: 13.0,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  SizedBox(
                                    width: 5,
                                  ),
                                  documentSnapshot.get('isRead') == false
                                      ? Icon(
                                          Icons.done,
                                          color: secondryColor,
                                          size: 15,
                                        )
                                      : Icon(
                                          Icons.done_all,
                                          color: primaryColor,
                                          size: 15,
                                        )
                                ],
                              ),
                            ],
                          ),
                        ],
                      )),
            ),
          ],
        ),
      ),
      InkWell(
        child: CircleAvatar(
          backgroundColor: secondryColor,
          radius: 20.0,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(90),
            child: CachedNetworkImage(
              imageUrl: widget.sender.imageUrl![0] ?? '',
              useOldImageOnUrlChange: true,
              placeholder: (context, url) => CupertinoActivityIndicator(
                radius: 15,
              ),
              errorWidget: (context, url, error) => Icon(Icons.error),
            ),
          ),
        ),
        onTap: () => showDialog(
            barrierDismissible: false,
            context: context,
            builder: (context) {
              return Info(widget.sender, widget.sender, null);
            }),
      ),
    ];
  }

  _messagesIsRead(documentSnapshot) {
    return <Widget>[
      InkWell(
        child: CircleAvatar(
          backgroundColor: secondryColor,
          radius: 20.0,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(90),
            child: CachedNetworkImage(
              imageUrl: widget.second.imageUrl![0] ?? '',
              useOldImageOnUrlChange: true,
              placeholder: (context, url) => CupertinoActivityIndicator(
                radius: 15,
              ),
              errorWidget: (context, url, error) => Icon(Icons.error),
            ),
          ),
        ),
        onTap: () => showDialog(
            barrierDismissible: false,
            context: context,
            builder: (context) {
              return Info(widget.second, widget.sender, null);
            }),
      ),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              child: documentSnapshot.data()!['image_url'] != ''
                  ? InkWell(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: <Widget>[
                          // Container(
                          //   alignment: Alignment.center,
                          //   child: adWidget,
                          //   width: myBanner.size.width.toDouble(),
                          //   height: myBanner.size.height.toDouble(),
                          // ),
                          new Container(
                            margin: EdgeInsets.only(
                                top: 2.0, bottom: 2.0, right: 15, left: 5),
                            child: CachedNetworkImage(
                              placeholder: (context, url) => Center(
                                child: CupertinoActivityIndicator(
                                  radius: 10,
                                ),
                              ),
                              errorWidget: (context, url, error) =>
                                  Icon(Icons.error),
                              height: MediaQuery.of(context).size.height * .65,
                              width: MediaQuery.of(context).size.width * .9,
                              imageUrl:
                                  documentSnapshot.data()!['image_url'] ?? '',
                              fit: BoxFit.fitWidth,
                            ),
                            height: 150,
                            width: 150.0,
                            color: Color.fromRGBO(0, 0, 0, 0.2),
                            padding: EdgeInsets.all(5),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: Text(
                                documentSnapshot.data()!["time"] != null
                                    ? DateFormat.yMMMd('en_US')
                                        .add_jm()
                                        .format(documentSnapshot
                                            .data()!["time"]
                                            .toDate())
                                        .toString()
                                    : "",
                                style: TextStyle(
                                  color: secondryColor,
                                  fontSize: 13.0,
                                  fontWeight: FontWeight.w600,
                                )),
                          )
                        ],
                      ),
                      onTap: () {
                        Navigator.of(context).push(CupertinoPageRoute(
                          builder: (context) => LargeImage(
                            documentSnapshot.data()!['image_url'],
                          ),
                        ));
                      },
                    )
                  : Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 15.0, vertical: 10.0),
                      width: MediaQuery.of(context).size.width * 0.65,
                      margin: EdgeInsets.only(
                          top: 8.0, bottom: 8.0, right: 10, left: 5),
                      decoration: BoxDecoration(
                          color: secondryColor.withOpacity(.3),
                          borderRadius: BorderRadius.circular(20)),
                      child: Column(
                        children: <Widget>[
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              Expanded(
                                child: Container(
                                  child: Text(
                                    documentSnapshot.data()!['text'],
                                    style: TextStyle(
                                      color: Colors.black87,
                                      fontSize: 15.0,
                                      //fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: <Widget>[
                                  Text(
                                    documentSnapshot.data()!["time"] != null
                                        ? DateFormat.MMMd('en_US')
                                            .add_jm()
                                            .format(documentSnapshot
                                                .data()!["time"]
                                                .toDate())
                                            .toString()
                                        : "",
                                    style: TextStyle(
                                      color: secondryColor,
                                      fontSize: 13.0,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      )),
            ),
          ],
        ),
      ),
    ];
  }

  List<Widget> generateReceiverLayout(DocumentSnapshot documentSnapshot) {
    if (!documentSnapshot.get('isRead')) {
      chatReference.doc(documentSnapshot.id).update({
        'isRead': true,
      });

      return _messagesIsRead(documentSnapshot);
    }
    return _messagesIsRead(documentSnapshot);
  }

  generateMessages(AsyncSnapshot<QuerySnapshot> snapshot) {
    return snapshot.data!.docs
        .map<Widget>((doc) => Container(
              margin: const EdgeInsets.symmetric(vertical: 10.0),
              child: new Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: doc.get('type') == "Call"
                      ? [
                          Text(doc.get("time") != null
                              ? "${doc.get('text')} : " +
                                  DateFormat.yMMMd('en_US')
                                      .add_jm()
                                      .format(doc.get("time").toDate())
                                      .toString() +
                                  " by ${doc.get('sender_id') == widget.sender.id ? "You" : "${widget.second.name}"}"
                              : "")
                        ]
                      : doc.get('sender_id') != widget.sender.id
                          ? generateReceiverLayout(
                              doc,
                            )
                          : generateSenderLayout(doc)),
            ))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _willPopCallback,
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: Colors.white,
        appBar: AppBar(
            backgroundColor: primaryColor,
            centerTitle: true,
            elevation: 0,
            title: Column(
              children: [
                Text(widget.second.name!),
                isTyping
                    ? Text(
                        "Typing...",
                        style: TextStyle(color: Colors.white, fontSize: 10),
                      )
                    : SizedBox.shrink(),
              ],
            ),
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios),
              color: Colors.white,
              onPressed: () {
                _willPopCallback();
                Navigator.pop(context);
              },
            ),
            actions: <Widget>[
              IconButton(
                  icon: Icon(Icons.call), onPressed: () => onJoin("AudioCall")),
              IconButton(
                  icon: Icon(Icons.video_call),
                  onPressed: () => onJoin("VideoCall")),
              PopupMenuButton(itemBuilder: (ct) {
                return [
                  PopupMenuItem(
                    value: 'value1',
                    child: InkWell(
                      onTap: () => showDialog(
                          barrierDismissible: true,
                          context: context,
                          builder: (context) => ReportUser(
                                currentUser: widget.sender,
                                seconduser: widget.second,
                              )).then((value) => Navigator.pop(ct)),
                      child: Container(
                          width: 100,
                          height: 30,
                          child: Text(
                            "Report".tr().toString(),
                          )),
                    ),
                  ),
                  PopupMenuItem(
                    height: 30,
                    value: 'value2',
                    child: InkWell(
                      child: Text(isBlocked ? "Unblock user" : "Block user"),
                      onTap: () {
                        Navigator.pop(ct);
                        showDialog(
                          context: context,
                          builder: (BuildContext ctx) {
                            return AlertDialog(
                              title: Text(isBlocked ? 'Unblock' : 'Block'),
                              content: Text('Do you want to ').tr(args: [
                                "${isBlocked ? 'Unblock' : 'Block'}",
                                "${widget.second.name}"
                              ]),
                              actions: <Widget>[
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(false),
                                  child: Text('No'.tr().toString()),
                                ),
                                TextButton(
                                  onPressed: () async {
                                    Navigator.pop(ctx);
                                    if (isBlocked &&
                                        blockedBy == widget.sender.id) {
                                      chatReference.doc('blocked').set({
                                        'isBlocked': !isBlocked,
                                        'blockedBy': widget.sender.id,
                                      }, SetOptions(merge: true));
                                    } else if (!isBlocked) {
                                      chatReference.doc('blocked').set({
                                        'isBlocked': !isBlocked,
                                        'blockedBy': widget.sender.id,
                                      }, SetOptions(merge: true));
                                    } else {
                                      CustomSnackbar.showSnackBar(
                                        context: context,
                                        text:
                                            "You can't unblock".tr().toString(),
                                      );
                                    }
                                  },
                                  child: Text('Yes'.tr().toString()),
                                ),
                              ],
                            );
                          },
                        );
                      },
                    ),
                  )
                ];
              })
            ]),
        body: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Scaffold(
            backgroundColor: primaryColor,
            body: ClipRRect(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(50.0),
                topRight: Radius.circular(50.0),
              ),
              child: Container(
                decoration: BoxDecoration(
                    // image: DecorationImage(
                    //     fit: BoxFit.fitWidth,
                    //     image: AssetImage("asset/chat.jpg")),
                    borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(50),
                        topRight: Radius.circular(50)),
                    color: Color.fromARGB(220, 255, 255, 255)),
                padding: EdgeInsets.all(5),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    StreamBuilder<QuerySnapshot>(
                      stream: chatReference
                          .orderBy('time', descending: true)
                          .snapshots(),
                      builder: (BuildContext context,
                          AsyncSnapshot<QuerySnapshot> snapshot) {
                        if (!snapshot.hasData)
                          return Container(
                            height: 15,
                            width: 15,
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation(primaryColor),
                              strokeWidth: 2,
                            ),
                          );
                        return Expanded(
                          child: ListView(
                            reverse: true,
                            children: generateMessages(snapshot),
                          ),
                        );
                      },
                    ),
                    Divider(height: 1.0),
                    Container(
                      alignment: Alignment.bottomCenter,
                      decoration:
                          BoxDecoration(color: Theme.of(context).cardColor),
                      child: isBlocked
                          ? Text(
                              "Sorry You can't send message!".tr().toString())
                          : _buildTextComposer(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: AdHelper.interstitialAdUnitId,
      request: AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          this._interstitialAd = ad;

          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              //  _moveToHome();
            },
          );

          _isInterstitialAdReady = true;
        },
        onAdFailedToLoad: (err) {
          print('Failed to load an interstitial ad: ${err.message}');
          _isInterstitialAdReady = false;
        },
      ),
    );
  }

  Widget getDefaultSendButton() {
    return IconButton(
      icon: Transform.rotate(
        angle: -pi / 9,
        child: Icon(
          Icons.send,
          size: 25,
        ),
      ),
      color: primaryColor,
      onPressed: _isWritting
          ? () => _sendText(_textController.text.trimRight())
          : null,
    );
  }

  Widget _buildTextComposer() {
    return IconTheme(
        data: IconThemeData(color: _isWritting ? primaryColor : secondryColor),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 0.0),
          child: Row(
            children: <Widget>[
              Container(
                margin: EdgeInsets.symmetric(horizontal: 0.0),
                child: IconButton(
                    icon: Icon(
                      Icons.photo_camera,
                      color: primaryColor,
                    ),
                    onPressed: () async {
                      var image = await ImagePicker.platform
                          .pickImage(source: ImageSource.gallery);
                      int timestamp = new DateTime.now().millisecondsSinceEpoch;
                      Reference storageReference = FirebaseStorage.instance
                          .ref()
                          .child('chats/${widget.chatId}/img_' +
                              timestamp.toString() +
                              '.jpg');
                      UploadTask uploadTask =
                          storageReference.putFile(File(image!.path));
                      await uploadTask.then((p0) async {
                        String fileUrl =
                            await storageReference.getDownloadURL();
                        _sendImage(messageText: 'Photo', imageUrl: fileUrl);
                      });
                    }),
              ),
              new Flexible(
                child: new TextField(
                  controller: _textController,
                  maxLines: 15,
                  minLines: 1,
                  autofocus: false,
                  onChanged: (String messageText) {
                    setState(() {
                      _isWritting = messageText.trim().length > 0;
                      if (_isWritting)
                        _setTyper(widget.sender.id!, 'yes');
                      else {
                        _setTyper(widget.sender.id!, 'no');
                      }
                    });
                  },
                  decoration: new InputDecoration.collapsed(
                      floatingLabelBehavior: FloatingLabelBehavior.auto,
                      // border: OutlineInputBorder(
                      //     borderRadius: BorderRadius.circular(18)),
                      hintText: "Send a message...".tr().toString()),
                ),
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 4.0),
                child: getDefaultSendButton(),
              ),
            ],
          ),
        ));
  }

  Future<Null> _sendText(String text) async {
    _textController.clear();
    chatReference.add({
      'type': 'Msg',
      'text': text,
      'sender_id': widget.sender.id,
      'receiver_id': widget.second.id,
      'isRead': false,
      'image_url': '',
      'time': FieldValue.serverTimestamp(),
    }).then((documentReference) {
      setState(() {
        _isWritting = false;
        _setTyper(widget.sender.id!, 'no');
      });
    }).catchError((e) {});
  }

  void _sendImage({required String messageText, required String imageUrl}) {
    chatReference.add({
      'type': 'Image',
      'text': messageText,
      'sender_id': widget.sender.id,
      'receiver_id': widget.second.id,
      'isRead': false,
      'image_url': imageUrl,
      'time': FieldValue.serverTimestamp(),
    });
  }

  Future<void> onJoin(callType) async {
    if (!isBlocked) {
      // await for camera and mic permissions before pushing video page
      print('----------call tye-----------$callType');
      print('----------widget.sender.ide-----------${widget.sender.id}');
      print('----------widget.sec.id-----------${widget.second.id}');
      await handleCameraAndMic(callType);
      await chatReference.add({
        'type': 'Call',
        'text': callType,
        'sender_id': widget.sender.id,
        'receiver_id': widget.second.id,
        'isRead': false,
        'image_url': "",
        'time': FieldValue.serverTimestamp(),
      });
      print('%%%%%%%%%%%%%%%${widget.chatId},${widget.second},$callType');

      // push video page with given channel name
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DialCall(
              channelName: widget.chatId,
              receiver: widget.second,
              callType: callType),
        ),
      );
    } else {
      CustomSnackbar.showSnackBar(
          text: "Blocked !".tr().toString(), context: context);
    }
  }

  _isTyping() async {
    db.collection('chats').doc(widget.chatId).snapshots().listen((event) {
      if (event.data()!.isNotEmpty) if (event.data()![widget.second.id]
              ['isTyping'] ==
          'yes') {
        if (mounted)
          setState(() {
            isTyping = true;
          });
      } else {
        if (mounted)
          setState(() {
            isTyping = false;
          });
      }
    });
  }

  _setTyper(String senderID, String text) async {
    db.collection('chats').doc(widget.chatId).set({
      senderID: {
        'isTyping': text,
      },
    }, SetOptions(merge: true));
  }
}

Future<void> handleCameraAndMic(callType) async {
  if (callType == 'VideoCall') {
    await [
      Permission.camera,
      Permission.microphone,
    ].request();
  } else {
    await Permission.microphone.request();
  }

  // await PermissionHandler().requestPermissions(callType == "VideoCall"
  //     ? [PermissionGroup.camera, PermissionGroup.microphone]
  //     : [PermissionGroup.microphone]);
}
