import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:worldchat/Login.dart';
import 'package:worldchat/telas/AbaContatos.dart';
import 'package:worldchat/telas/AbaConversas.dart';

import 'main.dart';
import 'model/localization_constantes.dart';

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> with SingleTickerProviderStateMixin {
  TabController _tabController;

  List<String> _itensMenu;

  Firestore db = Firestore.instance;

  String _emailUsuario = "";
  String _idiomaSelecionado = "";

  Future _recuperarDadosUsuario() async {
    FirebaseAuth auth = FirebaseAuth.instance;
    FirebaseUser usuarioLogado = await auth.currentUser();

    DocumentSnapshot snapshot =
    await db.collection("usuarios").document(usuarioLogado.uid).get();
    Map<String, dynamic> dados = snapshot.data;

    _mudarIdioma(dados["codIdioma"]);

    setState(() {
      _emailUsuario = usuarioLogado.email;
    });
  }

  Future _verificarUsuarioLogado() async {
    FirebaseAuth auth = FirebaseAuth.instance;

    FirebaseUser usuarioLogado = await auth.currentUser();

    if (usuarioLogado == null) {
      Navigator.pushReplacementNamed(context, "/login");
    }
  }

  _mudarIdioma(String idioma){
    Locale _temp;
    switch(idioma){
      case "en":
        _temp = Locale(idioma, "US");
        break;
      case "es":
        _temp = Locale(idioma, "ES");
        break;
      case "pt":
        _temp = Locale(idioma, "BR");
        break;
      default:
        _temp = Locale("pt", "BR");
        break;
    }
    MyApp.setLocale(context, _temp);
  }

  @override
  void initState() {
    super.initState();
    _verificarUsuarioLogado();
    _recuperarDadosUsuario();
    _tabController = TabController(length: 2, vsync: this);
  }

  _escolhaMenuItem(String itemEscolhido) {

    switch (itemEscolhido) {
      case "Configurações":
        Navigator.pushNamed(context, "/configuracoes");
        break;
      case "Settings":
        Navigator.pushNamed(context, "/configuracoes");
        break;
      case "Ajustes":
        Navigator.pushNamed(context, "/configuracoes");
        break;
      case "Sair":
        _delogarUsuario();
        break;
      case "Log off":
        _delogarUsuario();
        break;
      case "Desconectarse":
        _delogarUsuario();
        break;
    }
  }

  _delogarUsuario() async {
    FirebaseAuth auth = FirebaseAuth.instance;
    await auth.signOut();

    Navigator.pushReplacementNamed(context, "/login");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("WorldChat"),
        bottom: TabBar(
          indicatorWeight: 4,
          labelStyle: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: <Widget>[
            Tab(
              text: getTraducao(context, "home_conversas"),
            ),
            Tab(
              text: getTraducao(context, "home_contatos"),
            ),
          ],
        ),
        actions: <Widget>[
          PopupMenuButton<String>(
            onSelected: _escolhaMenuItem,
            itemBuilder: (context) {
              _itensMenu = [getTraducao(context, "home_pop_config"),
                getTraducao(context, "home_pop_sair")];
              return _itensMenu.map((String item) {
                return PopupMenuItem<String>(
                  value: item,
                  child: Text(item),
                );
              }).toList();
            },
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: <Widget>[
          AbaConversas(),
          AbaContatos(),
        ],
      ),
    );
  }
}
