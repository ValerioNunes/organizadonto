import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_calendar_carousel/flutter_calendar_carousel.dart' show CalendarCarousel;
import 'package:flutter_calendar_carousel/classes/event.dart' ;
import 'package:flutter_calendar_carousel/classes/event_list.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:clinica_org/models/agenda.dart';
import 'package:clinica_org/models/paciente.dart';
import 'package:clinica_org/models/aluno.dart';

import 'package:firebase_database/firebase_database.dart' as fb;

class Calendario extends StatefulWidget {
  Calendario({Key key, this.userId, this.Fimclinica}) : super(key: key);

  final String userId;
  final TextEditingController Fimclinica;

  @override
  _CalendarioState createState() => new _CalendarioState();
}

class _CalendarioState extends State<Calendario> {

  EventList<Event> _markedDateMap = new EventList<Event>();
  DateTime _currentDate = DateTime.now();
  DateTime _currentDate2 = DateTime.now();
  String _currentMonth = '';
  Agenda _model = null;

  DateTime _Inicio = new DateTime.now();
  DateTime fimclinica = new DateTime.now();
  TextEditingController _OBS = new TextEditingController();
  TextEditingController _PacienteFilter = new TextEditingController();
  TextEditingController _Data = new TextEditingController();
  TextEditingController _Paciente = new TextEditingController();
  final GlobalKey<FormState> _formKey = new GlobalKey<FormState>();
  static List<String> _turnos = <String>['','T1', 'T2','T1 + T2'];
  String _turno = '';
  String _turnofiltro = '';
  String filterPaciente = "";

  fb.Query _PacienteQuery;

  final fb.FirebaseDatabase _database = fb.FirebaseDatabase.instance;
  StreamSubscription<fb.Event> _onModelValueSubscription;
  StreamSubscription<fb.Event> _onModelAddedSubscription;
  StreamSubscription<fb.Event> _onModelChangedSubscription;
  StreamSubscription<fb.Event> _onModelDeleteSubscription;
  StreamSubscription<fb.Event> _onPacienteAddedSubscription;
  StreamSubscription<fb.Event> _onPacienteChangedSubscription;

  int _selectedDrawerIndex = 0 ;

  CalendarCarousel  _calendarCarouselNoHeader;
  List<Agenda> _modelList = null;
  List<String> _agendaDay =  new List();
  List<Paciente> _PacienteList = null;

  static Widget _MyIcon = new Container(
    decoration: new BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.all(Radius.circular(1000)),
        border: Border.all(color: Colors.red, width: 2.0)),
    child: new Icon(
      Icons.person,
      color: Colors.red,
    ),
  );

  static Widget _FimClinicaIcon = new Container(
    decoration: new BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.all(Radius.circular(1000)),
        border: Border.all(color: Colors.red, width: 2.0)),
    child: new Icon(
      Icons.assignment_turned_in,
      color: Colors.green,
    ),
  );

  static Widget _PaceiroIcon = new Container(
    decoration: new BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.all(Radius.circular(1000)),
        border: Border.all(color: Colors.amber, width: 2.0)),
    child: new Icon(
      Icons.person,
      color: Colors.amber,
    ),
  );

  StreamSubscription<fb.Event> subscription;

  @override
  void initState() {
    _modelList = new List();
    subscription  = _database.reference()
        .child("dupla")
        .orderByChild("aluno1Id")
        .equalTo(widget.userId)
        .onValue
        .listen((fb.Event event) {
      if(event.snapshot.value !=  null) {
        Map<dynamic, dynamic> map = event.snapshot.value;
        List<String> _parceiros = new List();
        _parceiros.add(widget.userId);
        map.forEach((key, value) =>
        {
        _parceiros.add(value['aluno2Id']),
        });
        for(String s in _parceiros) {
          fb.Query _modelQuery = _database.reference().child("agenda").orderByChild("alunoId").equalTo(s);
          _onModelAddedSubscription =
              _modelQuery.onChildAdded.listen(_onModelAdded);
          _onModelChangedSubscription =
              _modelQuery.onChildChanged.listen(_onModelChanged);
          _onModelDeleteSubscription = _modelQuery.onChildRemoved.listen(_onModelRemove);
        }
      }
    });

    subscription  = _database.reference()
        .child("aluno")
        .orderByChild("alunoId")
        .equalTo(widget.userId)
        .onValue
        .listen((fb.Event event) {
      if(event.snapshot.value !=  null) {
        Map<dynamic, dynamic> map = event.snapshot.value;
        fimclinica =  null;
        dynamic dias_semana = new List<bool>();

        map.forEach((key, value) =>
        {
            fimclinica = new DateTime.fromMillisecondsSinceEpoch(value["fimclinica"]),
            dias_semana  = value["dias_semana"]
        });
        if(fimclinica != null  && dias_semana != null){
          int diasFaltam = fimclinica.difference(DateTime.now()).inDays;
          int cont = 0;
          for(int i = 1; i <= (diasFaltam + 1) ; i++ ){
            (dias_semana[DateTime.now().add(new Duration( days: i)).weekday - 1]) ? cont++ : null ;
          }

          setState(() {
            _markedDateMap.add(fimclinica, new Event(
                date: fimclinica,
                title: "Fim_de_Clinica",
                icon: _FimClinicaIcon ));

          });

          widget.Fimclinica.text = (cont > 0) ? "Mais " + cont.toString() +" de Clínica(s), " + DateFormat.yMMMd().format(fimclinica) :
          " Clínica finalizada há "+ fimclinica.difference(DateTime.now()).inDays.toString() +", " + DateFormat.yMMMd().format(fimclinica);
        }

      }

    });


    _PacienteFilter = new TextEditingController();

    _PacienteFilter.addListener(() {
      setState(() {
        filterPaciente  = _PacienteFilter.text;
      });
    });

    _PacienteList = new List();
    fb.Query _PacienteQuery = _database.reference().child("paciente").orderByChild("alunoId").equalTo(widget.userId);
    _onPacienteAddedSubscription = _PacienteQuery.onChildAdded.listen(_onPacienteAdded);
    _onPacienteChangedSubscription = _PacienteQuery.onChildChanged.listen(_onPacienteChanged);

    super.initState();
  }

  @override
  void dispose() {
    if(_onModelAddedSubscription != null)
    _onModelAddedSubscription.cancel();
    if(_onModelChangedSubscription != null)
    _onModelChangedSubscription.cancel();
    if(_onModelDeleteSubscription != null)
    _onModelDeleteSubscription.cancel();
    if(subscription!= null)
    subscription.cancel();
    if(_onPacienteAddedSubscription != null)
    _onPacienteAddedSubscription.cancel();
    if(_onPacienteChangedSubscription != null)
    _onPacienteChangedSubscription.cancel();
    if(_PacienteFilter != null)
    _PacienteFilter.dispose();

    super.dispose();
  }

  _onModelChanged(fb.Event event) {
    var oldEntry = _modelList.singleWhere((entry) {
      return entry.key == event.snapshot.key;
    });
    setState(() {
      Agenda agenda = Agenda.fromSnapshot(event.snapshot);
      _onRemoverMaker(agenda);
      _modelList[_modelList.indexOf(oldEntry)] = agenda;
      _onAddMaker(agenda);

    });
  }
  _onModelRemove(fb.Event event) {
    var oldEntry = _modelList.singleWhere((entry) {
      return entry.key == event.snapshot.key;
    });
    setState(() {
      _onRemoverMaker(oldEntry);
      _modelList.remove(oldEntry);
    });
  }
  _onModelAdded(fb.Event event) {

    setState(() {
      Agenda agenda = Agenda.fromSnapshot(event.snapshot);
      _modelList.add(agenda);
      _onAddMaker(agenda);
    });
  }
  _onPacienteChanged(fb.Event event) {
    var oldEntry = _PacienteList.singleWhere((entry) {
      return entry.key == event.snapshot.key;
    });
    setState(() {
      _PacienteList[_PacienteList.indexOf(oldEntry)] =
          Paciente.fromSnapshot(event.snapshot);
    });
  }
  _onPacienteAdded(fb.Event event) {
    setState(() {
      _PacienteList.add(Paciente.fromSnapshot(event.snapshot));
    });
  }

  void _showMsg(BuildContext context, String msg) {

    showDialog(
      context: context,
      builder: (BuildContext context) {
        // return object of type Dialog
        return AlertDialog(
          title: new Text("Info"),
          content: new Text(msg),
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

  _onRemoverMaker(Agenda agenda){
    DateTime data =  DateTime(agenda.inicio.year,agenda.inicio.month,agenda.inicio.day);
    Widget icon = (widget.userId == agenda.alunoId ) ?  _MyIcon : _PaceiroIcon;

    _markedDateMap.remove(
        data,
        new Event(
          date: data,
          title: agenda.atendimento,
          icon: icon,
        ));
  }
  _onAddMaker(Agenda agenda){

    DateTime data =  DateTime(agenda.inicio.year,agenda.inicio.month,agenda.inicio.day);
    Widget icon = (widget.userId == agenda.alunoId ) ?  _MyIcon : _PaceiroIcon;

    _markedDateMap.add(
        data,
        new Event(
          date: data,
          title: agenda.atendimento,
          icon: icon,
        ));
  }

  bool _compareDia(DateTime a,  DateTime b){
    if(a == null || b == null)
      return false;
    if(a.day != b.day)
      return false;
    if(a.month != b.month)
      return false;
    if(a.year != b.year)
      return false;
    return true;
  }

  _onSelectItem(int index) {
    _PacienteFilter.text = "";
    _Paciente.text = "";
    _OBS.text = "";
    _turno = "";
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
        //_onRemoverMaker(_modelList[index]);
        //_modelList.remove(_modelList[index]);
      });
    });
  }

  _editarModel(Agenda model){
    print(model.pacienteId);
    _model = model;
    _onSelectItem(1);
  }

  bool submit() {
    // First validate form.
    if (this._formKey.currentState.validate() && _model.pacienteId != null ) {
      _formKey.currentState.save(); // Save our form now.
      _formKey.currentState.reset();
      _model.alunoId = widget.userId;

      _model.inicio = _currentDate2;
      _model.fim = _currentDate2;

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

  Widget _showModelList() {

    if (_modelList !=  null && _modelList.length > 0) {
      _agendaDay.clear();
      return ListView.builder(
          shrinkWrap: true,

          itemCount: _modelList.length,
          itemBuilder: (BuildContext context, int index) {
            String   modelId      = _modelList[index].key;
            String   nomePaciente = _modelList[index].pacientenome +"\nTurno: "+ _modelList[index].turno;
            DateTime data         = _modelList[index].inicio;
            String   obs          = _modelList[index].obs;
            String   atendimento  = ( obs != "") ? _modelList[index].atendimento + " , OBS: " + obs :  _modelList[index].atendimento;

            if( _compareDia(data,_currentDate2))
              _agendaDay.add(_modelList[index].turno);

            return ( _compareDia(data,_currentDate2))? (_modelList[index].alunoId == widget.userId) ?

            Dismissible(
              key: Key(modelId),
              background: Container(color: Colors.red),
              onDismissed: (direction) async {
                _deleteModel(modelId, index);
              },
              child: ListTile(
                title: Text(
                  nomePaciente,
                  style: TextStyle(color:Colors.red, fontSize: 15.0 ,fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  atendimento ,
                  style: TextStyle(fontSize: 13.0),
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
            ):
            ListTile(
                title: Text(
                  nomePaciente,
                  style: TextStyle(color:Colors.amber, fontSize: 15.0 ,fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  atendimento,
                  style: TextStyle(fontSize: 13.0),
                ),

            ) : Container();
          });
    } else {
      return Center(child: Text("Nenhum Atendimento",
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 30.0),));
    }
  }

  _setModel(Paciente paciente){

    _model.pacienteId = paciente.key;
    _model.pacientenome = paciente.nome;
    _model.atendimento = paciente.atendimento;
    _PacienteFilter.text = paciente.nome;
    _Paciente.text = paciente.nome;
  }

  Widget _showPacienteList() {

    if (_PacienteList !=  null) {
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
                new TextFormField(
                  controller : _Data,
                  enabled: false,
                  decoration: const InputDecoration(
                    icon: const Icon(Icons.calendar_today),
                    hintText: 'Data',
                    labelText:'Data',
                  ),
                  keyboardType: TextInputType.text,
                  //inputFormatters: [WhitelistingTextInputFormatter.digitsOnly,],
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

                            return   new DropdownMenuItem(
                              value: value,
                              child: (_turnofiltro != value) ? new Text(value) : new Text("") ,
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

  Widget _showCalendario() {
    return SingleChildScrollView(
      child: Column(
        children: <Widget>[
          Container(
            child: new Row(
              children: <Widget>[
                RaisedButton(
                  child: Text('PREV'),
                  color: Colors.amber,
                  onPressed: () {
                    setState(() {
                      _currentDate2 = _currentDate2.subtract(Duration(days: 30));
                      _currentMonth =DateFormat.yMMM().format(_currentDate2);
                    });
                  },
                ),
                Expanded(
                    child: Center(child: Text(_currentMonth, style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15.0)),
                    )),
                RaisedButton(
                  child: Text('NEXT'),
                  color: Colors.amber,
                  onPressed: () {
                    setState(() {
                      _currentDate2 = _currentDate2.add(Duration(days: 30));
                      _currentMonth = DateFormat.yMMM().format(_currentDate2);
                    });
                  },
                )
              ],
            ),
          ),
          Container(
            child: _calendarCarouselNoHeader,
          ),
          Container(child: _showModelList(),
            width: 300,
            alignment: Alignment.bottomRight,)
        ],
      ),
    );
  }

  _getDrawerItemWidget(int pos,BuildContext context) {
    switch (pos) {
      case 0:
        return _showCalendario() ;
      case 1:
        return _showCadEdt(context);
      default:
        return new Text("Error");
    }
  }

    @override
    Widget build(BuildContext context) {
      _calendarCarouselNoHeader = CalendarCarousel<Event>(
        todayBorderColor: Colors.green,
        onDayPressed: (DateTime date, List<Event> events) {
          this.setState(() =>{ _currentDate2 = date });
          events.forEach((event) => print(event.title));
          _Data.text = DateFormat.yMMMd().format(date);
        },
        weekendTextStyle: TextStyle( color: Colors.red,),
        thisMonthDayBorderColor: Colors.grey,
        weekFormat: false,
        markedDatesMap: _markedDateMap,
        height: 300.0,
        selectedDateTime: _currentDate2,
        markedDateShowIcon: true,
        markedDateIconMaxShown: 2,
        markedDateMoreShowTotal:false, // null for not showing hidden events indicator
        showHeader: false,
        markedDateIconBuilder: (event) {
          return event.icon;
        },
        todayTextStyle: TextStyle(
          color: Colors.blue,
        ),
        todayButtonColor: Colors.yellow,
        selectedDayTextStyle: TextStyle(color: Colors.yellow,),
        minSelectedDate: fimclinica.subtract(Duration(days: 90)),
        maxSelectedDate: fimclinica,
        //inactiveDateColor: Colors.black12,
        onCalendarChanged: (DateTime date) {
          this.setState(() => _currentMonth = DateFormat.yMMM().format(date));
        },
      );

      return new Scaffold(
          body:  _getDrawerItemWidget(_selectedDrawerIndex,context),
          floatingActionButton: FloatingActionButton(
              tooltip: 'Increment',
              child: Icon(Icons.add),
              onPressed: (){
                if( _agendaDay.length < 2 && !_agendaDay.contains(_turnos[3])) {
                  _model = new Agenda();
                  _onSelectItem(1);
                }
                else
                  _showMsg(context, "Ops, Não tem mais Vaga !");
              }
          ));
    }
  }
