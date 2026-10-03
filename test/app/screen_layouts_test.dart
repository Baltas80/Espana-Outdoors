import 'package:espana_outdoors/app/screen_layouts.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('defines exactly the twelve canonical screen layouts', () {
    expect(EOScreenLayouts.all.length, 12);
    expect(
      EOScreenLayouts.all.map((layout) => layout.id).toSet().length,
      12,
    );
  });

  test('keeps every layout inside the canonical viewport', () {
    for (final layout in EOScreenLayouts.all) {
      expect(layout.slots, isNotEmpty, reason: layout.title);
      for (final slot in layout.slots) {
        final rect = slot.rect;
        expect(rect.left, greaterThanOrEqualTo(0), reason: '${layout.title}/${slot.name}');
        expect(rect.top, greaterThanOrEqualTo(0), reason: '${layout.title}/${slot.name}');
        expect(rect.width, greaterThan(0), reason: '${layout.title}/${slot.name}');
        expect(rect.height, greaterThan(0), reason: '${layout.title}/${slot.name}');
        expect(rect.right, lessThanOrEqualTo(EOLayoutCanvas.width), reason: '${layout.title}/${slot.name}');
        expect(rect.bottom, lessThanOrEqualTo(EOLayoutCanvas.height), reason: '${layout.title}/${slot.name}');
      }

      if (layout.hasBottomNavigation) {
        final bottom = layout.slot('bottomNavigation').rect;
        expect(bottom.left, 0);
        expect(bottom.width, EOLayoutCanvas.width);
        expect(bottom.height, EOLayoutCanvas.bottomBarHeight);
        expect(bottom.top, EOLayoutCanvas.height - EOLayoutCanvas.bottomBarHeight);
      }
    }
  });

  test('uses the shared app-bar geometry where an app bar exists', () {
    for (final layout in EOScreenLayouts.all) {
      final topBar = layout.slots.where((slot) => slot.name == 'topBar');
      for (final slot in topBar) {
        expect(slot.rect.left, EOLayoutCanvas.horizontal, reason: layout.title);
        expect(slot.rect.width, EOLayoutCanvas.contentWidth, reason: layout.title);
        expect(slot.rect.top, EOLayoutCanvas.safeTop, reason: layout.title);
        expect(slot.rect.height, 56, reason: layout.title);
      }
    }
  });
}
