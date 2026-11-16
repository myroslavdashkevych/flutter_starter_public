import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_starter/domain/_shared/wrapper/result/failure.dart';
import 'package:flutter_starter/domain/entity/character.dart';
import 'package:flutter_starter/presentation/_shared/l10n/character_status_label.dart';
import 'package:flutter_starter/presentation/_shared/l10n/failure_message.dart';
import 'package:flutter_starter/presentation/_shared/l10n/l10n_extension.dart';
import 'package:flutter_starter/presentation/_shared/theme/const/app_spacing.dart';
import 'package:flutter_starter/presentation/_shared/widget/image/character_image.dart';
import 'package:flutter_starter/presentation/_shared/widget/state/failure_view.dart';
import 'package:flutter_starter/presentation/character_detail/bloc/character_detail_bloc.dart';
import 'package:flutter_starter/presentation/character_detail/bloc/character_detail_event.dart';
import 'package:flutter_starter/presentation/character_detail/bloc/character_detail_state.dart';
import 'package:material_ui/material_ui.dart';

class CharacterDetailPage extends StatelessWidget {
  const CharacterDetailPage({
    required this.id,
    required this.favoriteToggleBuilder,
    this.notFoundActionBuilder,
    super.key,
  });

  final int id;
  final Widget Function(Character character) favoriteToggleBuilder;

  /// When set, a missing character shows this action instead of a retry.
  final WidgetBuilder? notFoundActionBuilder;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CharacterDetailBloc, CharacterDetailState>(
      builder: (context, state) => Scaffold(
        appBar: AppBar(
          title: Text(switch (state) {
            CharacterDetailLoaded(:final character) => character.name,
            _ => context.l10n.characterDetailTitle,
          }),
          actions: [
            if (state case CharacterDetailLoaded(:final character))
              favoriteToggleBuilder(character),
          ],
        ),
        body: switch (state) {
          CharacterDetailLoading() => const Center(
            child: CircularProgressIndicator(),
          ),
          CharacterDetailFailed(failure: final NotFoundFailure failure)
              when notFoundActionBuilder != null =>
            Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.content),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  spacing: AppSpacing.inline,
                  children: [
                    Text(
                      failure.message(context.l10n),
                      textAlign: TextAlign.center,
                    ),
                    notFoundActionBuilder!(context),
                  ],
                ),
              ),
            ),
          CharacterDetailFailed(:final failure) => Center(
            child: FailureView(
              failure: failure,
              onRetry: () => context.read<CharacterDetailBloc>().add(
                CharacterDetailRetried(id),
              ),
            ),
          ),
          CharacterDetailLoaded(:final character) => _CharacterDetail(
            character: character,
          ),
        },
      ),
    );
  }
}

class _CharacterDetail extends StatelessWidget {
  const _CharacterDetail({required this.character});

  final Character character;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ListView(
      children: [
        AspectRatio(
          aspectRatio: 1,
          child: CharacterImage(url: character.imageUrl),
        ),
        _CharacterField(
          label: l10n.characterDetailStatus,
          value: character.status.label(l10n),
        ),
        _CharacterField(
          label: l10n.characterDetailSpecies,
          value: character.species,
        ),
        _CharacterField(
          label: l10n.characterDetailGender,
          value: character.gender,
        ),
        _CharacterField(
          label: l10n.characterDetailOrigin,
          value: character.originName,
        ),
        _CharacterField(
          label: l10n.characterDetailLocation,
          value: character.locationName,
        ),
        _CharacterField(
          label: l10n.characterDetailEpisodes,
          value: '${character.episodeCount}',
        ),
      ],
    );
  }
}

class _CharacterField extends StatelessWidget {
  const _CharacterField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(title: Text(label), subtitle: Text(value));
  }
}
