import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:pp_tracker/models/cycle_profile.dart';
import 'package:pp_tracker/models/menstrual_cycle.dart';
import 'package:pp_tracker/models/user_model.dart';
import 'package:pp_tracker/theme/app_theme.dart';

/// The final onboarding step: collects the three metrics that bootstrap the
/// whole cycle engine (last period start, cycle length, period length).
///
/// Designed so a user can finish in a single tap — everything is pre-filled
/// with medically-typical defaults and a live preview shows what the numbers
/// mean. On completion it writes the profile into [UserModel] (which persists
/// it locally and to the cloud) and calls [onComplete].
class CycleSetupView extends StatefulWidget {
  /// Called after the profile has been applied and the persist kicked off.
  final Future<void> Function() onComplete;

  const CycleSetupView({super.key, required this.onComplete});

  @override
  State<CycleSetupView> createState() => _CycleSetupViewState();
}

class _CycleSetupViewState extends State<CycleSetupView> {
  late DateTime _lastPeriodStart;
  late int _cycleLength;
  late int _periodLength;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    // Seed from whatever the model already has (defaults on a fresh account).
    final p = context.read<UserModel>().cycleProfile;
    _lastPeriodStart = p.lastPeriodStart;
    _cycleLength = p.cycleLength;
    _periodLength = p.periodLength;
  }

  MenstrualCycle get _preview => MenstrualCycle(
        cycleStartDate: _lastPeriodStart,
        cycleLength: _cycleLength,
        periodLength: _periodLength,
      );

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _lastPeriodStart,
      firstDate: DateTime(now.year - 1, now.month, now.day),
      lastDate: now,
      helpText: 'When did your last period start?',
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.primary,
            onPrimary: Colors.white,
            surface: AppColors.surface,
            onSurface: AppColors.textPrimary,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _lastPeriodStart = picked);
  }

  Future<void> _complete() async {
    if (_saving) return;
    setState(() => _saving = true);
    final model = context.read<UserModel>();
    await model.setupCycle(CycleProfile(
      lastPeriodStart: _lastPeriodStart,
      cycleLength: _cycleLength,
      periodLength: _periodLength,
    ));
    await widget.onComplete();
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final preview = _preview;
    final daysAgo = DateTime.now().difference(_lastPeriodStart).inDays;

    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl, AppSpacing.xxl, AppSpacing.xl, AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ---- Header -------------------------------------------------
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: AppGradients.brand,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      boxShadow: AppShadows.glow(AppColors.primary),
                    ),
                    child: const Icon(Icons.spa_rounded,
                        color: Colors.white, size: 28),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text('Let\'s set up your cycle', style: AppText.h1),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Three quick details personalise your predictions. '
                    'You can change them anytime in your profile.',
                    style: AppText.body.copyWith(height: 1.5),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // ---- 1. Last period start ---------------------------------
                  _SetupCard(
                    step: '1',
                    icon: Icons.event_rounded,
                    color: AppColors.menstrual,
                    title: 'Last period start',
                    subtitle: 'The first day of your most recent period',
                    child: InkWell(
                      onTap: _pickDate,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md, vertical: AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.alpha(AppColors.menstrual, 0.08),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(
                              color: AppColors.alpha(AppColors.menstrual, 0.25)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today_rounded,
                                size: 18, color: AppColors.menstrualDeep),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    DateFormat.yMMMMEEEEd()
                                        .format(_lastPeriodStart),
                                    style: AppText.bodyStrong,
                                  ),
                                  Text(
                                    daysAgo <= 0
                                        ? 'Today'
                                        : daysAgo == 1
                                            ? 'Yesterday'
                                            : '$daysAgo days ago',
                                    style: AppText.caption,
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.edit_calendar_rounded,
                                size: 18, color: AppColors.primary),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // ---- 2. Cycle length --------------------------------------
                  _SetupCard(
                    step: '2',
                    icon: Icons.autorenew_rounded,
                    color: AppColors.luteal,
                    title: 'Cycle length',
                    subtitle: 'Days from one period to the next',
                    child: _Stepper(
                      value: _cycleLength,
                      min: CycleProfile.minCycleLength,
                      max: CycleProfile.maxCycleLength,
                      unit: 'days',
                      color: AppColors.lutealDeep,
                      onChanged: (v) => setState(() => _cycleLength = v),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // ---- 3. Period length -------------------------------------
                  _SetupCard(
                    step: '3',
                    icon: Icons.water_drop_rounded,
                    color: AppColors.fertile,
                    title: 'Period length',
                    subtitle: 'Days of bleeding',
                    child: _Stepper(
                      value: _periodLength,
                      min: CycleProfile.minPeriodLength,
                      max: CycleProfile.maxPeriodLength,
                      unit: 'days',
                      color: AppColors.fertileDeep,
                      onChanged: (v) => setState(() => _periodLength = v),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // ---- Live preview -----------------------------------------
                  _PreviewCard(
                    nextPeriod: preview.nextPeriodDate,
                    ovulation: preview.ovulationDate,
                  ),
                ],
              ),
            ),
          ),

          // ---- CTA ------------------------------------------------------------
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl, AppSpacing.xs, AppSpacing.xl, AppSpacing.xl),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton(
                onPressed: _saving ? null : _complete,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  disabledBackgroundColor:
                      AppColors.alpha(AppColors.primary, 0.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : Text('Complete setup',
                        style:
                            AppText.bodyStrong.copyWith(color: Colors.white)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A titled, numbered card wrapping a single setup control.
class _SetupCard extends StatelessWidget {
  final String step;
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final Widget child;

  const _SetupCard({
    required this.step,
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.alpha(color, 0.14),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppText.h3),
                    Text(subtitle, style: AppText.caption),
                  ],
                ),
              ),
              Text('$step/3', style: AppText.overline),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );
  }
}

/// A − value + stepper with an inline slider, keeping the value within
/// [min]..[max].
class _Stepper extends StatelessWidget {
  final int value;
  final int min;
  final int max;
  final String unit;
  final Color color;
  final ValueChanged<int> onChanged;

  const _Stepper({
    required this.value,
    required this.min,
    required this.max,
    required this.unit,
    required this.color,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            _RoundButton(
              icon: Icons.remove_rounded,
              enabled: value > min,
              onTap: () => onChanged(value - 1),
            ),
            Expanded(
              child: Column(
                children: [
                  RichText(
                    text: TextSpan(
                      text: '$value',
                      style: AppText.display.copyWith(color: color, fontSize: 40),
                      children: [
                        TextSpan(
                          text: ' $unit',
                          style: AppText.body.copyWith(color: color),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            _RoundButton(
              icon: Icons.add_rounded,
              enabled: value < max,
              onTap: () => onChanged(value + 1),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: color,
            inactiveTrackColor: AppColors.alpha(color, 0.15),
            thumbColor: color,
            overlayColor: AppColors.alpha(color, 0.12),
            trackHeight: 4,
          ),
          child: Slider(
            value: value.toDouble(),
            min: min.toDouble(),
            max: max.toDouble(),
            divisions: max - min,
            onChanged: (v) => onChanged(v.round()),
          ),
        ),
      ],
    );
  }
}

class _RoundButton extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const _RoundButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: enabled
          ? AppColors.primarySoft
          : AppColors.alpha(AppColors.divider, 0.6),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: enabled ? onTap : null,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 46,
          height: 46,
          child: Icon(
            icon,
            color: enabled ? AppColors.primaryDeep : AppColors.textTertiary,
          ),
        ),
      ),
    );
  }
}

/// A soft gradient card summarising what the chosen numbers predict.
class _PreviewCard extends StatelessWidget {
  final DateTime nextPeriod;
  final DateTime ovulation;

  const _PreviewCard({required this.nextPeriod, required this.ovulation});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: AppGradients.phaseWash(AppColors.primary),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.alpha(AppColors.primary, 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome_rounded,
                  size: 18, color: AppColors.primaryDeep),
              const SizedBox(width: AppSpacing.xs),
              Text('Based on this, we predict',
                  style: AppText.label.copyWith(color: AppColors.primaryDeep)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _PreviewStat(
                  icon: Icons.water_drop_rounded,
                  color: AppColors.menstrualDeep,
                  label: 'Next period',
                  value: DateFormat.MMMd().format(nextPeriod),
                ),
              ),
              Container(width: 1, height: 40, color: AppColors.divider),
              Expanded(
                child: _PreviewStat(
                  icon: Icons.spa_rounded,
                  color: AppColors.ovulationDeep,
                  label: 'Ovulation',
                  value: DateFormat.MMMd().format(ovulation),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PreviewStat extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;

  const _PreviewStat({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 6),
        Text(value, style: AppText.h3.copyWith(color: color)),
        Text(label, style: AppText.caption),
      ],
    );
  }
}
