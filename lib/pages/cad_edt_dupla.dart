import 'package:flutter/material.dart';
import 'package:clinica_org/models/dupla.dart';
import 'package:clinica_org/models/aluno.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:async';
import 'package:clinica_org/models/atendimento.dart';


class CadDupla extends StatefulWidget {
  CadDupla({Key key, this.userId, }) : super(key: key);
  final String userId;

  @override
  State<StatefulWidget> createState() => new _CadDuplaState();
}

class _CadDuplaState extends State<CadDupla> {


  final GlobalKey<FormState> _formKey = new GlobalKey<FormState>();

  final FirebaseDatabase _database = FirebaseDatabase.instance;
  StreamSubscription<Event> _onModelAddedSubscription;
  StreamSubscription<Event> _onModelChangedSubscription;
  StreamSubscription<Event> _onAlunoAddedSubscription;
  StreamSubscription<Event> _onAlunoChangedSubscription;
  //StreamSubscription<Event> _onModelDeleteSubscription;


  TextEditingController _Aluno2Id = new TextEditingController();
  int _selectedDrawerIndex = 0 ;

  Dupla _model = new Dupla();

  List<Dupla> _modelList = null;
  List<Aluno> _AlunoList = null;

  Query _modelQuery;
  Query _AlunoQuery;

  _getDrawerItemWidget(int pos,BuildContext context) {
    switch (pos) {
      case 0:
        return  _showModelList() ;
      case 1:
        return _showCadEdt(context);
      default:
        return new Text("Error");
    }
  }
  _onSelectItem(int index) {
    setState(() => _selectedDrawerIndex = index);
    print(_selectedDrawerIndex);
  }


  _addNewModel(Dupla model) {
    _database.reference().child("dupla").push().set(model.toJson());
  }
  _updateModel(Dupla model){
    //Toggle completed

    if (model != null) {
      _database.reference().child("dupla").child(model.key).set(model.toJson());
    }
  }

  _deleteModel(String modelId, int index) {
    _database.reference().child("dupla").child(modelId).remove().then((_) {
      setState(() {
        _modelList.removeAt(index);
      });
    });
  }

  bool submit() {
    // First validate form.
    if (this._formKey.currentState.validate()) {
      _formKey.currentState.save(); // Save our form now.
      _formKey.currentState.reset();
      _model.aluno1Id = widget.userId;

      if(_model.key == "")
        _addNewModel(_model);
      else
        _updateModel(_model);

      _model = Dupla();
      _onSelectItem(0);
      return true;
    }
    return false;
  }

  void _showVerifyEmailDialog(BuildContext context) {

    showDialog(
      context: context,
      builder: (BuildContext context) {
        // return object of type Dialog
        return AlertDialog(
          title: new Text("Info"),
          content: new Text("Salvo com Sucesso"),
          actions: <Widget>[
            new FlatButton(
              child: new Text("OK"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  void initState() {

    super.initState();

    _modelList = new List();
    _modelQuery = _database.reference().child("dupla").orderByChild("aluno1Id").equalTo(widget.userId);

    _onModelAddedSubscription = _modelQuery.onChildAdded.listen(_onModelAdded);
    _onModelChangedSubscription = _modelQuery.onChildChanged.listen(_onModelChanged);
    //_onModelDeleteSubscription = _modelQuery.onChildRemoved.listen(_onModelRemove);

    _AlunoList = new List();
    _AlunoQuery = _database.reference().child("aluno");

     _onAlunoAddedSubscription = _AlunoQuery.onChildAdded.listen(_onAlunoAdded);
    _onAlunoChangedSubscription = _AlunoQuery.onChildChanged.listen(_onAlunoChanged);
    //_onModelDeleteSubscription = _modelQuery.onChildRemoved.listen(_onModelRemove);
  }

  @override
  void dispose() {
    _onModelAddedSubscription.cancel();
    _onModelChangedSubscription.cancel();
    _onAlunoAddedSubscription.cancel();
    _onAlunoChangedSubscription.cancel();
    // _onModelDeleteSubscription.cancel();

    super.dispose();
  }
  _onModelChanged(Event event) {
    var oldEntry = _modelList.singleWhere((entry) {
      return entry.key == event.snapshot.key;
    });
    setState(() {
      _modelList[_modelList.indexOf(oldEntry)] =
          Dupla.fromSnapshot(event.snapshot);
    });
  }
  _onModelRemove(Event event) {
    var oldEntry = _modelList.singleWhere((entry) {
      return entry.key == event.snapshot.key;
    });
    setState(() {
      _modelList.remove(oldEntry);
    });
  }
  _onModelAdded(Event event) {
    setState(() {
      _modelList.add(Dupla.fromSnapshot(event.snapshot));
    });
  }

  _onAlunoChanged(Event event) {
    var oldEntry = _AlunoList.singleWhere((entry) {
      return entry.key == event.snapshot.key;
    });
    setState(() {
      _AlunoList[_AlunoList.indexOf(oldEntry)] =
          Aluno.fromSnapshot(event.snapshot);
    });
  }
  _onAlunoRemove(Event event) {
    var oldEntry = _AlunoList.singleWhere((entry) {
      return entry.key == event.snapshot.key;
    });
    setState(() {
      _AlunoList.remove(oldEntry);
    });
  }
  _onAlunoAdded(Event event) {
    setState(() {
      _AlunoList.add(Aluno.fromSnapshot(event.snapshot));
    });
  }

 _setModel(Aluno parceiro){
    print(parceiro.nome);
    _Aluno2Id.text = parceiro.nome;
    _model.aluno2Id = parceiro.alunoId;
 }
  _editarModel(Dupla model){
    print(model.aluno1Id);
    _model = model;
    _onSelectItem(1);
  }

  Widget _showModelList() {
    if (_modelList !=  null) {
      return ListView.builder(
          shrinkWrap: true,
          itemCount: _modelList.length,
          itemBuilder: (BuildContext context, int index) {
            String modelId = _modelList[index].key;
            String nomealuno2 = _modelList[index].nomealuno2;
            String aluno2Id = _modelList[index].aluno2Id;
            return Dismissible(
              key: Key(modelId),
              background: Container(color: Colors.red),
              onDismissed: (direction) async {
                _deleteModel(modelId, index);
              },
              child: ListTile(
                title: Text(
                  nomealuno2,
                  style: TextStyle(fontSize: 20.0),
                ),
                subtitle: Text(
                  aluno2Id,
                  style: TextStyle(fontSize: 10.0),
                ),
                trailing: IconButton(
                    icon: Icon(
                      Icons.edit,
                      color: Colors.green,
                      size: 20.0,
                    ),
                    onPressed: () {
                      _editarModel(_modelList[index]);
                    }),
              ),
            );
          });
    } else {
      return Center(child: Text("Welcome. Your list is empty",
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 30.0),));
    }
  }

  Widget _showAlunoList() {
    if (_modelList !=  null) {
      return ListView.builder(
          shrinkWrap: true,
          itemCount: _AlunoList.length,
          itemBuilder: (BuildContext context, int index) {
            String modelId  = _AlunoList[index].key;
            String alunoId = _AlunoList[index].alunoId;
            String nome = _AlunoList[index].nome;
            return (alunoId != widget.userId) ?
            ListTile(
                title: Text(
                  nome,
                  style: TextStyle(fontSize: 20.0),
                ),
                subtitle: Text(
                  alunoId ,
                  style: TextStyle(fontSize: 10.0),
                ),
                trailing: IconButton(
                    icon: Icon(
                      Icons.add,
                      color: Colors.green,
                      size: 20.0,
                    ),
                    onPressed: () {
                     this._setModel(_AlunoList[index]);
                    }),
            ) : new Container();
          });
    } else {
      return Center(child: Text("Welcome. Your list is empty",
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 30.0),));
    }
  }

  Widget _showCadEdt(BuildContext context) {
    if(_model.key != "") {
      _Aluno2Id.text = _model.aluno2Id;
    }
    return new SafeArea(
        top: false,
        bottom: false,
        child: new Form(
            key: this._formKey,
            autovalidate: true,
            child: new ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              children: <Widget>[
                new TextFormField(
                  controller : _Aluno2Id,
                  enabled: false,
                  decoration: const InputDecoration(
                    icon: const Icon(Icons.person_add),
                    hintText: 'Parceiro',
                    labelText:'Parceiro',
                  ),
                  validator: (value) => value.isEmpty ? 'Digite o Parceiro' : null,
                  onSaved: (String value) {
                    this._model.nomealuno2 = value;
                  },
                  keyboardType: TextInputType.text,
                  //inputFormatters: [WhitelistingTextInputFormatter.digitsOnly,],
                ),
                new Container(

                  child: new RaisedButton(
                    child: new Text(
                      'Salvar',
                      style: new TextStyle(
                          color: Colors.white
                      ),
                    ),
                    onPressed: () => (submit()),
                    color: Colors.blue,
                  ),

                  margin: new EdgeInsets.only(
                      top: 20.0
                  ),
                ),
                new Container(

                  child: new RaisedButton(
                    child: new Text(
                      'Voltar',
                      style: new TextStyle(
                          color: Colors.white
                      ),
                    ),
                    onPressed: () =>  _onSelectItem(0),
                    color: Colors.black26,
                  ),

                  margin: new EdgeInsets.only(
                      top: 20.0
                  ),
                ),
                _showAlunoList(),
              ],
            )));
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
        appBar: new AppBar(
          title: new Text('Cadastro de Dupla'),
        ),
        body: _getDrawerItemWidget(_selectedDrawerIndex,context),
        floatingActionButton: FloatingActionButton(
            tooltip: 'Increment',
            child: Icon(Icons.add),
            onPressed:() => {
            _onSelectItem(1)
            }
        )
    );
  }
}