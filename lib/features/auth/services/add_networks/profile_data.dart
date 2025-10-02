class ProfileData {
  final String url;
  final String username;
  final String fullName;
  final String profilePicUrl;
  final int followers;
  final int followees;
  final int totalPosts;

  ProfileData({
    required this.url,
    required this.username,
    required this.fullName,
    required this.profilePicUrl,
    required this.followers,
    required this.followees,
    required this.totalPosts,
  });

  factory ProfileData.fromJson(Map<String, dynamic> json) {
    return ProfileData(
      url: json['url'] ?? '',
      username: json['username'] ?? '',
      fullName: json['full_name'] ?? '',
      profilePicUrl: json['profile_pic_url'] ?? '',
      followers: json['followers'] ?? 0,
      followees: json['followees'] ?? 0,
      totalPosts: json['total_posts'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'username': username,
      'full_name': fullName,
      'profile_pic_url': profilePicUrl,
      'followers': followers,
      'followees': followees,
      'total_posts': totalPosts,
    };
  }
}
