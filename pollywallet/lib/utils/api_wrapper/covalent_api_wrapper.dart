import 'dart:convert';

import 'package:pollywallet/api_key.dart';
import 'package:pollywallet/constants.dart';
import 'package:pollywallet/models/covalent_models/covalent_token_list.dart';
import 'package:pollywallet/models/covalent_models/matic_transactions_list.dart';
import 'package:pollywallet/models/covalent_models/token_history.dart';
import 'package:pollywallet/utils/api_wrapper/testnet_token_data.dart';
import 'package:pollywallet/utils/misc/box.dart';
import 'package:http/http.dart' as http;
import 'package:pollywallet/utils/misc/credential_manager.dart';
import 'package:pollywallet/utils/network/network_config.dart';
import 'package:pollywallet/utils/network/network_manager.dart';
import 'package:pollywallet/utils/web3_utils/matic_transactions.dart';

class CovalentApiWrapper {
  static const baseUrl = "https://api.covalenthq.com/v1";
  static Future<CovalentTokenList> tokensMaticList() async {
    int id = await BoxUtils.getNetworkConfig();
    print(id);
    String address = await CredentialManager.getAddress();
    String url;
    CovalentTokenList ctl;
    Future future;
    var data;
    if (id == 0) {
      url = baseUrl +
          "/80001/address/" +
          address +
          "/balances_v2/?nft=true&key=" +
          CovalentKey;
      future = MaticTransactions.balanceOf(maticAddress);
      BigInt native = await future;
      data = Items(
          balance: native.toString(),
          contractAddress: maticAddress,
          contractDecimals: 18,
          contractTickerSymbol: "MATIC",
          contractName: "Matic",
          logoUrl: tokenIconUrl,
          quote: 0,
          quoteRate: 12);
    } else {
      String address = await CredentialManager.getAddress();
      url = baseUrl +
          // "/1/address/" +
          // "0x7092Fdbc448698461A3ae98488C35568f368e0AD" +
          "/137/address/" +
          address +
          "/balances_v2/?nft=true&key=" +
          CovalentKey;
    }
    print(url);
    var resp = await http.get(url);

    var json = jsonDecode(resp.body);
    ctl = CovalentTokenList.fromJson(json);
    if (data != null) ctl.data.items.add(data);
    return ctl;
  }

  static Future<TokenHistory> maticTokenTransfers(
      String contractAddress) async {
    int id = await BoxUtils.getNetworkConfig();
    print(id);
    NetworkConfigObject config = await NetworkManager.getNetworkObject();
    TokenHistory ctl;
    String address = await CredentialManager.getAddress();
    String url = "https://api.covalenthq.com/v1/" +
        config.chainId.toString() +
        "/address/" +
        address +
        "/transfers_v2/?contract-address=" +
        contractAddress +
        "&key=ckey_780ed3c9aba3496e8e9948bada0";
    print(url);
    var resp = await http.get(url);
    var json = jsonDecode(resp.body);
    ctl = TokenHistory.fromJson(json);

    return ctl;
  }

  static Future<CovalentTokenList> tokenEthList() async {
    int id = await BoxUtils.getNetworkConfig();
    print(id);
    CovalentTokenList ctl;
    if (id == 0) {
      ctl = await TestNetTokenData.goerliTokenList();
    } else {
      String address = await CredentialManager.getAddress();
      String url = baseUrl +
          "/1/address/" +
          address +
          "/balances_v2/?key=" +
          CovalentKey;
      var resp = await http.get(url);

      var json = jsonDecode(resp.body);
      ctl = CovalentTokenList.fromJson(json);
    }
    return ctl;
  }

  static Future<MaticTransactionListModel> maticTransactionList() async {
    NetworkConfigObject config = await NetworkManager.getNetworkObject();
    MaticTransactionListModel ctl;

    String address = await CredentialManager.getAddress();
    String url = baseUrl +
        "/" +
        config.chainId.toString() +
        "/address/" +
        address +
        "/transactions_v2/?key=" +
        CovalentKey;
    print(url);
    var resp = await http.get(url);
    var json = jsonDecode(resp.body);
    print(resp.body);
    ctl = MaticTransactionListModel.fromJson(json);

    return ctl;
  }
}
