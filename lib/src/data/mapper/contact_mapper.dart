import '../../../models/contact_dto.dart';
import '../../domain/entities/registration.dart';

extension ContactMapper on ContactDto {
  ContactDraft toEntity() =>
      ContactDraft(name: name, email: email, phone: phone);
}

extension ContactPayload on ContactDraft {
  ContactDto toDto() => ContactDto(name, email, phone);
}

extension ProfileMapper on ProfileDto {
  RegisteredProfile toEntity() => RegisteredProfile(uid, contact.toEntity());
}
