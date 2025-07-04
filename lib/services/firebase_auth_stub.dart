// Stub for firebase_auth on desktop platforms
class User {}

class UserCredential {
  final User? user;
  UserCredential({this.user});
}

class FirebaseAuthException implements Exception {
  final String code;
  final String message;
  FirebaseAuthException({required this.code, required this.message});
}

class FirebaseAuth {
  static FirebaseAuth instance = FirebaseAuth();
  User? get currentUser => null;
  Future<UserCredential> signInWithEmailAndPassword(
          {required String email, required String password}) async =>
      UserCredential(user: null);
  Future<UserCredential> createUserWithEmailAndPassword(
          {required String email, required String password}) async =>
      UserCredential(user: null);
  Future<void> signOut() async {}
}
