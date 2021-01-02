import 'package:hive/hive.dart';
import 'package:polly_wallet/constants.dart';
import 'package:polly_wallet/models/credentials/credentials.dart';
import 'package:polly_wallet/models/credentials/credentialsList.dart';
import 'package:hive_flutter/hive_flutter.dart';

class BoxUtils {
  static Future<void> initializeHive() async {
    await Hive.initFlutter("PollyWalletHive");
    Hive.registerAdapter(CredentialsAdapter());
    Hive.registerAdapter(CredentialsListAdapter());
  }

  static Future<bool> checkLogin() async {
    var box = await Hive.openBox<CredentialsList>(credentialBox);
    int len = box.length;
    if (len == 0)
      return false;
    else
      return true;
  }

  static Future<bool> setFirstAccount(
      String mnemonic, String privateKey, String address, String salt) async {
    var box = await Hive.openBox<CredentialsList>(credentialBox);
    int len = box.length;
    var creds = new Credentials()
      ..address = address
      ..privateKey = privateKey
      ..mnemonic = mnemonic;
    var credsList = new CredentialsList()
      ..active = 0
      ..credentials = [creds]
      ..salt = salt;
    if (len == 1) {
      box.putAt(0, credsList);
    } else {
      box.add(credsList);
    }
    print(box.getAt(0).salt);
    print(box.getAt(0).credentials[0].address);
    return true;
  }
  static Future<String> getAddress () async {
    Box<CredentialsList> box = await Hive.openBox<CredentialsList>(credentialBox);
    int active = box.getAt(0).active;
    return box.getAt(0).credentials[active].address;
  }
}
