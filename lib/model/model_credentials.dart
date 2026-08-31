import 'package:flutter/material.dart';
import 'package:credential_manager/credential_manager.dart';

class CredentialsModel with ChangeNotifier {
  final _credentials = CredentialManager();

  var idEdit = TextEditingController();
  var passwordEdit = TextEditingController();

  CredentialsModel() {
    Future(() async {
      _credentials.init(preferImmediatelyAvailableCredentials: true);
      notifyListeners();
    });
  }

  Future<void> store() async {
    return await _credentials.savePasswordCredentials(
        PasswordCredential(username: idEdit.text, password: passwordEdit.text));
  }

  Future<Credentials> get() async {
    var credential = await _credentials.getPasswordCredentials();
    if (credential != null) {
      idEdit.text = credential.passwordCredential!.username!;
      passwordEdit.text = credential.passwordCredential!.password!;
      notifyListeners();
    }
    return credential;
  }

  // ==========================================
  // TRACCAR API & SESSION BACKEND INTEGRATION
  // ==========================================

  /// Traccar REST API (`/api/session`) authentication ke liye Form URL-encoded map
  Map<String, String> toTraccarFormBody() {
    return {
      'email': idEdit.text.trim(),
      'password': passwordEdit.text,
    };
  }

  /// Traccar Session REST Header format
  Map<String, String> toTraccarAuthHeaders() {
    return {
      'Content-Type': 'application/x-www-form-urlencoded',
    };
  }

  /// Traccar session login complete hone par automatically credentials save karne ka helper
  Future<bool> loginAndSaveToTraccar(Future<bool> Function(String email, String password) traccarLoginApiCall) async {
    try {
      if (idEdit.text.isNotEmpty && passwordEdit.text.isNotEmpty) {
        bool success = await traccarLoginApiCall(idEdit.text.trim(), passwordEdit.text);
        if (success) {
          await store(); // Traccar backend auth success par Android Credential Manager me store hoga
        }
        return success;
      }
    } catch (e) {
      debugPrint('CredentialsModel: Traccar authentication error - $e');
    }
    return false;
  }

  //
  // Future<void> preventSilentAccess() async {
  //   await _credentials.preventSilentAccess();
  // }
  //
  // Future<void> openPlatformCredentialSettings() async {
  //   await _credentials.openPlatformCredentialSettings();
  // }
}
