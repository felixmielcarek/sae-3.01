import 'package:dafl_project_flutter/persistence/database_connexion.dart';

import 'searcher.dart';

class DatabaseSearcher extends Searcher{
  DatabaseConnexion dbConnexion = DatabaseConnexion();

  Future<bool> searchUser(String? username, String? password) async { return true; }


  @override
  Future<bool> searchByUsername(String? username) async{
    final connection = await dbConnexion.initConnexion();

    connection.query('select * from utilisateur where username = $username').toList().then((rows) {
      if(rows.isEmpty){
        connection.close();
        return false;
      }
    });

    connection.close();
    return true;
  }
}