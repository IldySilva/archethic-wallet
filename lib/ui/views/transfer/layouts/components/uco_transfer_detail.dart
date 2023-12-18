/// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:aewallet/application/account/providers.dart';
import 'package:aewallet/application/settings/primary_currency.dart';
import 'package:aewallet/model/data/account_balance.dart';
import 'package:aewallet/model/primary_currency.dart';
import 'package:aewallet/ui/themes/styles.dart';
import 'package:aewallet/ui/util/amount_formatters.dart';
import 'package:aewallet/ui/util/transfer_recipient_formatters.dart';
import 'package:aewallet/ui/views/transfer/bloc/provider.dart';
import 'package:aewallet/ui/widgets/components/sheet_detail_card.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class UCOTransferDetail extends ConsumerWidget {
  const UCOTransferDetail({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localizations = AppLocalizations.of(context)!;

    final transfer = ref.watch(TransferFormProvider.transferForm);
    final primaryCurrency =
        ref.watch(PrimaryCurrencyProviders.selectedPrimaryCurrency);
    final accountSelected =
        ref.watch(AccountProviders.selectedAccount).valueOrNull;

    if (accountSelected == null) return const SizedBox();

    var amountInUco = transfer.amount;
    if (primaryCurrency.primaryCurrency == AvailablePrimaryCurrencyEnum.fiat) {
      amountInUco = transfer.amountConverted;
    }
    return Container(
      width: MediaQuery.of(context).size.width,
      padding: const EdgeInsets.only(left: 20, right: 20),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Align(
              child: AutoSizeText(
                AmountFormatters.standard(
                  amountInUco,
                  transfer.symbol(context),
                ),
                style: ArchethicThemeStyles.textStyleSize28W700Primary,
              ),
            ),
          ),
          SheetDetailCard(
            children: [
              Text(
                '${localizations.txListFrom} ${accountSelected.nameDisplayed}',
                style: ArchethicThemeStyles.textStyleSize12W400Primary,
              ),
            ],
          ),
          SheetDetailCard(
            children: [
              Text(
                '${localizations.txListTo} ${transfer.recipient.format(localizations)}',
                style: ArchethicThemeStyles.textStyleSize12W400Primary,
              ),
              Text(
                AmountFormatters.standard(
                  amountInUco,
                  transfer.symbol(context),
                ),
                style: ArchethicThemeStyles.textStyleSize12W400Primary,
              ),
            ],
          ),
          SheetDetailCard(
            children: [
              Text(
                localizations.estimatedFees,
                style: ArchethicThemeStyles.textStyleSize12W400Primary,
              ),
              Text(
                AmountFormatters.standardSmallValue(
                  transfer.feeEstimationOrZero,
                  AccountBalance.cryptoCurrencyLabel,
                ),
                style: ArchethicThemeStyles.textStyleSize12W400Primary,
              ),
            ],
          ),
          SheetDetailCard(
            children: [
              Text(
                localizations.total,
                style: ArchethicThemeStyles.textStyleSize12W400Primary,
              ),
              Text(
                AmountFormatters.standard(
                  transfer.feeEstimationOrZero + amountInUco,
                  AccountBalance.cryptoCurrencyLabel,
                ),
                style: ArchethicThemeStyles.textStyleSize12W400Primary,
              ),
            ],
          ),
          SheetDetailCard(
            children: [
              Text(
                localizations.availableAfterTransfer,
                style: ArchethicThemeStyles.textStyleSize12W400Primary,
              ),
              Text(
                AmountFormatters.standard(
                  accountSelected.balance!.nativeTokenValue -
                      (transfer.feeEstimationOrZero + amountInUco),
                  transfer.symbol(context),
                ),
                style: ArchethicThemeStyles.textStyleSize12W400Primary,
              ),
            ],
          ),
          if (transfer.message.isNotEmpty)
            SheetDetailCard(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        localizations.sendMessageConfirmHeader,
                        style: ArchethicThemeStyles.textStyleSize12W400Primary,
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Text(
                          transfer.message,
                          style:
                              ArchethicThemeStyles.textStyleSize12W400Primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
