import 'dart:async';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:vibration/vibration.dart';
import 'dart:math';
import './views/pages/home/p_home.dart';
import './views/pages/main/p_main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:rive/rive.dart' as riv;
import '../controller/controller.dart';
import '../model/music.dart';
import 'model/music.dart';
import 'model/spot.dart';
import 'model/user.dart';

void main() {
  MyApp mainApp = MyApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  Controller controller = Controller();


  // This widget is the root of your application.
  @override
  Widget build(BuildContext context){
    Paint.enableDithering = true;
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    return ChangeNotifierProvider(
      create: (context) => CardProvider(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Flutter Demo',
        home: HomePage(),
      ),
    );
  }
}

enum CardStatus { like, disLike, discovery, message}

class CardProvider extends ChangeNotifier{
  List<Spot> _spotsList = MyApp().controller.currentUser.Spots2;
  bool _isDragging = false;
  double _angle = 0;
  Offset _position = Offset.zero;
  Size _screenSize = Size.zero;

  List<Spot> get spotsList => _spotsList;
  bool get isDragging => _isDragging;
  Offset get position => _position;
  double get angle => _angle;





  void setScreenSize(Size screenSize) => _screenSize = screenSize;

  void startPosition(DragStartDetails details) {
    _isDragging = true;

    notifyListeners();
  }

  void updatePosition(DragUpdateDetails details) {
    _position += details.delta;

    final x = _position.dx;
    _angle = 45 * x / _screenSize.width;
    notifyListeners();
  }

  void endPosition(context) {
    _isDragging = false;
    notifyListeners();

    final status = getStatus(force: true);


    switch (status) {
      case CardStatus.like:
        like(context);
        break;
      case CardStatus.disLike:
        dislike();
        break;
      case CardStatus.discovery:
        discovery();
        break;
      case CardStatus.message:
        message(context);
        break;
      default:
        resetPosition();
    }
  }
  void resetPosition() {
    _isDragging = false;
    _position = Offset.zero;
    _angle = 0;

    notifyListeners();
  }

  double getStatusOpacity() {
    final delta = 100;
    final pos = max(_position.dx.abs(), _position.dy.abs());
    final opacity = pos / delta;

    return min(opacity, 1);
  }

  CardStatus? getStatus({bool force = false}) {
    final x = _position.dx;
    final y = _position.dy;
    final forceDiscovery = x.abs() < 80;
    final forceMessage = x.abs() < 100;

    if(force) {
      final delta = 100;

      if (x >= delta) {
        return CardStatus.like;
      } else if ( x <= -delta){
        return CardStatus.disLike;
      } else if ( y <= -delta/2 && forceDiscovery){
        return CardStatus.message;
      } else if (y >= delta * 2 && x.abs() < 100) {
        return CardStatus.discovery;
      }
    } else{
      final delta = 20;

      if(y <= -delta * 2 && forceDiscovery) {
        return CardStatus.message;
      } else if (y >= delta *2 && x.abs() < 80) {
        return CardStatus.discovery;
      }else  if ( x >= delta) {
        return CardStatus.like;
      } else if ( x <= -delta) {
        return CardStatus.disLike;
      }
    }
  }
  void dislike() {
    print("dislike");
    _angle = -20;
    _position -= Offset(2 * _screenSize.width, 0);
    _nextCard();

    notifyListeners();
  }

  void discovery() {
    _angle = 0;
    _position -= Offset(0, -_screenSize.height);
    _discovery_card();
    print("discovery");
    if(MyApp().controller.currentUser.Discovery.contains(MyApp().controller.currentUser.Spots2?.last.music)){
      MyApp().controller.currentUser.Discovery.remove(MyApp().controller.currentUser.Spots2?.last.music);
      Fluttertoast.showToast(
      msg: 'Supprimer',
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.TOP,
      timeInSecForIosWeb: 2,
      backgroundColor: Colors.red,
      textColor: Colors.white
      );
    }
    else{
      if(MyApp().controller.currentUser.Spots2.last != null){
        MyApp().controller.currentUser.addDiscovery(MyApp().controller.currentUser.Spots2.last.music);
        Fluttertoast.showToast(
            msg: 'Ajouté',
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.TOP,
            timeInSecForIosWeb: 2,
            backgroundColor: Colors.deepPurple,
            textColor: Colors.white
        );
        notifyListeners();
      }

    }

  }

  void message(context) {
    print("message");
    _angle = 0;
    _position -= Offset(0, _screenSize.height);
    _message_card();
    showModalBottomSheet(
      isDismissible: false,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      context: context,
      constraints: BoxConstraints(
        maxWidth:  600,
        maxHeight: double.infinity,
      ),
      builder: (context) => buildSheet(),);
    notifyListeners();
  }
  Widget buildSheet(){
    final messageTextField = TextEditingController();
    return Container(
      height: 550,
      width: 350,
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            offset: const Offset(
              0,
              0,
            ),
            blurRadius: 10.0,
            spreadRadius: 2.0,
          ),
          BoxShadow(
            color: Colors.white.withOpacity(0.3),
            offset: const Offset(0.0, 0.0),
            blurRadius: 0.0,
            spreadRadius: 0.0,
          ),//BoxShadow//BoxShadow
        ],
        color: Color(0xFF232123),
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(30),
          topLeft: Radius.circular(30),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 10, 20, 10),
        child: Column(
          children: [

            Container(
              height: 5,
              width: 130,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Color(0xFF8A8A8A),
              ),
            ),
            SizedBox(height: 30,),
            Container(
              width: double.infinity,
              height: 300,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Color(0xFF302C30),
              ),
              child: Padding(
                padding: EdgeInsets.all(20),
                child: TextField(
                  controller: messageTextField,
                  maxLength: 300,
                  style: TextStyle(fontFamily: 'DMSans', color: Colors.white.withOpacity(1) ,fontSize: 17, fontWeight: FontWeight.w200),
                  expands: true,
                  maxLines: null,
                  textInputAction: TextInputAction.send,
                  decoration: InputDecoration(
                    hintStyle: TextStyle(
                      color: Colors.white,
                    ),
                    border: InputBorder.none,
                    hintText: "Mon message",
                  ),
                ),
              ),
            ),
            SizedBox(height: 20,),
            SizedBox(
              width: double.infinity,
              height: 70,
              child: ElevatedButton(
                onPressed: () {
                  sendMessage(messageTextField.text, MyApp().controller.currentUser.Spots2.last.user);
                },
                style: ElevatedButton.styleFrom(
                  primary: Color(0xFF3F1DC3),
                  textStyle: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(17)
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text("Envoyer"),
                    Opacity(opacity: 0.2,
                      child: Image.asset("assets/images/send_logo.png",),)
                  ],
                ),
              ),
            )
          ],
        ),
      ),

    );


  }
  void sendMessage(String message, User destinataire){
    print(MyApp().controller.currentUser.Spots2.last.user.usernameDafl);
  }



  void like(context) {
    print("like");
    _angle = 20;
    _position += Offset(2 * _screenSize.width, 0);
    _nextCard();
    notifyListeners();

  }

  Future _nextCard() async {
    print(_spotsList.length);
    if (_spotsList.isEmpty) {
      print('dernier');
      return;
    }
    else {
      await Future.delayed(Duration(milliseconds: 200));
      print(_spotsList.last.music.name);
      _spotsList.removeLast();
      resetPosition();
    }
  }

  Future _discovery_card() async {
    await Future.delayed(Duration(milliseconds: 200));
    resetPosition();
  }

  Future _message_card() async {
    await Future.delayed(Duration(milliseconds: 200));
    resetPosition();
  }

}


class Splash extends StatefulWidget {
  const Splash({Key? key}) : super(key: key);

  @override
  State<Splash> createState() => _SplashState();
}

class _SplashState extends State<Splash> {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      Timer(Duration(seconds: 2), () {
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder:
                (context) =>MainPage()
            )
        );
      });
    });


  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF141414),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 300,
              width: 300,
              child: riv.RiveAnimation.asset('assets/images/new_file (2).riv'),
            ),
            SizedBox(height: 50),
          ],
        ),
      ),
    );
  }
}
Object Notify(int index, context, {bool isError = true}){
  String message;
  if(isError == true){
    switch(index){
      case 0: {
        message = "Ce nom d'utilisateur existe déjà ! Veuillez réessayer.";
        break;
      }
      case 1: {
        message = "Mots de passe différents ! Veuillez réessayer.";
        break;
      }
      case 2: {
        message = "Identifiant incorrect ! Veuillez réessayer.";
        break;
      }
      case 3: {
        message = "Mot de passe incorrect ! Votre mot de passe doit contenir 8 caractères minimum.";
        break;
      }
      case 4: {
        message = "Mot de passe incorrect ! Veuillez réessayer.";
        break;
      }
      default:
        message = "Une erreur est survenue pendant l'inscription. Veuillez réessayer.";
        break;

    }
    return ScaffoldMessenger.of(context).showSnackBar( SnackBar(
        dismissDirection: DismissDirection.down,
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        content: Stack(
          clipBehavior: Clip.none,
          children: [

            Container(
              padding: EdgeInsets.all(16),
              height: 90,
              child: Row(
                children: [
                  Container(
                    height: 48,
                    width: 48,
                  ),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Oh oh !", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),),
                      Text(message,style: TextStyle(
                      ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,),
                    ],
                  ),),
                ],
              ),
              decoration: BoxDecoration(
                image: DecorationImage(
                    image: AssetImage("assets/images/backgroundNotify.png"),
                    fit: BoxFit.cover),
                gradient: LinearGradient(colors: [Color(0xFF81052a),Color(0xFF810548)],begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.all(Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 10,
                    offset: Offset(4, 8), // Shadow position
                  ),
                ],
              ),
            ),
            Positioned(
                top: -50,
                left: -20,
                child: Container(
                  color:  Colors.transparent,
                  height: 110,
                  width: 110,
                  child: riv.RiveAnimation.asset("assets/images/error_icon.riv"),)),
          ],
        )
    ));
  }
  else{
    switch(index){
      case 0: {
        message = "Vous avez changer votre identifiant avec succès";
        break;
      }
      case 1: {
        message = "Vous avez changer votre mot de passe avec succès";
        break;
      }
      default:
        message = "L'opération a bien été éxécutée";
        break;

    }
    return ScaffoldMessenger.of(context).showSnackBar( SnackBar(
        dismissDirection: DismissDirection.down,
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        content: Stack(
          clipBehavior: Clip.none,
          children: [

            Container(
              padding: EdgeInsets.all(16),
              height: 90,
              child: Row(
                children: [
                  Container(
                    height: 48,
                    width: 48,
                  ),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Super !", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),),
                      Text(message,style: TextStyle(
                      ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,),
                    ],
                  ),),
                ],
              ),
              decoration: BoxDecoration(
                image: DecorationImage(
                    image: AssetImage("assets/images/valid_background.png"),
                    fit: BoxFit.cover),
                gradient: LinearGradient(colors: [Color(0xFF81052a),Color(0xFF810548)],begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.all(Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 10,
                    offset: Offset(4, 8), // Shadow position
                  ),
                ],
              ),
            ),
            Positioned(
                top: -50,
                left: -20,
                child: Container(
                  color:  Colors.transparent,
                  height: 110,
                  width: 110,
                  child: riv.RiveAnimation.asset("assets/images/valid_icon.riv"),)),
          ],
        )
    ));

  }

}


