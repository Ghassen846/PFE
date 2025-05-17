import 'package:first_app_new/helpers/bloc/home_bloc.dart';
import 'package:first_app_new/helpers/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class InfoCard extends StatelessWidget {
  final String title;
  final String value;
  final MaterialColor color;
  final IconData icon;
  final VoidCallback? onTap;

  const InfoCard({
      super.key,
      required this.title,
      required this.value,
      required this.color,
      required this.icon,
      this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<HomeBloc, HomeState>(
      listener: (context, state) {},
      builder: (context, state) {
        return InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(15),
          splashColor: color.withOpacity(0.3),
          child: Container(
            decoration: BoxDecoration(
              color:
                  state.isDark ? ThemeHelper.whiteColor : ThemeHelper.blackColor,
              borderRadius:
                  BorderRadius.circular(15), // Rounded corners for the card
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 2,
                  blurRadius: 5,
                  offset: const Offset(0, 3), // changes position of shadow
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 40), // Icon at the top
                const SizedBox(height: 10),
                Text(value,
                    style: TextStyle(
                        color: color, fontSize: 24, fontWeight: FontWeight.bold)),
                Text(title,
                    style: TextStyle(
                        color: state.isDark
                            ? ThemeHelper.blackColor
                            : ThemeHelper.whiteColor,
                        fontSize: 16)),
              ],
            ),
          ),
        );
      },
    );
  }
}
