import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/failure.dart';
import '../../domain/entities/registration.dart';
import '../../domain/usecases/registration_actions.dart';
import '../bloc/registration_cubit.dart';
import '../widgets/draft_panel.dart';
import '../widgets/messages.dart';

class RegistrationPage extends StatefulWidget {
  const RegistrationPage({super.key});
  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController(),
      _email = TextEditingController(),
      _phone = TextEditingController(),
      _password = TextEditingController();
  bool _hidden = true;
  ContactDraft get _contact =>
      ContactDraft(name: _name.text, email: _email.text, phone: _phone.text);
  void _restore(ContactDraft draft) {
    _name.text = draft.name;
    _email.text = draft.email;
    _phone.text = draft.phone;
    _password.clear();
  }

  void _submit() {
    if (!_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    context.read<RegistrationCubit>().submit(_contact, _password.text);
  }

  @override
  void dispose() {
    for (final c in [_name, _email, _phone, _password]) {
      c.dispose();
    }
    super.dispose();
  }

  Widget _field(
    String label,
    TextEditingController controller,
    InputIssue? Function(String) check,
    bool enabled, {
    TextInputType? type,
    bool secret = false,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: type,
      obscureText: secret && _hidden,
      textInputAction: secret ? TextInputAction.done : TextInputAction.next,
      onFieldSubmitted: secret ? (_) => _submit() : null,
      validator: (v) => inputMessage(check(v ?? '')),
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: secret
            ? IconButton(
                onPressed: () => setState(() => _hidden = !_hidden),
                icon: Icon(_hidden ? Icons.visibility : Icons.visibility_off),
              )
            : null,
      ),
    ),
  );
  @override
  Widget build(
    BuildContext context,
  ) => BlocConsumer<RegistrationCubit, RegistrationState>(
    listenWhen: (a, b) => a.registration != b.registration,
    listener: (c, s) {
      if (s.registration is Success) {
        _password.clear();
      } else if (s.registration is Empty) {
        for (final f in [_name, _email, _phone, _password]) {
          f.clear();
        }
        _form.currentState?.reset();
      }
    },
    builder: (c, state) {
      final cubit = c.read<RegistrationCubit>(), result = state.registration;
      final saved = result is Success<RegisteredProfile>,
          enabled = !saved && !state.busy;
      final failure =
          state.actionError ??
          (result is ErrorState<RegisteredProfile> ? result.failure : null);
      return Scaffold(
        appBar: AppBar(title: const Text('Регистрация')),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      saved ? 'Регистрация успешна' : 'Создать аккаунт',
                      style: Theme.of(c).textTheme.headlineSmall,
                    ),
                    if (saved)
                      const Text(
                        'Данные сохранены в Firebase Realtime Database.',
                      ),
                    const SizedBox(height: 16),
                    _field('Имя', _name, RegisterAccount.nameIssue, enabled),
                    _field(
                      'Email',
                      _email,
                      RegisterAccount.emailIssue,
                      enabled,
                      type: TextInputType.emailAddress,
                    ),
                    _field(
                      'Телефон',
                      _phone,
                      RegisterAccount.phoneIssue,
                      enabled,
                      type: TextInputType.phone,
                    ),
                    if (!saved)
                      _field(
                        'Пароль',
                        _password,
                        RegisterAccount.passwordIssue,
                        enabled,
                        secret: true,
                      ),
                    if (failure != null)
                      Text(
                        failureMessage(failure),
                        style: TextStyle(color: Theme.of(c).colorScheme.error),
                      ),
                    if (!saved)
                      FilledButton(
                        onPressed: enabled ? _submit : null,
                        child: result is Loading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Зарегистрироваться'),
                      ),
                    if (saved)
                      OutlinedButton(
                        onPressed: state.busy ? null : cubit.reset,
                        child: const Text('Новая регистрация'),
                      ),
                    if (!saved)
                      DraftPanel(
                        state: state.draft,
                        busy: state.busy,
                        save: () => cubit.storeDraft(_contact),
                        remove: cubit.removeDraft,
                        reload: cubit.reloadDraft,
                        restore: _restore,
                      ),
                    if (state.draft
                        case ErrorState<ContactDraft>(:final failure)
                        when saved) ...[
                      Text(failureMessage(failure)),
                      TextButton(
                        onPressed: state.busy ? null : cubit.removeDraft,
                        child: const Text('Удалить черновик'),
                      ),
                    ],
                    const Divider(),
                    Text(
                      'Push-уведомления',
                      style: Theme.of(c).textTheme.titleMedium,
                    ),
                    Text(pushMessage(state.push.phase)),
                    if (state.push.message.isNotEmpty)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Text(state.push.message),
                        ),
                      ),
                    TextButton.icon(
                      onPressed: state.busy ? null : cubit.retryPush,
                      icon: const Icon(Icons.notifications_active_outlined),
                      label: Text(
                        saved
                            ? 'Повторить запрос push'
                            : 'Разрешить уведомления',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}
