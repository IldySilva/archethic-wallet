import 'package:flutter/material.dart';
import 'package:patrol/patrol.dart';

Future<void> importWalletAction(PatrolTester $) async {
  await $(CheckboxListTile).tap();
  await $(#importWallet).tap();
  final finder = createFinder(RegExp('.*testnet.*'));
  await $(finder).tap();

  final seedWord = [
    'pave',
    'shrug',
    'coffee',
    'daughter',
    'hip',
    'mechanic',
    'scale',
    'trigger',
    'lake',
    'resist',
    'way',
    'repair',
    'good',
    'animal',
    'tennis',
    'boost',
    'walk',
    'story',
    'dash',
    'brass',
    'buzz',
    'orphan',
    'feed',
    'connect'
  ];

  const length = 23;
  for (var index = 0; index <= length; index++) {
    final seedWordFieldFinder = createFinder(Key('seedWord$index'));
    await $(seedWordFieldFinder).tap();
    await $(seedWordFieldFinder).scrollTo().enterText(seedWord[index]);
  }
  await $(#seedWordsOKbutton).tap(
    settleTimeout: const Duration(minutes: 10),
  );

  // TODO Reactivate this. For now it doesn't work for an unknown reason (Patrol issue ?)
  // await $(#accountNameDAVID).tap();

  await $(#accessModePIN).tap();

  // code pin 000000 avec confirmation
  const pinLength = 12;
  for (var i = pinLength; i >= 1; i--) {
    await $('0').tap(
      settleTimeout: const Duration(minutes: 10),
    );
  }
}
