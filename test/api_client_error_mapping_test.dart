import 'package:edalab/core/network/api_client.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ApiClient.userFacingError never leaks raw network exceptions', () {
    test('AuthRetriableFetchException maps to the connection message', () {
      final error = Exception(
        'AuthRetriableFetchException: certificate_verify_error: '
        'SSL Certification verification failed',
      );

      final message = ApiClient.userFacingError(error);

      expect(message, ApiClient.connectionErrorMessage);
      expect(message.toLowerCase(), isNot(contains('exception')));
      expect(message.toLowerCase(), isNot(contains('certificate')));
    });

    test('TLS handshake failures map to the connection message', () {
      expect(
        ApiClient.userFacingError(
          Exception('HandshakeException: Connection terminated during handshake'),
        ),
        ApiClient.connectionErrorMessage,
      );
      expect(
        ApiClient.userFacingError(
          Exception('ClientException with SocketException: connection closed'),
        ),
        ApiClient.connectionErrorMessage,
      );
    });

    test('known backend messages still pass through unchanged', () {
      expect(
        ApiClient.userFacingError(Exception('Invalid login credentials')),
        'Invalid login credentials',
      );
    });
  });
}
