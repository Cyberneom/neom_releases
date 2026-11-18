import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:neom_core/domain/model/app_profile.dart';
import 'package:neom_core/domain/model/collective.dart';
import 'package:neom_core/domain/model/item_list.dart';

Position? _getPosition(bool isNull, {double lat = 0.0, double lng = 0.0}) {
  if (isNull) return null;
  return Position(
    latitude: lat,
    longitude: lng,
    timestamp: DateTime.now(),
    accuracy: 0.0,
    altitude: 0.0,
    heading: 0.0,
    speed: 0.0,
    speedAccuracy: 0.0,
    altitudeAccuracy: 1.0,
    headingAccuracy: 1.0,
  );
}

void main() {
  group('Position Null Safety in Release Upload', () {
    test('Proof of original bug: pos?.latitude != 0.0 evaluates to true when pos is null', () {
      final pos = _getPosition(true);
      // In Dart, null != 0.0 evaluates to true:
      expect(pos?.latitude != 0.0, isTrue);
      // Forced unwrap throws TypeError:
      expect(() {
        if (pos?.latitude != 0.0) {
          final _ = pos!;
        }
      }, throwsA(isA<TypeError>()));
    });

    test('Safe guard: pos != null && pos.latitude != 0.0 evaluates to false when pos is null', () {
      final pos = _getPosition(true);
      final safeCondition = pos != null && pos.latitude != 0.0;
      expect(safeCondition, isFalse);
    });

    test('Profile with null position does not assign releaseItemlist.position and does not crash', () {
      final profile = AppProfile();
      profile.position = _getPosition(true);
      final releaseItemlist = Itemlist();

      final profilePos = profile.position;
      if (profilePos != null && profilePos.latitude != 0.0) {
        releaseItemlist.position = profilePos;
      }

      expect(releaseItemlist.position, isNull);
    });

    test('Profile with latitude 0.0 is not assigned to releaseItemlist.position', () {
      final profile = AppProfile();
      profile.position = _getPosition(false, lat: 0.0, lng: 0.0);
      final releaseItemlist = Itemlist();

      final profilePos = profile.position;
      if (profilePos != null && profilePos.latitude != 0.0) {
        releaseItemlist.position = profilePos;
      }

      expect(releaseItemlist.position, isNull);
    });

    test('Profile with valid coordinate assigns releaseItemlist.position', () {
      final profile = AppProfile();
      profile.position = _getPosition(false, lat: 20.6767, lng: -103.3475);
      final releaseItemlist = Itemlist();

      final profilePos = profile.position;
      if (profilePos != null && profilePos.latitude != 0.0) {
        releaseItemlist.position = profilePos;
      }

      expect(releaseItemlist.position, isNotNull);
      expect(releaseItemlist.position?.latitude, 20.6767);
      expect(releaseItemlist.position?.longitude, -103.3475);
    });

    test('Collective with null position does not assign releaseItemlist.position and does not crash', () {
      final collective = Collective();
      collective.position = _getPosition(true);
      final releaseItemlist = Itemlist();

      final collectivePos = collective.position;
      if (collectivePos != null && collectivePos.latitude != 0.0) {
        releaseItemlist.position = collectivePos;
      }

      expect(releaseItemlist.position, isNull);
    });

    test('Collective with valid coordinate assigns releaseItemlist.position', () {
      final collective = Collective();
      collective.position = _getPosition(false, lat: 19.4326, lng: -99.1332);
      final releaseItemlist = Itemlist();

      final collectivePos = collective.position;
      if (collectivePos != null && collectivePos.latitude != 0.0) {
        releaseItemlist.position = collectivePos;
      }

      expect(releaseItemlist.position, isNotNull);
      expect(releaseItemlist.position?.latitude, 19.4326);
    });
  });
}
