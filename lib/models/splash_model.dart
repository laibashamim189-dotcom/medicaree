enum NavigationTarget {
  login,
  home,
}

class SplashModel {
  final NavigationTarget target;

  SplashModel({required this.target});
}