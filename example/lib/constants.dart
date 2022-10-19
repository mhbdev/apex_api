import 'package:apex_api/apex_api.dart';
import 'package:example/models.dart';

class Constants {
  static final responseModels = {
    Response: (x) => Response.fromJson(x),
    GetCurrenciesResponse: (x) => GetCurrenciesResponse.fromJson(x),
  };

  static const _webSecretKey = "jOfFOoBIs1/vkJ+EgpFtJfDgjBN9Bd6EmnJNwQX61uU=";
  static const _webPublicKey = """-----BEGIN PUBLIC KEY-----
MIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEAzuPTVf873vAHUSIrQ4x9
2lIN3W3OfmleTBVWPI4dZ+Dda56jEw9ALwDxAdUDIvSssiJ2Axr6LCDaQId3a8Ex
o5zJfuVnCGIvLunquxaI9GFJlUugk22ETClNaXAUPNL0gOGrStf8Wu1wSAEz1N5I
abyaoUEr1a1QVSI6kIqtPIF+urnq9B8d1BpGqx6S4WzsD4/LdOi4eGyCmm+fN91i
W1XUNq19PrzLXT+asyxky9aEPDR+J7s/NP4kKK+v0uT/k3alfPBo3DCzmuGBDX9q
+QTeHoDyg0r6MO+mRQVoMPikK6bnRwT/ffGi6szfBOPyDXJPQ00N6VnI8H5Xbgfh
WcEUXBr483FpP7LTUTrl9DzQig+SkBy2LtdIecBAkjhc5jNMqi2QglmUmeGujv05
8dksPv9GRMOtZjWEB/Zrzi+R/hCUmF9EhV5jn1XMbFlqxBC08eZnuc3+WyQzWxCN
MRo7+lOw+W9b7bS0YGsOVVyt4ThWB+6rP2/h9Q9QepM3CqFIjOJpCAJas8eQpjiX
M5o9tbqtRG+/3p2zwA2ePZWCahM+zsKOV6fOmsRPDYSzPqjIPxMt8OcqRkb0lcmp
4pWuevsRO0Wb8e+4Rcz2rKzPu8w2NHM/MkFDXz2qoxsOXz0KaFtVTA4OhqSns9io
apcIE/EkN6ERn5NeidjF3OUCAwEAAQ==
-----END PUBLIC KEY-----""";

  static const _iOSSecretKey = "wmaS7w7dqxcEOlPt+yzYjtbOD8+elUuYm/5QpsxcF9s=";
  static const _iOSPublicKey = """-----BEGIN PUBLIC KEY-----
MIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEAuo1kUiX/egN/YjErxzyd
TtG3hiabwKN7hQUSAtJ0Jtxxj9dpsVcuDxIEQ5ofZr1NBt3m7hzvO3ReOqinwv2B
TEFyVScsZvXrMQgU613l2rMVFPpOUTo9PXv4N/eSGinpzPX84rSYVO/xZtAOLpeX
01dTYEcSXhYB+mqcv+SHosfdqe5Iu/422d8d4NmJPIOaCzQqm9BuV3/vLAgJf+39
arirQTwXpqrSuF5tDTaSweIevMXYQd+59rSpqN4OtiBOzjuJYPtDKFKS4XGBraQJ
XLmx3BzPyARWvNeYAkeQ4OFD9fKK5x6OXIEAqJrOvE+YL1aQVhYNESP/CcXbAm/q
0QmxbqanK4MNT9vj5K+5LsnUcSnGy0cWZVsulQ5td8A6WyeRaYo/DvcSwfQEcyB/
2nKgVg7SYGrVdtjGAbbYQGbXi+REcX7i9UMTlnGIhFDAsAP8VjLId869orI95QLD
cRiudg5BxyvJQxn/GXZ6a4fNOaBXq7JOu/erE9JoEC0HP1Uw29efi55Z0ELeA5Jt
xU6G2LDsDQz6HqIDZHPQJl9uBYb4ev5pvZdTo6hhUPTirrSNRzFeRDhxOijcCh93
TYTYKPLRAkb+CigP1NtPaUqlOvM/D1Ktp0E1SnlzQnfRr9LdUH12h/ruxsIr/T2p
ug19Gy9r0Z/Cbr21mhnCpJMCAwEAAQ==
-----END PUBLIC KEY-----""";

  static const _androidSecretKey =
      "MeK8X30U96k5+IxV4/JdFWFh2nKUcVCvUsuRpUamJaA=";
  static const _androidPublicKey = """-----BEGIN PUBLIC KEY-----
MIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEAu3zwMwBpHdhYwSEhdpAD
s7no5t4aMYr/7nWvfOm7WN1lyDM//nxlmHVc/9WGIesqBR55k2f3AZgaIQgi2NLW
rpmqiCqB6awA5361XoqVRU9P5JhG1lPDu93hLr7ab7DEvkq3owE4A7blQ/LiZfJa
1hp9733g/UoNmrdhUEj646lyn1D/OZYxg+dr8Xo6cI+W0CjqLH8p7MwMGmsfkC91
LMKXks2ExOK5rpEzpZl3wMcmRiwf3je0LJKJRtOQijNOLsr8GXPb+2qDwatm2fsP
fvt9HpuBy6IhoeEkAMlzimRlz0BT2ZRLQXGJV1dO5wb4258MZ+XpkfcxjRLg1oWv
oJoUG1xCYksx1YjIe/kYMLTASUp3EmqrcuhrLuASLU/mGaxtkeqjiWCr1mHMtrVK
KD0gu1qzpY6P9tk3zK3LCSWbR3scPh6PZbhWc49QHhGLiaQC6XshT1BBsmIBEn+r
8jjMxM7R4m9EnC1FUttTti/ojOAOqx+GB27/D+xoic9UBwt3EHxGTe2NR/uzIcxw
DG/5yg3Bl+pXFDjCbr1Eba4ujTVrto/Yr07Zbyx4xbTJHruTW8NezPXTBL2Ul7Vz
mAJfUZmdCJ37vh0xzzrBJKD45wNVOyJ/vUb8PdYAbK6cJhy/DeWabrDQQI5wF8dr
rq2uWG3PwaQ0Ppi6XlLlkZECAwEAAQ==
-----END PUBLIC KEY-----""";

  static const webKey = KeyPair(_webSecretKey, _webPublicKey);
  static const androidKey = KeyPair(_androidSecretKey, _androidPublicKey);
  static const iOSKey = KeyPair(_iOSSecretKey, _iOSPublicKey);

  static const String serverUrl = 'https://api.apexteam.net';

  // TODO : replace url
  static const String uploadUrl = 'https://api.apexteam.net';

  static const String namespace = 'matinex';

  static const int privateVersion = 2;

  static const int publicVersion = 2;
}
