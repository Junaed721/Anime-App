import 'dart:convert';

import 'package:aespack/aespack.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart';

import '../services/request_service.dart';

class Extractor {
  Future<List<String>> extract(String url) async {
    bool auto;
    List<String> list = [];
    final response = await RequestService.create().requestAnimeCdn(url);

    if (response.body != null) {
      dom.Document document = parse(response.body!);

      var iv = document
          .getElementsByClassName('wrapper')
          .first
          .attributes
          .values
          .first
          .toString()
          .split('container-')[1];

      var secretkey = document
          .getElementsByTagName('body')
          .first
          .attributes
          .values
          .first
          .toString()
          .split('container-')[1];

      var decryptkey = document
          .getElementsByClassName('videocontent')
          .first
          .attributes
          .values
          .first
          .toString()
          .split('videocontent-')[1];

      var scriptData = document
          .getElementsByTagName('script')[2]
          .attributes
          .values
          .last
          .toString();

      var preEncryptAjaxParams =
          await Aespack.decrypt(scriptData, secretkey, iv);
      var pre2EncryptAjaxParams = preEncryptAjaxParams.toString().split('&')[0];
      var encryptAjaxParams =
          preEncryptAjaxParams!.split(pre2EncryptAjaxParams)[1];

      var id = document
          .getElementsByTagName('input')
          .first
          .attributes
          .values
          .last
          .toString();

      var preEncryptedId = await Aespack.encrypt(id, secretkey, iv);

      var encryptedId = preEncryptedId!;

      var prehost = url.split('https://')[1].split('/')[0];
      var host = 'https://$prehost/';

      final prejsonresponse = await RequestService.create().requestAnimeData(
          host, encryptedId.toString(), encryptAjaxParams, id);

      var jsonresponse = prejsonresponse.body.toString();

      var data = jsonDecode(jsonresponse)['data'].toString();

      var decryptedData = await cryptohandler(data, iv, decryptkey, false);

      var preArray = jsonDecode(decryptedData!)['source'].toString();

      String fileURL = preArray.split('file:')[1].split(',')[0];
      list.add(fileURL);

      return list;
    } else {
      print('Error: Response body is null.');
      // Handle the error or return an empty list, depending on your use case.
      return [];
    }
  }

  Future<String?> cryptohandler(
      String string, String iv, String secretkey, bool encrypt) async {
    String? data = '';
    if (encrypt == true) {
      data = await Aespack.encrypt(string, secretkey, iv);
    } else {
      data = await Aespack.decrypt(string, secretkey, iv);
    }
    await Future.delayed(const Duration(seconds: 1));
    return data;
  }
}
