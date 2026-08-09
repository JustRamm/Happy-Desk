/// Shared flag used to distinguish user-initiated sign-outs from
/// unexpected session terminations (JWT expiry, remote revocation, etc.).
///
/// Set [markUserInitiatedSignOut] before calling logout() so the global
/// auth listener in [UAndMeApp] can suppress the "session ended" snackbar
/// (Scenario 6).
library sign_out_flag;

bool userInitiatedSignOut = false;

/// Call this immediately before a user-triggered logout to prevent the
/// global auth-state listener from showing the "session ended" snackbar.
void markUserInitiatedSignOut() {
  userInitiatedSignOut = true;
}
