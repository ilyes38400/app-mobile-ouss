import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart';
import 'package:http/http.dart' as http;
import '../extensions/shared_pref.dart';
import '../screens/sign_in_screen.dart';
import '../../extensions/extension_util/int_extensions.dart';
import '../extensions/common.dart';
import '../extensions/constants.dart';
import '../extensions/system_utils.dart';
import '../main.dart';
import '../utils/app_config.dart';
import '../utils/app_constants.dart';

Map<String, String> buildHeaderTokens() {
  Map<String, String> header = {
    HttpHeaders.contentTypeHeader: 'application/json; charset=utf-8',
    HttpHeaders.cacheControlHeader: 'no-cache',
    HttpHeaders.acceptHeader: 'application/json; charset=utf-8',
    'Access-Control-Allow-Headers': '*',
    'Access-Control-Allow-Origin': '*',
  };

  if (userStore.isLoggedIn || getBoolAsync(IS_SOCIAL)) {
    print('Token trouvé: ${userStore.token}'); // Pour vérifier le token
    header.putIfAbsent(HttpHeaders.authorizationHeader, () => 'Bearer ${userStore.token}');
  }
  log(jsonEncode(header));
  return header;
}

Uri buildBaseUrl(String endPoint) {
  Uri url = Uri.parse(endPoint);
  if (!endPoint.startsWith('http')) url = Uri.parse('$mBaseUrl$endPoint');

  log('URL: ${url.toString()}');

  return url;
}

Future<Response> buildHttpResponse(String endPoint, {HttpMethod method = HttpMethod.GET, Map? request}) async {
  if (await isNetworkAvailable()) {
    var headers = buildHeaderTokens();
    Uri url = buildBaseUrl(endPoint);

    Response response;

    if (method == HttpMethod.POST) {
      log('Request: $request');

      if (request != null && request.values.any((v) => v is File)) {
        var multipartReq = http.MultipartRequest('POST', url)
          ..headers.addAll(headers);

        for (var entry in request.entries) {
          if (entry.value is File) {
            multipartReq.files.add(await http.MultipartFile.fromPath(
              entry.key,
              (entry.value as File).path,
            ));
          } else {
            multipartReq.fields[entry.key] = entry.value.toString();
          }
        }

        var streamed = await multipartReq.send();
        response = await http.Response.fromStream(streamed);
      } else {
        response = await http.post(
          url,
          body: jsonEncode(request),
          headers: headers,
        );
      }

    } else if (method == HttpMethod.DELETE) {
      response = await http.delete(url, headers: headers);

    } else if (method == HttpMethod.PUT) {
      response = await http.put(
        url,
        body: jsonEncode(request),
        headers: headers,
      );

    } else {
      response = await http.get(url, headers: headers);
    }

    log('Response ($method): ${response.statusCode} ${response.body}');

    return response;
  } else {
    throw errorInternetNotAvailable;
  }
}

@deprecated
Future<Response> getRequest(String endPoint) async => buildHttpResponse(endPoint);

@deprecated
Future<Response> postRequest(String endPoint, Map request) async => buildHttpResponse(endPoint, request: request, method: HttpMethod.POST);

Future handleResponse(Response response) async {
  if (!await isNetworkAvailable()) {
    throw errorInternetNotAvailable;
  }

  print("🌐 DEBUG handleResponse:");
  print("   - Status Code: ${response.statusCode}");
  print("   - Response Body: ${response.body}");

  if (response.statusCode.isSuccessful()) {
    return jsonDecode(response.body);
  } else {
    var string = await (isJsonValid(response.body));
    print("❌ DEBUG Erreur HTTP:");
    print("   - Status: ${response.statusCode}");
    print("   - Raw Body: ${response.body}");
    print("   - Parsed: $string");

    if (string!.isNotEmpty) {
      if (string.toString().contains("Unauthenticated")) {
        await removeKey(IS_LOGIN);
        await removeKey(USER_ID);
        await removeKey(FIRSTNAME);
        await removeKey(LASTNAME);
        await removeKey(USER_PROFILE_IMG);
        await removeKey(DISPLAY_NAME);
        await removeKey(PHONE_NUMBER);
        await removeKey(GENDER);
        await removeKey(AGE);
        await removeKey(HEIGHT);
        await removeKey(HEIGHT_UNIT);
        await removeKey(IS_OTP);
        await removeKey(IS_SOCIAL);
        await removeKey(WEIGHT);
        await removeKey(WEIGHT_UNIT);
        userStore.clearUserData();
        if (getBoolAsync(IS_SOCIAL) || !getBoolAsync(IS_REMEMBER)) {
          await removeKey(PASSWORD);
          await removeKey(EMAIL);
        }
        userStore.setLogin(false);
        push(SignInScreen(), isNewTask: true);
      } else {
        throw string;
      }
    } else {
      throw 'Please try again later.';
    }
  }
}

//region Common
enum HttpMethod { GET, POST, DELETE, PUT }

class TokenException implements Exception {
  final String message;

  const TokenException([this.message = ""]);

  String toString() => "FormatException: $message";
}
//endregion

Future<String?> isJsonValid(json) async {
  try {
    var f = jsonDecode(json) as Map<String, dynamic>;
    return f['message'];
  } catch (e) {
    log(e.toString());
    return "";
  }
}

Future<MultipartRequest> getMultiPartRequest(String endPoint, {String? baseUrl}) async {
  String url = '${baseUrl ?? buildBaseUrl(endPoint).toString()}';
  log(url);
  return MultipartRequest('POST', Uri.parse(url));
}

Future<void> sendMultiPartRequest(MultipartRequest multiPartRequest, {Function(dynamic)? onSuccess, Function(dynamic)? onError}) async {
  http.Response response = await http.Response.fromStream(await multiPartRequest.send());
  print("Result: ${response.body}");

  if (response.statusCode.isSuccessful()) {
    onSuccess?.call(response.body);
  } else {
    onError?.call(errorSomethingWentWrong);
  }
}
