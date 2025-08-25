

class OtpResponse {
  final bool status;
  final String message;
  final String orderNo;

  OtpResponse({
    required this.status,
    required this.message,
    required this.orderNo,
  });

  factory OtpResponse.fromJson(Map<String, dynamic> json) {
    return OtpResponse(
      status: json['status'] ?? false,
      message: json['message'] ?? '',
      orderNo: json['data']?['orderNo'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'message': message,
      'data': {
        'orderNo': orderNo,
      },
    };
  }
}

