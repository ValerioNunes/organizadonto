import 'package:firebase_database/firebase_database.dart';

class Agenda {

  String key = "";
  String alunoId;

  String pacienteId;
  String pacientenome = "";

  String obs = "";
  String atendimento = "";
  DateTime inicio;
  DateTime fim;
  String turno = "";


  Agenda(){}


  Agenda.fromSnapshot(DataSnapshot snapshot):
        key = snapshot.key,
        inicio =  new DateTime.fromMillisecondsSinceEpoch(snapshot.value["inicio"]),
        fim =  new DateTime.fromMillisecondsSinceEpoch(snapshot.value["fim"]),
        alunoId = snapshot.value["alunoId"],
        pacienteId = snapshot.value["pacienteId"],
        pacientenome = snapshot.value["pacientenome"],
        atendimento = snapshot.value["atendimento"],
        turno = snapshot.value["turno"],
        obs = snapshot.value["obs"];
  toJson() {
    return {
      "inicio": inicio.millisecondsSinceEpoch,
      "fim": fim.millisecondsSinceEpoch,
      "alunoId": alunoId,
      "pacienteId": pacienteId,
      "pacientenome": pacientenome,
      "atendimento": atendimento,
      "obs": obs,
      "turno":turno
    };
  }
}