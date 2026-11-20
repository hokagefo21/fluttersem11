class ContactDraft {
  final String name, email, phone;
  const ContactDraft({
    required this.name,
    required this.email,
    required this.phone,
  });
  bool get isEmpty =>
      name.trim().isEmpty && email.trim().isEmpty && phone.trim().isEmpty;
  ContactDraft get normalized => ContactDraft(
    name: name.trim(),
    email: email.trim().toLowerCase(),
    phone: phone.trim(),
  );
}

class RegisteredProfile {
  final String uid;
  final ContactDraft contact;
  const RegisteredProfile(this.uid, this.contact);
}

enum PushPhase {
  initializing,
  ready,
  waiting,
  denied,
  missingToken,
  unavailable,
  sent,
  received,
  opened,
  displayFailed,
  sendFailed,
  statusFailed,
  tokenFailed,
  requested,
}

class PushNotice {
  final PushPhase phase;
  final String message;
  const PushNotice(this.phase, [this.message = '']);
  PushNotice update(PushPhase next, {String? body}) {
    final text = body ?? message;
    if (text.isNotEmpty &&
        (next == PushPhase.sent || next == PushPhase.requested)) {
      return PushNotice(PushPhase.received, text);
    }
    return PushNotice(next, text);
  }
}
