import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:worldchat/Home.dart';
import 'package:worldchat/model/Usuario.dart';
import 'main.dart';
import 'model/Idioma.dart';
import 'model/localization_constantes.dart';

class Cadastro extends StatefulWidget {
  @override
  _CadastroState createState() => _CadastroState();
}

class _CadastroState extends State<Cadastro> {
  TextEditingController _controllerNome = TextEditingController();
  TextEditingController _controllerEmail = TextEditingController();
  TextEditingController _controllerSenha = TextEditingController();
  String _mensagemErro = "";
  String _idiomaSelecionado = "";

  _validarCampos() {
    String nome = _controllerNome.text;
    String email = _controllerEmail.text;
    String senha = _controllerSenha.text;

    if (nome.isNotEmpty) {
      if (email.isNotEmpty) {
        if (email.contains("@")) {
          if (senha.isNotEmpty) {
            if (senha.length >= 8) {
              setState(() {
                _mensagemErro = "";
              });
              if(_idiomaSelecionado == getTraducao(context, "login_idioma")){
                setState(() {
                  _mensagemErro = getTraducao(context, "cadastro_idioma");
                });
              }else {
                String codIdioma = "";
                if(_idiomaSelecionado == "Português"){
                  codIdioma = "pt";
                }else if(_idiomaSelecionado == "English"){
                  codIdioma = "en";
                }else if(_idiomaSelecionado == "Español"){
                  codIdioma = "es";
                }
                Usuario usuario = Usuario();
                usuario.nome = nome;
                usuario.email = email;
                usuario.senha = senha;
                usuario.codIdioma = codIdioma;
                usuario.urlImagem = "https://firebasestorage.googleapis.com/v0/b/worldchat-dc40f.appspot.com/o/perfil%2Fimg-usuario-padrao.png?alt=media&token=7793be16-db40-4819-9a86-7836200ff1d4";
                _cadastrarUsuario(usuario);
              }
            } else {
              setState(() {
                _mensagemErro = getTraducao(context, "cadastro_senha_tamanho");
              });
            }
          } else {
            setState(() {
              _mensagemErro = getTraducao(context, "cadastro_senha_vazia");
            });
          }
        } else {
          setState(() {
            _mensagemErro = getTraducao(context, "cadastro_email_invalido");
          });
        }
      } else {
        setState(() {
          _mensagemErro = getTraducao(context, "cadastro_email_vazio");
        });
      }
    } else {
      setState(() {
        _mensagemErro = getTraducao(context, "cadastro_nome_vazio");
      });
    }
  }

  _cadastrarUsuario(Usuario usuario) {
    FirebaseAuth auth = FirebaseAuth.instance;

    auth
        .createUserWithEmailAndPassword(
            email: usuario.email, password: usuario.senha)
        .then((firebaseUser) {
      Firestore db = Firestore.instance;

      db
          .collection("usuarios")
          .document(firebaseUser.user.uid)
          .setData(usuario.toMap());

      Navigator.pushNamedAndRemoveUntil(context, "/home", (_) => false);
    }).catchError((error) {
      setState(() {
        _mensagemErro =
            getTraducao(context, "cadastro_erro");
      });
    });
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(getTraducao(context, "cadastro_cadastro")),
        automaticallyImplyLeading: false,
        leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () => Navigator.pushNamedAndRemoveUntil(context, "/login", (_) => false),
          ),
      ),
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
                  child: Image.asset("imagens/usuario.png",
                      width: 200, height: 150),
                ),
                Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: TextField(
                    controller: _controllerNome,
                    autofocus: true,
                    keyboardType: TextInputType.text,
                    style: TextStyle(
                      fontSize: 20,
                    ),
                    decoration: InputDecoration(
                        contentPadding: EdgeInsets.fromLTRB(32, 16, 32, 16),
                        hintText: getTraducao(context, "cadastro_nome"),
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
                Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: TextField(
                    controller: _controllerEmail,
                    keyboardType: TextInputType.emailAddress,
                    style: TextStyle(
                      fontSize: 20,
                    ),
                    decoration: InputDecoration(
                        contentPadding: EdgeInsets.fromLTRB(32, 16, 32, 16),
                        hintText: getTraducao(context, "cadastro_email"),
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
                  controller: _controllerSenha,
                  obscureText: true,
                  keyboardType: TextInputType.text,
                  style: TextStyle(
                    fontSize: 20,
                  ),
                  decoration: InputDecoration(
                      contentPadding: EdgeInsets.fromLTRB(32, 16, 32, 16),
                      hintText: getTraducao(context, "cadastro_senha"),
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
                  padding: EdgeInsets.only(top: 8),
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
                  )
                ),
                Padding(
                  padding: EdgeInsets.only(top: 16, bottom: 10),
                  child: RaisedButton(
                    child: Text(
                      getTraducao(context, "cadastro_cadastrar"),
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
                Center(
                  child: Text(
                    _mensagemErro,
                    style: TextStyle(
                      color: Colors.blue,
                      fontSize: 20,
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
