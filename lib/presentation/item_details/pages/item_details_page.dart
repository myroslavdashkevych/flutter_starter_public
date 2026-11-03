import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_starter/domain/_shared/failure.dart';
import 'package:flutter_starter/domain/items/entities/item.dart';
import 'package:flutter_starter/presentation/_shared/l10n/failure_messages.dart';
import 'package:flutter_starter/presentation/_shared/l10n/item_status_labels.dart';
import 'package:flutter_starter/presentation/_shared/l10n/l10n_extension.dart';
import 'package:flutter_starter/presentation/_shared/widgets/failure_view.dart';
import 'package:flutter_starter/presentation/_shared/widgets/item_image.dart';
import 'package:flutter_starter/presentation/item_details/bloc/item_details_cubit.dart';
import 'package:flutter_starter/presentation/item_details/bloc/item_details_state.dart';

class ItemDetailsPage extends StatelessWidget {
  const ItemDetailsPage({
    required this.id,
    required this.favoriteToggleBuilder,
    this.notFoundActionBuilder,
    super.key,
  });

  final int id;
  final Widget Function(Item item) favoriteToggleBuilder;

  /// When set, a missing item shows this action instead of a retry.
  final WidgetBuilder? notFoundActionBuilder;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ItemDetailsCubit, ItemDetailsState>(
      builder: (context, state) => Scaffold(
        appBar: AppBar(
          title: Text(switch (state) {
            ItemDetailsLoaded(:final item) => item.name,
            _ => context.l10n.itemDetailsTitle,
          }),
          actions: [
            if (state case ItemDetailsLoaded(:final item))
              favoriteToggleBuilder(item),
          ],
        ),
        body: switch (state) {
          ItemDetailsLoading() => const Center(
            child: CircularProgressIndicator(),
          ),
          ItemDetailsFailed(failure: final NotFoundFailure failure)
              when notFoundActionBuilder != null =>
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 8,
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
          ItemDetailsFailed(:final failure) => Center(
            child: FailureView(
              failure: failure,
              onRetry: () => context.read<ItemDetailsCubit>().load(id),
            ),
          ),
          ItemDetailsLoaded(:final item) => _ItemDetails(item: item),
        },
      ),
    );
  }
}

class _ItemDetails extends StatelessWidget {
  const _ItemDetails({required this.item});

  final Item item;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ListView(
      children: [
        AspectRatio(aspectRatio: 1, child: ItemImage(url: item.imageUrl)),
        _ItemField(
          label: l10n.itemDetailsStatus,
          value: item.status.label(l10n),
        ),
        _ItemField(label: l10n.itemDetailsSpecies, value: item.species),
        _ItemField(label: l10n.itemDetailsGender, value: item.gender),
        _ItemField(label: l10n.itemDetailsOrigin, value: item.originName),
        _ItemField(label: l10n.itemDetailsLocation, value: item.locationName),
        _ItemField(
          label: l10n.itemDetailsEpisodes,
          value: '${item.episodeCount}',
        ),
      ],
    );
  }
}

class _ItemField extends StatelessWidget {
  const _ItemField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(title: Text(label), subtitle: Text(value));
  }
}
