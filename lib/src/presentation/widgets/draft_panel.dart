import 'package:flutter/material.dart';

import '../../../components/retry_panel.dart';
import '../../domain/entities/registration.dart';
import '../bloc/registration_cubit.dart';
import 'messages.dart';

class DraftPanel extends StatelessWidget {
  final ViewState<ContactDraft> state;
  final bool busy;
  final VoidCallback save, remove, reload;
  final ValueChanged<ContactDraft> restore;
  const DraftPanel({
    super.key,
    required this.state,
    required this.busy,
    required this.save,
    required this.remove,
    required this.reload,
    required this.restore,
  });
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const Divider(),
      Text(
        'Черновик на устройстве',
        style: Theme.of(context).textTheme.titleMedium,
      ),
      switch (state) {
        Loading() => const LinearProgressIndicator(),
        Empty() => const Text('Сохранённого черновика нет.'),
        Success(:final value) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Черновик сохранён.'),
            Wrap(
              children: [
                TextButton(
                  onPressed: busy ? null : () => restore(value),
                  child: const Text('Восстановить'),
                ),
                TextButton(
                  onPressed: busy ? null : remove,
                  child: const Text('Удалить черновик'),
                ),
              ],
            ),
          ],
        ),
        ErrorState(:final failure) => RetryPanel(
          failureMessage(failure),
          busy ? null : reload,
        ),
      },
      if (state is ErrorState)
        TextButton(
          onPressed: busy ? null : remove,
          child: const Text('Удалить черновик'),
        ),
      TextButton.icon(
        onPressed: busy ? null : save,
        icon: const Icon(Icons.save_outlined),
        label: const Text('Сохранить без пароля'),
      ),
    ],
  );
}
