import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pp_tracker/components/app_card.dart';
import 'package:pp_tracker/models/blog/app_user.dart';
import 'package:pp_tracker/models/user_model.dart';
import 'package:pp_tracker/state/auth_controller.dart';
import 'package:pp_tracker/theme/app_theme.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<UserModel>(
      builder: (context, model, _) {
        return CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(child: _Header()),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md, 0, AppSpacing.md, 120),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _GoalCard(model: model),
                  const SizedBox(height: AppSpacing.xl),
                  const SectionHeader(title: 'Cycle'),
                  _CycleSettings(model: model),
                  const SizedBox(height: AppSpacing.xl),
                  const SectionHeader(title: 'Reminders'),
                  _Reminders(model: model),
                  const SizedBox(height: AppSpacing.xl),
                  const SectionHeader(title: 'Medications'),
                  _Medications(model: model),
                  const SizedBox(height: AppSpacing.xl),
                  const SectionHeader(title: 'Data & privacy'),
                  _DataActions(),
                  const SizedBox(height: AppSpacing.xl),
                  const SectionHeader(title: 'Account'),
                  const _AccountActions(),
                ]),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();
  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthController>().currentUser;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.lg),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            _Avatar(user: user),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Your profile', style: AppText.label),
                  Text(
                    user?.displayName ?? 'Welcome back',
                    style: AppText.h1,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (user?.email != null)
                    Text(user!.email!,
                        style: AppText.caption,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis)
                  else if (user?.isAnonymous ?? false)
                    Text('Guest — sign in to sync your data',
                        style: AppText.caption),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final AppUser? user;
  const _Avatar({required this.user});

  @override
  Widget build(BuildContext context) {
    final avatarUrl = user?.avatarUrl;
    return Container(
      width: 56,
      height: 56,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDeep],
        ),
        shape: BoxShape.circle,
      ),
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.center,
      child: (avatarUrl != null && avatarUrl.isNotEmpty)
          ? Image.network(
              avatarUrl,
              fit: BoxFit.cover,
              width: 56,
              height: 56,
              errorBuilder: (_, __, ___) => _initialsOrIcon(),
            )
          : _initialsOrIcon(),
    );
  }

  Widget _initialsOrIcon() {
    if (user != null && !user!.isAnonymous) {
      return Text(user!.initials,
          style: AppText.h3.copyWith(color: Colors.white));
    }
    return const Icon(Icons.person_rounded, color: Colors.white, size: 30);
  }
}

class _GoalCard extends StatelessWidget {
  final UserModel model;
  const _GoalCard({required this.model});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('I\'m using Petal to…', style: AppText.h3),
          const SizedBox(height: AppSpacing.sm),
          ...TrackingGoal.values.map((goal) {
            final selected = model.preferences.goal == goal;
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: GestureDetector(
                onTap: () => model.setGoal(goal),
                child: AnimatedContainer(
                  duration: AppDuration.fast,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.alpha(AppColors.primary, 0.10)
                        : AppColors.surfaceAlt,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(
                      color: selected ? AppColors.primary : Colors.transparent,
                      width: 1.6,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        selected
                            ? Icons.radio_button_checked_rounded
                            : Icons.radio_button_unchecked_rounded,
                        color: selected
                            ? AppColors.primary
                            : AppColors.textTertiary,
                        size: 20,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(goal.label,
                          style: AppText.bodyStrong.copyWith(
                            color: selected
                                ? AppColors.primary
                                : AppColors.textPrimary,
                          )),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _CycleSettings extends StatelessWidget {
  final UserModel model;
  const _CycleSettings({required this.model});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        children: [
          _Stepper(
            label: 'Cycle length',
            value: model.cycleLength,
            unit: 'days',
            onChanged: (v) => model.updateCycleSettings(cycleLength: v),
          ),
          const Divider(height: AppSpacing.lg, color: AppColors.divider),
          _Stepper(
            label: 'Period length',
            value: model.periodLength,
            unit: 'days',
            onChanged: (v) => model.updateCycleSettings(periodLength: v),
          ),
        ],
      ),
    );
  }
}

class _Stepper extends StatelessWidget {
  final String label;
  final int value;
  final String unit;
  final ValueChanged<int> onChanged;
  const _Stepper(
      {required this.label,
      required this.value,
      required this.unit,
      required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(label, style: AppText.bodyStrong)),
        _RoundButton(icon: Icons.remove_rounded, onTap: () => onChanged(value - 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Text('$value $unit', style: AppText.h3),
        ),
        _RoundButton(icon: Icons.add_rounded, onTap: () => onChanged(value + 1)),
      ],
    );
  }
}

class _RoundButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _RoundButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.alpha(AppColors.primary, 0.10),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
      ),
    );
  }
}

class _Reminders extends StatelessWidget {
  final UserModel model;
  const _Reminders({required this.model});

  @override
  Widget build(BuildContext context) {
    final p = model.preferences;
    return AppCard(
      child: Column(
        children: [
          _Toggle(
            label: 'Period reminders',
            value: p.periodReminders,
            onChanged: (v) => model.setReminderPrefs(period: v),
          ),
          const Divider(height: AppSpacing.lg, color: AppColors.divider),
          _Toggle(
            label: 'Fertile window alerts',
            value: p.fertileReminders,
            onChanged: (v) => model.setReminderPrefs(fertile: v),
          ),
          const Divider(height: AppSpacing.lg, color: AppColors.divider),
          _Toggle(
            label: 'Daily wellness tips',
            value: p.dailyTips,
            onChanged: (v) => model.setReminderPrefs(tips: v),
          ),
        ],
      ),
    );
  }
}

class _Toggle extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _Toggle(
      {required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(label, style: AppText.bodyStrong)),
        Switch.adaptive(
          value: value,
          activeColor: AppColors.primary,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _Medications extends StatelessWidget {
  final UserModel model;
  const _Medications({required this.model});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        children: [
          for (var i = 0; i < model.medications.length; i++) ...[
            if (i > 0)
              const Divider(height: AppSpacing.lg, color: AppColors.divider),
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.alpha(AppColors.primary, 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: const Icon(Icons.medication_rounded,
                      color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(model.medications[i].name, style: AppText.bodyStrong),
                      Text(model.medications[i].schedule, style: AppText.caption),
                    ],
                  ),
                ),
                Switch.adaptive(
                  value: model.medications[i].enabled,
                  activeColor: AppColors.primary,
                  onChanged: (v) =>
                      model.setMedicationEnabled(model.medications[i], v),
                ),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          TextButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.add_rounded, color: AppColors.primary),
            label: Text('Add medication',
                style: AppText.label.copyWith(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }
}

class _DataActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        children: const [
          _ActionRow(icon: Icons.ios_share_rounded, label: 'Export health report'),
          Divider(height: AppSpacing.lg, color: AppColors.divider),
          _ActionRow(
              icon: Icons.contact_emergency_rounded,
              label: 'Emergency contacts'),
          Divider(height: AppSpacing.lg, color: AppColors.divider),
          _ActionRow(icon: Icons.lock_rounded, label: 'Privacy & security'),
        ],
      ),
    );
  }
}

class _AccountActions extends StatelessWidget {
  const _AccountActions();

  Future<void> _confirmSignOut(BuildContext context) async {
    final auth = context.read<AuthController>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Sign out?', style: AppText.h3),
        content: Text(
          auth.isGuest
              ? 'You\'re using a guest account. Your local data stays on this '
                  'device. Sign out anyway?'
              : 'You can sign back in anytime with Google.',
          style: AppText.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel',
                style: AppText.label.copyWith(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Sign out',
                style: AppText.label.copyWith(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (confirmed == true) await auth.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        onTap: () => _confirmSignOut(context),
        child: Row(
          children: [
            const Icon(Icons.logout_rounded,
                color: AppColors.danger, size: 22),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text('Sign out',
                  style: AppText.bodyStrong
                      .copyWith(color: AppColors.danger)),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  const _ActionRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.textSecondary, size: 22),
        const SizedBox(width: AppSpacing.md),
        Expanded(child: Text(label, style: AppText.bodyStrong)),
        const Icon(Icons.chevron_right_rounded,
            color: AppColors.textTertiary),
      ],
    );
  }
}
