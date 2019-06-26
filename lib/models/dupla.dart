import 'package:firebase_database/firebase_database.dart';

class Dupla {
  String key = "";
  String aluno1Id;
  String aluno2Id;
  String nomealuno2;
  Dupla();

  Dupla.fromSnapshot(DataSnapshot snapshot):
        key = snapshot.key,
        aluno1Id = snapshot.value["aluno1Id"],
        aluno2Id = snapshot.value["aluno2Id"],
        nomealuno2 = snapshot.value["nomealuno2"];
  toJson() {
    return {
      "aluno1Id":  aluno1Id,
      "aluno2Id":  aluno2Id,
      "nomealuno2": nomealuno2,
    };
  }
}