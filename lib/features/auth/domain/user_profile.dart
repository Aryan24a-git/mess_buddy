class UserProfile {
  final String name;
  final String email;
  final double monthlyBudget;
  final String? roomNo;
  final String? roommateName;
  final String? hostelName;
  final String loginMethod; // 'email' | 'google'
  final String? profilePicPath;
  final String? referralCode;

  const UserProfile({
    required this.name,
    required this.email,
    required this.monthlyBudget,
    this.roomNo,
    this.roommateName,
    this.hostelName,
    this.loginMethod = 'email',
    this.profilePicPath,
    this.referralCode,
  });

  UserProfile copyWith({
    String? name,
    String? email,
    double? monthlyBudget,
    String? roomNo,
    String? roommateName,
    String? hostelName,
    String? loginMethod,
    String? profilePicPath,
    String? referralCode,
  }) {
    return UserProfile(
      name: name ?? this.name,
      email: email ?? this.email,
      monthlyBudget: monthlyBudget ?? this.monthlyBudget,
      roomNo: roomNo ?? this.roomNo,
      roommateName: roommateName ?? this.roommateName,
      hostelName: hostelName ?? this.hostelName,
      loginMethod: loginMethod ?? this.loginMethod,
      profilePicPath: profilePicPath ?? this.profilePicPath,
      referralCode: referralCode ?? this.referralCode,
    );
  }
}
