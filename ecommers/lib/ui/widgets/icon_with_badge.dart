import 'package:badges/badges.dart';
import 'package:ecommers/ui/decorations/dimens/index.dart';
import 'package:ecommers/ui/decorations/index.dart';
import 'package:flutter/material.dart';

class IconWithBadge extends Badge {
  final int badgeValue;
  final BadgePosition badgePosition;
  final Widget icon;
  final TextStyle badgeTextStyle;

  IconWithBadge({
    this.badgeValue = 0,
    this.badgePosition,
    this.badgeTextStyle,
    @required this.icon,
  }) : super(
          child: icon,
          badgeContent: Text(
            badgeValue.toString(),
            style: badgeTextStyle,
            textAlign: TextAlign.center,
          ),
          position:
              badgePosition ?? BadgePosition.bottomLeft(bottom: -4, left: -9),
          shape: BadgeShape.square,
          borderRadius: Dimens.badgeBorderRadius,
          elevation: 1.0,
          badgeColor: Palette.badge,
          animationType: BadgeAnimationType.scale,
          showBadge: badgeValue != 0,
          padding: EdgeInsets.fromLTRB(5, 2, 5, 1),
        );
}
