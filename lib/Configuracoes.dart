import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'main.dart';
import 'model/DemoLocalization.dart';
import 'model/Idioma.dart';
import 'model/localization_constantes.dart';

class Configuracoes extends StatefulWidget {
  @override
  _ConfiguracoesState createState() => _ConfiguracoesState();
}

class _ConfiguracoesState extends State<Configuracoes> {
  TextEditingController _controllerNome = TextEditingController();
  Firestore db = Firestore.instance;
  File _imagem;
  String _idUsuarioLogado;
  bool _subindoImagem = false;
  String _urlImagemRecuperada;
  String _idiomaSelecionado = "";

  Future _recuperarImagem(String origemImagem) async {
    File imagemSelecionada;

    switch (origemImagem) {
      case "camera":
        imagemSelecionada =
        await ImagePicker.pickImage(source: ImageSource.camera);
        break;
      case "galeria":
        imagemSelecionada =
        await ImagePicker.pickImage(source: ImageSource.gallery);
        break;
    }

    setState(() {
      _imagem = imagemSelecionada;
      if (_imagem != null) {
        _subindoImagem = true;
        _uploadImagem();
      }
    });
  }

  Future _uploadImagem() async {
    FirebaseStorage storage = FirebaseStorage.instance;
    StorageReference pastaRaiz = storage.ref();
    StorageReference arquivo =
    pastaRaiz.child("perfil").child(_idUsuarioLogado + ".jpg");

    StorageUploadTask task = arquivo.putFile(_imagem);
    task.events.listen((StorageTaskEvent storageEvent) {
      if (storageEvent.type == StorageTaskEventType.progress) {
        setState(() {
          _subindoImagem = true;
        });
      } else if (storageEvent.type == StorageTaskEventType.success) {
        setState(() {
          _subindoImagem = false;
        });
      }
    });

    task.onComplete.then((StorageTaskSnapshot snapshot) {
      _recuperaUrlImagem(snapshot);
    });
  }

  Future _recuperaUrlImagem(StorageTaskSnapshot snapshot) async {
    String url = await snapshot.ref.getDownloadURL();
    _atualizarUrlImagemFirestore(url);

    setState(() {
      _urlImagemRecuperada = url;
    });
  }

  _atualizarNomeFirestore() {
    String nome = _controllerNome.text;
    String codIdioma = "";
    Firestore db = Firestore.instance;

    if(_idiomaSelecionado == "Português"){
      codIdioma = "pt";
    }else if(_idiomaSelecionado == "English"){
      codIdioma = "en";
    }else if(_idiomaSelecionado == "Español"){
      codIdioma = "es";
    }

    Map<String, dynamic> dadosAtualizar;


    if(codIdioma == ""){
      dadosAtualizar = {"nome": nome};
      print("Desgraça");
    }else {
      print("Mizera");
      dadosAtualizar = {"nome": nome, "codIdioma": codIdioma};
    }

    db
        .collection("usuarios")
        .document(_idUsuarioLogado)
        .updateData(dadosAtualizar);
  }

  _atualizarUrlImagemFirestore(String url) {
    Map<String, dynamic> dadosAtualizar = {"urlImagem": url};

    db
        .collection("usuarios")
        .document(_idUsuarioLogado)
        .updateData(dadosAtualizar);
  }

  _recuperarDadosUsuario() async {
    FirebaseAuth auth = FirebaseAuth.instance;
    FirebaseUser usuarioLogado = await auth.currentUser();
    _idUsuarioLogado = usuarioLogado.uid;

    DocumentSnapshot snapshot =
    await db.collection("usuarios").document(_idUsuarioLogado).get();

    Map<String, dynamic> dados = snapshot.data;
    _controllerNome.text = dados["nome"];

    if (dados["urlImagem"] != null) {
      setState(() {
        _urlImagemRecuperada = dados["urlImagem"];
      });
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
    _recuperarDadosUsuario();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        leading: Transform.translate(
          offset: Offset(0, 0),
          child: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () async {
              FirebaseAuth auth = FirebaseAuth.instance;
              FirebaseUser usuarioLogado = await auth.currentUser();
              DocumentSnapshot snapshot =
                  await db.collection("usuarios").document(usuarioLogado.uid).get();
              Map<String, dynamic> dados = snapshot.data;

              _mudarIdioma(dados["codIdioma"]);
              Navigator.pop(context);
            },
          ),
        ),
        title: Text(getTraducao(context, "config_config")),
      ),
      body: Container(
        padding: EdgeInsets.all(16),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              children: <Widget>[
                Container(
                  padding: EdgeInsets.all(16),
                  child: _subindoImagem
                      ? CircularProgressIndicator()
                      : Container(),
                ),
                CircleAvatar(
                  radius: 100,
                  backgroundColor: Colors.grey,
                  backgroundImage: _urlImagemRecuperada != null
                      ? NetworkImage(_urlImagemRecuperada)
                      : null,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    FlatButton(
                      child: Text(getTraducao(context, "config_camera")),
                      onPressed: () {
                        _recuperarImagem("camera");
                      },
                    ),
                    FlatButton(
                      child: Text(getTraducao(context,"config_galeria")),
                      onPressed: () {
                        _recuperarImagem("galeria");
                      },
                    ),
                  ],
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
                        hintText: getTraducao(context, "config_nome"),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(32),
                        )),
                  ),
                ),
                Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        PopupMenuButton(
                          onSelected: (Idioma idioma){
                            _mudarIdioma(idioma.codIdioma);
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
                      getTraducao(context, "config_salvar"),
                      style: TextStyle(color: Colors.white, fontSize: 20),
                    ),
                    color: Colors.blue,
                    padding: EdgeInsets.fromLTRB(32, 16, 32, 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(32),
                    ),
                    onPressed: () {
                      _atualizarNomeFirestore();
                    },
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
