import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_starter/app/config/flavor.dart';
import 'package:talker/talker.dart';
import 'package:talker_bloc_logger/talker_bloc_logger.dart';

/// The Bloc observer of the app: it logs events and transitions outside
/// `prod`, and errors in every flavor (OBS-6).
BlocObserver createBlocObserver({
  required Talker talker,
  required Flavor flavor,
}) => TalkerBlocObserver(
  talker: talker,
  // States hold user data such as the email.
  settings: TalkerBlocLoggerSettings(enabled: flavor != Flavor.prod),
);
