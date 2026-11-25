import 'package:material_ui/material_ui.dart';

import '../theme/btj_theme.dart';

class BtjCheckBadge extends StatelessWidget {
  const BtjCheckBadge({
    super.key,
    this.size = 20,
    this.color = BtjColors.primary,
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.check_rounded,
        size: size * 0.68,
        color: Colors.white,
      ),
    );
  }
}

class BtjSectionHeader extends StatelessWidget {
  const BtjSectionHeader({
    super.key,
    required this.title,
    this.trailing,
  });

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: BtjColors.textPrimary,
              letterSpacing: -0.2,
            ),
          ),
        ),
        ?trailing,
      ],
    );
  }
}
