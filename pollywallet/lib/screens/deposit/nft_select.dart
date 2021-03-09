import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:pollywallet/constants.dart';
import 'package:pollywallet/models/tansaction_data/transaction_data.dart';
import 'package:pollywallet/models/transaction_models/transaction_information.dart';
import 'package:pollywallet/state_manager/covalent_states/covalent_token_list_cubit_ethereum.dart';
import 'package:pollywallet/state_manager/deposit_data_state/deposit_data_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pollywallet/theme_data.dart';
import 'package:pollywallet/utils/network/network_config.dart';
import 'package:pollywallet/utils/network/network_manager.dart';
import 'package:pollywallet/utils/web3_utils/eth_conversions.dart';
import 'package:pollywallet/utils/web3_utils/ethereum_transactions.dart';
import 'package:pollywallet/widgets/colored_tabbar.dart';
import 'package:pollywallet/widgets/loading_indicator.dart';
import 'package:pollywallet/widgets/nft_tile.dart';
import 'package:web3dart/web3dart.dart';

class NftSelectDeposit extends StatefulWidget {
  @override
  _NftSelectDepositState createState() => _NftSelectDepositState();
}

class _NftSelectDepositState extends State<NftSelectDeposit>
    with SingleTickerProviderStateMixin {
  DepositDataCubit data;
  BuildContext context;
  int bridge = 0;
  double balance;
  int tokenCountToSend = 1;
  int selectedIndex = 0;
  int args; // 0 no bridge , 1 = pos , 2 = plasma , 3 both
  int index = 0;
  TabController _controller;
  var ethCubit;
  @override
  initState() {
    Future.delayed(Duration.zero, () {
      _controller = TabController(length: 2, vsync: this);

      _controller.addListener(() {
        if (_controller.index == 0) {
          bridge = 1;
        } else {
          bridge = 2;
        }
      });
    });
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _refreshLoop(ethCubit);
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    ethCubit = context.read<CovalentTokensListEthCubit>();
    this.data = context.read<DepositDataCubit>();
    this.args = ModalRoute.of(context).settings.arguments;
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
        body: BlocBuilder<DepositDataCubit, DepositDataState>(
          builder: (BuildContext context, state) {
            return BlocBuilder<CovalentTokensListEthCubit,
                CovalentTokensListEthState>(builder: (context, tokenstate) {
              print(tokenstate);
              print(state);
              if (state is DepositDataFinal &&
                  tokenstate is CovalentTokensListEthLoaded) {
                var balance = EthConversions.weiToEth(
                    BigInt.parse(state.data.token.balance),
                    state.data.token.contractDecimals);
                this.balance = balance;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    bridge == 1
                        ? Text(
                            "POS bridge",
                            style: AppTheme.title,
                          )
                        : bridge == 2
                            ? Text("Plasma Bridge", style: AppTheme.title)
                            : SizedBox(),
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.6,
                      child: ListView.builder(
                        itemCount: state.data.token.nftData.length,
                        itemBuilder: (context, index) {
                          return FlatButton(
                            onPressed: () {
                              setState(() {
                                selectedIndex = index;
                              });
                            },
                            padding: EdgeInsets.all(0),
                            child: NftDepositTile(
                              data: state.data.token.nftData[index],
                              selected: index == selectedIndex,
                            ),
                          );
                        },
                      ),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        bridge == 2
                            ? ListTile(
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
                              )
                            : Container(),
                        SafeArea(
                          child: ListTile(
                            leading: FlatButton(
                              onPressed: () {
                                if (state.data.token.nftData[index]
                                        .tokenBalance ==
                                    null) {
                                  return;
                                }
                                setState(() {
                                  tokenCountToSend = int.parse(state
                                      .data.token.nftData[index].tokenBalance);
                                });
                              },
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                              child: ClipOval(
                                  child: Material(
                                color: AppTheme.secondaryColor.withOpacity(0.3),
                                child: SizedBox(
                                    height: 56,
                                    width: 56,
                                    child: Center(
                                        child: Text(
                                      state.data.token.contractName
                                          .substring(0, 1)
                                          .toUpperCase(),
                                      style: AppTheme.title,
                                    ))),
                              )),
                            ),
                            contentPadding: EdgeInsets.all(0),
                            title: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  state.data.token.contractName,
                                  style: AppTheme.subtitle,
                                )
                              ],
                            ),
                            trailing: FlatButton(
                              onPressed: () {
                                if (state.data.token.nftData[index]
                                        .tokenBalance ==
                                    null) {
                                  _sendDepositTransactionERC721(state, context);
                                } else {
                                  _sendDepositTransactionERC1155(
                                      state, context);
                                }
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
                print(tokenstate);
                print(state);
                return Center(child: Text("Something went Wrong"));
              }
            });
          },
        ));
  }

  _sendDepositTransactionERC721(
      DepositDataFinal state, BuildContext context) async {
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
    var spender = "";
    var approvalStatus = false;
    if (bridge == 1) {
      approvalStatus = await EthereumTransactions.erc721ApprovalStatusPos(
          state.data.token.contractAddress);
      spender = config.erc721PredicatePos;
    } else {
      approvalStatus = await EthereumTransactions.erc721ApprovalStatusPlasma(
          state.data.token.contractAddress);
      spender = config.depositManager;
    }

    if (!approvalStatus) {
      bool appr = await showDialog(
        context: context,
        builder: (BuildContext context) {
          return alert;
        },
      );
      if (appr) {
        trx = await EthereumTransactions.erc721Approve(
            BigInt.parse(state.data.token.nftData[selectedIndex].tokenId),
            state.data.token.contractAddress,
            spender);
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
        trx = await EthereumTransactions.erc721DepositPos(
            BigInt.parse(state.data.token.nftData[selectedIndex].tokenId),
            state.data.token.contractAddress);

        transactionData = TransactionData(
            to: config.rootChainProxy,
            amount: "0",
            trx: trx,
            type: TransactionType.DEPOSITPOS);
      } else {
        trx = await EthereumTransactions.erc721DepositPlasma(
            BigInt.parse(state.data.token.nftData[selectedIndex].tokenId),
            state.data.token.contractAddress);
        transactionData = TransactionData(
            to: config.depositManager,
            amount: "0",
            trx: trx,
            type: TransactionType.DEPOSITPLASMA);
      }
    }

    Navigator.of(context, rootNavigator: true).pop();

    Navigator.pushNamed(context, ethereumTransactionConfirmRoute,
        arguments: transactionData);
  }

  _sendDepositTransactionERC1155(
      DepositDataFinal state, BuildContext context) async {
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
    var spender = "";
    var approvalStatus = false;
    if (bridge == 1) {
      spender = config.erc721PredicatePos;
      approvalStatus = await EthereumTransactions.erc1155ApprovalStatus(
          state.data.token.contractAddress, spender);
    } else {
      spender = config.depositManager;
      approvalStatus = await EthereumTransactions.erc1155ApprovalStatus(
          state.data.token.contractAddress, spender);
    }

    if (!approvalStatus) {
      bool appr = await showDialog(
        context: context,
        builder: (BuildContext context) {
          return alert;
        },
      );
      if (appr) {
        trx = await EthereumTransactions.erc721Approve(
            BigInt.parse(state.data.token.nftData[selectedIndex].tokenId),
            state.data.token.contractAddress,
            spender);
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
      return;
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
