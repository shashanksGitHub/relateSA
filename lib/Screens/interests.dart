import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hookup4u/Screens/University.dart';
import 'package:hookup4u/util/color.dart';
import 'package:hookup4u/util/snackbar.dart';
import 'package:easy_localization/easy_localization.dart';

class Interest extends StatefulWidget {
  final Map<String, dynamic> userData;
  Interest(this.userData);

  @override
  _InterestState createState() => _InterestState();
}

class _InterestState extends State<Interest> {
  List<Map<String, dynamic>> interestList = [
    {
      'name': 'Physically fit'.tr().toString(),
      'ontap': false,
      'code': 'physicallyFit'
    },
    {
      'name': 'Voluptuous'.tr().toString(),
      'ontap': false,
      'code': 'voluptuous'
    },
    {
      'name': 'Perceptive'.tr().toString(),
      'ontap': false,
      'code': 'perceptive'
    },
    {
      'name': 'Spontaneous'.tr().toString(),
      'ontap': false,
      'code': 'spontaneous'
    },
    {'name': 'Outgoing'.tr().toString(), 'ontap': false, 'code': 'outgoing'},
    {
      'name': 'Optimistic'.tr().toString(),
      'ontap': false,
      'code': 'optimistic'
    },
    {
      'name': 'Passionate'.tr().toString(),
      'ontap': false,
      'code': 'passionate'
    },
    {
      'name': 'Affectionate'.tr().toString(),
      'ontap': false,
      'code': 'affectionate'
    },
    {
      'name': 'Family oriented'.tr().toString(),
      'ontap': false,
      'code': 'familyOriented'
    },
    {
      'name': 'Hard working and Ambitious'.tr().toString(),
      'ontap': false,
      'code': 'hardWorkingAndAmbitious'
    },
  ];
  List selected = [];
  bool select = false;
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      floatingActionButton: AnimatedOpacity(
        opacity: 1.0,
        duration: Duration(milliseconds: 50),
        child: Padding(
          padding: const EdgeInsets.only(top: 10.0),
          child: FloatingActionButton(
            elevation: 10,
            child: IconButton(
              color: secondryColor,
              icon: Icon(Icons.arrow_back_ios),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            backgroundColor: Colors.white38,
            onPressed: () {
              dispose();
              Navigator.pop(context);
            },
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startTop,
      body: Container(
        height: MediaQuery.of(context).size.height,
        child: SingleChildScrollView(
          child: Column(
            // mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Padding(
                child: Text(
                  "My interests are".tr().toString(),
                  style: TextStyle(fontSize: 40),
                ),
                padding: EdgeInsets.only(left: 50, top: 80),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 70, vertical: 50),
                child: ListView.builder(
                  physics: NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: interestList.length,
                  itemBuilder: (BuildContext context, index) {
                    return Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: OutlinedButton(
                        //   highlightedBorderColor: primaryColor,
                        child: Container(
                          height: MediaQuery.of(context).size.height * .055,
                          width: MediaQuery.of(context).size.width * .65,
                          child: Center(
                              child: Text("${interestList[index]["name"]}",
                                  style: TextStyle(
                                      fontSize: 20,
                                      color: interestList[index]["ontap"]
                                          ? primaryColor
                                          : secondryColor,
                                      fontWeight: FontWeight.bold))),
                        ),
                        // borderSide: BorderSide(
                        //     width: 1,
                        //     style: BorderStyle.solid,
                        //     color: interestList[index]["ontap"]
                        //         ? primaryColor
                        //         : secondryColor),
                        // shape: RoundedRectangleBorder(
                        //     borderRadius: BorderRadius.circular(25)),
                        onPressed: () {
                          setState(() {
                            if (selected.length < 11) {
                              interestList[index]["ontap"] =
                                  !interestList[index]["ontap"];
                              if (interestList[index]["ontap"]) {
                                selected.add(interestList[index]["code"]);
                                print(interestList[index]["name"]);
                                print(selected);
                              } else {
                                selected.remove(interestList[index]["code"]);
                                print(selected);
                              }
                            } else {
                              if (interestList[index]["ontap"]) {
                                interestList[index]["ontap"] =
                                    !interestList[index]["ontap"];
                                selected.remove(interestList[index]["code"]);
                              } else {
                                CustomSnackbar.showSnackBar(
                                    text: "select upto 10".tr().toString(),
                                    context: context);
                              }
                            }
                          });
                        },
                      ),
                    );
                  },
                ),
              ),
              Column(
                children: <Widget>[
                  selected.length > 0
                      ? Padding(
                          padding: const EdgeInsets.only(bottom: 40),
                          child: Align(
                            alignment: Alignment.bottomCenter,
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
                                  height:
                                      MediaQuery.of(context).size.height * .065,
                                  width:
                                      MediaQuery.of(context).size.width * .75,
                                  child: Center(
                                      child: Text(
                                    "CONTINUE".tr().toString(),
                                    style: TextStyle(
                                        fontSize: 15,
                                        color: textColor,
                                        fontWeight: FontWeight.bold),
                                  ))),
                              onTap: () {
                                widget.userData.addAll({
                                  "myInterest": {
                                    'interest': selected,
                                  },
                                });
                                print(widget.userData);
                                Navigator.push(
                                    context,
                                    CupertinoPageRoute(
                                        builder: (context) =>
                                            University(widget.userData)));
                              },
                            ),
                          ),
                        )
                      : Padding(
                          padding: const EdgeInsets.only(bottom: 40),
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: InkWell(
                              child: Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.rectangle,
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                  height:
                                      MediaQuery.of(context).size.height * .065,
                                  width:
                                      MediaQuery.of(context).size.width * .75,
                                  child: Center(
                                      child: Text(
                                    "CONTINUE".tr().toString(),
                                    style: TextStyle(
                                        fontSize: 15,
                                        color: secondryColor,
                                        fontWeight: FontWeight.bold),
                                  ))),
                              onTap: () {
                                CustomSnackbar.showSnackBar(
                                    text: "Please select one".tr().toString(),
                                    context: context);
                              },
                            ),
                          ),
                        )
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
