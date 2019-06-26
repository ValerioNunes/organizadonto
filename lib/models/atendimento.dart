import 'package:firebase_database/firebase_database.dart';

class Atendimento {
  String key = "";
  String nome;

  Atendimento({this.nome});

  Atendimento.fromSnapshot(DataSnapshot snapshot) :
        key = snapshot.key,
        nome = snapshot.value["nome"];
  toJson() {
    return {
      "nome": nome
    };
  }

}