import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:http/http.dart';
import 'package:pollywallet/constants.dart';
import 'package:pollywallet/models/covalent_models/matic_transactions_list.dart';
import 'package:pollywallet/theme_data.dart';
import 'package:pollywallet/utils/api_wrapper/covalent_api_wrapper.dart';
import 'package:pollywallet/utils/web3_utils/eth_conversions.dart';

class MaticTransactionList extends StatefulWidget {
  @override
  _MaticTransactionListState createState() => _MaticTransactionListState();
}

class _MaticTransactionListState extends State<MaticTransactionList> {
  bool _loading = true;
  bool _error = false;
  MaticTransactionListModel list;
  @override
  void initState() {
    try {
      CovalentApiWrapper.maticTransactionList().then((value) {
        setState(() {
          list = value;
          _loading = false;
        });
      });
    } catch (e) {
      print(e.toString());
      setState(() {
        _error = true;
      });
    }

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
        shape: AppTheme.cardShape,
        elevation: AppTheme.cardElevations,
        color: AppTheme.white,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _loading || _error
                ? Container()
                : Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      "Transaction List",
                      style: AppTheme.subtitle,
                    ),
                  ),
            Expanded(
              child: RefreshIndicator(
                  onRefresh: _refresh,
                  child: _loading
                      ? Center(
                          child: SpinKitFadingFour(
                            size: 50,
                            color: AppTheme.primaryColor,
                          ),
                        )
                      : _error
                          ? Center(
                              child: Text(
                                "Something went wrong..",
                                style: AppTheme.body1,
                              ),
                            )
                          : ListView.builder(
                              itemCount: list.data.items.length,
                              itemBuilder: (context, index) {
                                TransactionItem item = list.data.items[index];
                                return FlatButton(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      ListTile(
                                        isThreeLine: true,
                                        leading: Icon(
                                          Icons.check_circle_outline,
                                          color: Colors.green,
                                          size: 30,
                                        ),
                                        trailing: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                                EthConversions.weiToEth(
                                                        BigInt.parse(
                                                            item.value),
                                                        18)
                                                    .toString(),
                                                style: AppTheme.title),
                                            Text(
                                              item.valueQuote == null
                                                  ? "\$0.0"
                                                  : "\$" +
                                                      item.valueQuote
                                                          .toString(),
                                              style: AppTheme.subtitle,
                                            ),
                                          ],
                                        ),
                                        title: Text(
                                          item.txHash,
                                          style: AppTheme.title,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        subtitle: item.toAddress == null
                                            ? Container()
                                            : Wrap(
                                                alignment: WrapAlignment.start,
                                                children: [
                                                  Icon(Icons.arrow_forward),
                                                  Text(
                                                    item.toAddress,
                                                    style: AppTheme.subtitle,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ],
                                              ),
                                      ),
                                      Divider(
                                        color: AppTheme.grey,
                                      )
                                    ],
                                  ),
                                  onPressed: () {
                                    Navigator.pushNamed(
                                        context, transactionStatusMaticRoute,
                                        arguments: item.txHash);
                                  },
                                );
                              },
                            )),
            ),
          ],
        ));
  }

  Future<void> _refresh() async {
    try {
      list = await CovalentApiWrapper.maticTransactionList();
      setState(() {});
    } catch (e) {
      print(e.toString());
      setState(() {
        _error = true;
      });
    }
  }
}
