/// SPDX-License-Identifier: AGPL-3.0-or-later

// Package imports:
import 'package:core/model/data/hive_db.dart';
import 'package:event_taxi/event_taxi.dart';

class ContactRemovedEvent implements Event {
  ContactRemovedEvent({this.contact});

  final Contact? contact;
}
