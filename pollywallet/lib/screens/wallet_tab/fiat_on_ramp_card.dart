import 'package:flutter/material.dart';
import 'package:pollywallet/constants.dart';
import 'package:pollywallet/theme_data.dart';
import 'package:pollywallet/utils/misc/credential_manager.dart';
import 'package:pollywallet/utils/network/network_config.dart';
import 'package:pollywallet/utils/network/network_manager.dart';

class FiatOnRampCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      child: Card(
        shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.all(Radius.circular(AppTheme.cardRadius))),
        borderOnForeground: true,
        elevation: AppTheme.cardElevations,
        color: AppTheme.white,
        child: SizedBox(
          height: 91,
          child: Center(
            child: FlatButton(
              padding: EdgeInsets.all(0),
              onPressed: () async {
                var address = await CredentialManager.getAddress();
                NetworkConfigObject config =
                    await NetworkManager.getNetworkObject();
                String url = config.transakLink + address;
                Navigator.pushNamed(context, transakRoute, arguments: url);
              },
              child: ListTile(
                leading: Image.asset(transakIcon),
                title:
                    Text("Buy Tokens with Bank Cards", style: AppTheme.title),
                subtitle: Text(
                  "Directly buy Crypto tokens with Credit/Debit Card",
                  style: AppTheme.subtitle,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}