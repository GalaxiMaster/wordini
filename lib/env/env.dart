import 'package:envied/envied.dart';

part 'env.g.dart';

@Envied(path: '.env')
abstract class Env {
    @EnviedField(varName: 'MERRIAM_WEB_API_KEY', obfuscate: true)
    static final String merriamWebsterApiKey = _Env.merriamWebsterApiKey;
    @EnviedField(varName: 'ENCRYPTION_KEY', obfuscate: true)
    static final String encryptionKey = _Env.encryptionKey;
    @EnviedField(varName: 'serverClientId', obfuscate: true)
    static final String serverClientId = _Env.serverClientId;
    @EnviedField(varName: 'clientIdGcloud', obfuscate: true)
    static final String clientIdGcloud = _Env.clientIdGcloud;
    @EnviedField(varName: 'gptApiWorkerLink', obfuscate: true)
    static final String apiUrl = _Env.apiUrl;

}