import 'package:flutter/material.dart';
import 'package:clinica_org/models/aluno.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:async';
import 'package:intl/intl.dart' show DateFormat;
import 'package:clinica_org/models/datetimeitem.dart';

class CadAluno extends StatefulWidget {
  CadAluno({Key key, this.userId,this.Fimclinica }) : super(key: key);
  final String userId;
  final TextEditingController Fimclinica;

  @override
  State<StatefulWidget> createState() => new _CadAlunoState();
}

class _CadAlunoState extends State<CadAluno> {

  final GlobalKey<FormState> _formKey = new GlobalKey<FormState>();

  final FirebaseDatabase _database = FirebaseDatabase.instance;
  StreamSubscription<Event> _onModelValueSubscription;
  StreamSubscription<Event> _onModelsValueSubscription;

  int _selectedDrawerIndex = 0 ;

  Aluno _model;
  List<Aluno> _modelList;
  Query _modelQuery;

  TextEditingController _Nome = new TextEditingController();
  DateTime _DateTime = new DateTime.now();
  dynamic _DiaSemana = <bool>[false,false,false,false,false,false,false];

  _onSelectItem(int index) {
    setState(() => _selectedDrawerIndex = index);
    print(_selectedDrawerIndex);
  }

  _addNewModel(Aluno model) {
    _database.reference().child("aluno").push().set(model.toJson());
  }
  _updateModel(Aluno model){
    if (model != null) {
      _database.reference().child("aluno").child(_model.key).set(model.toJson());
    }
  }
  _deleteModel(String modelId, int index) {
    _database.reference().child("aluno").child(modelId).remove().then((_) {
      setState(() {
        _modelList.removeAt(index);
      });
    });
  }

  bool submit() {
    // First validate form.
    if (this._formKey.currentState.validate()) {
      _formKey.currentState.save(); // Save our form now.

      _model.alunoId = widget.userId;
      _model.fimclinica = _DateTime;
      _model.dias_semana = _DiaSemana;

      if(_model.key == "")
        _addNewModel(_model);
      else
        _updateModel(_model);

      return true;
    }
    return false;
  }StreamSubscription<Event> subscription;
 void _updateFimClinica() {
   subscription = _database
       .reference()
       .child("aluno")
       .orderByChild("alunoId")
       .equalTo(widget.userId)
       .onValue
       .listen((Event event) {
     if (event.snapshot.value != null) {
       Map<dynamic, dynamic> map = event.snapshot.value;
       DateTime fimclinica = null;
       dynamic dias_semana = new List<bool>();

       map.forEach((key, value) =>
       {
       fimclinica =
       new DateTime.fromMillisecondsSinceEpoch(value["fimclinica"]),
       dias_semana = value["dias_semana"]
       });
       if (fimclinica != null && dias_semana != null) {
         int diasFaltam = fimclinica
             .difference(DateTime.now())
             .inDays;
         int cont = 0;
         for (int i = 1; i <= (diasFaltam + 1); i++) {
           (dias_semana[DateTime
               .now()
               .add(new Duration(days: i))
               .weekday - 1]) ? cont++ : null;
         }

         widget.Fimclinica.text =
         (cont > 0) ? "Mais " + cont.toString() + " de Clínica(s), " +
             DateFormat.yMMMd().format(fimclinica) :
         " Clínica finalizada há " + fimclinica
             .difference(DateTime.now())
             .inDays
             .toString() + ", " +
             DateFormat.yMMMd().format(fimclinica);
       }
     }
   });
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

    if(_model == null) {
      _model = new Aluno();
    }
    _modelQuery = _database
        .reference()
        .child("aluno")
        .orderByChild("alunoId")
        .equalTo(widget.userId);
     _onModelValueSubscription = _modelQuery.onValue.listen(_onModelValue);

  }

  @override
  void dispose() {
     _onModelValueSubscription.cancel();
    super.dispose();
  }
  _onModelValue(Event event) {
    setState(() {
            if(event.snapshot.value !=  null) {
              Map<dynamic, dynamic> map = event.snapshot.value;
              map.forEach((key, value) =>
              {
              _model.key = key,
              _model.nome = value['nome'],
              _model.alunoId = value['alunoId'],
              _model.fimclinica =  new DateTime.fromMillisecondsSinceEpoch(value['fimclinica']),
              _model.dias_semana = value['dias_semana']
              });
              _Nome.text  = _model.nome;
              _DateTime   =  _model.fimclinica;
              _DiaSemana  = _model.dias_semana;
            }
      });
  }

  Widget _showCadEdt() {

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
                      hintText: 'Nome aluno',
                      labelText: 'Name',
                    ),
                    validator: (value) => value.isEmpty ? 'Digite seu Nome' : null,
                    onSaved: (String value) {
                      this._model.nome = value;
                    }
                ),
                new Container(
                     child: new Text(
                        'Fim da Clínica:',
                        style: DefaultTextStyle.of(context).style.apply(fontSizeFactor: 1.5),
                      ),
                    margin: new EdgeInsets.only(
                        top: 20.0
                    )
                ),
                new ListTile(

                  leading: new Icon(Icons.today, color: Colors.grey[500]),
                  title: new DateTimeItem(
                    dateTime: _DateTime,
                    onChanged: (dateTime) => setState(() =>  _DateTime = dateTime),
                  ),
                ),
                new Container(
                    child: new Text(
                      'Dias de Atuação:',
                      style: DefaultTextStyle.of(context).style.apply(fontSizeFactor: 1.2),
                    ),
                    margin: new EdgeInsets.only(
                        top: 20.0
                    )
                ),
                new Container(
                    child: new Column(
                      children: <Widget>[
                        new CheckboxListTile( value: _DiaSemana[6],onChanged:(bool value) {  setState(() => _DiaSemana[6] = value );  },title: new Text('Dom'),activeColor: Colors.red),
                        new CheckboxListTile( value: _DiaSemana[0],onChanged:(bool value) {  setState(() => _DiaSemana[0] = value );  },title: new Text('Seg'),activeColor: Colors.red),
                        new CheckboxListTile( value: _DiaSemana[1],onChanged:(bool value) {  setState(() => _DiaSemana[1] = value );  },title: new Text('Ter'),activeColor: Colors.red),
                        new CheckboxListTile( value: _DiaSemana[2],onChanged:(bool value) {  setState(() => _DiaSemana[2] = value );  },title: new Text('Qua'),activeColor: Colors.red),
                        new CheckboxListTile( value: _DiaSemana[3],onChanged:(bool value) {  setState(() => _DiaSemana[3] = value );  },title: new Text('Qui'),activeColor: Colors.red),
                        new CheckboxListTile( value: _DiaSemana[4],onChanged:(bool value) {  setState(() => _DiaSemana[4] = value );  },title: new Text('Sex'),activeColor: Colors.red),
                        new CheckboxListTile( value: _DiaSemana[5],onChanged:(bool value) {  setState(() => _DiaSemana[5] = value );  },title: new Text('Sab'),activeColor: Colors.red),
                      ],
                    ),
                ),
                new Container(
                  child: new RaisedButton(
                    child: new Text(
                      'Salvar',
                      style: new TextStyle(
                          color: Colors.white
                      ),
                    ),
                    onPressed: () => (submit()) ? _showVerifyEmailDialog(context) : null,
                    color: Colors.blue,
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
          title: new Text('Editar Conta'),
        ),
        body: _showCadEdt(),
    );
  }
}