import 'package:flutter/material.dart';

import 'dart:async';
import 'package:geocoder/geocoder.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location_permissions/location_permissions.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'User Location',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Location'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final Map<String, Marker> _markers = {};
  Completer<GoogleMapController> _controller = Completer();
  static final CameraPosition _myLocation = CameraPosition(
    target: LatLng(20.5937, 78.9629),
  );
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: GoogleMap(
        initialCameraPosition: _myLocation,
        mapType: MapType.normal,
        onMapCreated: (GoogleMapController controller) {
          _controller.complete(controller);
        },
        markers: _markers.values.toSet(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _userLocation,
        tooltip: 'Current Location',
        child: Icon(Icons.gps_fixed),
      ),
    );
  }

  void _userLocation() async {
    //It checks the permission status, if not granted it shows the dialog
    //for accessing the location
    PermissionStatus permission =
        await LocationPermissions().requestPermissions();
    switch (permission) {
      case PermissionStatus.granted:
        //permission granted then call _getUserLocation()
        _getUserLocation();
        break;
      case PermissionStatus.denied:
        //permission denied then call show dialog for accessing permission
        alertDialog(context);
        break;
      case PermissionStatus.restricted:
        //permission restricted then tell user to enable permission from settings
        alertDialog(context);
        break;
      case PermissionStatus.unknown:
        break;
    }
  }

  void _getUserLocation() async {
    //Show the dialog until the location fetched
    waitingDialog(context, "Getting your Location..");

    //getting user current latitude and longitude
    var currentLocation = await Geolocator()
        .getCurrentPosition(desiredAccuracy: LocationAccuracy.best);

    //converting the latitude nad longitude to an address
    var addresses = await Geocoder.local.findAddressesFromCoordinates(
        Coordinates(currentLocation.latitude, currentLocation.longitude));

    //pop the dialog when location is fetched
    Navigator.pop(context);

    //now set the marker on map
    setState(() {
      final marker = Marker(
        markerId: MarkerId("curr_loc"),
        position: LatLng(currentLocation.latitude, currentLocation.longitude),
        infoWindow: InfoWindow(title: addresses.first.addressLine),
      );

      //calling method which will animate the map to current location
      resetCamera(
          LatLng(currentLocation.latitude, currentLocation.longitude), 18);
      _markers["Current Location"] = marker;
    });
  }

  Future<void> resetCamera(LatLng latLng, double zoom) async {
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newCameraPosition(
        CameraPosition(target: latLng, tilt: 50, zoom: zoom, bearing: 15.0)));
  }

  waitingDialog(BuildContext context, String description) => showDialog(
      context: context,
      barrierDismissible: false,
      useRootNavigator: false,
      builder: (BuildContext context) {
        return AlertDialog(
          content: ListTile(
            leading: CircularProgressIndicator(
              backgroundColor: Colors.red,
            ),
            title: Text(description),
          ),
        );
      });

  alertDialog(BuildContext context) => showDialog(
      context: context,
      barrierDismissible: false,
      useRootNavigator: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Permission Denied"),
          content: Text(
              "Please Allow Permission to use location. Please Enable it from setting"),
          actions: <Widget>[
            RaisedButton(
              child: Text("Ok"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      });
}
