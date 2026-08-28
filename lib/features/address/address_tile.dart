import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import 'package:wallet_test/core/theme/app_tokens.dart';
import 'package:wallet_test/features/address/address_display.dart';
import 'package:wallet_test/features/address/address_tile_bloc.dart';

class AddressTile extends StatefulWidget {
  const AddressTile({
    super.key,
    required this.address,
    required this.network,
  });

  final String address;
  final String network;

  @override
  State<AddressTile> createState() => _AddressTileState();
}

class _AddressTileState extends State<AddressTile> {
  late final AddressTileBloc _bloc = GetIt.instance<AddressTileBloc>();
  late final StreamSubscription<AddressTileState> _subscription;
  late AddressTileState _state = _bloc.state;

  @override
  void initState() {
    super.initState();
    _subscription = _bloc.stream.listen((state) {
      if (mounted) {
        setState(() => _state = state);
      }
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    _bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textScaleFactor = MediaQuery.textScalerOf(context).scale(1);

    final iconData = _state.error != null
        ? Icons.error_outline
        : _state.copied
            ? Icons.check
            : Icons.copy;

    final iconColor = _state.error != null
        ? AppTokens.danger
        : _state.copied
            ? AppTokens.success
            : AppTokens.textSecondary;

    return SizedBox(
      height: AppTokens.cellHeight,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTokens.horizontalPadding,
        ),
        child: Row(
          children: [
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.network,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTokens.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppTokens.verticalGap),
                      Text(
                        formatAddressForCell(
                          widget.address,
                          textScaleFactor,
                        ),
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppTokens.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.clip,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppTokens.gapTextIcon),
            SizedBox(
              width: AppTokens.tapTarget,
              height: AppTokens.tapTarget,
              child: IconButton(
                padding: EdgeInsets.zero,
                onPressed: () => _bloc.add(CopyTapped(widget.address)),
                icon: Icon(
                  iconData,
                  size: AppTokens.iconSize,
                  color: iconColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
