/// Conditional export: uses th web implementation (with dart:html) on web,
/// and a simple stub (cover image + external link) on mobile/desktop.
library;

export 'embed_video_section_stub.dart'
    if (dart.library.html) 'embed_video_section_web.dart';
