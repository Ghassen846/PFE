import 'services/api_service.dart';
import 'services/server_config.dart';

void main() {
  final endpoint = 'api/users/register';
  // Use the public test method to access URL building
  final uri = ApiService.testBuildUrl(endpoint);
  print('Base URL: ${ServerConfig.activeServerUrl}');
  print('Endpoint: $endpoint');
  print('Final URL: $uri');
}

// Add this to api_service.dart temporarily
// static Uri testBuildUrl(String endpoint) {
//   return _buildUrl(endpoint);
// }
