import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_swiper_null_safety/flutter_swiper_null_safety.dart';
//import 'package:flutter_swiper/flutter_swiper.dart';
import 'package:hookup4u/models/user_model.dart';
import 'package:hookup4u/service/fetch_subscriptions.dart';
import 'package:hookup4u/util/color.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import 'package:url_launcher/url_launcher.dart';
import '../Profile/profile.dart';
import 'package:rflutter_alert/rflutter_alert.dart';
import 'package:easy_localization/easy_localization.dart';

class Subscription extends StatefulWidget {
  final bool? isPaymentSuccess;
  final User? currentUser;
  final Map items;
  Subscription(this.currentUser, this.isPaymentSuccess, this.items);

  @override
  _SubscriptionState createState() => _SubscriptionState();
}

class _SubscriptionState extends State<Subscription> {
  /// if the api is available or not.
  bool isAvailable = true;

  /// products for sale

  /// Past purchases

  /// Update to purchases
  late StreamSubscription _streamSubscription;
  List<Package> packageSubs = [];
  var response;
  bool _isLoading = true;
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  @override
  void initState() {
    super.initState();
    getProducts();
    // Show payment failure alert.
    if (widget.isPaymentSuccess != null && !widget.isPaymentSuccess!) {
      WidgetsBinding.instance!.addPostFrameCallback((_) async {
        await Alert(
          context: context,
          type: AlertType.error,
          title: "Failed".tr().toString(),
          desc: "Oops !! something went wrong. Try Again".tr().toString(),
          buttons: [
            DialogButton(
              child: Text(
                "Retry".tr().toString(),
                style: TextStyle(color: Colors.white, fontSize: 20),
              ),
              onPressed: () => Navigator.pop(context),
              width: 120,
            )
          ],
        ).show();
      });
    }
  }

  @override
  void dispose() {
    _streamSubscription.cancel();
    super.dispose();
  }

  Future<List<String>> _fetchPackageIds() async {
    List<String> packageId = [];

    await FirebaseFirestore.instance
        .collection("Packages")
        .where('status', isEqualTo: true)
        .get()
        .then((value) {
      packageId.addAll(value.docs.map((e) => e['id']));
    });

    return packageId;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          // mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            Container(
              margin: EdgeInsets.only(top: 20, right: 20),
              alignment: Alignment.topRight,
              child: IconButton(
                alignment: Alignment.topRight,
                color: Colors.black,
                icon: Icon(
                  Icons.cancel,
                  size: 25,
                ),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    ListTile(
                      dense: true,
                      title: Text(
                        "Get our premium plans".tr().toString(),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: primaryColor,
                            fontSize: 25,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    ListTile(
                      dense: true,
                      leading: Icon(
                        Icons.star,
                        color: Colors.blue,
                      ),
                      title: Text(
                        "Unlimited swipe.".tr().toString(),
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w400),
                      ),
                    ),
                    ListTile(
                      dense: true,
                      leading: Icon(
                        Icons.star,
                        color: Colors.green,
                      ),
                      title: Text(
                        "Search users around",
                        style: TextStyle(

                            // Color(0xFF1A1A1A),
                            fontSize: 16,
                            fontWeight: FontWeight.w400),
                      ).tr(args: ["${widget.items['paid_radius'] ?? ''}"]),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10)),
                          height: 100,
                          width: MediaQuery.of(context).size.width * .85,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Swiper(
                              key: UniqueKey(),
                              curve: Curves.linear,
                              autoplay: true,
                              physics: ScrollPhysics(),
                              itemBuilder: (BuildContext context, int index2) {
                                return Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: <Widget>[
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: <Widget>[
                                          Icon(
                                            adds[index2]["icon"],
                                            color: adds[index2]["color"],
                                          ),
                                          SizedBox(
                                            width: 5,
                                          ),
                                          Text(
                                            adds[index2]["title"],
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                      Text(
                                        adds[index2]["subtitle"],
                                        textAlign: TextAlign.center,
                                      ),
                                    ]);
                              },
                              itemCount: adds.length,
                              pagination: new SwiperPagination(
                                  alignment: Alignment.bottomCenter,
                                  builder: DotSwiperPaginationBuilder(
                                      activeSize: 10,
                                      color: secondryColor,
                                      activeColor: primaryColor)),
                              control: new SwiperControl(
                                size: 20,
                                color: primaryColor,
                                disableColor: secondryColor,
                              ),
                              loop: false,
                            ),
                          ),
                        ),
                      ),
                    ),
                    _isLoading
                        ? Container(
                            height: MediaQuery.of(context).size.width * .8,
                            child: Center(
                              child: CircularProgressIndicator(
                                  valueColor: new AlwaysStoppedAnimation<Color>(
                                      primaryColor)),
                            ),
                          )
                        : packageSubs.length > 0
                            ? Stack(
                                alignment: Alignment.bottomCenter,
                                children: [
                                  Align(
                                    alignment: Alignment.center,
                                    child: Transform.rotate(
                                      angle: -pi / 2,
                                      child: Container(
                                        width:
                                            MediaQuery.of(context).size.height *
                                                .16,
                                        height:
                                            MediaQuery.of(context).size.width *
                                                .8,
                                        decoration: BoxDecoration(
                                            border: Border.all(
                                                width: 2, color: primaryColor)),
                                        child: Center(
                                          child: (CupertinoPicker(
                                              squeeze: 1.4,
                                              looping: true,
                                              magnification: 1.08,
                                              offAxisFraction: -.2,
                                              backgroundColor: Colors.white,
                                              scrollController:
                                                  FixedExtentScrollController(
                                                      initialItem: 0),
                                              itemExtent: 100,
                                              onSelectedItemChanged: (value) {
                                                // setState(() {
                                                //   selectedProduct =
                                                //       products[value];
                                                // });
                                              },
                                              children:
                                                  packageSubs.map((product) {
                                                return Transform.rotate(
                                                  angle: pi / 2,
                                                  child: Center(
                                                    child: Column(
                                                      children: [
                                                        // productList(
                                                        //   context: context,
                                                        //   product: product,
                                                        //   interval: Platform
                                                        //           .isIOS
                                                        //       ? getInterval(
                                                        //           product)
                                                        //       : getIntervalAndroid(
                                                        //           product),
                                                        //   intervalCount: Platform
                                                        //           .isIOS
                                                        //       ? product
                                                        //           .skProduct!
                                                        //           .subscriptionPeriod!
                                                        //           .numberOfUnits
                                                        //           .toString()
                                                        //       : product
                                                        //           .skuDetail!
                                                        //           .subscriptionPeriod
                                                        //           .split("")[1],
                                                        //   price: product.price,
                                                        //   onTap: () {
                                                        //     null;
                                                        //   },
                                                        // ),

                                                        Text(product
                                                            .packageType.name),
                                                      ],
                                                    ),
                                                  ),
                                                );
                                              }).toList())),
                                        ),
                                      ),
                                    ),
                                  ),
                                  // selectedProduct != null
                                  //     ? Center(
                                  //         child: ListTile(
                                  //           title: Text(
                                  //             selectedProduct.title,
                                  //             textAlign: TextAlign.center,
                                  //           ),
                                  //           subtitle: Text(
                                  //             selectedProduct.description,
                                  //             textAlign: TextAlign.center,
                                  //           ),
                                  //           trailing: Text(
                                  //               "${products.indexOf(selectedProduct) + 1}/${products.length}"),
                                  //         ),
                                  //       )
                                  //    : Container()
                                ],
                              )
                            : Container(
                                height: MediaQuery.of(context).size.width * .8,
                                child: Center(
                                  child: Text("No active product found!!"
                                      .tr()
                                      .toString()),
                                ),
                              )
                  ],
                ),
              ),
            ),
            Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: InkWell(
                    child: Container(
                        decoration: BoxDecoration(
                            shape: BoxShape.rectangle,
                            borderRadius: BorderRadius.circular(25),
                            gradient: LinearGradient(
                                begin: Alignment.topRight,
                                end: Alignment.bottomLeft,
                                colors: [
                                  primaryColor.withOpacity(.5),
                                  primaryColor.withOpacity(.8),
                                  primaryColor,
                                  primaryColor
                                ])),
                        height: MediaQuery.of(context).size.height * .055,
                        width: MediaQuery.of(context).size.width * .55,
                        child: Center(
                            child: Text(
                          "CONTINUE".tr().toString(),
                          style: TextStyle(
                              fontSize: 15,
                              color: textColor,
                              fontWeight: FontWeight.bold),
                        ))),
                    onTap: () async {
                      // if (selectedProduct != null)
                      //   _buyProduct(selectedProduct);
                      // else {
                      //   CustomSnackbar.snackbar(
                      //       "You must choose a subscription to continue."
                      //           .tr()
                      //           .toString(),
                      //       _scaffoldKey);
                      // }
                    },
                  ),
                )),
            // SizedBox(
            //   height: 15,
            // ),
            Platform.isIOS
                ? InkWell(
                    child: Container(
                        decoration: BoxDecoration(
                            shape: BoxShape.rectangle,
                            borderRadius: BorderRadius.circular(25),
                            gradient: LinearGradient(
                                begin: Alignment.topRight,
                                end: Alignment.bottomLeft,
                                colors: [
                                  primaryColor.withOpacity(.5),
                                  primaryColor.withOpacity(.8),
                                  primaryColor,
                                  primaryColor
                                ])),
                        height: MediaQuery.of(context).size.height * .055,
                        width: MediaQuery.of(context).size.width * .55,
                        child: Center(
                            child: Text(
                          "RESTORE PURCHASE".tr().toString(),
                          style: TextStyle(
                              fontSize: 15,
                              color: textColor,
                              fontWeight: FontWeight.bold),
                        ))),
                    onTap: () async {
                      // var result = await _getpastPurchases();
                      // if (result.length == 0) {
                      //   showDialog(
                      //       context: context,
                      //       builder: (ctx) {
                      //         return AlertDialog(
                      //           content:
                      //               Text("No purchase found".tr().toString()),
                      //           title: Text("Past Purchases".tr().toString()),
                      //         );
                      //       });
                      // }
                    },
                  )
                : Container(),
            SizedBox(
              height: 10,
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: <Widget>[
                  GestureDetector(
                    child: Text(
                      "Privacy Policy".tr().toString(),
                      style: TextStyle(color: Colors.blue),
                    ),
                    onTap: () => launch(
                        "https://relatesa.co.za/privacy-policy/"), //TODO: add privacy policy
                  ),
                  GestureDetector(
                    child: Text(
                      "Terms & Conditions".tr().toString(),
                      style: TextStyle(color: Colors.blue),
                    ),
                    onTap: () => launch(
                        "https://relatesa.co.za/terms-conditions/"), //TODO: add Terms and conditions
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  getProducts() async {
    final offering = await Featch().getProducts(context);
    if (offering.isNotEmpty) {
      print(offering);
      final packages = offering
          .map((offer) => offer.availablePackages)
          .expand((pair) => pair)
          .toList();
      setState(() {
        packageSubs = packages;
      });
    } else {
      debugPrint('isEmpty');
    }
  }
//   Widget productList({
//     required BuildContext context,
//     required String intervalCount,
//     required String interval,
//     required Function onTap,
//     required ProductDetails product,
//     required String price,
//   }) {
//     return AnimatedContainer(
//       curve: Curves.easeIn,
//       height: 100, //setting up dimention if product get selected
//       width: selectedProduct !=
//               product //setting up dimention if product get selected
//           ? MediaQuery.of(context).size.width * .19
//           : MediaQuery.of(context).size.width * .22,
//       decoration: selectedProduct == product
//           ? BoxDecoration(
//               shape: BoxShape.rectangle,
//               borderRadius: BorderRadius.circular(10),
//               color: Colors.white,
//               border: Border.all(width: 2, color: primaryColor))
//           : null,
//       duration: Duration(milliseconds: 500),
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.spaceAround,
//         children: <Widget>[
//           SizedBox(height: MediaQuery.of(context).size.height * .02),
//           Text(intervalCount,
//               style: TextStyle(
//                   color: selectedProduct !=
//                           product //setting up color if product get selected
//                       ? Colors.black
//                       : primaryColor,
//                   fontSize: 25,
//                   fontWeight: FontWeight.bold)),
//           Text(interval,
//               style: TextStyle(
//                   color: selectedProduct !=
//                           product //setting up color if product get selected
//                       ? Colors.black
//                       : primaryColor,
//                   fontWeight: FontWeight.w600,
//                   fontSize: 15)),
//           Text(price,
//               style: TextStyle(
//                   color: selectedProduct !=
//                           product //setting up product if product get selected
//                       ? Colors.black
//                       : primaryColor,
//                   fontSize: 13,
//                   fontWeight: FontWeight.bold)),
//         ],
//         //      )),
//       ),
//     );

//   }

}
