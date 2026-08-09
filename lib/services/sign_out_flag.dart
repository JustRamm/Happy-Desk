/// Shared flag used to distinguish user-initiated sign-outs from
/// unexpected session terminations (JWT expiry, remote revocation, etc.).
bool userInitiatedSignOut = false;

/// Call this immediately before a user-triggered logout to prevent the
/// global auth-state listener from showing the "session ended" snackbar.
void markUserInitiatedSignOut() {
  userInitiatedSignOut = true;
}
