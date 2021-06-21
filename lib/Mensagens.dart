import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:translator/translator.dart';
import 'package:worldchat/model/Conversa.dart';
import 'package:worldchat/model/Mensagem.dart';
import 'dart:io';
import 'model/Usuario.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'model/localization_constantes.dart';

class Mensagens extends StatefulWidget {
  Usuario contato;

  Mensagens(this.contato);

  @override
  _MensagensState createState() => _MensagensState();
}

class _MensagensState extends State<Mensagens> {
  TextEditingController _controllerMensagem = TextEditingController();
  Firestore db = Firestore.instance;
  String _idUsuarioLogado;
  String _idUsuarioDestinatario;
  bool _subindoImagem = false;
  final _controller = StreamController<QuerySnapshot>.broadcast();
  ScrollController _scrollController = ScrollController();
  final tradutor = GoogleTranslator();
  bool _traducaoAtiva = true;

  _enviarMensagem() async{

    DocumentSnapshot sRemetente =
    await db.collection("usuarios").document(_idUsuarioLogado).get();
    Map<String, dynamic> dRemetente = sRemetente.data;

    DocumentSnapshot sDestinatario =
    await db.collection("usuarios").document(_idUsuarioDestinatario).get();
    Map<String, dynamic> dDestinatario = sDestinatario.data;

    String textoMensagem = _controllerMensagem.text;
    if (textoMensagem.isNotEmpty) {
      Mensagem mensagem = Mensagem();
      mensagem.idUsuario = _idUsuarioLogado;
      mensagem.mensagem = textoMensagem;
      mensagem.mensagemTraduzida = await tradutor.translate(textoMensagem, from: dRemetente["codIdioma"], to: dDestinatario["codIdioma"]); // en-US, pt-BR, pt-PT...
      mensagem.urlImagem = "";
      mensagem.data = Timestamp.now().toString();
      mensagem.tipo = "texto";

      _salvarMensagem(_idUsuarioLogado, _idUsuarioDestinatario, mensagem);
      _salvarMensagem(_idUsuarioDestinatario, _idUsuarioLogado, mensagem);

      _salvarConversa(mensagem);
    }
  }

  _salvarConversa(Mensagem mensagem) async {
    Conversa cRemetente = Conversa();
    cRemetente.idRemetente = _idUsuarioLogado;
    cRemetente.idDestinatario = _idUsuarioDestinatario;
    cRemetente.mensagem = mensagem.mensagem;
    cRemetente.nome = widget.contato.nome;
    cRemetente.caminhoFoto = widget.contato.urlImagem;
    cRemetente.tipoMensagem = mensagem.tipo;
    cRemetente.salvar();

    DocumentSnapshot snapshot =
    await db.collection("usuarios").document(_idUsuarioLogado).get();
    Map<String, dynamic> dados = snapshot.data;

    Conversa cDestinatario = Conversa();
    cDestinatario.idRemetente = _idUsuarioDestinatario;
    cDestinatario.idDestinatario = _idUsuarioLogado;
    cDestinatario.mensagem = mensagem.mensagemTraduzida;
    cDestinatario.nome = dados["nome"];
    cDestinatario.caminhoFoto = dados["urlImagem"];
    cDestinatario.tipoMensagem = mensagem.tipo;
    cDestinatario.salvar();
  }

  _enviarFoto() async {
    File imagemSelecionada;

    imagemSelecionada =
    await ImagePicker.pickImage(source: ImageSource.gallery);
    _subindoImagem = true;
    String nomeImagem = DateTime.now().millisecondsSinceEpoch.toString();
    FirebaseStorage storage = FirebaseStorage.instance;
    StorageReference pastaRaiz = storage.ref();
    StorageReference arquivo = pastaRaiz
        .child("mensagens")
        .child(_idUsuarioLogado)
        .child(nomeImagem + ".jpg");

    StorageUploadTask task = arquivo.putFile(imagemSelecionada);
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

    Mensagem mensagem = Mensagem();
    mensagem.idUsuario = _idUsuarioLogado;
    mensagem.mensagem = "";
    mensagem.urlImagem = url;
    mensagem.data = Timestamp.now().toString();
    mensagem.tipo = "imagem";

    _salvarMensagem(_idUsuarioLogado, _idUsuarioDestinatario, mensagem);
    _salvarMensagem(_idUsuarioDestinatario, _idUsuarioLogado, mensagem);
    _salvarConversa(mensagem);
  }

  _salvarMensagem(
      String idRemetente, String idDestinatario, Mensagem msg) async {
    await db
        .collection("mensagens")
        .document(idRemetente)
        .collection(idDestinatario)
        .add(msg.toMap());

    _controllerMensagem.clear();
  }

  _recuperarDadosUsuario() async {
    FirebaseAuth auth = FirebaseAuth.instance;
    FirebaseUser usuarioLogado = await auth.currentUser();
    _idUsuarioLogado = usuarioLogado.uid;
    _idUsuarioDestinatario = widget.contato.idUsuario;
    _adicionarListenerMensagens();
  }

  Stream<QuerySnapshot> _adicionarListenerMensagens() {
    final stream = db
        .collection("mensagens")
        .document(_idUsuarioLogado)
        .collection(_idUsuarioDestinatario)
        .orderBy("data", descending: false)
        .snapshots();

    stream.listen((dados) {
      _controller.add(dados);
      Timer(Duration(milliseconds: 200), (){
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      });
    });
  }

  @override
  void initState() {
    super.initState();
    _recuperarDadosUsuario();
  }

  @override
  Widget build(BuildContext context) {
    var caixaMensagem = Container(
      padding: EdgeInsets.all(8),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: 8),
              child: TextField(
                controller: _controllerMensagem,
                autofocus: true,
                keyboardType: TextInputType.text,
                style: TextStyle(
                  fontSize: 20,
                ),
                decoration: InputDecoration(
                  contentPadding: EdgeInsets.fromLTRB(32, 8, 8, 16),
                  hintText: getTraducao(context, "mensagens_digite"),
                  hintMaxLines: 1,
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(32),
                  ),
                  prefixIcon: IconButton(
                    icon: _subindoImagem
                        ? CircularProgressIndicator()
                        : Icon(Icons.camera_alt),
                    onPressed: _enviarFoto,
                  ),
                ),
              ),
            ),
          ),
          FloatingActionButton(
            backgroundColor: Colors.blue,
            child: Icon(
              Icons.send,
              color: Colors.white,
            ),
            mini: true,
            onPressed: _enviarMensagem,
          ),
        ],
      ),
    );

    var stream = StreamBuilder(
      stream: _controller.stream,
      // ignore: missing_return
      builder: (context, snapshot) {
        switch (snapshot.connectionState) {
          case ConnectionState.none:
          case ConnectionState.waiting:
            return Center(
              child: Column(
                children: <Widget>[
                  Text(getTraducao(context, "mensagens_carregando")),
                  CircularProgressIndicator()
                ],
              ),
            );
            break;
          case ConnectionState.active:
          case ConnectionState.done:
            QuerySnapshot querySnapshot = snapshot.data;
            if (snapshot.hasError) {
              return Expanded(
                child: Text(getTraducao(context, "mensagens_erro")),
              );
            } else {
              return Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  itemCount: querySnapshot.documents.length,
                  itemBuilder: (context, indice) {
                    List<DocumentSnapshot> mensagens =
                    querySnapshot.documents.toList();
                    DocumentSnapshot item = mensagens[indice];
                    double larguraContainer =
                        MediaQuery.of(context).size.width * 0.8;

                    Alignment alinhamento = Alignment.centerRight;
                    Color cor = Colors.blue[200];

                    if (_idUsuarioLogado != item["idUsuario"]) {
                      alinhamento = Alignment.bottomLeft;
                      cor = Colors.white;
                    }

                    return Align(
                      alignment: alinhamento,
                      child: Padding(
                        padding: EdgeInsets.all(6),
                        child: Container(
                          width: larguraContainer,
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: cor,
                            borderRadius: BorderRadius.all(Radius.circular(8)),
                          ),
                          child: item["tipo"] == "texto"
                              ? Text(
                            _idUsuarioLogado == item["idUsuario"] ?
                            item["mensagem"] : _traducaoAtiva ?
                            item["mensagemTraduzida"] : item["mensagem"],
                            style: TextStyle(fontSize: 18),
                          )
                              : Image.network(item["urlImagem"]),
                        ),
                      ),
                    );
                  },
                ),
              );
            }
            break;
        }
      },
    );

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: Transform.translate(
          offset: Offset(-10, 0),
          child: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        titleSpacing: -20,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            CircleAvatar(
              maxRadius: 20,
              backgroundColor: Colors.grey,
              backgroundImage: widget.contato.urlImagem != null
                  ? NetworkImage(widget.contato.urlImagem)
                  : null,
            ),
            Padding(
              padding: EdgeInsets.only(left: 18),
              child: Text(widget.contato.nome),
            ),
          ],
        ),
        actions: <Widget>[
          Row(
            children: <Widget>[
              Text(
                getTraducao(context, "mensagens_traducao"),
                style: TextStyle(
                  fontSize: 16,
                ),
              ),
              Switch(
                value: _traducaoAtiva,
                onChanged: (bool e){
                  setState(() {
                    _traducaoAtiva = e;
                  });
                },
                activeColor: Colors.lightBlue[100],
              ),
            ],
          ),
        ],
      ),
      body: Container(
        width: MediaQuery.of(context).size.width,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage("imagens/bg.png"),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
            child: Container(
              padding: EdgeInsets.all(8),
              child: Column(
                children: <Widget>[
                  stream,
                  caixaMensagem,
                ],
              ),
            )),
      ),
    );
  }
}
