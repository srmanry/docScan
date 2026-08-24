import 'package:flutter/material.dart';

class SubscriptionPage extends StatelessWidget {
  const SubscriptionPage({super.key});

  static const _plans = [
    _Plan(
      name: 'Weekly',
      price: '\$1.49',
      cadence: '/7 days',
      summary: 'Short plan for urgent document work without committing long term.',
      ocrLimit: '40 OCR pages',
      aiLimit: '20 AI actions',
      accent: Color(0xFF0F766E),
      features: [
        'Best for occasional bursts of scanning',
        'Google account billing only',
        'No rollover on unused quota',
      ],
      cta: 'Choose Weekly',
    ),
    _Plan(
      name: 'Monthly',
      price: '\$3.99',
      cadence: '/month',
      summary: 'Balanced plan for students and office users who scan regularly.',
      ocrLimit: '220 OCR pages',
      aiLimit: '90 AI actions',
      accent: Color(0xFF1D4ED8),
      recommended: true,
      features: [
        'Best value if you use the app every week',
        'Built around capped OCR and AI usage',
        'Extra credit packs are available separately',
      ],
      cta: 'Choose Monthly',
    ),
    _Plan(
      name: '3 Months',
      price: '\$9.99',
      cadence: '/3 months',
      summary: 'Longer plan with a modest discount, but still capped to stay safe.',
      ocrLimit: '750 OCR pages',
      aiLimit: '300 AI actions',
      accent: Color(0xFF7C3AED),
      features: [
        'Lower effective monthly price than monthly billing',
        'No plan extends past three months',
        'Made for steady but controlled use',
      ],
      cta: 'Choose 3 Months',
    ),
  ];

  static const _packs = [
    _AddonPack(
      title: 'Extra OCR Pack',
      price: '\$0.99',
      detail: '100 extra OCR pages',
      icon: Icons.document_scanner_outlined,
    ),
    _AddonPack(
      title: 'Extra AI Pack',
      price: '\$1.29',
      detail: '40 extra AI actions',
      icon: Icons.psychology_outlined,
    ),
  ];

  void _showComingSoon(BuildContext context, String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label billing setup is coming next.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Subscription')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          _HeroCard(
            onPressed: () => _showComingSoon(context, 'Subscription'),
          ),
          const SizedBox(height: 20),
          Text('Plans', style: theme.textTheme.titleLarge),
          const SizedBox(height: 6),
          Text(
            'No guest billing and no unlimited plan. Every paid tier stays capped so OCR and AI costs remain predictable.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          for (final plan in _plans) ...[
            _PlanCard(
              plan: plan,
              onPressed: () => _showComingSoon(context, plan.name),
            ),
            const SizedBox(height: 14),
          ],
          const SizedBox(height: 6),
          Text('Add-on Credits', style: theme.textTheme.titleLarge),
          const SizedBox(height: 10),
          for (final pack in _packs) ...[
            _AddonPackTile(
              pack: pack,
              onTap: () => _showComingSoon(context, pack.title),
            ),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 18),
          Text('Why This Model Is Safe', style: theme.textTheme.titleLarge),
          const SizedBox(height: 10),
          const _SafetyPoint(
            icon: Icons.lock_outline,
            title: 'No unlimited usage',
            body: 'Heavy users cannot consume OCR pages and AI responses forever on one low fee.',
          ),
          const SizedBox(height: 10),
          const _SafetyPoint(
            icon: Icons.query_stats_outlined,
            title: 'Built around current Google API costs',
            body: 'Cloud Vision page OCR and Gemini AI usage both scale with usage, so short capped plans are safer than open-ended ones.',
          ),
          const SizedBox(height: 10),
          const _SafetyPoint(
            icon: Icons.add_card_outlined,
            title: 'Extra demand is paid separately',
            body: 'Add-on credit packs cover users who need more without pushing the app into loss.',
          ),
          const SizedBox(height: 18),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Pricing Guardrail', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(
                    'Keep subscriptions to weekly, monthly, and 3-month terms only. Do not add longer plans until backend usage metering is live.',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  final VoidCallback onPressed;

  const _HeroCard({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1D4ED8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Text(
                'Loss-Safe Pricing',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Keep plans short, capped, and tied to Google sign-in.',
              style: theme.textTheme.headlineMedium?.copyWith(
                color: Colors.white,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'These caps are sized around Cloud Vision OCR and Gemini 2.5 Flash usage so the app does not drift into loss too quickly.',
              style: TextStyle(color: Colors.white70, height: 1.45),
            ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: onPressed,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF0F172A),
              ),
              child: const Text('Use These Capped Plans'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final _Plan plan;
  final VoidCallback onPressed;

  const _PlanCard({required this.plan, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: plan.recommended ? plan.accent : theme.colorScheme.outlineVariant,
          width: plan.recommended ? 1.6 : 1,
        ),
        color: theme.colorScheme.surfaceContainer,
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: plan.accent.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(Icons.workspace_premium_outlined, color: plan.accent),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(plan.name, style: theme.textTheme.titleLarge),
                          if (plan.recommended) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: plan.accent,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: const Text(
                                'Recommended',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        plan.summary,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: plan.price,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  TextSpan(
                    text: plan.cadence,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _LimitChip(label: plan.ocrLimit, color: plan.accent),
                _LimitChip(label: plan.aiLimit, color: plan.accent),
              ],
            ),
            const SizedBox(height: 14),
            for (final feature in plan.features) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.check_circle, size: 18, color: plan.accent),
                  const SizedBox(width: 8),
                  Expanded(child: Text(feature, style: theme.textTheme.bodyMedium)),
                ],
              ),
              const SizedBox(height: 8),
            ],
            const SizedBox(height: 4),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onPressed,
                style: FilledButton.styleFrom(
                  backgroundColor: plan.recommended ? plan.accent : theme.colorScheme.primary,
                ),
                child: Text(plan.cta),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LimitChip extends StatelessWidget {
  final String label;
  final Color color;

  const _LimitChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _AddonPackTile extends StatelessWidget {
  final _AddonPack pack;
  final VoidCallback onTap;

  const _AddonPackTile({required this.pack, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(pack.icon, color: theme.colorScheme.primary),
        ),
        title: Text(pack.title),
        subtitle: Text(pack.detail),
        trailing: Text(
          pack.price,
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}

class _SafetyPoint extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const _SafetyPoint({
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: theme.colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: theme.colorScheme.onSecondaryContainer),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(
                    body,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Plan {
  final String name;
  final String price;
  final String cadence;
  final String summary;
  final String ocrLimit;
  final String aiLimit;
  final List<String> features;
  final Color accent;
  final bool recommended;
  final String cta;

  const _Plan({
    required this.name,
    required this.price,
    required this.cadence,
    required this.summary,
    required this.ocrLimit,
    required this.aiLimit,
    required this.features,
    required this.accent,
    required this.cta,
    this.recommended = false,
  });
}

class _AddonPack {
  final String title;
  final String price;
  final String detail;
  final IconData icon;

  const _AddonPack({
    required this.title,
    required this.price,
    required this.detail,
    required this.icon,
  });
}
