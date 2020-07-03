/* Code modified from https://medium.com/flutterpub/flutter-how-to-do-user-login-with-firebase-a6af760b14d5 */
import 'package:flutter/material.dart';

import '../data/authentication.dart';
import '../data/user.dart';

class LoginSignup extends StatefulWidget {
  final Auth auth;

  LoginSignup(this.auth);

  @override
  State<StatefulWidget> createState() => _LoginSignupState();
}

class _LoginSignupState extends State<LoginSignup> {
  final _formKey = GlobalKey<FormState>();

  bool _isLoading;
  bool _isLoginForm;

  String _email;
  String _password;
  String _confirmPassword;
  String _name;
  String _errorMessage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Sign In"),
      ),
      body: Stack(
        children: <Widget>[
          _loginForm(),
          _circularProgress(),
        ],
      ),
    );
  }

  @override
  void initState() {
    _errorMessage = '';
    _isLoading = false;
    _isLoginForm = true;
    super.initState();
  }

  Widget _circularProgress() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }
    return Container(height: 0, width: 0);
  }

  Widget _confirmPasswordInput() {
    if (_isLoginForm) {
      return Container();
    }
    return Padding(
      padding: EdgeInsets.only(top: 4),
      child: TextFormField(
        maxLines: 1,
        obscureText: true,
        autofocus: false,
        decoration: InputDecoration(
          hintText: 'Confirm Password',
          icon: Icon(Icons.lock, color: Colors.grey),
        ),
        validator: (value) => value.isEmpty ? 'Password can\'t be empty' : null,
        onSaved: (value) => _confirmPassword = value,
      ),
    );
  }

  Widget _emailInput() {
    return Padding(
      padding: EdgeInsets.only(top: 4),
      child: TextFormField(
        maxLines: 1,
        keyboardType: TextInputType.emailAddress,
        autofocus: false,
        decoration: InputDecoration(
          hintText: 'Email',
          icon: Icon(Icons.mail, color: Colors.grey),
        ),
        validator: (value) => value.isEmpty ? 'Email can\'t be empty' : null,
        onSaved: (value) => _email = value.trim(),
      ),
    );
  }

  Widget _errorMessageWidget() {
    if (_errorMessage != null && _errorMessage.isNotEmpty) {
      return Center(
        child: Text(
          _errorMessage,
          style: Theme.of(context).textTheme.bodyText1.copyWith(color: Colors.red),
        ),
      );
    } else {
      return Container(height: 0);
    }
  }

  Widget _loginForm() {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: <Widget>[
              _title(),
              _logo(),
              _errorMessageWidget(),
              _emailInput(),
              _nameInput(),
              _passwordInput(),
              _confirmPasswordInput(),
              _submitButton(),
              _switchButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _logo() {
    return Padding(
      padding: EdgeInsets.fromLTRB(0, 24, 0, 24),
      child: CircleAvatar(
        backgroundColor: Colors.transparent,
        radius: 96,
        child: Image.asset('assets/logo.png'),
      ),
    );
  }

  Widget _nameInput() {
    if (_isLoginForm) {
      return Container();
    }
    return Padding(
      padding: EdgeInsets.only(top: 4),
      child: TextFormField(
        maxLines: 1,
        autofocus: false,
        decoration: InputDecoration(
          hintText: 'Name',
          icon: Icon(Icons.person, color: Colors.grey),
        ),
        validator: (value) => value.length < 5 ? 'Name is too short' : null,
        onSaved: (value) => _name = value,
      ),
    );
  }

  Widget _passwordInput() {
    return Padding(
      padding: EdgeInsets.only(top: 4),
      child: TextFormField(
        maxLines: 1,
        obscureText: true,
        autofocus: false,
        decoration: InputDecoration(
          hintText: 'Password',
          icon: Icon(Icons.lock, color: Colors.grey),
        ),
        validator: (value) => value.isEmpty ? 'Password can\'t be empty' : null,
        onSaved: (value) => _password = value,
      ),
    );
  }

  void _resetForm() {
    _formKey.currentState.reset();
    _errorMessage = '';
  }

  Widget _submitButton() {
    return Padding(
      padding: EdgeInsets.only(top: 24),
      child: SizedBox(
        height: 40,
        width: double.infinity,
        child: RaisedButton(
          child: Text(_isLoginForm ? 'Login' : 'Create account'),
          onPressed: _validateAndSubmit,
        ),
      ),
    );
  }

  Widget _switchButton() {
    return FlatButton(
      child: Text(_isLoginForm ? 'Create an account' : 'Have an account? Sign in'),
      onPressed: _toggleFormMode,
    );
  }

  Widget _title() {
    return Column(
      children: <Widget>[
        Text(
          'Bid Euchre',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headline3.copyWith(color: Theme.of(context).primaryColor),
        ),
      ],
    );
  }

  void _toggleFormMode() {
    _resetForm();
    setState(() {
      _isLoginForm = !_isLoginForm;
    });
  }

  bool _validateAndSave() {
    final form = _formKey.currentState;
    if (form.validate()) {
      form.save();
      return true;
    }
    return false;
  }

  void _validateAndSubmit() async {
    setState(() {
      _errorMessage = '';
      _isLoading = true;
    });
    if (_validateAndSave()) {
      String userId = '';
      try {
        if (_isLoginForm) {
          userId = await widget.auth.signIn(_email, _password);
        } else {
          if (_password != _confirmPassword) {
            setState(() {
              _isLoading = false;
              _errorMessage = 'Passwords do not match!';
            });
          } else {
            userId = await widget.auth.signUp(_email, _password);
            User.newUser(userId, _name);
          }
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
          switch (e.code) {
            case 'ERROR_INVALID_EMAIL':
              _errorMessage = 'Invalid email address';
              break;
            case 'ERROR_USER_NOT_FOUND':
              _errorMessage = 'Account not found';
              break;
            case 'ERROR_WRONG_PASSWORD':
              _errorMessage = 'Incorrect password';
              break;
            default:
              _errorMessage = e.message;
          }
        });
      }
    } else {
      _isLoading = false;
    }
  }
}
