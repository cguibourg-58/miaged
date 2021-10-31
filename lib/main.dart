import 'dart:async';
import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:firebase_core/firebase_core.dart'; // new
import 'package:firebase_auth/firebase_auth.dart'; // new
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart'; // new

import 'src/authentication.dart'; // new
import 'src/widgets.dart';

void main() {
  //Firebase.initializeApp();
  runApp((MyApp()));
}

Cloth selectedCloth = Cloth("", "", 0, "", "", "", false);

void selectCloth(Cloth c) {
  selectedCloth = c;
}

void goToClothListPage(BuildContext c) {
  Navigator.push(
    c,
    MaterialPageRoute(builder: (context) => ClothListPage()),
  );
}

void goToClothDetailedPage(BuildContext c) {
  Navigator.push(
    c,
    MaterialPageRoute(builder: (context) => ClothDetailsPage()),
  );
}

FirebaseFirestore firestoreInstance = FirebaseFirestore.instance;
List _cloth = <Cloth>[];

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MIAGED',
      theme: ThemeData(
        primarySwatch: Colors.red,
      ),
      home: Scaffold(
          appBar: AppBar(
            title: Text("MIAGED"),
            automaticallyImplyLeading: false,
          ),
          body: LoginPage()),
    );
  }
}

class LoginPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool loggedIn = false;
  //FirebaseAuth auth = FirebaseAuth.instance;
  TextEditingController _textLogin = TextEditingController();
  TextEditingController _textPassword = TextEditingController();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    Firebase.initializeApp();
  }

  @override
  Widget build(BuildContext context) {
    log("build");
    return Container(
        child: Column(
      children: [
        TextFormField(
          controller: _textLogin,
          decoration:
              InputDecoration(border: OutlineInputBorder(), hintText: "Login"),
        ),
        TextFormField(
          controller: _textPassword,
          obscureText: true,
          decoration: InputDecoration(
              border: OutlineInputBorder(), hintText: "Password"),
        ),
        ElevatedButton(
          style: ButtonStyle(
            backgroundColor: MaterialStateProperty.all<Color>(Colors.blueGrey),
          ),
          onPressed: () {
            connect();
          },
          child: const Text('Se connecter'),
        ),
      ],
    ));
  }

  Future<void> connect() async {
    log("tu as touché sur le bouton");
    log("login: " + _textLogin.text);
    verifyEmail();
    /*if (loggedIn) {
      log("bien joué!");
      //goToClothListPage(context);
    }*/
  }

  void verifyEmail() async {
    String email = _textLogin.text;
    String password = _textPassword.text;
    //email = "tuveuxdupainpigeon@gmail.com"
    //pwd = "easy12"
    //log("email: " + email + " - password: " + password);
    void Function(FirebaseAuthException e) errorCallback;
    try {
      log("tu es dans la sauce");
      /*var methods = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);*/
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
              email: _textLogin.text, password: _textPassword.text);
      loggedIn = true;
      _cloth.clear();
      goToClothListPage(context);
      //log("nice tu es connecté");
    } /*on FirebaseAuthException */ catch (e) {
      log('Failed with error code: ${e}');
      loggedIn = false;
      log("dsl tu n'as pas mis le bon email et/ou le bon mot de passe");
    }
  }
}

class ClothListPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _ClothListPageState();
}

class _ClothListPageState extends State<ClothListPage> {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  Future<bool> initClothList() async {
    if (_cloth.length > 0) {
      _cloth.clear();
    }
    await firestoreInstance.collection("cloths").get().then((querySnapshot) {
      querySnapshot.docs.forEach((result) {
        print(result);
        log(result.get("title"));
        log(result.get("size"));
        log(result.get("price").toString());
        log(result.get("imageSrc"));
        log(result.get("category"));
        log(result.get("brand"));
        log(result.get("resizeImage").toString());
        _cloth.add(Cloth(
            result.get("title").toString(),
            result.get("size").toString(),
            result.get("price") * 1.0,
            result.get("imageSrc").toString(),
            result.get("category").toString(),
            result.get("brand").toString(),
            result.get("resizeImage")));
      });
      log(_cloth.toString());
    });
    return true;
  }

  @override
  void didChangeDependencies() {
    if (_cloth.length > 0) {
      build(context);
    }
    super.didChangeDependencies();
  }

  Widget buildItemCard(Cloth c) {
    if (c.resize) {
      return InkWell(
        child: Card(
          child: Container(
            padding: const EdgeInsets.all(8),
            height: 300,
            width: double.infinity,
            decoration: BoxDecoration(
                image: DecorationImage(
                    fit: BoxFit.cover, image: NetworkImage(c.imageSrc))),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20.0, 82.0, 20.0, 1.0),
              child: Container(
                alignment: Alignment.bottomCenter,
                color: Colors.white,
                child: Text(
                  c.title +
                      '\nTaille : ' +
                      c.size +
                      '\n' +
                      c.price.toStringAsFixed(2) +
                      ' €',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ),
        onTap: () => {selectCloth(c), goToClothDetailedPage(context)},
      );
    }
    return InkWell(
      child: Card(
        child: Container(
          padding: const EdgeInsets.all(8),
          height: 300,
          width: double.infinity,
          decoration: BoxDecoration(
              image: DecorationImage(image: NetworkImage(c.imageSrc))),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20.0, 82.0, 20.0, 1.0),
            child: Container(
              alignment: Alignment.bottomCenter,
              color: Colors.white,
              child: Text(
                c.title +
                    '\nTaille : ' +
                    c.size +
                    '\n' +
                    c.price.toStringAsFixed(2) +
                    ' €',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
      onTap: () => {selectCloth(c), goToClothDetailedPage(context)},
    );
  }

  Widget buildAllItem() {
    List<Widget> cards = <Widget>[];
    double i = 0;
    _cloth.forEach((element) {
      cards.add(buildItemCard(element));
      i++;
      log(i.toString());
    });

    return GridView.count(
      primary: false,
      padding: const EdgeInsets.all(20),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      crossAxisCount: 2,
      children: cards,
    );
  }

  Widget buildShortedItem(String cat) {
    List<Widget> cards = <Widget>[];
    double i = 0;
    _cloth.forEach((element) {
      if (element.category == cat) {
        cards.add(buildItemCard(element));
        i++;
        log(i.toString());
      }
      if (cat == "Hauts") {
        if (element.category == "Chemises" || element.category == "T-Shirt") {
          cards.add(buildItemCard(element));
          i++;
          log(i.toString());
        }
      }
    });

    return GridView.count(
      primary: false,
      padding: const EdgeInsets.all(20),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      crossAxisCount: 2,
      children: cards,
    );
  }

  @override
  Widget build(BuildContext context) => FutureBuilder(
        future: initClothList(),
        //future: dataInitialized,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            Widget clothList;
            //initClothList();
            clothList = buildAllItem();
            log("ClothListPage");
            return DefaultTabController(
                length: 4,
                child: Scaffold(
                    appBar: AppBar(
                      bottom: TabBar(
                        tabs: [
                          Tab(
                            text: "Tout",
                          ),
                          Tab(text: "Hauts"),
                          Tab(text: "Pantalons"),
                          Tab(text: "Chauss."),
                        ],
                      ),
                      title: Text("MIAGED"),
                      automaticallyImplyLeading: false,
                    ),
                    body: TabBarView(
                      children: [
                        Scaffold(
                          body: clothList,
                          bottomNavigationBar: buttonNavigation(0),
                        ),
                        Scaffold(
                          body: buildShortedItem("Hauts"),
                          bottomNavigationBar: buttonNavigation(0),
                        ),
                        Scaffold(
                          body: buildShortedItem("Pantalons"),
                          bottomNavigationBar: buttonNavigation(0),
                        ),
                        Scaffold(
                          body: buildShortedItem("Chaussures"),
                          bottomNavigationBar: buttonNavigation(0),
                        )
                      ],
                    )));
          } else {
            Widget clothList;
            //initClothList();
            clothList = buildAllItem();
            log("ClothListPage");
            return Scaffold(
              appBar: AppBar(
                title: Text("MIAGED"),
                automaticallyImplyLeading: false,
              ),
              body: Container(
                alignment: Alignment.center,
                child: CircularProgressIndicator(),
              ),
              bottomNavigationBar: buttonNavigation(0),
            );
          }
        },
      );
}

Widget buttonNavigation(int index) {
  return BottomNavigationBar(items: const <BottomNavigationBarItem>[
    BottomNavigationBarItem(
      icon: Icon(Icons.attach_money),
      label: 'Acheter',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.shopping_bag),
      label: 'Panier',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.person),
      label: 'Profil',
    ),
  ], currentIndex: index);
}

class Cloth {
  String title;
  String size;
  double price;
  String imageSrc;
  String category; //Chemise, T-Shirt, Chaussure, Pantalon, ...
  String brand;
  bool resize;

  Cloth(this.title, this.size, this.price, this.imageSrc, this.category,
      this.brand, this.resize) {
    log("new Cloth:" +
        this.title +
        " ; " +
        this.size +
        " ; " +
        this.price.toString() +
        " ; " +
        this.imageSrc +
        " ; " +
        this.category +
        " ; " +
        this.brand +
        " ; " +
        this.resize.toString());
  }
}

class ClothDetailsPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _ClothDetailsPageState();
}

class _ClothDetailsPageState extends State<ClothDetailsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("MIAGED"),
          automaticallyImplyLeading: true,
        ),
        body: ListView(
          children: [
            Container(
              height: 70,
              alignment: Alignment.topCenter,
              child: Text(
                selectedCloth.title,
                style: TextStyle(
                    height: 2, fontSize: 30, fontWeight: FontWeight.bold),
              ),
            ),
            Container(
              height: 400.0,
              width: 100.0,
              alignment: Alignment.topCenter,
              child: Image(
                image: NetworkImage(selectedCloth.imageSrc),
              ),
            ),
            Container(
              alignment: Alignment.topCenter,
              child: Text(
                "À partir de " + selectedCloth.price.toStringAsFixed(2) + " €",
                style: TextStyle(height: 2, fontSize: 25),
              ),
            ),
            Container(
              alignment: Alignment.topCenter,
              child: Text(
                "Marque : " + selectedCloth.brand,
                style: TextStyle(fontSize: 22),
              ),
            ),
            Container(
              alignment: Alignment.topCenter,
              child: Text(
                "Catégorie : " + selectedCloth.category,
                style: TextStyle(height: 1.5, fontSize: 18),
              ),
            ),
            Container(
              alignment: Alignment.topCenter,
              child: Text(
                "Taille : " + selectedCloth.size,
                style: TextStyle(height: 1.5, fontSize: 18),
              ),
            ),
            Container(
              alignment: Alignment.bottomCenter,
              height: 100,
              child: ElevatedButton(
                  style: ButtonStyle(
                    backgroundColor:
                        MaterialStateProperty.all<Color>(Colors.orangeAccent),
                  ),
                  onPressed: () => print(""),
                  child: RichText(
                    text: TextSpan(
                      children: [
                        WidgetSpan(
                          child: Icon(Icons.shopping_bag),
                        ),
                        WidgetSpan(
                          child: Text(
                            ' Ajouter au panier',
                            style: TextStyle(fontSize: 18),
                          ),
                        ),
                      ],
                    ),
                  )),
            ),
          ],
        ));
  }
}

void goToLoginPage() {}

void goToShoppingCartPage() {}

void goToUserPage() {}
