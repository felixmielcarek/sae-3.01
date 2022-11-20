import 'package:dafl_project_flutter/model/message.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class MessageDatabaseServices{

  // Make an unique chat ID between 2 client. Look like 'User1-User2'
  static String getChatId(String idSender, String idReceiver){

      // Test to always have the same id
      if (idSender.hashCode <= idReceiver.hashCode)
        return '$idSender-${idReceiver}';
      else
        return '${idReceiver}-$idSender';

  }


  // Send a message from an user to an other
  void sendMessage(Message message, String idSender, String idReceiver) {
    String chatId = getChatId(idSender, idReceiver);

    var documentReference = FirebaseFirestore.instance
        .collection('messages')
        .doc(chatId)
        .collection(chatId)
        .doc(DateTime.now().millisecondsSinceEpoch.toString());

    FirebaseFirestore.instance.runTransaction((transaction) async {
      transaction.set(documentReference, message.toHashMap());
    });
  }

  // Get a message from a snapshot Firestore
  Message _getMessage(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    var data = snapshot.data();
    if (data == null)
      throw Exception("no data in database");

    return Message.fromMap(data);
  }

  // Get a list of messages from Firestore
  List<Message> _getAllMessages(QuerySnapshot<Map<String, dynamic>> snapshot) {
    return snapshot.docs.map((doc) {
      return _getMessage(doc);
    }).toList();
  }

  // Get the massages from Firestore
  Stream<List<Message>> getMessage(String chatId) {
    return FirebaseFirestore.instance
        .collection('messages')
        .doc(chatId)
        .collection(chatId)
        .snapshots().map(_getAllMessages);
  }
}