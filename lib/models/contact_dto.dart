class ContactDto {
  final String name, email, phone;
  const ContactDto(this.name, this.email, this.phone);
  factory ContactDto.fromJson(Map<String, dynamic> json) => ContactDto(
    json['name'] as String,
    json['email'] as String,
    json['phone'] as String,
  );
  Map<String, Object?> toJson() => {
    'name': name,
    'email': email,
    'phone': phone,
  };
}

class ProfileDto {
  final String uid;
  final ContactDto contact;
  const ProfileDto(this.uid, this.contact);
}
