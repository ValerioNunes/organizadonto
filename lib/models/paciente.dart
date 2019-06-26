import 'package:firebase_database/firebase_database.dart';

class Paciente {
  String key = "";
  String nome= "";
  String telefone= "";
  String alunoId= "";
  String atendimento= "";

  Paciente();

  Paciente.fromSnapshot(DataSnapshot snapshot) :
        key = snapshot.key,
        nome = snapshot.value["nome"],
        telefone = snapshot.value["telefone"],
        alunoId = snapshot.value["pacienteId"],
        atendimento = snapshot.value["atendimento"];

  toJson() {
    return {
      "nome": nome,
      "telefone": telefone,
      "alunoId": alunoId,
      "atendimento": atendimento,
    };
  }
}