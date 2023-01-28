import '../../../apex_api.dart';

// Number Page
class DetectUserRequest extends Request {
  final String? countryCode;
  final String username;
  final Json? mockResponse;

  factory DetectUserRequest.phone(String countryCode, String phoneNumber, {Json? mockResponse}) {
    return DetectUserRequest._(countryCode + int.parse(phoneNumber).toString(),
        countryCode: countryCode, mockResponse: mockResponse);
  }

  factory DetectUserRequest.email(String email, {String? countryCode, Json? mockResponse}) {
    return DetectUserRequest._(email, countryCode: countryCode, mockResponse: mockResponse);
  }

  DetectUserRequest._(this.username, {this.countryCode, this.mockResponse})
      : super(1001, isPublic: false);

  @override
  Future<Json> get json async => {
        if (countryCode != null) 'cc': countryCode,
        'identifier': username,
      };

  @override
  Future<Json> get responseMock async =>
      mockResponse ?? {'success': -5, 'message': 'You are registered! Login using password :)'};
}

// Login
class LoginRequest extends Request {
  final String? countryCode;
  final String username;
  final String password;
  final Json? mockResponse;

  factory LoginRequest.phone(String countryCode, String phoneNumber, String password,
      {Json? mockResponse}) {
    return LoginRequest._(countryCode + int.parse(phoneNumber).toString(), password,
        countryCode: countryCode, mockResponse: mockResponse);
  }

  factory LoginRequest.email(String email, String password,
      {String? countryCode, Json? mockResponse}) {
    return LoginRequest._(email, password, countryCode: countryCode, mockResponse: mockResponse);
  }

  LoginRequest._(this.username, this.password, {this.countryCode, this.mockResponse})
      : super(1002, isPublic: false);

  @override
  Future<Json> get json async => {
        if (countryCode != null) 'cc': countryCode,
        'identifier': username,
        'password': password,
      };

  @override
  Future<Json> get responseMock async =>
      mockResponse ??
      {'success': 1, 'token': 'GENERATED_TOKEN_TO_TEST_USING_MOCKS', 'message': 'Welcome <3'};
}

// Register
class VerifyUserRequest extends Request {
  final String? countryCode;
  final String username;
  final String otp;
  final String password;
  final Json? mockResponse;

  factory VerifyUserRequest.phone(
      String countryCode, String phoneNumber, String password, String otp,
      {Json? mockResponse}) {
    return VerifyUserRequest._(
      countryCode + int.parse(phoneNumber).toString(),
      password,
      otp,
      countryCode: countryCode,
      mockResponse: mockResponse,
    );
  }

  factory VerifyUserRequest.email(String email, String password, String otp,
      {String? countryCode, Json? mockResponse}) {
    return VerifyUserRequest._(
      email,
      password,
      otp,
      countryCode: countryCode,
      mockResponse: mockResponse,
    );
  }

  VerifyUserRequest._(this.username, this.password, this.otp, {this.countryCode, this.mockResponse})
      : super(1003, isPublic: false);

  @override
  Future<Json> get json async => {
        if (countryCode != null) 'cc': countryCode,
        'identifier': username,
        'new_password': password,
        'otp': otp,
      };

  @override
  Future<Json> get responseMock async =>
      mockResponse ?? {'success': 1, 'message': 'Successfully registered with new password!'};
}

// Forgot Password
class ForgotPasswordRequest extends Request {
  final String? countryCode;
  final String username;
  final Json? mockResponse;

  factory ForgotPasswordRequest.phone(String countryCode, String phoneNumber,
      {Json? mockResponse}) {
    return ForgotPasswordRequest._(countryCode + int.parse(phoneNumber).toString(),
        countryCode: countryCode, mockResponse: mockResponse);
  }

  factory ForgotPasswordRequest.email(String email, {String? countryCode, Json? mockResponse}) {
    return ForgotPasswordRequest._(email, countryCode: countryCode, mockResponse: mockResponse);
  }

  ForgotPasswordRequest._(this.username, {this.countryCode, this.mockResponse})
      : super(1004, isPublic: false);

  @override
  Future<Json> get json async => {
        if (countryCode != null) 'cc': countryCode,
        'identifier': username,
      };

  @override
  Future<Json> get responseMock async =>
      mockResponse ??
      {'success': -3, 'message': 'Password has been revoked! Login with new password!'};
}
