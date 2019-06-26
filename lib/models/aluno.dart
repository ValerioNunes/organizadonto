import 'package:firebase_database/firebase_database.dart';

class Aluno {
  String key = "";
  String nome;
  String alunoId;
  DateTime fimclinica;
  dynamic dias_semana = new List<bool>();

  Aluno();

  Aluno.fromSnapshot(DataSnapshot snapshot):
        key = snapshot.key,
        nome = snapshot.value["nome"],
        fimclinica =  new DateTime.fromMillisecondsSinceEpoch(snapshot.value["fimclinica"]),
        alunoId = snapshot.value["alunoId"];

  toJson() {
    return {
      "nome": nome,
      "fimclinica": fimclinica.millisecondsSinceEpoch,
      "alunoId": alunoId,
      "dias_semana": dias_semana
    };
  }
}