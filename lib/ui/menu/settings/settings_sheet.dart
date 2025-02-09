import 'package:aewallet/application/account/providers.dart';
import 'package:aewallet/application/authentication/authentication.dart';
import 'package:aewallet/application/connectivity_status.dart';
import 'package:aewallet/application/session/session.dart';
import 'package:aewallet/application/settings/language.dart';
import 'package:aewallet/application/settings/primary_currency.dart';
import 'package:aewallet/application/settings/settings.dart';
import 'package:aewallet/application/settings/version.dart';
import 'package:aewallet/domain/repositories/features_flags.dart';
import 'package:aewallet/infrastructure/datasources/tokens_list.hive.dart';
import 'package:aewallet/infrastructure/rpc/websocket_server.dart';
import 'package:aewallet/model/authentication_method.dart';
import 'package:aewallet/model/available_language.dart';
import 'package:aewallet/model/device_lock_timeout.dart';
import 'package:aewallet/model/privacy_mask_option.dart';
import 'package:aewallet/model/setting_item.dart';
import 'package:aewallet/ui/themes/archethic_theme.dart';
import 'package:aewallet/ui/themes/archethic_theme_base.dart';
import 'package:aewallet/ui/themes/styles.dart';
import 'package:aewallet/ui/util/ui_util.dart';
import 'package:aewallet/ui/views/authenticate/auth_factory.dart';
import 'package:aewallet/ui/views/authenticate/logging_out.dart';
import 'package:aewallet/ui/views/main/components/sheet_appbar.dart';
import 'package:aewallet/ui/views/main/home_page.dart';
import 'package:aewallet/ui/views/settings/backupseed_sheet.dart';
import 'package:aewallet/ui/widgets/components/dialog.dart';
import 'package:aewallet/ui/widgets/components/icon_widget.dart';
import 'package:aewallet/ui/widgets/components/sheet_skeleton.dart';
import 'package:aewallet/ui/widgets/components/sheet_skeleton_interface.dart';
import 'package:aewallet/ui/widgets/dialogs/authentification_method_dialog.dart';
import 'package:aewallet/ui/widgets/dialogs/language_dialog.dart';
import 'package:aewallet/ui/widgets/dialogs/lock_timeout_dialog.dart';
import 'package:aewallet/ui/widgets/dialogs/primary_currency_dialog.dart';
import 'package:aewallet/util/cache_manager_hive.dart';
import 'package:aewallet/util/case_converter.dart';
import 'package:aewallet/util/get_it_instance.dart';
import 'package:aewallet/util/haptic_util.dart';
import 'package:aewallet/util/mnemonics.dart';
import 'package:aewallet/util/universal_platform.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:material_symbols_icons/symbols.dart';

part 'about_menu_view.dart';
part 'components/settings_list_item.dart';
part 'components/settings_list_item_defaultvalue.dart';
part 'components/settings_list_item_singleline.dart';
part 'components/settings_list_item_switch.dart';
part 'customization_menu_view.dart';
part 'main_settings_view.dart';
part 'security_menu_view.dart';
part 'settings_sheet_wallet.dart';
