import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:topography_project/src/Authentication/application/login_request.dart';

class LoginButton extends StatefulWidget {
  final Function onTap;
  final Function onAnimatinoEnd;
  final double elementsOpacity;
  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;



  const LoginButton(
      {super.key,
      required this.onTap,
      required this.onAnimatinoEnd,
      required this.elementsOpacity,
      required this.formKey,
      required this.emailController,
      required this.passwordController});

  @override
  State<LoginButton> createState() => _LoginButtonState();
}

class _LoginButtonState extends State<LoginButton> {




  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 300),
      tween: Tween(begin: 1, end: widget.elementsOpacity),
      onEnd: () async {
        widget.onAnimatinoEnd();

      },
      builder: (_, value, __) => GestureDetector(
        onTap: () {
          if(widget.formKey.currentState!.validate()){
            // HTTP request to login
            login(widget.emailController.text, widget.passwordController.text);
          }
        },
        child: Opacity(
          opacity: value,
          child: Container(
            width: 230,
            height: 75,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: Color.fromARGB(255, 224, 227, 231),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  AppLocalizations.of(context)!.login,
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                      fontSize: 19),
                ),
                SizedBox(width: 15),
                Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.black,
                  size: 26,
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
