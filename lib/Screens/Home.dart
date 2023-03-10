import 'dart:math';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_swiper_null_safety/flutter_swiper_null_safety.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:hookup4u/Screens/Information.dart';
import 'package:hookup4u/Screens/Payment/subscriptions.dart';
import 'package:hookup4u/Screens/Tab.dart';
import 'package:hookup4u/ads/ads.dart';
import 'package:hookup4u/models/user_model.dart';
import 'package:hookup4u/swipe_stack.dart';
import 'package:hookup4u/util/color.dart';

import 'package:easy_localization/easy_localization.dart';

List userRemoved = [];
int countswipe = 1;

class CardPictures extends StatefulWidget {
  final List<User> users;
  final User currentUser;
  final int swipedcount;
  final Map items;
  CardPictures(this.currentUser, this.users, this.swipedcount, this.items);

  @override
  _CardPicturesState createState() => _CardPicturesState();
}

class _CardPicturesState extends State<CardPictures>
    with AutomaticKeepAliveClientMixin<CardPictures>, WidgetsBindingObserver {
  // TabbarState state = TabbarState();
  Map<String, bool> active = {'active': false};
  final Stream<QuerySnapshot> _usersStream =
      FirebaseFirestore.instance.collection('Active').snapshots();

  bool onEnd = false;
  //Ads _ads = new Ads();
  InterstitialAd? _interstitialAd;
  bool _isInterstitialAdReady = false;

  late AdWidget adWidget;
  final AdSize adSize = AdSize(height: 300, width: 50);

  bool _isBannerAdReady = true;

  GlobalKey<SwipeStackState> swipeKey = GlobalKey<SwipeStackState>();
  bool get wantKeepAlive => true;
  final auth.FirebaseAuth _auth = auth.FirebaseAuth.instance;

  void initState() {
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
    userOnline();
    WidgetsBinding.instance.addObserver(this);

    // adWidget = AdWidget(ad: myBanner);

    super.initState();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    final auth.FirebaseAuth _auth = auth.FirebaseAuth.instance;
    var user = _auth.currentUser;
    print('sdfghfdfgh');
    // final auth.FirebaseAuth _auth = auth.FirebaseAuth.instance;
    // print('done1${AppLifecycleState.resumed}');
    // print('done2${AppLifecycleState.detached}');
    // print('done3${AppLifecycleState.inactive}');
    // print('done4${AppLifecycleState.paused}');

    if (state == AppLifecycleState.resumed && user != null) {
      print('done$state');

      active = {'active': true};
      await FirebaseFirestore.instance
          .collection('Active')
          .doc(widget.currentUser.id)
          .set(active);
      // await FirebaseFirestore.instance
      //     .collection('Users')
      //     .doc(widget.currentUser.id)
      //     .set({'isOnline': true}, SetOptions(merge: true));
    } else {
      print('done3$state');
      // active = {'active': false};

      await FirebaseFirestore.instance
          .collection('Active')
          .doc(widget.currentUser.id)
          .delete();

      // await FirebaseFirestore.instance
      //     .collection('Users')
      //     .doc(widget.currentUser.id)
      //     .set({'isOnline': false}, SetOptions(merge: true));
    }
  }

  // void didChangeAppLifecycleState(AppLifecycleState state) async {
  //   if (state == AppLifecycleState.resumed ||
  //       state == AppLifecycleState.paused) {
  //     print('-------');
  //     await FirebaseFirestore.instance
  //         .collection('Users')
  //         .doc(widget.currentUser.id)
  //         .update({
  //       'isOnline': true,
  //     });
  //   } else {
  //     await FirebaseFirestore.instance
  //         .collection('Users')
  //         .doc(widget.currentUser.id)
  //         .update({
  //       'isOnline': false,
  //     });
  //   }
  // }

  @override
  void dispose() {
    _interstitialAd?.dispose();

    super.dispose();
  }

  final BannerAdListener listener = BannerAdListener(
    // Called when an ad is successfully received.
    onAdLoaded: (Ad ad) {
      print('Ad loaded.');
    },
    // Called when an ad request failed.
    onAdFailedToLoad: (Ad ad, LoadAdError error) {
      // Dispose the ad here to free resources.
      ad.dispose();
      print('Ad failed to load: $error');
    },
    // Called when an ad opens an overlay that covers the screen.
    onAdOpened: (Ad ad) => print('Ad opened.'),
    // Called when an ad removes an overlay that covers the screen.
    onAdClosed: (Ad ad) => print('Ad closed.'),
    // Called when an impression occurs on the ad.
    onAdImpression: (Ad ad) => print('Ad impression.'),
  );
  userOnline() async {
    print('Here we are active');
    active = {'active': true};
    await FirebaseFirestore.instance
        .collection('Active')
        .doc(widget.currentUser.id)
        .set(active);
  }

  realtimeNumbers() {
    var numberOfUsersOnline;
    return StreamBuilder<QuerySnapshot>(
      stream: _usersStream,
      builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.hasError) {
          return ListTile(
            title: Text('0'),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Text("Loading");
        }
        numberOfUsersOnline = snapshot.data!.size.toString();

        return Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Text(
              'Online Users: $numberOfUsersOnline',
              style: TextStyle(fontSize: 16),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    print(
        '//////////////////////////////-${widget.users}-///////////////////////////////////');

    int freeSwipe = widget.items['free_swipes'] != null
        ? int.parse(widget.items['free_swipes'])
        : 10;
    bool exceedSwipes = widget.swipedcount >= freeSwipe;
    return Scaffold(
      backgroundColor: primaryColor,
      body: Container(
        decoration: BoxDecoration(
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(50), topRight: Radius.circular(50)),
            color: Colors.white),
        child: ClipRRect(
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(50), topRight: Radius.circular(50)),
          child: Column(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    AbsorbPointer(
                      absorbing: exceedSwipes,
                      child: Stack(
                        children: <Widget>[
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                            ),
                            height: MediaQuery.of(context).size.height * .78,
                            width: MediaQuery.of(context).size.width,
                            child:
                                //onEnd ||
                                widget.users.length == 0
                                    ? Stack(
                                        alignment: Alignment.topCenter,
                                        children: [
                                          realtimeNumbers(),
                                          Align(
                                            alignment: Alignment.center,
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: <Widget>[
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.all(8.0),
                                                  child: CircleAvatar(
                                                    backgroundColor:
                                                        secondryColor,
                                                    radius: 40,
                                                  ),
                                                ),
                                                Text(
                                                  "There's no one new around you."
                                                      .tr()
                                                      .toString(),
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                      color: secondryColor,
                                                      decoration:
                                                          TextDecoration.none,
                                                      fontSize: 18),
                                                )
                                              ],
                                            ),
                                          ),
                                        ],
                                      )
                                    : Stack(
                                        children: [
                                          realtimeNumbers(),
                                          SwipeStack(
                                            key: swipeKey,
                                            children: widget.users.map((index) {
                                              // User user;
                                              return SwiperItem(builder:
                                                  (SwiperPosition position,
                                                      double progress) {
                                                return Material(
                                                    elevation: 5,
                                                    borderRadius:
                                                        BorderRadius.all(
                                                            Radius.circular(
                                                                30)),
                                                    child: Container(
                                                      child: Stack(
                                                        children: <Widget>[
                                                          ClipRRect(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .all(Radius
                                                                        .circular(
                                                                            30)),
                                                            child: Swiper(
                                                              customLayoutOption:
                                                                  CustomLayoutOption(
                                                                stateCount: 0,
                                                                startIndex: 0,
                                                              ),
                                                              key: UniqueKey(),
                                                              physics:
                                                                  NeverScrollableScrollPhysics(),
                                                              itemBuilder:
                                                                  (BuildContext
                                                                          context,
                                                                      int index2) {
                                                                return Container(
                                                                  height: MediaQuery.of(
                                                                              context)
                                                                          .size
                                                                          .height *
                                                                      .78,
                                                                  width: MediaQuery.of(
                                                                          context)
                                                                      .size
                                                                      .width,
                                                                  child:
                                                                      CachedNetworkImage(
                                                                    imageUrl:
                                                                        index.imageUrl![index2] ??
                                                                            "",
                                                                    fit: BoxFit
                                                                        .cover,
                                                                    useOldImageOnUrlChange:
                                                                        true,
                                                                    placeholder:
                                                                        (context,
                                                                                url) =>
                                                                            CupertinoActivityIndicator(
                                                                      radius:
                                                                          20,
                                                                    ),
                                                                    errorWidget: (context,
                                                                            url,
                                                                            error) =>
                                                                        Icon(Icons
                                                                            .error),
                                                                  ),
                                                                  // child: Image.network(
                                                                  //   index.imageUrl[index2],
                                                                  //   fit: BoxFit.cover,
                                                                  // ),
                                                                );
                                                              },
                                                              itemCount: index
                                                                  .imageUrl!
                                                                  .length,
                                                              pagination: new SwiperPagination(
                                                                  alignment:
                                                                      Alignment
                                                                          .bottomCenter,
                                                                  builder: DotSwiperPaginationBuilder(
                                                                      activeSize:
                                                                          13,
                                                                      color:
                                                                          secondryColor,
                                                                      activeColor:
                                                                          primaryColor)),
                                                              control:
                                                                  new SwiperControl(
                                                                color:
                                                                    primaryColor,
                                                                disableColor:
                                                                    secondryColor,
                                                              ),
                                                              loop: false,
                                                            ),
                                                          ),
                                                          Padding(
                                                            padding:
                                                                const EdgeInsets
                                                                    .all(48.0),
                                                            child: position
                                                                        .toString() ==
                                                                    "SwiperPosition.Left"
                                                                ? Align(
                                                                    alignment:
                                                                        Alignment
                                                                            .topRight,
                                                                    child: Transform
                                                                        .rotate(
                                                                      angle:
                                                                          pi /
                                                                              8,
                                                                      child:
                                                                          Container(
                                                                        height:
                                                                            40,
                                                                        width:
                                                                            100,
                                                                        decoration: BoxDecoration(
                                                                            shape:
                                                                                BoxShape.rectangle,
                                                                            border: Border.all(width: 2, color: Colors.red)),
                                                                        child:
                                                                            Center(
                                                                          child: Text(
                                                                              "NOPE".tr().toString(),
                                                                              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 32)),
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  )
                                                                : position.toString() ==
                                                                        "SwiperPosition.Right"
                                                                    ? Align(
                                                                        alignment:
                                                                            Alignment.topLeft,
                                                                        child: Transform
                                                                            .rotate(
                                                                          angle:
                                                                              -pi / 8,
                                                                          child:
                                                                              Container(
                                                                            height:
                                                                                40,
                                                                            width:
                                                                                100,
                                                                            decoration:
                                                                                BoxDecoration(shape: BoxShape.rectangle, border: Border.all(width: 2, color: Colors.lightBlueAccent)),
                                                                            child:
                                                                                Center(
                                                                              child: Text("LIKE".tr().toString(), style: TextStyle(color: Colors.lightBlueAccent, fontWeight: FontWeight.bold, fontSize: 32)),
                                                                            ),
                                                                          ),
                                                                        ),
                                                                      )
                                                                    : Container(),
                                                          ),
                                                          Padding(
                                                            padding:
                                                                const EdgeInsets
                                                                        .only(
                                                                    bottom: 10),
                                                            child: Align(
                                                                alignment: Alignment
                                                                    .bottomLeft,
                                                                child: ListTile(
                                                                    onTap: () {
                                                                      _loadInterstitialAd();

                                                                      // _ads.myInterstitial()
                                                                      //   ..load()
                                                                      //   ..show();

                                                                      //  if (_isBannerAdReady)
                                                                      _interstitialAd
                                                                          ?.show();

                                                                      showDialog(
                                                                          barrierDismissible:
                                                                              false,
                                                                          context:
                                                                              context,
                                                                          builder:
                                                                              (context) {
                                                                            return Info(
                                                                                index,
                                                                                widget.currentUser,
                                                                                swipeKey);
                                                                          });
                                                                    },
                                                                    title: StreamBuilder<
                                                                            DocumentSnapshot>(
                                                                        stream: FirebaseFirestore
                                                                            .instance
                                                                            .collection(
                                                                                'Users')
                                                                            .doc(index
                                                                                .id)
                                                                            .snapshots(),
                                                                        builder: (context,
                                                                            AsyncSnapshot<DocumentSnapshot<Object?>>
                                                                                snapshot) {
                                                                          var data = snapshot.data?.data() as Map<
                                                                              String,
                                                                              dynamic>;
                                                                          print(
                                                                              '________${data}ok');

                                                                          return Row(
                                                                            children: [
                                                                              Text(
                                                                                "${index.name}, ${index.editInfo!['showMyAge'] != null ? !index.editInfo!['showMyAge'] ? index.age : "" : index.age}",
                                                                                style: TextStyle(color: Colors.white, fontSize: 25, fontWeight: FontWeight.bold),
                                                                              ),
                                                                              const SizedBox(width: 10),
                                                                              // CircleAvatar(
                                                                              //   radius: 7,
                                                                              //   backgroundColor: index.isOnline == null || index.isOnline == false ? Colors.red : Colors.green,

                                                                              // )
                                                                            ],
                                                                          );
                                                                        }),
                                                                    subtitle:
                                                                        Text(
                                                                      "${index.address}",
                                                                      style:
                                                                          TextStyle(
                                                                        color: Colors
                                                                            .white,
                                                                        fontSize:
                                                                            20,
                                                                      ),
                                                                    ))),
                                                          ),
                                                        ],
                                                      ),
                                                    ));
                                              });
                                            }).toList(growable: true),
                                            threshold: 30,
                                            maxAngle: 100,
                                            //animationDuration: Duration(milliseconds: 400),
                                            visibleCount: 5,
                                            historyCount: 1,
                                            stackFrom: StackFrom.Right,
                                            translationInterval: 5,
                                            scaleInterval: 0.08,
                                            onSwipe: (int index,
                                                SwiperPosition position) async {
                                              _adsCheck(countswipe);
                                              print(position);
                                              print(widget.users[index].name);
                                              CollectionReference docRef =
                                                  FirebaseFirestore.instance
                                                      .collection("Users");
                                              if (position ==
                                                  SwiperPosition.Left) {
                                                await docRef
                                                    .doc(widget.currentUser.id)
                                                    .collection("CheckedUser")
                                                    .doc(widget.users[index].id)
                                                    .set({
                                                  'DislikedUser':
                                                      widget.users[index].id,
                                                  'timestamp': DateTime.now(),
                                                }, SetOptions(merge: true));

                                                if (index <
                                                    widget.users.length) {
                                                  userRemoved.clear();
                                                  setState(() {
                                                    userRemoved.add(
                                                        widget.users[index]);
                                                    widget.users
                                                        .removeAt(index);
                                                  });
                                                }
                                              } else if (position ==
                                                  SwiperPosition.Right) {
                                                if (likedByList.contains(
                                                    widget.users[index].id)) {
                                                  showDialog(
                                                      context: context,
                                                      builder: (ctx) {
                                                        Future.delayed(
                                                            Duration(
                                                                milliseconds:
                                                                    1700), () {
                                                          Navigator.pop(ctx);
                                                        });
                                                        return Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                      .only(
                                                                  top: 80),
                                                          child: Align(
                                                            alignment: Alignment
                                                                .topCenter,
                                                            child: Card(
                                                              child: Container(
                                                                height: 100,
                                                                width: 300,
                                                                child: Center(
                                                                  child: Text(
                                                                    "It's a match\n With ",
                                                                    textAlign:
                                                                        TextAlign
                                                                            .center,
                                                                    style: TextStyle(
                                                                        color:
                                                                            primaryColor,
                                                                        fontSize:
                                                                            30,
                                                                        decoration:
                                                                            TextDecoration.none),
                                                                  ).tr(args: [
                                                                    '${widget.users[index].name}'
                                                                  ]),
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                        );
                                                      });
                                                  await docRef
                                                      .doc(
                                                          widget.currentUser.id)
                                                      .collection("Matches")
                                                      .doc(widget
                                                          .users[index].id)
                                                      .set({
                                                    'Matches':
                                                        widget.users[index].id,
                                                    'isRead': false,
                                                    'userName': widget
                                                        .users[index].name,
                                                    'pictureUrl': widget
                                                        .users[index]
                                                        .imageUrl![0],
                                                    'timestamp': FieldValue
                                                        .serverTimestamp()
                                                  }, SetOptions(merge: true));
                                                  await docRef
                                                      .doc(widget
                                                          .users[index].id)
                                                      .collection("Matches")
                                                      .doc(
                                                          widget.currentUser.id)
                                                      .set({
                                                    'Matches':
                                                        widget.currentUser.id,
                                                    'userName':
                                                        widget.currentUser.name,
                                                    'pictureUrl': widget
                                                        .currentUser
                                                        .imageUrl![0],
                                                    'isRead': false,
                                                    'timestamp': FieldValue
                                                        .serverTimestamp()
                                                  }, SetOptions(merge: true));
                                                }

                                                await docRef
                                                    .doc(widget.currentUser.id)
                                                    .collection("CheckedUser")
                                                    .doc(widget.users[index].id)
                                                    .set({
                                                  'LikedUser':
                                                      widget.users[index].id,
                                                  'timestamp': FieldValue
                                                      .serverTimestamp(),
                                                }, SetOptions(merge: true));
                                                await docRef
                                                    .doc(widget.users[index].id)
                                                    .collection("LikedBy")
                                                    .doc(widget.currentUser.id)
                                                    .set({
                                                  'LikedBy':
                                                      widget.currentUser.id,
                                                  'timestamp': FieldValue
                                                      .serverTimestamp()
                                                }, SetOptions(merge: true));
                                                if (index <
                                                    widget.users.length) {
                                                  userRemoved.clear();
                                                  setState(() {
                                                    userRemoved.add(
                                                        widget.users[index]);
                                                    widget.users
                                                        .removeAt(index);
                                                  });
                                                }
                                              } else
                                                debugPrint(
                                                    "onSwipe $index $position");
                                            },
                                            onRewind: (int index,
                                                SwiperPosition position) {
                                              swipeKey.currentContext!
                                                  .dependOnInheritedWidgetOfExactType();
                                              widget.users.insert(
                                                  index, userRemoved[0]);
                                              setState(() {
                                                userRemoved.clear();
                                              });
                                              debugPrint(
                                                  "onRewind $index $position");
                                              print(widget.users[index].id);
                                            },
                                          ),
                                        ],
                                      ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(25),
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: <Widget>[
                                  widget.users.length != 0
                                      ? FloatingActionButton(
                                          heroTag: UniqueKey(),
                                          backgroundColor: Colors.white,
                                          child: Icon(
                                            userRemoved.length > 0
                                                ? Icons.replay
                                                : Icons.not_interested,
                                            color: userRemoved.length > 0
                                                ? Colors.amber
                                                : secondryColor,
                                            size: 20,
                                          ),
                                          onPressed: () {
                                            if (userRemoved.length > 0) {
                                              swipeKey.currentState!.rewind();
                                            }
                                          })
                                      : FloatingActionButton(
                                          heroTag: UniqueKey(),
                                          backgroundColor: Colors.white,
                                          child: Icon(
                                            Icons.refresh,
                                            color: Colors.green,
                                            size: 20,
                                          ),
                                          onPressed: () {},
                                        ),
                                  FloatingActionButton(
                                      heroTag: UniqueKey(),
                                      backgroundColor: Colors.white,
                                      child: Icon(
                                        Icons.clear,
                                        color: Colors.red,
                                        size: 30,
                                      ),
                                      onPressed: () {
                                        if (widget.users.length > 0) {
                                          print("object");
                                          swipeKey.currentState!.swipeLeft();
                                        }
                                      }),
                                  FloatingActionButton(
                                      heroTag: UniqueKey(),
                                      backgroundColor: Colors.white,
                                      child: Icon(
                                        Icons.favorite,
                                        color: Colors.lightBlueAccent,
                                        size: 30,
                                      ),
                                      onPressed: () {
                                        if (widget.users.length > 0) {
                                          swipeKey.currentState!.swipeRight();
                                        }
                                      }),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    exceedSwipes
                        ? Align(
                            alignment: Alignment.center,
                            child: InkWell(
                                child: Container(
                                  color: Colors.white.withOpacity(.3),
                                  child: Dialog(
                                    insetAnimationCurve: Curves.bounceInOut,
                                    insetAnimationDuration:
                                        Duration(seconds: 2),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(20)),
                                    backgroundColor: Colors.white,
                                    child: Container(
                                      height:
                                          MediaQuery.of(context).size.height *
                                              .55,
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceEvenly,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.error_outline,
                                            size: 50,
                                            color: primaryColor,
                                          ),
                                          Text(
                                            "you have already used the maximum number of free available swipes for 24 hrs."
                                                .tr()
                                                .toString(),
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.grey,
                                                fontSize: 20),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Icon(
                                              Icons.lock_outline,
                                              size: 120,
                                              color: primaryColor,
                                            ),
                                          ),
                                          Text(
                                            "For swipe more users just subscribe our premium plans."
                                                .tr()
                                                .toString(),
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                                color: primaryColor,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 20),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => Subscription(
                                            null, null, widget.items)))),
                          )
                        : Container()
                  ],
                ),
              ),
            ],
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

  void _adsCheck(count) {
    print(count);
    if (count % 3 == 0) {
      _loadInterstitialAd();

      _interstitialAd?.show();

      countswipe++;
    } else {
      countswipe++;
    }
  }
}
