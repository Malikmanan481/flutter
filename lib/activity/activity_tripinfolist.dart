import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:speedotrack/activity/activity_historyMap.dart';
import 'package:speedotrack/activity/activity_tripinfo.dart';
import 'package:speedotrack/globals.dart';

class TripInfoListActivity extends StatefulWidget {
  final List<Trip>? tripInfoModel;
  final String? name;
  final String? imei;

  const TripInfoListActivity(
      {Key? key, this.tripInfoModel, this.name, this.imei})
      : super(key: key);

  @override
  _TripInfoListActivityState createState() =>
      _TripInfoListActivityState(tripInfoModel, name, imei);
}

class _TripInfoListActivityState extends State<TripInfoListActivity> {
  final List<Trip>? tripInfoModel;
  final String? name;
  final String? imei;

  _TripInfoListActivityState(this.tripInfoModel, this.name, this.imei);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF6F6F6),
      appBar: AppBar(
        backgroundColor: Globals.appColor,
        elevation: 0.0,
        title: Text(
          'tripInfo'.tr,
          style:
              TextStyle(color: Color(0xFFF6F6F6), fontFamily: 'Baloo_Thambi_2'),
        ),
        iconTheme: IconThemeData(
          color: Color(0xFFF6F6F6),
        ),
      ),
      body: Container(
        color: Color(0xFFF6F6F6),
        child: tripInfoModel != null && tripInfoModel!.isNotEmpty
            ? ListView.builder(
                addAutomaticKeepAlives: false,
                itemCount: tripInfoModel!.length,
                physics: BouncingScrollPhysics(),
                shrinkWrap: true,
                scrollDirection: Axis.vertical,
                itemBuilder: (context, index) {
                  final trip = tripInfoModel![index];
                  return InkWell(
                    onTap: () {
                      Navigator.push(
                          context,
                          CupertinoPageRoute(
                              builder: (context) => HistoryMapActivity(
                                  name: name,
                                  imei: imei,
                                  from: 'trip',
                                  dtf: trip.start,
                                  dtt: trip.end,
                                  stop: '1',
                                  parking: false)));
                    },
                    child: Card(
                      elevation: 5,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(5))),
                      color: Color(0xFFF6F6F6),
                      child: Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Column(
                          children: <Widget>[
                            Container(
                              child: Stack(
                                children: <Widget>[
                                  Positioned(
                                    top: 10.0,
                                    bottom: 10.0,
                                    left: 15.0,
                                    child: Container(
                                      height: double.infinity,
                                      width: 2.0,
                                      color: Globals.appColor,
                                    ),
                                  ),
                                  Positioned(
                                    top: 5.0,
                                    left: 6.0,
                                    child: Container(
                                      height: 20.0,
                                      width: 20.0,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Color(0xFFF6F6F6),
                                      ),
                                      child: Container(
                                        margin: EdgeInsets.all(5.0),
                                        height: 20.0,
                                        width: 20.0,
                                        decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Colors.green),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 5.0,
                                    left: 6.0,
                                    child: Container(
                                      height: 20.0,
                                      width: 20.0,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Color(0xFFF6F6F6),
                                      ),
                                      child: Container(
                                        margin: EdgeInsets.all(5.0),
                                        height: 20.0,
                                        width: 20.0,
                                        decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Colors.red),
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(left: 50.0),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.max,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Row(
                                          children: <Widget>[
                                            Text(
                                              'startLocation'.tr,
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                  color: Colors.green,
                                                  fontSize: 14,
                                                  letterSpacing: 1.3,
                                                  fontWeight: FontWeight.bold,
                                                  fontFamily: 'Philosopher'),
                                            ),
                                            Spacer(),
                                            Text(
                                              '${trip.start ?? ''}',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                  color: Color(0xFF7E8188),
                                                  fontSize: 12,
                                                  letterSpacing: 1.3,
                                                  fontWeight: FontWeight.bold,
                                                  fontFamily: 'Montserrat'),
                                            ),
                                          ],
                                        ),
                                        if (trip.startAddress != null &&
                                            trip.startAddress!.isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.only(top: 2.0),
                                            child: Text(
                                              trip.startAddress!,
                                              textAlign: TextAlign.start,
                                              maxLines: 2,
                                              overflow: TextSpan.ellipsis,
                                              style: TextStyle(
                                                  color: Colors.black87,
                                                  fontSize: 12,
                                                  letterSpacing: 0.5,
                                                  fontWeight: FontWeight.w600,
                                                  fontFamily: 'Montserrat'),
                                            ),
                                          ),
                                        SizedBox(
                                          height: 12,
                                        ),
                                        Row(
                                          children: <Widget>[
                                            Text(
                                              'endLocation'.tr,
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                  color: Colors.red,
                                                  fontSize: 14,
                                                  letterSpacing: 1.3,
                                                  fontWeight: FontWeight.bold,
                                                  fontFamily: 'Philosopher'),
                                            ),
                                            Spacer(),
                                            Text(
                                              '${trip.end ?? ''}',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                  color: Color(0xFF7E8188),
                                                  fontSize: 12,
                                                  letterSpacing: 1.3,
                                                  fontWeight: FontWeight.bold,
                                                  fontFamily: 'Montserrat'),
                                            ),
                                          ],
                                        ),
                                        if (trip.endAddress != null &&
                                            trip.endAddress!.isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.only(top: 2.0),
                                            child: Text(
                                              trip.endAddress!,
                                              textAlign: TextAlign.start,
                                              maxLines: 2,
                                              overflow: TextSpan.ellipsis,
                                              style: TextStyle(
                                                  color: Colors.black87,
                                                  fontSize: 12,
                                                  letterSpacing: 0.5,
                                                  fontWeight: FontWeight.w600,
                                                  fontFamily: 'Montserrat'),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                                height: 40,
                                width: double.infinity,
                                child: Stack(
                                  children: <Widget>[
                                    Container(
                                      margin: EdgeInsets.only(
                                          left: 10, right: 10, top: 22.5),
                                      height: 2.0,
                                      color: Globals.appColor,
                                    ),
                                    Positioned(
                                      top: 5.0,
                                      left: 5.0,
                                      child: Container(
                                        height: 40.0,
                                        width: 40.0,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Color(0xFFF6F6F6),
                                        ),
                                        child: Icon(
                                          FontAwesomeIcons.car,
                                          color: Globals.appColor,
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      top: 5.0,
                                      right: 5.0,
                                      child: Container(
                                        height: 40.0,
                                        width: 40.0,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Color(0xFFF6F6F6),
                                        ),
                                        child: Icon(
                                          FontAwesomeIcons.mapMarkerAlt,
                                          color: Colors.red,
                                        ),
                                      ),
                                    ),
                                  ],
                                )),
                            Container(
                                height: 40,
                                width: double.infinity,
                                child: Row(
                                  children: <Widget>[
                                    Expanded(
                                      flex: 1,
                                      child: Text(
                                        '${'tripDuration'.tr}: ${trip.duration ?? ''}',
                                        textAlign: TextAlign.start,
                                        style: TextStyle(
                                            color: Color(0xFF7E8188),
                                            fontSize: 12,
                                            letterSpacing: 1.3,
                                            fontWeight: FontWeight.bold,
                                            fontFamily: 'Montserrat'),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 1,
                                      child: Text(
                                        '${'distance'.tr}(Km.): ${trip.length ?? '0'}',
                                        textAlign: TextAlign.end,
                                        style: TextStyle(
                                            color: Color(0xFF7E8188),
                                            fontSize: 12,
                                            letterSpacing: 1.3,
                                            fontWeight: FontWeight.bold,
                                            fontFamily: 'Montserrat'),
                                      ),
                                    )
                                  ],
                                )),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              )
            : Center(
                child: Text("noTripInfo".tr),
              ),
      ),
    );
  }
}
