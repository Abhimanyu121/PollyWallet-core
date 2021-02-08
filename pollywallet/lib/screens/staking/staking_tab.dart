import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:pollywallet/constants.dart';
import 'package:pollywallet/screens/staking/ui_elements/staking_card.dart';
import 'package:pollywallet/screens/staking/ui_elements/warning_card.dart';
import 'package:pollywallet/state_manager/covalent_states/covalent_token_list_cubit_ethereum.dart';
import 'package:pollywallet/state_manager/covalent_states/covalent_token_list_cubit_matic.dart';
import 'package:pollywallet/state_manager/staking_data/delegation_data_state/delegations_data_cubit.dart';
import 'package:pollywallet/state_manager/staking_data/validator_data/validator_data_cubit.dart';
import 'package:pollywallet/theme_data.dart';
import 'package:pollywallet/utils/web3_utils/eth_conversions.dart';

class StakingTab extends StatefulWidget {
  @override
  _StakingTabState createState() => _StakingTabState();
}

class _StakingTabState extends State<StakingTab>
    with AutomaticKeepAliveClientMixin<StakingTab> {
  bool showWarning;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    showWarning = true;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DelegationsDataCubit, DelegationsDataState>(
        builder: (context, delegationState) {
      return BlocBuilder<CovalentTokensListEthCubit,
          CovalentTokensListEthState>(
        builder: (context, ethTokenListState) {
          return BlocBuilder<CovalentTokensListMaticCubit,
                  CovalentTokensListMaticState>(
              builder: (context, maticTokenListState) {
            return BlocBuilder<ValidatorsdataCubit, ValidatorsDataState>(
                builder: (context, validatorsState) {
              if (delegationState is DelegationsDataStateInitial ||
                  delegationState is DelegationsDataStateLoading ||
                  validatorsState is ValidatorsDataStateInitial ||
                  validatorsState is ValidatorsDataStateLoading ||
                  ethTokenListState is CovalentTokensListEthInitial ||
                  ethTokenListState is CovalentTokensListEthLoading ||
                  maticTokenListState is CovalentTokensListMaticInitial ||
                  maticTokenListState is CovalentTokensListMaticLoading) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SpinKitFadingFour(
                        size: 50,
                        color: AppTheme.primaryColor,
                      )
                    ],
                  ),
                );
              } else if (delegationState is DelegationsDataStateFinal &&
                  validatorsState is ValidatorsDataStateFinal &&
                  ethTokenListState is CovalentTokensListEthLoaded &&
                  maticTokenListState is CovalentTokensListMaticLoaded) {
                var eth = EthConversions.weiToEth(
                    BigInt.parse(ethTokenListState.covalentTokenList.data.items
                        .where((element) =>
                            element.contractTickerSymbol.toLowerCase() == "eth")
                        .first
                        .balance),
                    18);
                var matic = EthConversions.weiToEth(
                    BigInt.parse(maticTokenListState
                        .covalentTokenList.data.items
                        .where((element) =>
                            element.contractTickerSymbol.toLowerCase() ==
                            "matic")
                        .first
                        .balance),
                    18);
                double qouteRate = maticTokenListState
                    .covalentTokenList.data.items
                    .where((element) =>
                        element.contractTickerSymbol.toLowerCase() == "matic")
                    .first
                    .quoteRate;

                var stakeQoute = qouteRate *
                    EthConversions.weiToEth(delegationState.stake, 18);
                var rateQoute = qouteRate *
                    EthConversions.weiToEth(delegationState.rewards, 18);

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: RefreshIndicator(
                    onRefresh: _refresh,
                    child: ListView(children: [
                      if (showWarning)
                        WarningCard(
                          onClose: () {
                            setState(() {
                              showWarning = false;
                            });
                          },
                        ),
                      StackingCard(
                          iconURL:
                              'https://cdn.iconscout.com/icon/free/png-256/matic-2709185-2249231.png',
                          maticWalletBalance: matic.toString(),
                          etcWalletBalance: eth.toString(),
                          maticStake:
                              EthConversions.weiToEth(delegationState.stake, 18)
                                  .toString(),
                          stakeUSD: stakeQoute.toStringAsFixed(2),
                          maticRewards: EthConversions.weiToEth(
                                  delegationState.rewards, 18)
                              .toString(),
                          rewardUSD: rateQoute.toStringAsFixed(2)),
                      listTile(
                          title:
                              '${delegationState.data.result.length} Delegation',
                          onTap: () {
                            print('Delegation');
                            Navigator.of(context).pushNamed(delegationRoute);
                          }),
                      listTile(
                          title:
                              '${validatorsState.data.result.length} Validators',
                          onTap: () {
                            print('Validators');
                            Navigator.of(context).pushNamed(allValidatorsRoute);
                          }),
                    ]),
                  ),
                );
              } else {
                print(delegationState.toString());
                print(validatorsState.toString());
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      IconButton(
                          icon: Icon(Icons.refresh),
                          color: AppTheme.grey,
                          onPressed: () {
                            context.read<DelegationsDataCubit>().setData();
                          }),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text("Something Went wrong."),
                      ),
                    ],
                  ),
                );
              }
            });
          });
        },
      );
    });
  }

  Widget listTile(
      {String title,
      String trailingText,
      @required Function onTap,
      bool showTrailingIcon = true}) {
    return Card(
      clipBehavior: Clip.antiAliasWithSaveLayer,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppTheme.cardRadius))),
      color: AppTheme.white,
      elevation: AppTheme.cardElevations,
      child: ListTile(
        tileColor: AppTheme.white,
        onTap: onTap,
        title: Text(
          title,
          style: AppTheme.listTileTitle,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (trailingText != null) Text(trailingText),
            if (showTrailingIcon) Icon(Icons.arrow_forward_ios),
          ],
        ),
      ),
    );
  }

  Future<void> _refresh() async {
    var delegationsCubit = context.read<DelegationsDataCubit>();
    var validatorCubit = context.read<ValidatorsdataCubit>();
    Future delegationsFuture = delegationsCubit.refresh();
    var validatorFutre = validatorCubit.refresh();
    await delegationsFuture;
    await validatorFutre;
  }

  @override
  bool get wantKeepAlive => true;
}
