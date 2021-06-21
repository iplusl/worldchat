import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:worldchat/Cadastro.dart';
import 'package:worldchat/main.dart';
import 'package:worldchat/model/Idioma.dart';

import 'Home.dart';
import 'model/Usuario.dart';
import 'model/localization_constantes.dart';

class Login extends StatefulWidget {
  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
  TextEditingController _controllerEmail = TextEditingController();
  TextEditingController _controllerSenha = TextEditingController();
  String _idiomaSelecionado = "";
  String _mensagemErro = "";

  _validarCampos() {
    String email = _controllerEmail.text;
    String senha = _controllerSenha.text;

    if (email.isNotEmpty) {
      if (email.contains("@")) {
        if (senha.isNotEmpty) {
          setState(() {
            _mensagemErro = "";
          });
          Usuario usuario = Usuario();
          usuario.email = email;
          usuario.senha = senha;
          _logarUsuario(usuario);
        } else {
          setState(() {
            _mensagemErro = getTraducao(context, "login_senha_vazia");
          });
        }
      } else {
        setState(() {
          _mensagemErro = getTraducao(context, "login_email_invalido");
        });
      }
    } else {
      setState(() {
        _mensagemErro = getTraducao(context, "login_email_vazio");
      });
    }
  }

  _logarUsuario(Usuario usuario) {
    FirebaseAuth auth = FirebaseAuth.instance;

    auth
        .signInWithEmailAndPassword(
        email: usuario.email, password: usuario.senha)
        .then((firebaseUser) {
      Navigator.pushReplacementNamed(context, "/home");
    }).catchError((error) {
      setState(() {
        _mensagemErro =
            getTraducao(context, "login_erro_autenticacao");
      });
    });
  }

  Future _verificarUsuarioLogado() async {
    FirebaseAuth auth = FirebaseAuth.instance;

    FirebaseUser usuarioLogado = await auth.currentUser();

    if (usuarioLogado != null) {
      Navigator.pushReplacementNamed(context, "/home");
    }
  }

  _mudarIdioma(Idioma idioma){
    Locale _temp;
    switch(idioma.codIdioma){
      case "en":
        _temp = Locale(idioma.codIdioma, "US");
        break;
      case "es":
        _temp = Locale(idioma.codIdioma, "ES");
        break;
      case "pt":
        _temp = Locale(idioma.codIdioma, "BR");
        break;
      default:
        _temp = Locale("pt", "BR");
        break;
    }
    MyApp.setLocale(context, _temp);
  }

  @override
  void initState() {
    _verificarUsuarioLogado();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          color: Colors.white,
        ),
        padding: EdgeInsets.all(16),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.only(bottom: 32),
                  child:
                  Image.asset("imagens/logo.png", width: 200, height: 150),
                ),
                Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: TextField(
                    controller: _controllerEmail,
                    autofocus: true,
                    keyboardType: TextInputType.emailAddress,
                    style: TextStyle(
                      fontSize: 20,
                    ),
                    decoration: InputDecoration(
                        contentPadding: EdgeInsets.fromLTRB(32, 16, 32, 16),
                        hintText: getTraducao(context, "login_email"),
                        hintStyle: TextStyle(
                          color: Colors.blue,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(32),
                        )),
                  ),
                ),
                TextField(
                  obscureText: true,
                  controller: _controllerSenha,
                  keyboardType: TextInputType.text,
                  style: TextStyle(
                    fontSize: 20,
                  ),
                  decoration: InputDecoration(
                      contentPadding: EdgeInsets.fromLTRB(32, 16, 32, 16),
                      hintText: getTraducao(context, "login_senha"),
                      hintStyle: TextStyle(
                        color: Colors.blue,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(32),
                      )),
                ),
                Padding(
                  padding: EdgeInsets.only(top: 16, bottom: 10),
                  child: RaisedButton(
                    child: Text(
                      getTraducao(context, "login_entrar"),
                      style: TextStyle(color: Colors.white, fontSize: 20),
                    ),
                    color: Colors.blue,
                    padding: EdgeInsets.fromLTRB(32, 16, 32, 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(32),
                    ),
                    onPressed: () {
                      _validarCampos();
                    },
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Center(
                      child: GestureDetector(
                        child: Text(
                          getTraducao(context, "login_cadastro"),
                          style: TextStyle(color: Colors.blue),
                        ),
                        onTap: () {
                          Navigator.pushReplacementNamed(context, "/cadastro");
                        },
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(left: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          PopupMenuButton(
                            onSelected: (Idioma idioma){
                              _mudarIdioma(idioma);
                              setState(() {
                                _idiomaSelecionado = idioma.nome;
                              });
                            },
                            tooltip: getTraducao(context, "login_idioma"),
                            icon: Icon(
                              Icons.language,
                              color: Colors.blue,
                            ),
                            itemBuilder: (context){
                              return Idioma.listaIdiomas().map((Idioma item){
                                return PopupMenuItem<Idioma>(
                                  value: item,
                                  child: Text(item.bandeira+" "+item.nome),
                                );
                              }).toList();
                            },
                          ),
                          Text(
                            _idiomaSelecionado != "" ?
                            _idiomaSelecionado:
                            _idiomaSelecionado = getTraducao(context, "login_idioma"),
                            style: TextStyle(
                                color: Colors.blue
                            ),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
                Padding(
                  padding: EdgeInsets.only(top: 16),
                  child: Center(
                    child: Text(
                      _mensagemErro,
                      style: TextStyle(
                        color: Colors.blue,
                        fontSize: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}