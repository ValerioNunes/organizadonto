import 'package:flutter/material.dart';
import 'package:clinica_org/services/authentication.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:clinica_org/models/todo.dart';
import 'package:clinica_org/pages/cad_edt_paciente.dart';
import 'package:clinica_org/pages/cad_edt_aluno.dart';
import 'package:clinica_org/pages/cad_edt_dupla.dart';
import 'package:clinica_org/pages/cad_edt_agenda.dart';
import 'package:clinica_org/pages/calendario.dart';
import 'dart:async';

class DrawerItem {
  String title;
  IconData icon;
  DrawerItem(this.title, this.icon);
}

class HomePage extends StatefulWidget {
  HomePage({Key key, this.auth, this.userId, this.onSignedOut})
      : super(key: key);


  final BaseAuth auth;
  final VoidCallback onSignedOut;
  final String userId;
  TextEditingController _FimClinica = new TextEditingController();

  @override
  State<StatefulWidget> createState() => new _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Todo> _todoList;

  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  final _textEditingController = TextEditingController();


  StreamSubscription<Event> _onTodoAddedSubscription;
  StreamSubscription<Event> _onTodoChangedSubscription;

  Query _todoQuery;

  bool _isEmailVerified = false;
  int _selectedDrawerIndex = 0;

  final drawerItems = [
    new DrawerItem("Meu Calendario", Icons.calendar_today),
    new DrawerItem("Cadastrar Paciente", Icons.person_add),
    new DrawerItem("Editar Conta", Icons.person),
    new DrawerItem("Parcerias", Icons.swap_horizontal_circle),
    new DrawerItem("Histórico", Icons.history),
  ];

  _getDrawerItemWidget(int pos) {
    switch (pos) {
      case 0:
        return new Calendario(userId: widget.userId, Fimclinica: widget._FimClinica,);
      case 1:
         return new CadPaciente(userId: widget.userId,);
      case 2:
        return new CadAluno(userId: widget.userId, Fimclinica: widget._FimClinica,);
      case 3:
        return new CadDupla(userId: widget.userId,);
      case 4:
        return new CadAgenda(userId: widget.userId,);
      default:
        return new Text("Error");
    }
  }
  _onSelectItem(int index) {
    setState(() => _selectedDrawerIndex = index);
    Navigator.of(context).pop(); // close the drawer
  }

  @override
  void initState() {
    super.initState();

  }

  void _checkEmailVerification() async {
    _isEmailVerified = await widget.auth.isEmailVerified();
    if (!_isEmailVerified) {

    }
  }

  void _resentVerifyEmail(){
    widget.auth.sendEmailVerification();
  }

  void _showVerifyEmailSentDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        // return object of type Dialog
        return AlertDialog(
          title: new Text("Verify your account"),
          content: new Text("Link to verify account has been sent to your email"),
          actions: <Widget>[
            new FlatButton(
              child: new Text("Dismiss"),
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
  void dispose() {
    super.dispose();
  }

  _onEntryChanged(Event event) {
    var oldEntry = _todoList.singleWhere((entry) {
      return entry.key == event.snapshot.key;
    });

    setState(() {
      _todoList[_todoList.indexOf(oldEntry)] = Todo.fromSnapshot(event.snapshot);
    });
  }

  _onEntryAdded(Event event) {
    setState(() {
      _todoList.add(Todo.fromSnapshot(event.snapshot));
    });
  }

  _signOut() async {
    try {
      await widget.auth.signOut();
      widget.onSignedOut();
    } catch (e) {
      print(e);
    }
  }


  _showDialog(BuildContext context) async {
    _textEditingController.clear();
    await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
          return AlertDialog(
            content: new Row(
              children: <Widget>[
                new Expanded(child: new TextField(
                  controller: _textEditingController,
                  autofocus: true,
                  decoration: new InputDecoration(
                    labelText: 'Add new todo',
                  ),
                ))
              ],
            ),
            actions: <Widget>[
              new FlatButton(
                  child: const Text('Cancel'),
                  onPressed: () {
                    Navigator.pop(context);
                  }),
              new FlatButton(
                  child: const Text('Save'),
                  onPressed: () {

                    Navigator.pop(context);
                  })
            ],
          );
      }
    );
  }


  @override
  Widget build(BuildContext context) {
    var drawerOptions = <Widget>[];
    for (var i = 0; i < drawerItems.length; i++) {
      var d = drawerItems[i];
      drawerOptions.add(
          new ListTile(
            leading: new Icon(d.icon),
            title: new Text(d.title),
            selected: i == _selectedDrawerIndex,
            onTap: () => _onSelectItem(i),
          )
      );
    }
    return new Scaffold(
        appBar: new AppBar(
          title: new Text('OrganizaDonto'),
          actions: <Widget>[
            new FlatButton(
                child: new Text('Logout',
                    style: new TextStyle(fontSize: 17.0, color: Colors.white)),
                onPressed: _signOut)
          ],
        ),
        drawer: new Drawer(
          child: new Column(
            children: <Widget>[

              new UserAccountsDrawerHeader( accountName: new Text("by Valerio Nunes"), accountEmail: null),
              new TextFormField(
                controller : widget._FimClinica,
                enabled: false,
                decoration: const InputDecoration(
                  icon: const Icon(Icons.offline_pin),
                  hintText: 'Fim da Clinica',
                  labelText:'Fim da Clinica',
                ),

                keyboardType: TextInputType.text,
                //inputFormatters: [WhitelistingTextInputFormatter.digitsOnly,],
              ),
              new Column(children: drawerOptions)
            ],
          ),
        ),
        body: _getDrawerItemWidget(_selectedDrawerIndex),

    );
  }
}
