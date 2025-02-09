/// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:aewallet/infrastructure/datasources/contacts.hive.dart';
import 'package:aewallet/infrastructure/datasources/tokens_list.hive.dart';
import 'package:aewallet/infrastructure/datasources/wallet_token_dto.hive.dart';
import 'package:aewallet/model/blockchain/keychain_secured_infos.dart';
import 'package:aewallet/model/blockchain/recent_transaction.dart';
import 'package:aewallet/model/blockchain/token_information.dart';
import 'package:aewallet/model/data/account_token.dart';
import 'package:aewallet/model/data/contact.dart';
import 'package:aewallet/model/keychain_service_keypair.dart';
import 'package:aewallet/model/transaction_infos.dart';
import 'package:aewallet/util/get_it_instance.dart';
import 'package:aewallet/util/keychain_util.dart';
import 'package:aewallet/util/number_util.dart';
import 'package:aewallet/util/queue.dart';
import 'package:aewallet/util/task.dart';
import 'package:archethic_lib_dart/archethic_lib_dart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';

class AppService {
  static final _logger = Logger('AppService');

  Future<Map<String, List<Transaction>>> getTransactionChain(
    Map<String, String> addresses,
    String? request,
  ) async {
    final transactionChainMap = await sl.get<ApiService>().getTransactionChain(
          addresses,
          request: request!,
        );
    return transactionChainMap;
  }

  Future<Map<String, Token>> getToken(
    List<String> addresses,
  ) async {
    final tokenMap = <String, Token>{};

    final addressesOutCache = <String>[];
    final tokensListDatasource = await TokensListHiveDatasource.getInstance();

    for (final address in addresses.toSet()) {
      final token = tokensListDatasource.getToken(address);
      if (token != null) {
        tokenMap[address] = token.toModel();
      } else {
        addressesOutCache.add(address);
      }
    }

    final getTokens = await addressesOutCache
        .map(
          (address) => Task(
            name: 'GetToken - address: $address',
            logger: _logger,
            action: () => sl.get<ApiService>().getToken([address]),
          ),
        )
        .autoRetry()
        .batch();

    for (final getToken in getTokens) {
      tokenMap.addAll(getToken);

      getToken.forEach((key, value) async {
        value = value.copyWith(address: key);
        await tokensListDatasource.setToken(value.toHive());
      });
    }

    return tokenMap;
  }

  Future<Map<String, List<TransactionInput>>> getTransactionInputs(
    List<String> addresses,
    String request, {
    int limit = 0,
    int pagingOffset = 0,
  }) async {
    final transactionInputs = <String, List<TransactionInput>>{};

    final getTransactionInputs = await addresses
        .toSet()
        .map(
          (address) => Task(
            name: 'GetTransactionInputs : address: $address',
            logger: _logger,
            action: () => sl.get<ApiService>().getTransactionInputs(
              [address],
              request: request,
              limit: limit,
              pagingOffset: pagingOffset,
            ),
          ),
        )
        .autoRetry()
        .batch();
    for (final getTransactionInput in getTransactionInputs) {
      transactionInputs.addAll(getTransactionInput);
    }

    return transactionInputs;
  }

  List<RecentTransaction> _removeRecentTransactionsDuplicates(
    List<RecentTransaction> recentTransactions,
  ) =>
      recentTransactions.fold<List<RecentTransaction>>(
        [],
        (keptRecentTransactions, element) {
          final matchingIndex = keptRecentTransactions.indexWhere(
            (keptRecentTransaction) =>
                keptRecentTransaction.typeTx == element.typeTx &&
                keptRecentTransaction.from == element.from &&
                keptRecentTransaction.type == element.type &&
                keptRecentTransaction.tokenAddress == element.tokenAddress &&
                keptRecentTransaction.indexInLedger == element.indexInLedger,
          );

          if (matchingIndex == -1) {
            return [
              ...keptRecentTransactions,
              element,
            ];
          }

          final matchingElement = keptRecentTransactions[matchingIndex];
          if (matchingElement.timestamp! > element.timestamp!) {
            return keptRecentTransactions;
          }

          return [
            for (var i = 0; i < keptRecentTransactions.length; i++)
              i == matchingIndex ? element : keptRecentTransactions[i],
          ];
        },
      );

  List<RecentTransaction> _populateRecentTransactionsFromTransactionInputs(
    List<TransactionInput> transactionInputs,
    String notificationRecipientAddress,
    int mostRecentTimestamp,
    int transactionTimestamp,
  ) {
    final recentTransactions = <RecentTransaction>[];
    for (final transactionInput in transactionInputs) {
      if (transactionInput.from!.toUpperCase() !=
              notificationRecipientAddress.toUpperCase() &&
          transactionInput.timestamp! >= mostRecentTimestamp &&
          transactionInput.timestamp! >= transactionTimestamp) {
        final recentTransaction = RecentTransaction()
          ..address = transactionInput.from
          ..amount = fromBigInt(transactionInput.amount).toDouble()
          ..typeTx = RecentTransaction.transferInput
          ..from = transactionInput.from
          ..recipient = notificationRecipientAddress
          ..timestamp = transactionInput.timestamp
          ..fee = 0
          ..tokenAddress = transactionInput.tokenAddress;
        recentTransactions.add(recentTransaction);
      }
    }
    return recentTransactions;
  }

  List<RecentTransaction> _populateRecentTransactionsFromTransactionChain(
    List<Transaction> transactionChain,
  ) {
    final recentTransactions = <RecentTransaction>[];
    for (final transaction in transactionChain) {
      _logger.info('type ${transaction.type!} ${transaction.toJson()}');
      if (transaction.type! == 'token') {
        final recentTransaction = RecentTransaction()
          ..address = transaction.address!.address
          ..timestamp = transaction.validationStamp!.timestamp
          ..typeTx = RecentTransaction.tokenCreation
          ..fee = fromBigInt(transaction.validationStamp!.ledgerOperations!.fee)
              .toDouble()
          ..tokenAddress = transaction.address!.address;
        recentTransactions.add(recentTransaction);
      }

      if (transaction.type! == 'hosting') {
        final recentTransaction = RecentTransaction()
          ..address = transaction.address!.address
          ..timestamp = transaction.validationStamp!.timestamp
          ..typeTx = RecentTransaction.hosting
          ..fee = fromBigInt(transaction.validationStamp!.ledgerOperations!.fee)
              .toDouble()
          ..tokenAddress = transaction.address!.address;
        recentTransactions.add(recentTransaction);
      }

      if (transaction.type! == 'transfer') {
        var nbTrf = 0;
        var indexInLedger = 0;
        for (final transfer in transaction.data!.ledger!.uco!.transfers) {
          final recentTransaction = RecentTransaction()
            ..address = transaction.address!.address
            ..typeTx = RecentTransaction.transferOutput
            ..amount = fromBigInt(
              transfer.amount,
            ).toDouble()
            ..recipient = transfer.to
            ..fee =
                fromBigInt(transaction.validationStamp!.ledgerOperations!.fee)
                    .toDouble()
            ..timestamp = transaction.validationStamp!.timestamp
            ..from = transaction.address!.address
            ..ownerships = transaction.data!.ownerships
            ..indexInLedger = indexInLedger;
          recentTransactions.add(recentTransaction);
          indexInLedger++;
          nbTrf++;
        }
        indexInLedger = 0;
        for (final transfer in transaction.data!.ledger!.token!.transfers) {
          final recentTransaction = RecentTransaction()
            ..address = transaction.address!.address
            ..typeTx = RecentTransaction.transferOutput
            ..amount = fromBigInt(
              transfer.amount,
            ).toDouble()
            ..recipient = transfer.to
            ..fee =
                fromBigInt(transaction.validationStamp!.ledgerOperations!.fee)
                    .toDouble()
            ..timestamp = transaction.validationStamp!.timestamp
            ..from = transaction.address!.address
            ..ownerships = transaction.data!.ownerships
            ..tokenAddress = transfer.tokenAddress
            ..indexInLedger = indexInLedger;
          recentTransactions.add(recentTransaction);
          indexInLedger++;
          nbTrf++;
        }
        if (nbTrf == 0) {
          for (final contractRecipient in transaction.data!.actionRecipients) {
            final recentTransaction = RecentTransaction()
              ..address = transaction.address!.address
              ..typeTx = RecentTransaction.transferOutput
              ..fee =
                  fromBigInt(transaction.validationStamp!.ledgerOperations!.fee)
                      .toDouble()
              ..timestamp = transaction.validationStamp!.timestamp
              ..from = contractRecipient.address
              ..ownerships = transaction.data!.ownerships
              ..indexInLedger = 0;
            recentTransactions.add(recentTransaction);
          }
        }
      }
    }
    return recentTransactions;
  }

  Future<List<RecentTransaction>> _buildRecentTransactionFromTransaction(
    List<RecentTransaction> recentTransactionList,
    String address,
    int mostRecentTimestamp,
  ) async {
    final _logger = Logger('AppService - recentTx');

    var newRecentTransactionList = recentTransactionList;
    _logger.info('>> START getTransaction : ${DateTime.now()}');
    final transaction = await sl.get<ApiService>().getTransaction(
      [address],
      request:
          'address, type, chainLength, validationStamp { timestamp, ledgerOperations { fee } }, data { actionRecipients { action, address, args } ledger { uco { transfers { amount, to } } token {transfers {amount, to, tokenAddress, tokenId } } } }',
    );
    _logger
      ..info('$transaction')
      ..info('>> END getTransaction : ${DateTime.now()}')
      ..info('>> START getTransactionInputs : ${DateTime.now()}');
    final transactionInputs = await sl.get<ApiService>().getTransactionInputs(
      [address],
      request: 'from, spent, tokenAddress, tokenId, amount, timestamp',
      limit: 10,
    );
    _logger.info('>> END getTransactionInputs : ${DateTime.now()}');
    if (transaction[address] != null) {
      final transactionTimeStamp =
          transaction[address]!.validationStamp!.timestamp!;

      if (transactionInputs[address] != null) {
        newRecentTransactionList
          ..addAll(
            _populateRecentTransactionsFromTransactionInputs(
              transactionInputs[address]!,
              address,
              mostRecentTimestamp,
              transaction[address]!.validationStamp!.timestamp!,
            ),
          )
          ..sort((tx1, tx2) => tx1.timestamp!.compareTo(tx2.timestamp!));
      }

      _logger
        ..info('1) $transactionInputs')
        ..info(
          'transactionTimeStamp $transactionTimeStamp > mostRecentTimestamp $mostRecentTimestamp)',
        );
      if (transactionTimeStamp > mostRecentTimestamp) {
        newRecentTransactionList
          ..addAll(
            _populateRecentTransactionsFromTransactionChain(
              [transaction[address]!],
            ),
          )
          ..sort((tx1, tx2) => tx1.timestamp!.compareTo(tx2.timestamp!));
      }

      // Remove doublons (on type / token address / from / timestamp)
      if (newRecentTransactionList.isNotEmpty) {
        newRecentTransactionList =
            _removeRecentTransactionsDuplicates(newRecentTransactionList);
      }
    }

    return newRecentTransactionList;
  }

  Future<List<RecentTransaction>> getAccountRecentTransactions(
    String genesisAddress,
    String lastAddress,
    String name,
    KeychainSecuredInfos keychainSecuredInfos,
    List<RecentTransaction> localRecentTransactionList,
  ) async {
    _logger.info(
      '>> START getRecentTransactions : ${DateTime.now()}',
    );

    // get the most recent movement in cache
    var mostRecentTimestamp = 0;
    if (localRecentTransactionList.isNotEmpty) {
      localRecentTransactionList.sort(
        (a, b) => b.timestamp!.compareTo(a.timestamp!),
      );
      mostRecentTimestamp = localRecentTransactionList.first.timestamp ?? 0;
    }
    var recentTransactions = <RecentTransaction>[];

    final keychain = keychainSecuredInfos.toKeychain();

    final lastIndex = await sl.get<ApiService>().getTransactionIndex(
      [lastAddress],
    );
    _logger.info('lastAddress : $lastAddress -> lastIndex: $lastIndex');
    var index = lastIndex[lastAddress] ?? 0;
    String addressToSearch;
    var iterMax = 10;
    recentTransactions.addAll(localRecentTransactionList);

    while (index > 0 && iterMax > 0) {
      addressToSearch = uint8ListToHex(
        keychain.deriveAddress(
          name,
          index: index,
        ),
      );
      _logger.info('addressToSearch : $addressToSearch');
      if (localRecentTransactionList.any(
        (element) =>
            element.address!.toUpperCase() == addressToSearch.toUpperCase(),
      )) {
        _logger.info('addressToSearch exists in local -> break');
        if (addressToSearch.toUpperCase() == lastAddress.toUpperCase()) {
          recentTransactions = await _buildRecentTransactionFromTransaction(
            recentTransactions,
            addressToSearch,
            mostRecentTimestamp,
          );
        }
        break;
      }

      recentTransactions = await _buildRecentTransactionFromTransaction(
        recentTransactions,
        addressToSearch,
        mostRecentTimestamp,
      );
      index--;
      iterMax--;
    }

    if (recentTransactions.length < 10) {
      // Get transaction inputs from genesis address if filtered list is < 10
      final genesisTransactionInputsMap = await getTransactionInputs(
        [genesisAddress],
        'from, type, spent, tokenAddress, amount, timestamp',
        limit: 10 - recentTransactions.length,
      );

      if (genesisTransactionInputsMap[genesisAddress] != null) {
        recentTransactions.addAll(
          _populateRecentTransactionsFromTransactionInputs(
            genesisTransactionInputsMap[genesisAddress]!,
            genesisAddress,
            mostRecentTimestamp,
            0,
          ),
        );
      }
    }

    // Remove doublons (on type / token address / from / timestamp)
    if (recentTransactions.isNotEmpty) {
      recentTransactions =
          _removeRecentTransactionsDuplicates(recentTransactions);
    }

    // Sort by timestamp desc and index ledger desc
    recentTransactions.sort((a, b) {
      final compareTimestamp = b.timestamp!.compareTo(a.timestamp!);
      if (compareTimestamp != 0) {
        return compareTimestamp;
      } else {
        return b.indexInLedger.compareTo(a.indexInLedger);
      }
    });

    // Get 10 first transactions
    recentTransactions = recentTransactions.sublist(
      0,
      recentTransactions.length > 10 ? 10 : recentTransactions.length,
    );

    // Get token id
    final tokensAddresses = <String>[];
    for (final recentTransaction in recentTransactions) {
      if (recentTransaction.tokenAddress != null &&
          recentTransaction.tokenAddress!.isNotEmpty &&
          recentTransaction.timestamp! >= mostRecentTimestamp) {
        tokensAddresses.add(recentTransaction.tokenAddress!);
      }
    }

    final recentTransactionLastAddresses = <String>[];
    final ownershipsAddresses = <String>[];

    // Search token Information
    final tokensAddressMap = await sl.get<AppService>().getToken(
          tokensAddresses.toSet().toList(),
        );

    for (final recentTransaction in recentTransactions) {
      // Get token Information
      if (recentTransaction.tokenAddress != null &&
          recentTransaction.tokenAddress!.isNotEmpty &&
          recentTransaction.timestamp! >= mostRecentTimestamp) {
        final token = tokensAddressMap[recentTransaction.tokenAddress];
        if (token != null) {
          recentTransaction.tokenInformation = TokenInformation(
            // TODO(reddwarf03): Use Genesis instead of address ?
            address: token.address,
            name: token.name,
            supply: fromBigInt(token.supply).toDouble(),
            symbol: token.symbol,
            type: token.type,
          );
        }
      }

      // Decrypt secrets
      switch (recentTransaction.typeTx) {
        case RecentTransaction.transferInput:
          if (recentTransaction.from != null) {
            if (recentTransaction.timestamp! >= mostRecentTimestamp) {
              ownershipsAddresses.add(recentTransaction.from!);
            }
            recentTransactionLastAddresses.add(recentTransaction.from!);
          }
          break;
        case RecentTransaction.transferOutput:
          if (recentTransaction.from != null) {
            if (recentTransaction.timestamp! >= mostRecentTimestamp) {
              ownershipsAddresses.add(recentTransaction.from!);
            }
            recentTransactionLastAddresses.add(recentTransaction.from!);
          }
          break;
      }
    }

    // Get List of ownerships
    final ownershipsMap = <String, List<Ownership>>{};

    final getTransactionOwnerships = await ownershipsAddresses
        .toSet()
        .map(
          (ownershipsAddress) => Task(
            name:
                'GetAccountRecentTransactions - ownershipsAddress: $ownershipsAddress',
            logger: _logger,
            action: () => sl.get<ApiService>().getTransactionOwnerships(
              [ownershipsAddress],
            ),
          ),
        )
        .autoRetry()
        .batch();

    for (final getTransactionOwnership in getTransactionOwnerships) {
      ownershipsMap.addAll(getTransactionOwnership);
    }

    final keychainServiceKeyPair = keychainSecuredInfos.services[name]!.keyPair;
    for (var recentTransaction in recentTransactions) {
      switch (recentTransaction.typeTx) {
        case RecentTransaction.transferInput:
          if (recentTransaction.from != null &&
              recentTransaction.timestamp! >= mostRecentTimestamp) {
            recentTransaction = _decryptedSecret(
              keypair: keychainServiceKeyPair!,
              ownerships: ownershipsMap[recentTransaction.from!] ?? [],
              recentTransaction: recentTransaction,
            );
          }
          break;
        case RecentTransaction.transferOutput:
          if (recentTransaction.address != null &&
              recentTransaction.timestamp! >= mostRecentTimestamp) {
            recentTransaction = _decryptedSecret(
              keypair: keychainServiceKeyPair!,
              ownerships: ownershipsMap[recentTransaction.address!] ?? [],
              recentTransaction: recentTransaction,
            );
          }
          break;
      }
    }

    // Check if the recent transactions are with contacts
    final contactsList = await ContactsHiveDatasource.instance().getContacts();
    final contactsListUpdated = <Contact>[];
    final contactsAddresses = <String>[];
    for (final contact in contactsList) {
      contactsAddresses.add(contact.address);
    }

    // Get last transactions for all tx and contacts
    final lastTransactionAddressesToSearch = [
      ...recentTransactionLastAddresses,
      ...contactsAddresses,
    ];

    final lastAddressesMap = <String, Transaction>{};

    final getLastTransactions = await lastTransactionAddressesToSearch
        .toSet()
        .map(
          (lastTransactionAddressToSearch) => Task(
            name:
                'GetAccountRecentTransactions - lastTransactionAddressToSearch: $lastTransactionAddressToSearch',
            logger: _logger,
            action: () => sl.get<ApiService>().getLastTransaction(
              [lastTransactionAddressToSearch],
              request: 'address',
            ),
          ),
        )
        .autoRetry()
        .batch();
    for (final getLastTransaction in getLastTransactions) {
      lastAddressesMap.addAll(getLastTransaction);
    }

    // We complete map with last address not found because no tx in the chain
    for (final lastTransactionAddressToSearch
        in lastTransactionAddressesToSearch) {
      if (lastAddressesMap[lastTransactionAddressToSearch] == null) {
        lastAddressesMap[lastTransactionAddressToSearch] = Transaction(
          type: '',
          data: Transaction.initData(),
          address:
              Address(address: lastTransactionAddressToSearch.toUpperCase()),
        );
      }
    }

    // Update contacts' last address
    for (final contact in contactsList) {
      if (lastAddressesMap[contact.address] != null &&
          lastAddressesMap[contact.address]!.address!.address!.toUpperCase() !=
              contact.address.toUpperCase()) {
        contact.address = lastAddressesMap[contact.address]!.address!.address ??
            contact.address;
        await ContactsHiveDatasource.instance().saveContact(contact);
      }
      contactsListUpdated.add(contact);
    }

    recentTransactions = _updateContactInTx(
      contactsList: contactsListUpdated,
      lastAddressesMap: lastAddressesMap,
      recentTransactions: recentTransactions,
    );

    _logger.info(
      '>> END getRecentTransactions : ${DateTime.now()}',
    );

    return recentTransactions;
  }

  List<RecentTransaction> _updateContactInTx({
    required List<RecentTransaction> recentTransactions,
    required Map<String, Transaction> lastAddressesMap,
    required List<Contact> contactsList,
  }) {
    lastAddressesMap = lastAddressesMap.map((key, value) {
      return MapEntry(key.toUpperCase(), value);
    });

    for (final recentTransaction in recentTransactions) {
      switch (recentTransaction.typeTx) {
        case RecentTransaction.transferInput:
          if (recentTransaction.from != null) {
            if (lastAddressesMap[recentTransaction.from!.toUpperCase()] !=
                    null &&
                lastAddressesMap[recentTransaction.from!.toUpperCase()]!
                        .address !=
                    null) {
              try {
                recentTransaction.contactInformation = contactsList
                    .where(
                      (contact) =>
                          lastAddressesMap[
                                  recentTransaction.from!.toUpperCase()]!
                              .address!
                              .address!
                              .toUpperCase() ==
                          contact.address.toUpperCase(),
                    )
                    .first;
              } catch (e) {
                recentTransaction.contactInformation = null;
              }
            } else {
              recentTransaction.contactInformation = null;
            }
          }
          break;
        case RecentTransaction.transferOutput:
          if (recentTransaction.recipient != null) {
            if (lastAddressesMap[recentTransaction.recipient!.toUpperCase()] !=
                    null &&
                lastAddressesMap[recentTransaction.recipient!.toUpperCase()]!
                        .address !=
                    null) {
              try {
                recentTransaction.contactInformation = contactsList
                    .where(
                      (contact) =>
                          lastAddressesMap[
                                  recentTransaction.recipient!.toUpperCase()]!
                              .address!
                              .address!
                              .toUpperCase() ==
                          contact.address.toUpperCase(),
                    )
                    .first;
              } catch (e) {
                recentTransaction.contactInformation = null;
              }
            } else {
              recentTransaction.contactInformation = null;
            }
          }
          break;
      }
    }
    return recentTransactions;
  }

  RecentTransaction _decryptedSecret({
    required KeychainServiceKeyPair keypair,
    required List<Ownership> ownerships,
    required RecentTransaction recentTransaction,
  }) {
    recentTransaction.decryptedSecret = List<String>.empty(growable: true);
    if (ownerships.isEmpty) {
      return recentTransaction;
    }
    for (final ownership in ownerships) {
      final authorizedPublicKey = ownership.authorizedPublicKeys.firstWhere(
        (AuthorizedKey authKey) =>
            authKey.publicKey!.toUpperCase() ==
            uint8ListToHex(Uint8List.fromList(keypair.publicKey)).toUpperCase(),
        orElse: AuthorizedKey.new,
      );
      if (authorizedPublicKey.encryptedSecretKey != null) {
        final aesKey = ecDecrypt(
          authorizedPublicKey.encryptedSecretKey,
          Uint8List.fromList(keypair.privateKey),
        );
        final decryptedSecret = aesDecrypt(ownership.secret, aesKey);
        recentTransaction.decryptedSecret!.add(utf8.decode(decryptedSecret));
      }
    }
    return recentTransaction;
  }

  Future<List<AccountToken>> getFungiblesTokensList(String address) async {
    _logger.info(
      '>> START getFungiblesTokensList : ${DateTime.now()}',
    );

    final balanceMap = await sl.get<ApiService>().fetchBalance([address]);
    final balance = balanceMap[address];
    final fungiblesTokensList = List<AccountToken>.empty(growable: true);

    final tokenAddressList = <String>[];
    if (balance == null) {
      return [];
    }

    for (final tokenBalance in balance.token) {
      if (tokenBalance.address != null) {
        tokenAddressList.add(tokenBalance.address!);
      }
    }

    // Search token Information
    final tokenMap = await sl.get<AppService>().getToken(
          tokenAddressList.toSet().toList(),
        );

    for (final tokenBalance in balance.token) {
      final token = tokenMap[tokenBalance.address];
      if (token != null && token.type == 'fungible') {
        var pairSymbolToken = '';
        final tokenSymbolSearch = <String>[];
        if (token.properties.isNotEmpty &&
            token.properties['token1_address'] != null &&
            token.properties['token2_address'] != null) {
          if (token.properties['token1_address'] != 'UCO') {
            tokenSymbolSearch.add(token.properties['token1_address']);
          }
          if (token.properties['token2_address'] != 'UCO') {
            tokenSymbolSearch.add(token.properties['token2_address']);
          }
          final tokensSymbolMap = await sl.get<AppService>().getToken(
                tokenSymbolSearch,
              );
          final pairSymbolToken1 = token.properties['token1_address'] != 'UCO'
              ? tokensSymbolMap[token.properties['token1_address']] != null
                  ? tokensSymbolMap[token.properties['token1_address']]!.symbol!
                  : ''
              : 'UCO';
          final pairSymbolToken2 = token.properties['token2_address'] != 'UCO'
              ? tokensSymbolMap[token.properties['token2_address']] != null
                  ? tokensSymbolMap[token.properties['token2_address']]!.symbol!
                  : ''
              : 'UCO';
          pairSymbolToken = '$pairSymbolToken1/$pairSymbolToken2';
        }

        final tokenInformation = TokenInformation(
          address: tokenBalance.address,
          aeip: token.aeip,
          name: token.name,
          id: token.id,
          type: token.type,
          supply: fromBigInt(token.supply).toDouble(),
          isLPToken: pairSymbolToken.isNotEmpty,
          symbol: pairSymbolToken.isNotEmpty ? pairSymbolToken : token.symbol,
          tokenProperties: token.properties,
        );
        final accountFungibleToken = AccountToken(
          tokenInformation: tokenInformation,
          amount: fromBigInt(tokenBalance.amount).toDouble(),
        );
        fungiblesTokensList.add(accountFungibleToken);
      }
    }
    fungiblesTokensList.sort(
      (a, b) => a.tokenInformation!.name!.compareTo(b.tokenInformation!.name!),
    );

    _logger.info(
      '>> END getFungiblesTokensList : ${DateTime.now()}',
    );

    return fungiblesTokensList;
  }

  Future<Map<String, Balance>> getBalanceGetResponse(
    List<String> addresses,
  ) async {
    final tasks = addresses.toSet().map(
          (address) => () => sl.get<ApiService>().fetchBalance(
                [address],
              ),
        );

    // Search token Information
    final balanceMap = await OperationQueue.run<Balance>(tasks);

    final balancesToReturn = <String, Balance>{};
    for (final address in addresses) {
      var balance = balanceMap[address] ??
          Balance(token: List<TokenBalance>.empty(growable: true));
      final balanceTokenList = List<TokenBalance>.empty(growable: true);

      for (var i = 0; i < balance.token.length; i++) {
        var balanceToken = const TokenBalance();
        balanceToken = balance.token[i];
        balanceTokenList.add(balanceToken);
      }
      balance = balance.copyWith(token: balanceTokenList);

      balancesToReturn[address] = balance;
    }
    return balancesToReturn;
  }

  Future<Map<String, Transaction>> getTransaction(
    List<String> addresses, {
    String request = Transaction.kTransactionQueryAllFields,
  }) async {
    final transactionMap = await sl.get<ApiService>().getTransaction(
          addresses.toSet().toList(),
          request: request,
        );
    return transactionMap;
  }

  Future<List<TransactionInfos>> getTransactionAllInfos(
    String address,
    DateFormat dateFormat,
    String cryptoCurrency,
    BuildContext context,
    KeychainServiceKeyPair keychainServiceKeyPair,
  ) async {
    final transactionsInfos = List<TransactionInfos>.empty(growable: true);

    final transactionMap = await sl.get<ApiService>().getTransaction(
      [address],
      request:
          ' address, data { content,  ownerships {  authorizedPublicKeys { encryptedSecretKey, publicKey } secret } ledger { uco { transfers { amount, to } }, token { transfers { amount, to, tokenAddress, tokenId } } } recipients }, type ',
    );
    final transaction = transactionMap[address];
    if (transaction == null) {
      return [];
    }
    if (transaction.address != null) {
      transactionsInfos.add(
        TransactionInfos(
          domain: '',
          titleInfo: 'Address',
          valueInfo: transaction.address!.address!,
        ),
      );
    }
    if (transaction.type != null) {
      transactionsInfos.add(
        TransactionInfos(
          domain: '',
          titleInfo: 'Type',
          valueInfo: transaction.type!,
        ),
      );
    }
    if (transaction.data != null) {
      transactionsInfos
          .add(TransactionInfos(domain: 'Data', titleInfo: '', valueInfo: ''));

      if (transaction.data!.content != null) {
        transactionsInfos.add(
          TransactionInfos(
            domain: 'Data',
            titleInfo: 'Content',
            valueInfo:
                transaction.type == 'token' || transaction.type == 'hosting'
                    ? 'See explorer...'
                    : transaction.data!.content == ''
                        ? 'N/A'
                        : transaction.data!.content!,
          ),
        );
      }

      if (transaction.data!.code != null) {
        transactionsInfos.add(
          TransactionInfos(
            domain: 'Data',
            titleInfo: 'Code',
            valueInfo: transaction.data!.code!,
          ),
        );
      }
      if (transaction.data!.ownerships.isNotEmpty) {
        for (final ownership in transaction.data!.ownerships) {
          final authorizedPublicKey = ownership.authorizedPublicKeys.firstWhere(
            (AuthorizedKey authKey) =>
                authKey.publicKey!.toUpperCase() ==
                uint8ListToHex(
                  Uint8List.fromList(keychainServiceKeyPair.publicKey),
                ).toUpperCase(),
            orElse: AuthorizedKey.new,
          );
          if (authorizedPublicKey.encryptedSecretKey != null) {
            final aesKey = ecDecrypt(
              authorizedPublicKey.encryptedSecretKey,
              Uint8List.fromList(keychainServiceKeyPair.privateKey),
            );
            final decryptedSecret = aesDecrypt(ownership.secret, aesKey);
            transactionsInfos.add(
              TransactionInfos(
                domain: 'Data',
                titleInfo: 'Secret',
                valueInfo: utf8.decode(decryptedSecret),
              ),
            );
          }
        }
      }
      if (transaction.data!.ledger != null &&
          transaction.data!.ledger!.uco != null &&
          transaction.data!.ledger!.uco!.transfers.isNotEmpty) {
        transactionsInfos.add(
          TransactionInfos(
            domain: 'UCOLedger',
            titleInfo: '',
            valueInfo: '',
          ),
        );
        for (var i = 0;
            i < transaction.data!.ledger!.uco!.transfers.length;
            i++) {
          if (transaction.data!.ledger!.uco!.transfers[i].to != null) {
            transactionsInfos.add(
              TransactionInfos(
                domain: 'UCOLedger',
                titleInfo: 'To',
                valueInfo: transaction.data!.ledger!.uco!.transfers[i].to!,
              ),
            );
          }
          if (transaction.data!.ledger!.uco!.transfers[i].amount != null) {
            transactionsInfos.add(
              TransactionInfos(
                domain: 'UCOLedger',
                titleInfo: 'Amount',
                valueInfo:
                    '${NumberUtil.formatThousands(fromBigInt(transaction.data!.ledger!.uco!.transfers[i].amount))} $cryptoCurrency',
              ),
            );
          }
        }
      }
      if (transaction.data!.ledger != null &&
          transaction.data!.ledger!.token != null &&
          transaction.data!.ledger!.token!.transfers.isNotEmpty) {
        transactionsInfos.add(
          TransactionInfos(
            domain: 'TokenLedger',
            titleInfo: '',
            valueInfo: '',
          ),
        );
        for (var i = 0;
            i < transaction.data!.ledger!.token!.transfers.length;
            i++) {
          if (transaction.data!.ledger!.token!.transfers[i].tokenAddress !=
              null) {
            transactionsInfos.add(
              TransactionInfos(
                domain: 'TokenLedger',
                titleInfo: 'Token',
                valueInfo:
                    transaction.data!.ledger!.token!.transfers[i].tokenAddress!,
              ),
            );
          }
          if (transaction.data!.ledger!.token!.transfers[i].to != null) {
            transactionsInfos.add(
              TransactionInfos(
                domain: 'TokenLedger',
                titleInfo: 'To',
                valueInfo: transaction.data!.ledger!.token!.transfers[i].to!,
              ),
            );
          }
          if (transaction.data!.ledger!.token!.transfers[i].amount != null) {
            final tokenMap = await sl.get<AppService>().getToken(
              [transaction.data!.ledger!.token!.transfers[i].tokenAddress!],
            );
            var tokenSymbol = '';
            if (tokenMap[transaction
                    .data!.ledger!.token!.transfers[i].tokenAddress!] !=
                null) {
              tokenSymbol = tokenMap[transaction
                          .data!.ledger!.token!.transfers[i].tokenAddress!]!
                      .symbol ??
                  '';
            }
            transactionsInfos.add(
              TransactionInfos(
                domain: 'TokenLedger',
                titleInfo: 'Amount',
                valueInfo:
                    '${NumberUtil.formatThousands(fromBigInt(transaction.data!.ledger!.token!.transfers[i].amount))} $tokenSymbol',
              ),
            );
          }
        }
      }
    }
    return transactionsInfos;
  }

  Future<double> getFeesEstimation(
    String originPrivateKey,
    String seed,
    String address,
    List<UCOTransfer> listUcoTransfer,
    List<TokenTransfer> listTokenTransfer,
    String message,
    KeychainServiceKeyPair keychainServiceKeyPair,
  ) async {
    final lastTransactionMap = await sl
        .get<ApiService>()
        .getLastTransaction([address], request: 'chainLength');
    final blockchainTxVersion = int.parse(
      (await sl.get<ApiService>().getBlockchainVersion()).version.transaction,
    );

    final transaction = Transaction(
      type: 'transfer',
      version: blockchainTxVersion,
      data: Transaction.initData(),
    );
    for (final transfer in listUcoTransfer) {
      transaction.addUCOTransfer(transfer.to!, transfer.amount!);
    }
    for (final transfer in listTokenTransfer) {
      transaction.addTokenTransfer(
        transfer.to!,
        transfer.amount!,
        transfer.tokenAddress!,
        tokenId: transfer.tokenId == null ? 0 : transfer.tokenId!,
      );
    }
    if (message.isNotEmpty) {
      final aesKey = uint8ListToHex(
        Uint8List.fromList(
          List<int>.generate(32, (int i) => Random.secure().nextInt(256)),
        ),
      );

      final authorizedPublicKeys = List<String>.empty(growable: true)
        ..add(
          uint8ListToHex(
            Uint8List.fromList(keychainServiceKeyPair.publicKey),
          ).toUpperCase(),
        );

      for (final transfer in listUcoTransfer) {
        final firstTxListRecipientMap =
            await sl.get<ApiService>().getTransactionChain(
          {transfer.to!: ''},
          request: 'previousPublicKey',
        );
        if (firstTxListRecipientMap.isNotEmpty) {
          final firstTxListRecipient = firstTxListRecipientMap[transfer.to!];
          if (firstTxListRecipient != null && firstTxListRecipient.isNotEmpty) {
            authorizedPublicKeys
                .add(firstTxListRecipient.first.previousPublicKey!);
          }
        }
      }

      for (final transfer in listTokenTransfer) {
        final firstTxListRecipientMap =
            await sl.get<ApiService>().getTransactionChain(
          {transfer.to!: ''},
          request: 'previousPublicKey',
        );
        if (firstTxListRecipientMap.isNotEmpty) {
          final firstTxListRecipient = firstTxListRecipientMap[transfer.to!];
          if (firstTxListRecipient != null && firstTxListRecipient.isNotEmpty) {
            authorizedPublicKeys
                .add(firstTxListRecipient.first.previousPublicKey!);
          }
        }
      }

      final authorizedKeys = List<AuthorizedKey>.empty(growable: true);
      for (final key in authorizedPublicKeys) {
        authorizedKeys.add(
          AuthorizedKey(
            encryptedSecretKey: uint8ListToHex(ecEncrypt(aesKey, key)),
            publicKey: key,
          ),
        );
      }

      transaction.addOwnership(
        uint8ListToHex(aesEncrypt(message, aesKey)),
        authorizedKeys,
      );
    }

    var transactionFee = const TransactionFee();
    final lastTransaction = lastTransactionMap[address];
    transaction
        .build(seed, lastTransaction!.chainLength ?? 0)
        .transaction
        .originSign(originPrivateKey);
    try {
      transactionFee =
          await sl.get<ApiService>().getTransactionFee(transaction);
    } catch (e, stack) {
      _logger.severe('Failed to get transaction fees', e, stack);
    }
    return fromBigInt(transactionFee.fee).toDouble();
  }
}
