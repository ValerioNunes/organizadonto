import 'package:flutter/material.dart';
import 'package:clinica_org/models/agenda.dart';
import 'package:clinica_org/models/paciente.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:async';
import 'package:clinica_org/models/datetimeitem.dart';
import 'package:intl/intl.dart' show DateFormat;

class CadAgenda extends StatefulWidget {
  CadAgenda({Key key, this.userId, }) : super(key: key);
  final String userId;

  @override
  State<StatefulWidget> createState() => new _CadAgendaState();
}

class _CadAgendaState extends State<CadAgenda> {


  final GlobalKey<FormState> _formKey = new GlobalKey<FormState>();

  DateTime _Inicio = new DateTime.now();
  DateTime _currentDate = new DateTime.now();

  TextEditingController _OBS = new TextEditingController();
  TextEditingController _PacienteFilter = new TextEditingController();
  TextEditingController _Paciente = new TextEditingController();


  final FirebaseDatabase _database = FirebaseDatabase.instance;
  StreamSubscription<Event> _onModelAddedSubscription;
  StreamSubscription<Event> _onModelChangedSubscription;
  StreamSubscription<Event> _onPacienteAddedSubscription;
  StreamSubscription<Event> _onPacienteChangedSubscription;
  //StreamSubscription<Event> _onModelDeleteSubscription;
  String filterPaciente = "";


  int _selectedDrawerIndex = 0 ;

  Agenda _model = new Agenda();

  List<Agenda> _modelList = null;
  List<Paciente> _PacienteList = null;


  Query _modelQuery;
  Query _PacienteQuery;

  static List<String> _turnos = <String>['','T1', 'T2','T1 + T2'];
  String _turno = '';

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
    _PacienteFilter.text = "";
    _Paciente.text = "";
    _OBS.text = "";
    setState(() => _selectedDrawerIndex = index);
  }
  _addNewModel(Agenda model) {
    _database.reference().child("agenda").push().set(model.toJson());
  }
  _updateModel(Agenda model){
    //Toggle completed
    if (model != null) {
      _database.reference().child("agenda").child(model.key).set(model.toJson());
    }
  }

  _deleteModel(String modelId, int index) {
    _database.reference().child("agenda").child(modelId).remove().then((_) {
      setState(() {
        _modelList.removeAt(index);
      });
    });
  }

  bool submit() {
    // First validate form.
    if (this._formKey.currentState.validate() && _model.pacienteId != null ) {
      _formKey.currentState.save(); // Save our form now.
      _formKey.currentState.reset();
      _model.alunoId = widget.userId;

      _model.inicio = _Inicio;
      _model.fim = _Inicio;

      if(_model.key == "")
        _addNewModel(_model);
      else
        _updateModel(_model);

      _model = Agenda();
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

    _modelList = new List();
    _modelQuery = _database.reference().child("agenda").orderByChild("alunoId").equalTo(widget.userId);


    _onModelAddedSubscription = _modelQuery.onChildAdded.listen(_onModelAdded);
    _onModelChangedSubscription = _modelQuery.onChildChanged.listen(_onModelChanged);
    //_onModelDeleteSubscription = _modelQuery.onChildRemoved.listen(_onModelRemove);

    _PacienteFilter = new TextEditingController();

    _PacienteFilter.addListener(() {
      setState(() {
        filterPaciente  = _PacienteFilter.text;
      });
    });

    _PacienteList = new List();
    _PacienteQuery = _database.reference().child("paciente").orderByChild("alunoId").equalTo(widget.userId);


    _onPacienteAddedSubscription = _PacienteQuery.onChildAdded.listen(_onPacienteAdded);
    _onPacienteChangedSubscription = _PacienteQuery.onChildChanged.listen(_onPacienteChanged);
    //_onModelDeleteSubscription = _modelQuery.onChildRemoved.listen(_onModelRemove);
    super.initState();
  }

  @override
  void dispose() {
    _onModelAddedSubscription.cancel();
    _onModelChangedSubscription.cancel();
    _onPacienteAddedSubscription.cancel();
    _onPacienteChangedSubscription.cancel();
    _PacienteFilter.dispose();
    // _onModelDeleteSubscription.cancel();
    super.dispose();
  }
  _onModelChanged( Event event) {
    var oldEntry = _modelList.singleWhere((entry) {
      return entry.key == event.snapshot.key;
    });
    setState(() {
      _modelList[_modelList.indexOf(oldEntry)] = Agenda.fromSnapshot(event.snapshot);

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
      _modelList.add(Agenda.fromSnapshot(event.snapshot));
    });
  }

  _onPacienteChanged(Event event) {
    var oldEntry = _PacienteList.singleWhere((entry) {
      return entry.key == event.snapshot.key;
    });
    setState(() {
      _PacienteList[_PacienteList.indexOf(oldEntry)] =
          Paciente.fromSnapshot(event.snapshot);
    });
  }
  _onPacienteRemove(Event event) {
    var oldEntry = _PacienteList.singleWhere((entry) {
      return entry.key == event.snapshot.key;
    });
    setState(() {
      _PacienteList.remove(oldEntry);
    });
  }
  _onPacienteAdded(Event event) {
    setState(() {
      _PacienteList.add(Paciente.fromSnapshot(event.snapshot));
    });
  }
  _setModel(Paciente paciente){

    _model.pacienteId = paciente.key;
    _model.pacientenome = paciente.nome;
    _model.atendimento = paciente.atendimento;
    _PacienteFilter.text = paciente.nome;
    _Paciente.text = paciente.nome;
  }
  _editarModel(Agenda model){
    print(model.pacienteId);
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
            String atendimento = _modelList[index].atendimento;
            String obs = _modelList[index].obs;
            String nomePaciente = _modelList[index].pacientenome;
            DateTime inicio = _modelList[index].inicio;

            return Dismissible(
              key: Key(modelId),
              background: Container(color: Colors.red),
              onDismissed: (direction) async {
                _deleteModel(modelId, index);
              },
              child: ListTile(
                title: Text(
                   DateFormat.yMMMd().format(inicio),
                  style: TextStyle(fontSize: 25.0),
                ),
                subtitle: Text(
                  atendimento + ", "+ nomePaciente + "\nOBS: "+ obs ,
                  style: TextStyle(fontSize: 15.0),
                ),
              ),
            );
          });
    } else {
      return Center(child: Text("Welcome. Your list is empty",
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 30.0),));
    }
  }

  Widget _showPacienteList() {
    if (_modelList !=  null) {
      return  ListView.builder(
          shrinkWrap: true,
          itemCount: _PacienteList.length,
          itemBuilder: (BuildContext context, int index) {
            return filterPaciente == null || filterPaciente == "" ?
            new Container():
            _PacienteList[index].nome.toLowerCase().contains(filterPaciente.toLowerCase()) ?
            ListTile(
              title: Text(
                _PacienteList[index].nome,
                style: TextStyle(fontSize: 14.0),
              ),
              subtitle: Text(
                _PacienteList[index].atendimento,
                style: TextStyle(fontSize: 10.0),
              ),
              trailing: IconButton(
                  icon: Icon(
                    Icons.add,
                    color: Colors.green,
                    size: 20.0,
                  ),
                  onPressed: () {
                    this._setModel(_PacienteList[index]);
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
      _Inicio = _model.inicio;
      _OBS.text = _model.obs;
      _Paciente.text = _model.pacientenome;
      _turno = _model.turno;
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
                new Container(
                    child: new Text(
                      'Inicio:',
                      style: DefaultTextStyle.of(context).style.apply(fontSizeFactor: 1.2),
                    ),
                    margin: new EdgeInsets.only(
                        top: 20.0
                    )
                ),
                new ListTile(
                  leading: new Icon(Icons.today, color: Colors.grey[500]),
                  title: new DateTimeItem(
                    dateTime: _Inicio,
                    onChanged: (dateTime) => setState(() =>  {_Inicio = dateTime, _model.inicio =  dateTime}),
                  ),
                ),
                new FormField(
                  validator: (value) => (_turnos.length == 0 ) ? 'Coloque o Atendimento' : null,
                  builder: (FormFieldState state) {
                    return InputDecorator(
                      decoration: InputDecoration(
                        icon: const Icon(Icons.add_alert),
                        labelText: 'Atendimento',
                      ),

                      child: new DropdownButtonHideUnderline(
                        child: new DropdownButton(
                          value: _turno,
                          isDense: true,
                          onChanged: (String newValue) {
                            _turno = newValue;
                            this._model.turno = _turno;
                            state.didChange(newValue);
                          },
                          items: _turnos.map((String value) {
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
                    child: new Text(
                      'Selecionar Paciente:',
                      style: DefaultTextStyle.of(context).style.apply(fontSizeFactor: 1.2),
                    ),
                    margin: new EdgeInsets.only(
                        top: 20.0
                    )
                ),
                new TextFormField(
                  controller : _Paciente,
                  enabled: false,
                  decoration: const InputDecoration(
                    icon: const Icon(Icons.person_add),
                    hintText: 'Paciente',
                    labelText:'Paciente',
                  ),
                  onSaved: (String value) {
                    this._model.pacientenome = value;
                  },
                  keyboardType: TextInputType.text,
                  //inputFormatters: [WhitelistingTextInputFormatter.digitsOnly,],
                ),
                new Card( child : _showPacienteList()),
                new TextField(
                  decoration: new InputDecoration(
                      labelText: "Nome do Paciente",
                      icon: const Icon(Icons.search),
                      hintText: 'Digite o nome do paciente',
                  ),
                  controller: _PacienteFilter,
                ),
                new TextFormField(
                    controller : _OBS,
                    decoration: const InputDecoration(
                      icon: const Icon(Icons.announcement),
                      hintText: 'OBS',
                      labelText: 'Observação',
                    ),
                    onSaved: (String value) {
                      this._model.obs = value;
                    }
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
                    onPressed: () =>  {_onSelectItem(0),},
                    color: Colors.black26,
                  ),

                  margin: new EdgeInsets.only(
                      top: 20.0
                  ),
                ),
              ],
            )));
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
        appBar: new AppBar(
          title: new Text('Cadastro de Agenda'),
        ),
        body: _getDrawerItemWidget(_selectedDrawerIndex,context)
    );
  }
}