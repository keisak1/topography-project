import 'package:provider/provider.dart';
import 'package:topography_project/src/Authentication/presentation/widgets/email_field.dart';
import 'package:topography_project/src/Authentication/presentation/widgets/login_button.dart';
import 'package:topography_project/src/Authentication/presentation/widgets/password_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:topography_project/main.dart';
import 'package:topography_project/src/HomePage/presentation/homepage_screen.dart';

class LoginScreen extends StatefulWidget {
  final Locale locale;
  final void Function(Locale? newLocale) onLocaleChange;

  const LoginScreen(
      {Key? key,
      required this.locale,
      required this.onLocaleChange})
      : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController emailController;
  late TextEditingController passwordController;
  double _elementsOpacity = 1;
  bool loadingBallAppear = false;
  double loadingBallSize = 1;

  @override
  void initState() {
    emailController = TextEditingController();
    passwordController = TextEditingController();
    super.initState();
  }

  void _changeLocale(Locale locale) {
    setState(() {
      Provider.of<LocaleProvider>(context, listen: false).changeLocale(locale);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(58, 66, 86, 1.0),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        bottom: false,
        child: loadingBallAppear
            ? Padding(
                padding: EdgeInsets.symmetric(vertical: 20, horizontal: 30.0),
                child: MyHomePage())
            : Padding(
                padding: EdgeInsets.symmetric(horizontal: 50.0),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        SizedBox(width: 240),
                        // add some spacing between text and button
                        TextButton(
                          onPressed: () async {
                            if (Provider.of<LocaleProvider>(context,
                                        listen: false)
                                    .locale
                                    .toString() ==
                                'en_EN') {
                              _changeLocale(Locale('pt', 'PT'));
                            } else if (Provider.of<LocaleProvider>(context,
                                        listen: false)
                                    .locale
                                    .toString() ==
                                'pt_PT') {
                              _changeLocale(Locale('en', 'EN'));
                            }
                            await AppLocalizations.delegate.load(
                                Provider.of<LocaleProvider>(context,
                                        listen: false)
                                    .locale);
                            setState(() {});
                          },
                          child: Text(
                            AppLocalizations.of(context)!.language,
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ]),
                      SizedBox(height: 70),
                      TweenAnimationBuilder<double>(
                        duration: Duration(milliseconds: 300),
                        tween: Tween(begin: 1, end: _elementsOpacity),
                        builder: (_, value, __) => Opacity(
                          opacity: value,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.flutter_dash,
                                  size: 60, color: Colors.grey),
                              SizedBox(height: 25),
                              Text(
                                AppLocalizations.of(context)!.welcome,
                                style: TextStyle(
                                    color: Colors.white, fontSize: 35),
                              ),
                              Text(
                                AppLocalizations.of(context)!.sign,
                                style: TextStyle(
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: 35),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 50),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8.0),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              EmailField(
                                  fadeEmail: _elementsOpacity == 0,
                                  emailController: emailController),
                              SizedBox(height: 40),
                              PasswordField(
                                  fadePassword: _elementsOpacity == 0,
                                  passwordController: passwordController),
                              SizedBox(height: 60),
                              LoginButton(
                                elementsOpacity: _elementsOpacity,
                                onTap: () {
                                  setState(() {
                                    _elementsOpacity = 0;
                                  });
                                },
                                onAnimatinoEnd: () async {
                                  await Future.delayed(
                                      Duration(milliseconds: 500));
                                  setState(() {
                                    loadingBallAppear = true;
                                  });
                                },
                                formKey: _formKey,
                                emailController: emailController,
                                passwordController: passwordController,
                              )
                            ],
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
