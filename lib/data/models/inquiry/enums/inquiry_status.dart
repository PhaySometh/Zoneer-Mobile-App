enum InquiryStatus {
  newStatus('new'),
  read('read'),
  replied('replied'),
  closed('closed');

  final String value;

  const InquiryStatus(this.value);

  static InquiryStatus fromValue(String? value) {
    return InquiryStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => InquiryStatus.newStatus,
    );
  }
}
