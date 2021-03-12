import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:pollywallet/constants.dart';
import 'package:pollywallet/models/deposit_models/deposit_model.dart';
import 'package:pollywallet/models/tansaction_data/transaction_data.dart';
import 'package:pollywallet/models/transaction_models/transaction_information.dart';
import 'package:pollywallet/state_manager/covalent_states/covalent_token_list_cubit_ethereum.dart';
import 'package:pollywallet/state_manager/deposit_data_state/deposit_data_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pollywallet/theme_data.dart';
import 'package:pollywallet/utils/fiat_crypto_conversions.dart';
import 'package:pollywallet/utils/network/network_config.dart';
import 'package:pollywallet/utils/network/network_manager.dart';
import 'package:pollywallet/utils/web3_utils/eth_conversions.dart';
import 'package:pollywallet/utils/web3_utils/ethereum_transactions.dart';
import 'package:pollywallet/widgets/colored_tabbar.dart';
import 'package:pollywallet/widgets/loading_indicator.dart';
import 'package:web3dart/web3dart.dart';

class DepositScreen extends StatefulWidget {
  @override
  _DepositScreenState createState() => _DepositScreenState();
}

class _DepositScreenState extends State<DepositScreen>
    with SingleTickerProviderStateMixin {
  TextEditingController _amount = TextEditingController();
  DepositDataCubit data;
  BuildContext context;
  int bridge = 0;
  bool _isInitialized = false;
  double balance;
  int args; // 0 no bridge , 1 = pos , 2 = plasma , 3 both
  int index = 0;
  TabController _controller;
  @override
  initState() {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      final ethCubit = context.read<CovalentTokensListEthCubit>();
      _refreshLoop(ethCubit);
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    this.args = ModalRoute.of(context).settings.arguments;
    _controller = TabController(length: 2, vsync: this);

    if (!_isInitialized) {
      if (args == 1) {
        _controller.animateTo(0);
      }
      if (args == 2) {
        _controller.animateTo(1);
      }
      _controller.addListener(() {
        if (_controller.index == 0) {
          bridge = 1;
          print(bridge);
        } else {
          bridge = 2;
        }
      });
    }
    this.data = context.read<DepositDataCubit>();
    print(args);

    if (args == 3 && bridge == 0) {
      bridge = 1;
    } else if (args != 3) {
      bridge = args;
    }

    return Scaffold(
        appBar: AppBar(
            title: Text("Deposit to Matic"),
            bottom: args == 3
                ? ColoredTabBar(
                    tabBar: TabBar(
                      controller: _controller,
                      labelStyle: AppTheme.tabbarTextStyle,
                      unselectedLabelStyle: AppTheme.tabbarTextStyle,
                      indicatorSize: TabBarIndicatorSize.tab,
                      indicator: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: AppTheme.white),
                      tabs: [
                        Tab(
                          child: Align(
                            child: Text(
                              'POS',
                              style: AppTheme.tabbarTextStyle,
                            ),
                          ),
                        ),
                        Tab(
                          child: Align(
                            child: Text(
                              'Plasma',
                              style: AppTheme.tabbarTextStyle,
                            ),
                          ),
                        ),
                      ],
                    ),
                    borderRadius: AppTheme.cardRadius,
                    color: AppTheme.tabbarBGColor,
                    tabbarMargin: AppTheme.cardRadius,
                    tabbarPadding: AppTheme.paddingHeight / 4,
                  )
                : null),
        body: TabBarView(
          physics: args == 3 ? ScrollPhysics() : NeverScrollableScrollPhysics(),
          controller: _controller,
          children: [
            BlocBuilder<DepositDataCubit, DepositDataState>(
              builder: (BuildContext context, state) {
                return BlocBuilder<CovalentTokensListEthCubit,
                    CovalentTokensListEthState>(builder: (context, tokenState) {
                  if (state is DepositDataFinal &&
                      tokenState is CovalentTokensListEthLoaded) {
                    var balance = EthConversions.weiToEth(
                        BigInt.parse(state.data.token.balance),
                        state.data.token.contractDecimals);
                    this.balance = balance;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "POS bridge",
                          style: AppTheme.title,
                        ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: MediaQuery.of(context).size.width * 0.7,
                              child: TextFormField(
                                controller: _amount,
                                keyboardAppearance: Brightness.dark,
                                textAlign: TextAlign.center,
                                autovalidateMode:
                                    AutovalidateMode.onUserInteraction,
                                validator: (val) => (val == "" ||
                                            val == null) ||
                                        (double.tryParse(val) == null ||
                                            (double.tryParse(val) < 0 ||
                                                double.tryParse(val) > balance))
                                    ? "Invalid Amount"
                                    : null,
                                keyboardType: TextInputType.numberWithOptions(
                                    decimal: true),
                                style: AppTheme.bigLabel,
                                decoration: InputDecoration(
                                  hintText: "Amount",
                                  hintStyle: AppTheme.body1,
                                  focusedBorder: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                ),
                              ),
                            ),
                            Text(
                              "\$" +
                                  FiatCryptoConversions.cryptoToFiat(
                                          double.parse(_amount.text == ""
                                              ? "0"
                                              : _amount.text),
                                          state.data.token.quoteRate)
                                      .toString(),
                              style: AppTheme.bigLabel,
                            )
                          ],
                        ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            SafeArea(
                              child: ListTile(
                                leading: FlatButton(
                                  onPressed: () {
                                    if (index == 0) {
                                      setState(() {
                                        _amount.text = balance.toString();
                                      });
                                    } else {
                                      setState(() {
                                        _amount.text =
                                            FiatCryptoConversions.cryptoToFiat(
                                                    balance,
                                                    state.data.token.quoteRate)
                                                .toString();
                                      });
                                    }
                                  },
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  child: ClipOval(
                                      child: Material(
                                    color: AppTheme.secondaryColor
                                        .withOpacity(0.3),
                                    child: SizedBox(
                                        height: 56,
                                        width: 56,
                                        child: Center(
                                          child: Text(
                                            "Max",
                                            style: AppTheme.title,
                                          ),
                                        )),
                                  )),
                                ),
                                title: Text(
                                  "Balance",
                                  style: AppTheme.subtitle,
                                ),
                                subtitle: Text(
                                  balance.toStringAsFixed(2) +
                                      " " +
                                      state.data.token.contractName,
                                  style: AppTheme.title,
                                ),
                                trailing: FlatButton(
                                  onPressed: () {
                                    _sendDepositTransaction(state, context);
                                  },
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  child: ClipOval(
                                      child: Material(
                                    color: AppTheme.primaryColor,
                                    child: SizedBox(
                                        height: 56,
                                        width: 56,
                                        child: Center(
                                          child: Icon(Icons.check,
                                              color: AppTheme.white),
                                        )),
                                  )),
                                ),
                              ),
                            ),
                          ],
                        )
                      ],
                    );
                  } else {
                    return Center(child: Text("Something went Wrong"));
                  }
                });
              },
            ),
            BlocBuilder<DepositDataCubit, DepositDataState>(
              builder: (BuildContext context, state) {
                return BlocBuilder<CovalentTokensListEthCubit,
                    CovalentTokensListEthState>(builder: (context, tokenState) {
                  if (state is DepositDataFinal &&
                      tokenState is CovalentTokensListEthLoaded) {
                    var balance = EthConversions.weiToEth(
                        BigInt.parse(state.data.token.balance),
                        state.data.token.contractDecimals);
                    this.balance = balance;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Plasma Bridge", style: AppTheme.title),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: MediaQuery.of(context).size.width * 0.7,
                              child: TextFormField(
                                controller: _amount,
                                keyboardAppearance: Brightness.dark,
                                textAlign: TextAlign.center,
                                autovalidateMode:
                                    AutovalidateMode.onUserInteraction,
                                validator: (val) => (val == "" ||
                                            val == null) ||
                                        (double.tryParse(val) == null ||
                                            (double.tryParse(val) < 0 ||
                                                double.tryParse(val) > balance))
                                    ? "Invalid Amount"
                                    : null,
                                keyboardType: TextInputType.numberWithOptions(
                                    decimal: true),
                                style: AppTheme.bigLabel,
                                decoration: InputDecoration(
                                  hintText: "Amount",
                                  hintStyle: AppTheme.body1,
                                  focusedBorder: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                ),
                              ),
                            ),
                            Text(
                              "\$" +
                                  FiatCryptoConversions.cryptoToFiat(
                                          double.parse(_amount.text == ""
                                              ? "0"
                                              : _amount.text),
                                          state.data.token.quoteRate)
                                      .toString(),
                              style: AppTheme.bigLabel,
                            )
                          ],
                        ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            ListTile(
                              leading: ClipOval(
                                clipBehavior: Clip.antiAlias,
                                child: Container(
                                  child: Text("!",
                                      style: TextStyle(
                                          fontSize: 50,
                                          color: AppTheme.black,
                                          fontWeight: FontWeight.bold)),
                                ),
                              ),
                              title: Text("Note"),
                              subtitle: Text(
                                  "Assets deposited from Plasma Bridge takes upto 7 days for withdrawl."),
                              isThreeLine: true,
                            ),
                            SafeArea(
                              child: ListTile(
                                leading: FlatButton(
                                  onPressed: () {
                                    if (index == 0) {
                                      setState(() {
                                        _amount.text = balance.toString();
                                      });
                                    } else {
                                      setState(() {
                                        _amount.text =
                                            FiatCryptoConversions.cryptoToFiat(
                                                    balance,
                                                    state.data.token.quoteRate)
                                                .toString();
                                      });
                                    }
                                  },
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  child: ClipOval(
                                      child: Material(
                                    color: AppTheme.secondaryColor
                                        .withOpacity(0.3),
                                    child: SizedBox(
                                        height: 56,
                                        width: 56,
                                        child: Center(
                                          child: Text(
                                            "Max",
                                            style: AppTheme.title,
                                          ),
                                        )),
                                  )),
                                ),
                                title: Text(
                                  "Balance",
                                  style: AppTheme.subtitle,
                                ),
                                subtitle: Text(
                                  balance.toStringAsFixed(2) +
                                      " " +
                                      state.data.token.contractName,
                                  style: AppTheme.title,
                                ),
                                trailing: FlatButton(
                                  onPressed: () {
                                    _sendDepositTransaction(state, context);
                                  },
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  child: ClipOval(
                                      child: Material(
                                    color: AppTheme.primaryColor,
                                    child: SizedBox(
                                        height: 56,
                                        width: 56,
                                        child: Center(
                                          child: Icon(Icons.check,
                                              color: AppTheme.white),
                                        )),
                                  )),
                                ),
                              ),
                            ),
                          ],
                        )
                      ],
                    );
                  } else {
                    return Center(child: Text("Something went Wrong"));
                  }
                });
              },
            ),
          ],
        ));
  }

  _sendDepositTransaction(DepositDataFinal state, BuildContext context) async {
    if (double.tryParse(_amount.text) == null ||
        double.tryParse(_amount.text) < 0 ||
        double.tryParse(_amount.text) > balance) {
      Fluttertoast.showToast(
          msg: "Invalid amount", toastLength: Toast.LENGTH_LONG);
      return;
    }
    Widget cancelButton = FlatButton(
      child: Text("Cancel"),
      onPressed: () {
        Navigator.pop(context, false);
      },
    );
    Widget continueButton = FlatButton(
      child: Text("Continue"),
      onPressed: () {
        Navigator.pop(context, true);
      },
    );

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: Text("AlertDialog"),
      shape: AppTheme.cardShape,
      content: Text(
          "You haven't given sufficient approval, would you like to approve now?"),
      actions: [
        cancelButton,
        continueButton,
      ],
    );
    GlobalKey<State> _key = new GlobalKey<State>();
    Dialogs.showLoadingDialog(context, _key);
    NetworkConfigObject config = await NetworkManager.getNetworkObject();
    Transaction trx;
    TransactionData transactionData;
    if (state.data.token.contractAddress.toLowerCase() ==
        ethAddress.toLowerCase()) {
      data.setData(DepositModel(
          token: state.data.token, amount: _amount.toString(), isEth: true));
      if (bridge == 1) {
        trx = await EthereumTransactions.depositEthPos(_amount.text);
        transactionData = TransactionData(
            to: config.erc20PredicatePos,
            trx: trx,
            amount: "0",
            type: TransactionType.DEPOSITPOS);
      } else {
        trx = await EthereumTransactions.depositEthPlasma(_amount.text);
        transactionData = TransactionData(
            to: config.depositManager,
            trx: trx,
            amount: "0",
            type: TransactionType.DEPOSITPLASMA);
      }
    }
    //Todo: Deposit Eth
    else {
      Bridge brd;
      if (bridge == 1)
        brd = Bridge.POS;
      else
        brd = Bridge.PLASMA;
      BigInt approval = await EthereumTransactions.bridgeAllowanceERC20(
          state.data.token.contractAddress, brd);
      var wei = EthConversions.ethToWei(_amount.text);
      if (approval < wei) {
        bool appr = await showDialog(
          context: context,
          builder: (BuildContext context) {
            return alert;
          },
        );
        if (appr) {
          if (bridge == 1) {
            trx = await EthereumTransactions.approveErc20(
              state.data.token.contractAddress,
              config.erc20PredicatePos,
            );
          } else {
            trx = await EthereumTransactions.approveErc20(
              state.data.token.contractAddress,
              config.depositManager,
            );
          }
          transactionData = TransactionData(
              to: state.data.token.contractAddress,
              amount: "0",
              trx: trx,
              type: TransactionType.APPROVE);
        } else {
          Navigator.of(context, rootNavigator: true).pop();
          return;
        }
      } else {
        if (bridge == 1) {
          trx = await EthereumTransactions.depositErc20Pos(
              _amount.text, state.data.token.contractAddress);
          transactionData = TransactionData(
              to: config.erc20PredicatePos,
              amount: _amount.text,
              trx: trx,
              type: TransactionType.DEPOSITPOS);
        } else {
          trx = await EthereumTransactions.depositErc20Plasma(
              _amount.text, state.data.token.contractAddress);
          transactionData = TransactionData(
              to: config.depositManager,
              amount: _amount.text,
              trx: trx,
              type: TransactionType.DEPOSITPLASMA);
        }
      }
    }
    Navigator.of(context, rootNavigator: true).pop();

    Navigator.pushNamed(context, ethereumTransactionConfirmRoute,
        arguments: transactionData);
  }

  _refreshLoop(CovalentTokensListEthCubit cubit) {
    new Timer.periodic(Duration(seconds: 30), (Timer t) {
      if (mounted) {
        cubit.refresh();
      }
    });
  }
}
