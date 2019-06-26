import 'package:flutter/material.dart';
import 'package:clinica_org/models/paciente.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:async';
import 'package:clinica_org/models/atendimento.dart';

class CadPaciente extends StatefulWidget {

  CadPaciente({Key key, this.userId, }) : super(key: key);
  final String userId;

  @override
  State<StatefulWidget> createState() => new _CadPacienteState();

}

class _CadPacienteState extends State<CadPaciente> {

  List<Atendimento> _items = [
    Atendimento( nome: "Endo" ),
    Atendimento( nome: "Protese")
  ];

  static List<String> _atendimentos = <String>['','Endo', 'Protese'];
  String _atendimento = "";

  TextEditingController _Nome = new TextEditingController();
  TextEditingController _Telefone = new TextEditingController();
  final GlobalKey<FormState> _formKey = new GlobalKey<FormState>();

  final FirebaseDatabase _database = FirebaseDatabase.instance;
  StreamSubscription<Event> _onModelAddedSubscription;
  StreamSubscription<Event> _onModelChangedSubscription;
  //StreamSubscription<Event> _onModelDeleteSubscription;

  int _selectedDrawerIndex = 0 ;

  Paciente _model = new Paciente();

  List<Paciente> _modelList;

  Query _modelQuery;

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
  }

  _addNewModel(Paciente model) {
      _database.reference().child("paciente").push().set(model.toJson());
  }
  _updateModel(Paciente model){
    //Toggle completed

    if (model != null) {
      _database.reference().child("paciente").child(model.key).set(model.toJson());
    }
  }

  _deleteModel(String modelId, int index) {
    _database.reference().child("paciente").child(modelId).remove().then((_) {
      setState(() {
        _modelList.removeAt(index);
      });
    });
  }

  bool submit() {
    // First validate form.
    if (this._formKey.currentState.validate() &&  _atendimento.compareTo("") != false) {
        _formKey.currentState.save(); // Save our form now.
        _formKey.currentState.reset();
        _model.alunoId = widget.userId;

        if(_model.key == "") {
          if (_atendimento.compareTo("") == false)
                _addNewModel(_model);
        }
         else
          _updateModel(_model);

        _model = Paciente();
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
    _modelQuery = _database
        .reference()
        .child("paciente")
        .orderByChild("alunoId")
        .equalTo(widget.userId);

    _onModelAddedSubscription = _modelQuery.onChildAdded.listen(_onModelAdded);
    _onModelChangedSubscription = _modelQuery.onChildChanged.listen(_onModelChanged);
    //_onModelDeleteSubscription = _modelQuery.onChildRemoved.listen(_onModelRemove);
  }

  @override
  void dispose() {
    _onModelAddedSubscription.cancel();
    _onModelChangedSubscription.cancel();
   // _onModelDeleteSubscription.cancel();

    super.dispose();
  }
  _onModelChanged(Event event) {
    var oldEntry = _modelList.singleWhere((entry) {
      return entry.key == event.snapshot.key;
    });
    setState(() {
      _modelList[_modelList.indexOf(oldEntry)] =
          Paciente.fromSnapshot(event.snapshot);
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
      _modelList.add(Paciente.fromSnapshot(event.snapshot));
    });
  }

  _editarModel(Paciente model){
    print(model.nome);
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
            String nome = _modelList[index].nome;
            String telefone = _modelList[index].telefone;
            String atendimento = _modelList[index].atendimento;

            return Dismissible(
              key: Key(modelId),
              background: Container(color: Colors.red),
              onDismissed: (direction) async {
                 _deleteModel(modelId, index);
              },
              child: ListTile(
                title: Text(
                  nome,
                  style: TextStyle(fontSize: 20.0),
                ),
                subtitle: Text(
                  telefone +"\n"+ atendimento,
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


  Widget _showCadEdt(BuildContext context) {

      if(_model.key != "") {
        _Nome.text = _model.nome;
        _Telefone.text = _model.telefone;
        _atendimento = _model.atendimento;
      }else{
        _Nome.text = "";
        _Telefone.text = "";
        _atendimento = "";
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
                    controller : _Nome,
                    decoration: const InputDecoration(
                      icon: const Icon(Icons.person),
                      hintText: 'Nome Paciente',
                      labelText: 'Name',
                    ),
                    validator: (value) => value.isEmpty ? 'Digite o Nome do paciente' : null,
                    onSaved: (String value) {
                      this._model.nome = value;
                    }
                ),
                new TextFormField(
                  controller : _Telefone,
                  decoration: const InputDecoration(
                    icon: const Icon(Icons.phone),
                    hintText: 'Telefone',
                    labelText: 'Telefone',
                  ),
                  validator: (value) => value.isEmpty ? 'Digite o Telefone' : null,
                  onSaved: (String value) {
                    this._model.telefone = value;
                  },
                  keyboardType: TextInputType.phone,
                  //inputFormatters: [WhitelistingTextInputFormatter.digitsOnly,],
                ),
                new FormField(
                        validator: (value) => (_atendimentos.length == 0 ) ? 'Coloque o Atendimento' : null,
                        builder: (FormFieldState state) {
                        return InputDecorator(
                        decoration: InputDecoration(
                        icon: const Icon(Icons.add_alert),
                        labelText: 'Atendimento',
                        ),

                        child: new DropdownButtonHideUnderline(
                        child: new DropdownButton(
                        value: _atendimento,
                        isDense: true,
                        onChanged: (String newValue) {
                          _atendimento = newValue;
                          this._model.atendimento = _atendimento;
                          state.didChange(newValue);
                        },

                        items: _atendimentos.map((String value) {
                        return new DropdownMenuItem(
                        value: value,
                        child: new Text(value),
                        );
                        }).toList(),
                        ),
                        ),
                        );
                        },
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
                    onPressed: () => { _onSelectItem(0), _model = new Paciente()},
                    color: Colors.black26,
                  ),

                  margin: new EdgeInsets.only(
                      top: 20.0
                  ),
                )
              ],
            )));
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text('Cadastro de Paciente'),
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