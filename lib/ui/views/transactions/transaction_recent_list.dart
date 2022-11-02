/// SPDX-License-Identifier: AGPL-3.0-or-later
import 'package:aewallet/application/recent_transactions.dart';
import 'package:aewallet/application/theme.dart';
import 'package:aewallet/localization.dart';
import 'package:aewallet/model/data/recent_transaction.dart';
import 'package:aewallet/ui/util/styles.dart';
import 'package:aewallet/ui/views/transactions/components/transaction_detail.dart';
// Package imports:
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TxList extends ConsumerWidget {
  const TxList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recentTransactionsAsyncValue = ref.watch(
      RecentTransactionProviders.recentTransactions,
    );
    final recentTransactions = recentTransactionsAsyncValue.valueOrNull;

    final theme = ref.watch(ThemeProviders.selectedTheme);

    return Column(
      children: [
        if (recentTransactionsAsyncValue.isLoading)
          SizedBox(
            height: 78,
            child: Center(
              child: CircularProgressIndicator(
                color: theme.text,
                strokeWidth: 1,
              ),
            ),
          ),
        if (recentTransactions != null)
          recentTransactions.isEmpty
              ? Container(
                  alignment: Alignment.center,
                  color: Colors.transparent,
                  width: MediaQuery.of(context).size.width,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 26),
                    child: Text(
                      AppLocalization.of(context)!
                          .recentTransactionsNoTransactionYet,
                      style: theme.textStyleSize14W600Primary,
                    ),
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: recentTransactions
                      .map(
                        (recentTransaction) => _TxListLine(
                          recentTransaction: recentTransaction,
                        ),
                      )
                      .toList(),
                ),
      ],
    );
  }
}

class _TxListLine extends ConsumerWidget {
  const _TxListLine({
    required this.recentTransaction,
  });

  final RecentTransaction recentTransaction;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Container(
        color: Colors.transparent,
        width: MediaQuery.of(context).size.width,
        child: Padding(
          padding: const EdgeInsets.only(left: 26, right: 26, top: 6),
          child: TransactionDetail(
            transaction: recentTransaction,
          ),
        ),
      );
}
