import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Optional: pass your Web client ID (server client id) when you call this
  // if you need extra behavior on Android or to request server-side tokens.
  Future<String?> signInWithGoogle({String? serverClientId}) async {
    try {
      final googleSignIn = GoogleSignIn.instance;

      // Initialize the singleton first (required in v7+).
      // Pass serverClientId: '<YOUR_WEB_CLIENT_ID>' if needed.
      await googleSignIn.initialize(serverClientId: serverClientId);

      // Clear previous session so the account chooser appears
      await googleSignIn.signOut();

      // Start interactive authentication. authenticate(...) replaces signIn()
      // and can accept a scopeHint list if necessary.
      final GoogleSignInAccount? googleUser =
          await googleSignIn.authenticate(scopeHint: ['email', 'profile']);

      // In some v7 flows `authenticate` throws instead of returning null,
      // but check for safety:
      if (googleUser == null) return "Google sign-in cancelled";

      // This returns a GoogleSignInAuthentication which currently contains
      // an idToken (no accessToken by default).
      final googleAuth = googleUser.authentication;
      final idToken = googleAuth.idToken;
      if (idToken == null) return "No id token returned by Google";

      // Create Firebase credential using the returned idToken.
      final credential = GoogleAuthProvider.credential(idToken: idToken);

      // Sign in to Firebase with the Google credential.
      final userCred = await _auth.signInWithCredential(credential);

      // Fetch Firestore user doc and enforce role/status logic.
      final docSnap =
          await _firestore.collection('users').doc(userCred.user!.uid).get();

      if (docSnap.exists) {
        final role = docSnap.get('role');
        final status = docSnap.get('status');

        if (role == 'teacher' && status != 'approved') {
          await _auth.signOut();
          return "Teacher account pending approval";
        }

        return role; // "student", "teacher", or "admin"
      } else {
        return "NEEDS_ROLE";
      }
    } on GoogleSignInException catch (e) {
      // GoogleSignIn-specific errors have helpful fields
      print('GoogleSignInException: code=${e.code} description=${e.description} details=${e.details}');
      return "Google sign-in failed";
    } catch (e, st) {
      print('signInWithGoogle error: $e\n$st');
      return "Google sign-in failed";
    }
  }

  Future<String?> createGoogleUserWithRole({required String role}) async {
    final user = _auth.currentUser;
    if (user == null) return "Not signed in";

    await _firestore.collection("users").doc(user.uid).set({
      "uid": user.uid,
      "name": user.displayName ?? "",
      "email": user.email,
      "phone": user.phoneNumber ?? "",
      "portfolio": "",
      "role": role,
      "status": role == "teacher" ? "pending" : "approved",
      "createdAt": FieldValue.serverTimestamp(),
    });

    return role;
  }
}
