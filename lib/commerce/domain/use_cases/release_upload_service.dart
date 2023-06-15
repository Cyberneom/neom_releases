
import 'package:neom_commons/core/domain/model/genre.dart';
import 'package:neom_commons/core/utils/enums/release_type.dart';

abstract class ReleaseUploadService {

  Future<void> setReleaseType(ReleaseType releaseType);
  void addInstrument(int index);
  void removeInstrument(int index);
  Future<void> addInstrumentsToReleaseItem();
  Future<void> uploadReleaseItem();
  Future<void> createReleasePost();
  Future<void> getPublisherPlace(context);
  bool validateInfo();
  void setPublishedYear(int year);
  void setIsPhysical();
  void setIsAutoPublished();
  void setReleaseName();
  void setReleaseDesc();
  bool validateNameDesc();
  Future<void> gotoReleaseSummary();
  Future<void> addReleaseCoverImg();
  void addGenre(Genre genre);
  void removeGenre(Genre genre);
  Future<void> addReleaseFile();


}
