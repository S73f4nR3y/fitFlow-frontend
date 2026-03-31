String? getInstructorPhotoUrl(dynamic instructor) {
  if (instructor == null) return null;

  final avatarUrl = instructor['avatarUrl'];
  if (avatarUrl != null && avatarUrl.toString().isNotEmpty) {
    final url = avatarUrl.toString();
    if (url.startsWith('http')) return url;
    return 'http://localhost:3000$url';
  }
  final userAvatar = instructor['user']?['avatarUrl'];
  if (userAvatar != null && userAvatar.toString().isNotEmpty) {
    final url = userAvatar.toString();
    if (url.startsWith('http')) return url;
    return 'http://localhost:3000$url';
  }
  final photoUrl = instructor['photoUrl'];
  if (photoUrl != null && photoUrl.toString().isNotEmpty) {
    final url = photoUrl.toString();
    if (url.startsWith('http')) return url;
    return 'http://localhost:3000$url';
  }
  return null;
}
