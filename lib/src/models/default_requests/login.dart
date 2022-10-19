import '../../../apex_api.dart';

// Number Page
class DetectUserRequest extends Request {
  final String countryCode;
  final String username;
  final Json? mockResponse;

  DetectUserRequest(this.countryCode, this.username, {this.mockResponse})
      : super(1001, isPublic: false);

  @override
  Future<Json> get json async =>
      {'cc': countryCode, 'username': username};

  @override
  Future<Json> get responseMock async => mockResponse ?? {};
}

// Login
class LoginRequest extends Request {
  final String countryCode;
  final String username;
  final String password;
  final Json? mockResponse;

  LoginRequest(this.countryCode, this.username, this.password, {this.mockResponse})
      : super(1002, isPublic: false);

  @override
  Future<Json> get json async =>
      {'cc': countryCode, 'username': username, 'password': password};

  @override
  Future<Json> get responseMock async => mockResponse ?? {};
}

// Register
class VerifyUserRequest extends Request {
  final String countryCode;
  final String username;
  final String otp;
  final String password;
  final Json? mockResponse;

  VerifyUserRequest(this.countryCode, this.username, this.password, this.otp, {this.mockResponse})
      : super(1003, isPublic: false);

  @override
  Future<Json> get json async => {
        'cc': countryCode,
        'username': username,
        'new_password': password,
        'otp': otp
      };

  @override
  Future<Json> get responseMock async => mockResponse ?? {};
}

// Forgot Password
class ForgotPasswordRequest extends Request {
  final String countryCode;
  final String username;
  final Json? mockResponse;

  ForgotPasswordRequest(this.countryCode, this.username, {this.mockResponse})
      : super(1004, isPublic: false);

  @override
  Future<Json> get json async => {
        'cc': countryCode,
        'username': username,
      };

  @override
  Future<Json> get responseMock async => mockResponse ?? {};
}
