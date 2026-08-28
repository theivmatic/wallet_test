String? cardsAuthRedirect(Uri uri, bool isAuthed) {
  final path = uri.path;

  if (!isAuthed && (path == '/cards' || path.startsWith('/cards/'))) {
    final location = uri.hasQuery ? '${uri.path}?${uri.query}' : uri.path;
    return '/onboarding?next=${Uri.encodeComponent(location)}';
  }

  if (isAuthed && path == '/onboarding') {
    final next = uri.queryParameters['next'];

    if (next == null) {
      return null;
    }

    if (next.isEmpty) {
      return '/cards';
    }

    final decoded = Uri.decodeComponent(next);

    if (_isSafeCardsLocation(decoded)) {
      return decoded;
    }

    return '/cards';
  }

  if (!isAuthed && path == '/onboarding') {
    return null;
  }

  return null;
}

bool _isSafeCardsLocation(String location) {
  if (location.startsWith('http://') || location.startsWith('https://')) {
    return false;
  }

  return location == '/cards' || location.startsWith('/cards/');
}
