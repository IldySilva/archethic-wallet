part of 'providers.dart';

@Riverpod(keepAlive: true)
class _AccountNotifier extends _$AccountNotifier {
  final _logger = Logger('AccountNotifier');

  @override
  FutureOr<Account?> build(String accountName) async {
    final repository = ref.read(AccountProviders.accountsRepository);
    final account = await repository.getAccount(accountName);

    return account;
  }

  Future<void> _refresh(
    List<Future<void> Function(Account account)> doRefreshes,
  ) async {
    try {
      final account = state.valueOrNull;
      if (account == null) return;
      await account.updateLastAddress();

      ref.read(refreshInProgressProviders.notifier).setRefreshInProgress(true);
      for (final doRefresh in doRefreshes) {
        await doRefresh(account);

        final newAccountData = account.copyWith();
        state = AsyncData(newAccountData);
      }
    } catch (e, stack) {
      _logger.severe('Refresh failed', e, stack);
    } finally {
      ref.read(refreshInProgressProviders.notifier).setRefreshInProgress(false);
    }
  }

  Future<void> _refreshRecentTransactions(Account account) async {
    final session = ref.read(sessionNotifierProvider).loggedIn!;
    await account.updateRecentTransactions(
      account.name,
      session.wallet.keychainSecuredInfos,
    );
  }

  Future<void> _refreshBalance(Account account) => account.updateBalance();

  Future<void> refreshRecentTransactions() => _refresh([
        (account) async {
          _logger.fine(
            'Start method refreshRecentTransactions for ${account.nameDisplayed}',
          );
          await _refreshRecentTransactions(account);
          await _refreshBalance(account);
          await account.updateFungiblesTokens();
          _logger.fine(
            'End method refreshRecentTransactions for ${account.nameDisplayed}',
          );
        },
      ]);

  Future<void> refreshFungibleTokens() => _refresh([
        (account) async {
          await account.updateFungiblesTokens();
        },
      ]);

  Future<void> refreshNFTs() => _refresh([
        (account) async {
          final session = ref.read(sessionNotifierProvider).loggedIn!;
          final tokenInformation = await ref.read(
            NFTProviders.getNFTList(
              account.lastAddress!,
              account.name,
              session.wallet.keychainSecuredInfos,
            ).future,
          );

          await account.updateNFT(
            session.wallet.keychainSecuredInfos,
            tokenInformation.$1,
            tokenInformation.$2,
          );
        },
      ]);

  Future<void> refreshBalance() => _refresh([_refreshBalance]);

  Future<void> refreshAll() => _refresh(
        [
          (account) async {
            _logger.fine('RefreshAll - Start Balance refresh');
            await _refreshBalance(account);
            _logger.fine('RefreshAll - End Balance refresh');
          },
          (account) async {
            _logger.fine('RefreshAll - Start recent transactions refresh');
            await _refreshRecentTransactions(account);
            _logger.fine('RefreshAll - End recent transactions refresh');
          },
          (account) async {
            _logger.fine('RefreshAll - Start Fungible Tokens refresh');
            await account.updateFungiblesTokens();
            _logger.fine('RefreshAll - End Fungible Tokens refresh');
          },
          (account) async {
            _logger.fine('RefreshAll - Start NFT refresh');
            final session = ref.read(sessionNotifierProvider).loggedIn!;
            final tokenInformation = await ref.read(
              NFTProviders.getNFTList(
                account.lastAddress!,
                account.name,
                session.wallet.keychainSecuredInfos,
              ).future,
            );
            await account.updateNFT(
              session.wallet.keychainSecuredInfos,
              tokenInformation.$1,
              tokenInformation.$2,
            );
            _logger.fine('RefreshAll - End NFT refresh');
          },
        ],
      );
}
