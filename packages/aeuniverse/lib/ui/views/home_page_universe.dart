// ignore_for_file: cancel_subscriptions

// Dart imports:
import 'dart:async';

// Flutter imports:
import 'package:aeuniverse/ui/widgets/components/app_text_field.dart';
import 'package:aeuniverse/ui/widgets/components/buttons.dart';
import 'package:aeuniverse/ui/widgets/components/picker_item.dart';
import 'package:aeuniverse/util/service_locator.dart';
import 'package:aewallet/ui/views/accounts/account_list.dart';
import 'package:core/localization.dart';
import 'package:core_ui/ui/util/dimens.dart';
import 'package:flutter/material.dart';

// Package imports:
import 'package:aewallet/ui/menu/menu_widget_wallet.dart';
import 'package:aewallet/ui/menu/settings_drawer_wallet_mobile.dart';
import 'package:aewallet/ui/views/transactions/transaction_recent_list.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:core/bus/account_changed_event.dart';
import 'package:core/bus/disable_lock_timeout_event.dart';
import 'package:core/util/get_it_instance.dart';
import 'package:core/util/haptic_util.dart';
import 'package:core/util/keychain_util.dart';
import 'package:core_ui/ui/util/responsive.dart';
import 'package:core_ui/ui/util/routes.dart';
import 'package:event_taxi/event_taxi.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';

// Project imports:
import 'package:aeuniverse/appstate_container.dart';
import 'package:aeuniverse/model/available_networks.dart';
import 'package:aeuniverse/ui/util/styles.dart';
import 'package:aeuniverse/ui/widgets/balance_infos.dart';
import 'package:aeuniverse/ui/widgets/logo.dart';
import 'package:aeuniverse/util/preferences.dart';

class AppHomePageUniverse extends StatefulWidget {
  const AppHomePageUniverse({super.key});

  @override
  State<AppHomePageUniverse> createState() => _AppHomePageUniverseState();
}

class _AppHomePageUniverseState extends State<AppHomePageUniverse>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Controller for placeholder card animations
  AnimationController? _placeholderCardAnimationController;
  Animation<double>? _opacityAnimation;
  bool? _animationDisposed;

  bool _lockDisabled = false; // whether we should avoid locking the app

  ScrollController? _scrollController;

  AnimationController? animationController;
  ColorTween? colorTween;
  CurvedAnimation? curvedAnimation;

  @override
  void initState() {
    super.initState();

    _registerBus();
    WidgetsBinding.instance.addObserver(this);

    // Setup placeholder animation and start
    _animationDisposed = false;
    _placeholderCardAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _placeholderCardAnimationController!
        .addListener(_animationControllerListener);
    _opacityAnimation = Tween<double>(begin: 1.0, end: 0.4).animate(
      CurvedAnimation(
        parent: _placeholderCardAnimationController!,
        curve: Curves.easeIn,
        reverseCurve: Curves.easeOut,
      ),
    );
    _opacityAnimation!.addStatusListener(_animationStatusListener);
    _placeholderCardAnimationController!.forward();

    _scrollController = ScrollController();
  }

  void _animationStatusListener(AnimationStatus status) {
    switch (status) {
      case AnimationStatus.dismissed:
        _placeholderCardAnimationController!.forward();
        break;
      case AnimationStatus.completed:
        _placeholderCardAnimationController!.reverse();
        break;
      default:
        break;
    }
  }

  void _animationControllerListener() {
    setState(() {});
  }

  void _startAnimation() {
    if (_animationDisposed!) {
      _animationDisposed = false;
      _placeholderCardAnimationController!
          .addListener(_animationControllerListener);
      _opacityAnimation!.addStatusListener(_animationStatusListener);
      _placeholderCardAnimationController!.forward();
    }
  }

  void _disposeAnimation() {
    if (!_animationDisposed!) {
      _animationDisposed = true;
      _opacityAnimation!.removeStatusListener(_animationStatusListener);
      _placeholderCardAnimationController!
          .removeListener(_animationControllerListener);
      _placeholderCardAnimationController!.stop();
    }
  }

  StreamSubscription<DisableLockTimeoutEvent>? _disableLockSub;
  StreamSubscription<AccountChangedEvent>? _switchAccountSub;

  void _registerBus() {
    // Hackish event to block auto-lock functionality
    _disableLockSub = EventTaxiImpl.singleton()
        .registerTo<DisableLockTimeoutEvent>()
        .listen((DisableLockTimeoutEvent event) {
      if (event.disable!) {
        cancelLockEvent();
      }
      _lockDisabled = event.disable!;
    });
    // User changed account
    _switchAccountSub = EventTaxiImpl.singleton()
        .registerTo<AccountChangedEvent>()
        .listen((AccountChangedEvent event) {
      setState(() {
        StateContainer.of(context).recentTransactionsLoading = true;

        _startAnimation();

        StateContainer.of(context).requestUpdate(account: event.account);
        _disposeAnimation();

        StateContainer.of(context).recentTransactionsLoading = false;
      });

      if (event.delayPop) {
        Future<void>.delayed(const Duration(milliseconds: 300), () {
          Navigator.of(context).popUntil(RouteUtils.withNameLike('/home'));
        });
      } else if (!event.noPop) {
        Navigator.of(context).popUntil(RouteUtils.withNameLike('/home'));
      }
    });
  }

  @override
  void dispose() {
    _destroyBus();
    WidgetsBinding.instance.removeObserver(this);
    _placeholderCardAnimationController!.dispose();
    _scrollController!.dispose();
    super.dispose();
  }

  void _destroyBus() {
    if (_disableLockSub != null) {
      _disableLockSub!.cancel();
    }
    if (_switchAccountSub != null) {
      _switchAccountSub!.cancel();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Handle websocket connection when app is in background
    // terminate it to be eco-friendly
    switch (state) {
      case AppLifecycleState.paused:
        setAppLockEvent();
        super.didChangeAppLifecycleState(state);
        break;
      case AppLifecycleState.resumed:
        cancelLockEvent();
        super.didChangeAppLifecycleState(state);
        break;
      default:
        super.didChangeAppLifecycleState(state);
        break;
    }
  }

  // To lock and unlock the app
  StreamSubscription<dynamic>? lockStreamListener;

  Future<void> setAppLockEvent() async {
    final Preferences _preferences = await Preferences.getInstance();
    if ((_preferences.getLock()) && !_lockDisabled) {
      if (lockStreamListener != null) {
        lockStreamListener!.cancel();
      }
      final Future<dynamic> delayed =
          Future<void>.delayed((_preferences.getLockTimeout()).getDuration());
      delayed.then((_) {
        return true;
      });
      lockStreamListener = delayed.asStream().listen((_) {
        Navigator.of(context)
            .pushNamedAndRemoveUntil('/', (Route<dynamic> route) => false);
      });
    }
  }

  Future<void> cancelLockEvent() async {
    if (lockStreamListener != null) {
      lockStreamListener!.cancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Responsive.isDesktop(context) == true
        ? Scaffold(
            extendBodyBehindAppBar: true,
            drawerEdgeDragWidth: 0,
            resizeToAvoidBottomInset: false,
            key: _scaffoldKey,
            backgroundColor: StateContainer.of(context).curTheme.background,
            body: SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              child: Container(
                width: MediaQuery.of(context).size.width,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: <Color>[
                      StateContainer.of(context).curTheme.backgroundMainTop!,
                      StateContainer.of(context).curTheme.backgroundMainBottom!
                    ],
                  ),
                ),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height,
                  child: Stack(
                    children: <Widget>[
                      StateContainer.of(context)
                          .curTheme
                          .getBackgroundScreen(context)!,
                      SizedBox(
                        width: Responsive.drawerWidth(context),
                        child: Padding(
                          padding: const EdgeInsets.only(top: 20.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: <Widget>[
                              getLogo(context),
                              const SizedBox(height: 20),
                              Stack(
                                children: <Widget>[
                                  Container(
                                    width: MediaQuery.of(context).size.width,
                                    height: MediaQuery.of(context).size.height *
                                        0.08,
                                    alignment: Alignment.centerRight,
                                    child: Padding(
                                      padding:
                                          const EdgeInsets.only(right: 10.0),
                                      child: AutoSizeText(
                                        StateContainer.of(context)
                                            .curNetwork
                                            .getNetworkCryptoCurrencyLabel(),
                                        style: AppStyles
                                            .textStyleSize80W700Primary15(
                                                context),
                                      ),
                                    ),
                                  ),
                                  BalanceInfosWidget().buildInfos(context),
                                ],
                              ),
                              BalanceInfosWidget().buildKPI(context),
                              const SizedBox(
                                height: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(
                        height: MediaQuery.of(context).size.height,
                        child: Padding(
                          padding: const EdgeInsets.only(
                            top: 180.0,
                          ),
                          child: MenuWidgetWallet().buildContextMenu(context),
                        ),
                      ),
                      /*SizedBox(
                        width: MediaQuery.of(context).size.width,
                        child: Padding(
                            padding: EdgeInsets.only(
                                top: 200.0,
                                left: Responsive.drawerWidth(context)),
                            child: Column(
                              children: [
                                MenuWidgetWallet().buildMenuTxExplorer(context),
                                const Expanded(child: TxListWidget()),
                              ],
                            )),
                      ),*/
                      InkWell(
                        onTap: () async {
                          await _networkDialog();
                        },
                        child: SizedBox(
                          width: MediaQuery.of(context).size.width,
                          height: 100,
                          child: Padding(
                            padding: EdgeInsets.only(
                                top: 20.0,
                                left: Responsive.drawerWidth(context)),
                            child: Column(
                              children: [
                                SvgPicture.asset(
                                  StateContainer.of(context)
                                          .curTheme
                                          .assetsFolder! +
                                      StateContainer.of(context)
                                          .curTheme
                                          .logoAlone! +
                                      '.svg',
                                  height: 30,
                                ),
                                Text(
                                    StateContainer.of(context)
                                        .curNetwork
                                        .getDisplayName(context),
                                    style: AppStyles.textStyleSize10W100Primary(
                                        context)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: MediaQuery.of(context).size.width,
                        height: 140,
                        child: Padding(
                            padding: EdgeInsets.only(
                                top: 70.0,
                                left: Responsive.drawerWidth(context)),
                            child:
                                MenuWidgetWallet().buildMainMenuIcons(context)),
                      ),
                      SizedBox(
                        width: MediaQuery.of(context).size.width,
                        child: Padding(
                            padding: const EdgeInsets.only(top: 20.0),
                            child: MenuWidgetWallet()
                                .buildSecondMenuIcons(context)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          )
        : Scaffold(
            extendBodyBehindAppBar: true,
            appBar: AppBar(
              title: InkWell(
                onTap: () async {
                  await _networkDialog();
                },
                child: Column(
                  children: [
                    SvgPicture.asset(
                      StateContainer.of(context).curTheme.assetsFolder! +
                          StateContainer.of(context).curTheme.logoAlone! +
                          '.svg',
                      height: 30,
                    ),
                    Text(
                        StateContainer.of(context)
                            .curNetwork
                            .getDisplayName(context),
                        style: AppStyles.textStyleSize10W100Primary(context)),
                  ],
                ),
              ),
              backgroundColor: Colors.transparent,
              elevation: 0.0,
              centerTitle: true,
              iconTheme: IconThemeData(
                  color: StateContainer.of(context).curTheme.text),
            ),
            drawerEdgeDragWidth: 0,
            resizeToAvoidBottomInset: false,
            key: _scaffoldKey,
            backgroundColor: StateContainer.of(context).curTheme.background,
            drawer: SizedBox(
              width: Responsive.drawerWidth(context),
              child: const Drawer(
                // TODO: dependencies issue
                child: SettingsSheetWalletMobile(),
              ),
            ),
            body: SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: <Color>[
                      StateContainer.of(context).curTheme.backgroundMainTop!,
                      StateContainer.of(context).curTheme.backgroundMainBottom!
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Column(
                        children: <Widget>[
                          InkWell(
                            onTap: () async {
                              sl.get<HapticUtil>().feedback(FeedbackType.light);
                              AccountsList(await KeychainUtil()
                                      .getListAccountsFromKeychain(
                                          await StateContainer.of(context)
                                              .getSeed(),
                                          StateContainer.of(context)
                                              .selectedAccount
                                              .name))
                                  .mainBottomSheet(context);
                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                StateContainer.of(context)
                                            .selectedAccount
                                            .name !=
                                        null
                                    ? Align(
                                        alignment: Alignment.center,
                                        child: Container(
                                          height: MediaQuery.of(context)
                                                  .size
                                                  .height *
                                              0.08,
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              Text(
                                                StateContainer.of(context)
                                                    .selectedAccount
                                                    .name!,
                                                style: AppStyles
                                                    .textStyleSize20W700EquinoxPrimary(
                                                        context),
                                              ),
                                            ],
                                          ),
                                        ),
                                      )
                                    : const SizedBox(),
                              ],
                            ),
                          ),
                          StateContainer.of(context).showBalance
                              ? BalanceInfosWidget().getBalance(context)
                              : const SizedBox(),
                          const SizedBox(
                            height: 10,
                          ),
                          StateContainer.of(context).showPriceChart
                              ? Stack(
                                  children: <Widget>[
                                    BalanceInfosWidget().buildInfos(context),
                                  ],
                                )
                              : const SizedBox(),
                        ],
                      ),
                      StateContainer.of(context).showPriceChart
                          ? BalanceInfosWidget().buildKPI(context)
                          : const SizedBox(),
                      Divider(
                        height: 1,
                        color: StateContainer.of(context).curTheme.text30,
                      ),
                      SizedBox(
                        height: MediaQuery.of(context).size.height -
                            kToolbarHeight -
                            kBottomNavigationBarHeight,
                        child: Stack(
                          children: <Widget>[
                            StateContainer.of(context)
                                .curTheme
                                .getBackgroundScreen(context)!,
                            Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: <Widget>[
                                const SizedBox(
                                  height: 7,
                                ),
                                MenuWidgetWallet().buildMainMenuIcons(context),
                                /*Divider(
                                  height: 15,
                                  color: StateContainer.of(context)
                                      .curTheme
                                      .text30,
                                ),
                                MenuWidgetWallet().buildMenuTxExplorer(context),
                                Divider(
                                  height: 15,
                                  color: StateContainer.of(context)
                                      .curTheme
                                      .text30,
                                ),*/
                                const SizedBox(
                                  height: 15,
                                ),
                                const Expanded(
                                  child: TxListWidget(),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
  }

  Future<void> _networkDialog() async {
    FocusNode endpointFocusNode = FocusNode();
    TextEditingController endpointController = TextEditingController();
    String? endpointError;

    final Preferences preferences = await Preferences.getInstance();
    final List<PickerItem> pickerItemsList =
        List<PickerItem>.empty(growable: true);
    for (var value in AvailableNetworks.values) {
      pickerItemsList.add(PickerItem(
          NetworksSetting(value).getDisplayName(context),
          await NetworksSetting(value).getLink(),
         '${StateContainer.of(context).curTheme.assetsFolder!}${StateContainer.of(context).curTheme.logoAlone!}.png',
          null,
          value,
          value == AvailableNetworks.ArchethicMainNet ? false : true));
    }

    final AvailableNetworks? selection = await showDialog<AvailableNetworks>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Padding(
              padding: const EdgeInsets.only(bottom: 10.0),
              child: Text(
                AppLocalization.of(context)!.networksHeader,
                style: AppStyles.textStyleSize24W700EquinoxPrimary(context),
              ),
            ),
            shape: RoundedRectangleBorder(
                borderRadius: const BorderRadius.all(Radius.circular(16.0)),
                side: BorderSide(
                    color: StateContainer.of(context).curTheme.text45!)),
            content: PickerWidget(
              pickerItems: pickerItemsList,
              selectedIndex: StateContainer.of(context).curNetwork.getIndex(),
              onSelected: (value) {
                Navigator.pop(context, value.value);
              },
            ),
          );
        });
    if (selection != null) {
      preferences.setNetwork(NetworksSetting(selection));
      setState(() {
        StateContainer.of(context).curNetwork = NetworksSetting(selection);
      });
      if (selection == AvailableNetworks.ArchethicDevNet) {
        endpointController.text = preferences.getNetworkDevEndpoint();
        final AvailableNetworks? endpoint = await showDialog<AvailableNetworks>(
            context: context,
            builder: (BuildContext context) {
              return StatefulBuilder(
                builder: (context, setState) {
                  return AlertDialog(
                    title: Padding(
                      padding: const EdgeInsets.only(bottom: 10.0),
                      child: Column(children: [
                        SvgPicture.asset(
                          '${StateContainer.of(context).curTheme.assetsFolder!}${StateContainer.of(context).curTheme.logoAlone!}.svg',
                          height: 30,
                        ),
                        Text(
                            StateContainer.of(context)
                                .curNetwork
                                .getDisplayName(context),
                            style:
                                AppStyles.textStyleSize10W100Primary(context)),
                        const SizedBox(
                          height: 20,
                        ),
                        Text(
                          AppLocalization.of(context)!.enterEndpointHeader,
                          style: AppStyles.textStyleSize16W400Primary(context),
                        ),
                      ]),
                    ),
                    shape: RoundedRectangleBorder(
                        borderRadius:
                            const BorderRadius.all(Radius.circular(16.0)),
                        side: BorderSide(
                            color:
                                StateContainer.of(context).curTheme.text45!)),
                    content: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: <Widget>[
                            AppTextField(
                              leftMargin: 0,
                              rightMargin: 0,
                              focusNode: endpointFocusNode,
                              controller: endpointController,
                              labelText:
                                  AppLocalization.of(context)!.enterEndpoint,
                              keyboardType: TextInputType.text,
                              style:
                                  AppStyles.textStyleSize14W600Primary(context),
                              inputFormatters: <TextInputFormatter>[
                                LengthLimitingTextInputFormatter(28),
                              ],
                            ),
                            Text(
                              'http://xxx.xxx.xxx.xxx:xxxx',
                              style:
                                  AppStyles.textStyleSize12W400Primary(context),
                            ),
                            endpointError != null
                                ? Container(
                                    margin: const EdgeInsets.only(
                                        top: 5, bottom: 5),
                                    child: Text(endpointError!,
                                        style: AppStyles
                                            .textStyleSize14W600Primary(
                                                context)),
                                  )
                                : const SizedBox(),
                          ],
                        ),
                        Row(
                          children: [
                            AppButton.buildAppButton(
                              const Key('addEndpoint'),
                              context,
                              AppButtonType.primary,
                              AppLocalization.of(context)!.ok,
                              Dimens.buttonTopDimens,
                              onPressed: () async {
                                endpointError = '';
                                if (endpointController.text.isEmpty) {
                                  setState(() {
                                    endpointError = AppLocalization.of(context)!
                                        .enterEndpointBlank;
                                    FocusScope.of(context)
                                        .requestFocus(endpointFocusNode);
                                  });
                                } else {
                                  if (Uri.parse(endpointController.text)
                                          .isAbsolute ==
                                      false) {
                                    setState(() {
                                      endpointError =
                                          AppLocalization.of(context)!
                                              .enterEndpointNotValid;
                                      FocusScope.of(context)
                                          .requestFocus(endpointFocusNode);
                                    });
                                  } else {
                                    preferences.setNetworkDevEndpoint(
                                        endpointController.text);
                                    Navigator.pop(context);
                                  }
                                }
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              );
            });
      }
      setupServiceLocator();
      await StateContainer.of(context)
          .requestUpdate(account: StateContainer.of(context).selectedAccount);
    }
  }
}
