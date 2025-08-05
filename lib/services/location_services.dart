import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

extension OnLocationPermissionStatus on LocationPermission{
  bool get isGranted => this == LocationPermission.whileInUse || this == LocationPermission.always;
  bool get temporaryDenied => this == LocationPermission.denied;
  bool get permanentlyDenied => this == LocationPermission.deniedForever;
}

extension OnPosition on Position{
  LatLng get latLng => LatLng(latitude, longitude);
}


class LocationServices{
  static Future<LocationPermission> get locationStatus => Geolocator.checkPermission();
  static Future<LocationPermission> get requestPermission => Geolocator.requestPermission();
  static Future<Position> get getPosition => Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
  static Stream<Position> get watchPosition =>Geolocator.getPositionStream();

  static Future<void> openAppSettings() => Geolocator.openAppSettings();
  static Future<void> openLocationSettings() => Geolocator.openLocationSettings();


  static Future<bool> _isServiceEnabled() async{
    final isEnabled = await Geolocator.isLocationServiceEnabled();
    if(!isEnabled){
      throw LocationException('Location services are disabled.');
    }
    return true;
  }

  static Future<LocationPermission> get checkAndRequestPermission async{
    await _isServiceEnabled();
    LocationPermission initState = await locationStatus;
    if(initState.isGranted){
      return initState;
    }else{
      return await requestPermission;
    }
  }


  static Future<Position?> getCurrentPosition({bool openSettingsIfDenied = false}) async {
    final permission = await checkAndRequestPermission;

    if (permission.isGranted) {
      return await getPosition;
    }

    if (openSettingsIfDenied && permission.permanentlyDenied) {
      await openLocationSettings();
    }

    return null;
  }

  static Stream<Position?> watchLivePosition({
    bool openSettingsIfDenied = false,
    LocationAccuracy accuracy = LocationAccuracy.high,
    int distanceFilter = 10,
  }) async* {
    final permission = await checkAndRequestPermission;

    if (permission.isGranted) {
      yield* Geolocator.getPositionStream(
        locationSettings: LocationSettings(
          accuracy: accuracy,
          distanceFilter: distanceFilter,
        ),
      );
    } else {
      if (openSettingsIfDenied && permission.permanentlyDenied) {
        await openLocationSettings();
      }
      yield null;
    }
  }
}


class LocationException implements Exception {
  final String message;
  LocationException(this.message);

  @override
  String toString() => 'LocationException: $message';
}