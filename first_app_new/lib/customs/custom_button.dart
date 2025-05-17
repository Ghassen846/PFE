
import 'package:first_app_new/helpers/bloc/home_bloc.dart';
import 'package:first_app_new/helpers/responsive/sizer_ext.dart';
import 'package:first_app_new/helpers/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:glassmorphism/glassmorphism.dart';


class CustomButton extends StatelessWidget {
  final bool? colorText;
  final Color? borderColor;
  final String text;
  final VoidCallback onPressed;
  final List<Color> colors;
  const CustomButton({
    required this.colors,
    required this.onPressed,
    super.key,
    required this.text,
    this.borderColor,
    this.colorText,
  });

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<HomeBloc, HomeState>(
      listener: (context, state) {
      },
      builder: (context, state) {
        return GlassmorphicContainer(
          width: 100,
          height: 50, // Define a fixed height for the button container
          borderRadius: 20,
          blur: 100,
          alignment: Alignment.bottomCenter,
          border: 2,
          linearGradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: colors,
            stops: const [
              0.1,
              1,
            ],
          ),
          borderGradient: LinearGradient(
            colors: [
              borderColor != null ? Colors.white : ThemeHelper.orangeColor,
              borderColor != null
                  ? Colors.white
                  : const Color((0xFFFFFFFF)).withOpacity(0.5),
            ],
          ),
          child: Center(
            child: TextButton(
              onPressed: onPressed,
              child: Text(
                      text,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14.sp,
                        color: colorText != null
                            ? ThemeHelper.whiteColor
                            : state.isDark
                                ? ThemeHelper.whiteColor
                                : ThemeHelper.blackColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        );
      },
    );
  }
}
