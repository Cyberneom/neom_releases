import 'package:flutter_test/flutter_test.dart';
import 'package:neom_releases/ui/release_upload_controller.dart';

void main() {
  String name(String owner, String title, int time) =>
      ReleaseUploadController.storageNameFor(
          ownerId: owner, title: title, createdTime: time);

  test('two artists with a track of the same title get different files', () {
    // Stored by title alone, the second "Intro" overwrote the first.
    expect(name('artist-a', 'Intro', 1000), isNot(name('artist-b', 'Intro', 1000)));
  });

  test('the same artist uploading the same title twice keeps both', () {
    expect(name('artist-a', 'Demo', 1000), isNot(name('artist-a', 'Demo', 2000)));
  });

  test('the name lives in the uploader folder', () {
    expect(name('artist-a', 'Mi Canción', 1000), 'artist-a/1000_mi-canción');
  });

  test('a title cannot climb out of the uploader folder', () {
    final n = name('artist-a', '../../other/Track', 1000);
    expect(n.split('/'), hasLength(2));
    expect(n, startsWith('artist-a/'));
    expect(n, isNot(contains('..')));
  });

  test('a title with no latin characters still gets a unique name', () {
    expect(name('artist-a', '夜の歌', 1000), 'artist-a/1000');
  });

  test('a missing owner does not produce a root-level file', () {
    expect(name('', 'Intro', 1000), 'unowned/1000_intro');
  });
}
