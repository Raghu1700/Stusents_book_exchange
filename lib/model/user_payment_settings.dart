class UserPaymentSettings {
  final String? phoneNumber;
  final String? upiId;
  final String? bankDetails;

  UserPaymentSettings({
    this.phoneNumber,
    this.upiId,
    this.bankDetails,
  });

  UserPaymentSettings copyWith({
    String? phoneNumber,
    String? upiId,
    String? bankDetails,
  }) {
    return UserPaymentSettings(
      phoneNumber: phoneNumber ?? this.phoneNumber,
      upiId: upiId ?? this.upiId,
      bankDetails: bankDetails ?? this.bankDetails,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'phoneNumber': phoneNumber,
      'upiId': upiId,
      'bankDetails': bankDetails,
    };
  }

  factory UserPaymentSettings.fromMap(Map<String, dynamic> map) {
    return UserPaymentSettings(
      phoneNumber: map['phoneNumber'],
      upiId: map['upiId'],
      bankDetails: map['bankDetails'],
    );
  }

  factory UserPaymentSettings.empty() {
    return UserPaymentSettings(
      phoneNumber: null,
      upiId: null,
      bankDetails: null,
    );
  }

  bool get hasPhoneNumber => phoneNumber != null && phoneNumber!.isNotEmpty;
  bool get hasUpiId => upiId != null && upiId!.isNotEmpty;
  bool get hasBankDetails => bankDetails != null && bankDetails!.isNotEmpty;
  bool get hasAnyPaymentMethod => hasPhoneNumber || hasUpiId || hasBankDetails;
}
