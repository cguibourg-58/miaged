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
String currentUsersUID = "";

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

void goToShoppingCartPage(BuildContext c) {
  Navigator.push(
    c,
    MaterialPageRoute(builder: (context) => ShoppingCartPage()),
  );
}

FirebaseFirestore firestoreInstance = FirebaseFirestore.instance;
List _cloth = <Cloth>[];
List _cartCloth = <Cloth>[];

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
      final User? user = FirebaseAuth.instance.currentUser;
      final uid = user!.uid;
      currentUsersUID = uid.toString();
      log("uid: " + currentUsersUID);
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

void addItemToCart(Cloth c) {
  FirebaseFirestore.instance
      .collection("users/" + currentUsersUID + "/cart")
      .add({
    'title': c.title,
    'size': c.size,
    'price': c.price,
    'imageSrc': c.imageSrc,
    'category': c.category,
    'brand': c.brand,
    'resizeImage': c.resizeImage
  });
}

class ClothListPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _ClothListPageState();
}

class _ClothListPageState extends State<ClothListPage> {
  Future<bool> initClothList() async {
    if (_cloth.length > 0) {
      _cloth.clear();
    }
    await firestoreInstance.collection("cloths").get().then((querySnapshot) {
      querySnapshot.docs.forEach((result) {
        /*print(result);
        log(result.get("title"));
        log(result.get("size"));
        log(result.get("price").toString());
        log(result.get("imageSrc"));
        log(result.get("category"));
        log(result.get("brand"));
        log(result.get("resizeImage").toString());*/
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

  Widget buildItemCard(Cloth c) {
    if (c.resizeImage) {
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
                            text: "Tous",
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
                          bottomNavigationBar: buttonNavigation(0, context),
                        ),
                        Scaffold(
                          body: buildShortedItem("Hauts"),
                          bottomNavigationBar: buttonNavigation(0, context),
                        ),
                        Scaffold(
                          body: buildShortedItem("Pantalons"),
                          bottomNavigationBar: buttonNavigation(0, context),
                        ),
                        Scaffold(
                          body: buildShortedItem("Chaussures"),
                          bottomNavigationBar: buttonNavigation(0, context),
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
              bottomNavigationBar: buttonNavigation(0, context),
            );
          }
        },
      );
}

Widget buttonNavigation(int index, BuildContext context) {
  return BottomNavigationBar(
      items: const <BottomNavigationBarItem>[
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
      ],
      currentIndex: index,
      onTap: (value) {
        if (value == 0 && index != 0) {
          goToClothListPage(context);
        }
        if (value == 1 && index != 1) {
          goToShoppingCartPage(context);
        }
        if (value == 2 && index != 2) {
          log("pas encore implémenté.");
        }
      });
}

class Cloth {
  String title;
  String size;
  double price;
  String imageSrc;
  String category; //Chemise, T-Shirt, Chaussure, Pantalon, ...
  String brand;
  bool resizeImage;

  Cloth(this.title, this.size, this.price, this.imageSrc, this.category,
      this.brand, this.resizeImage) {
    /*log(this.toString());*/
  }
  @override
  String toString() {
    return "title: " +
        this.title +
        " - size; " +
        this.size +
        " - price: " +
        this.price.toString() +
        " - imageSrc: " +
        this.imageSrc +
        " - category: " +
        this.category +
        " - brand: " +
        this.brand +
        " resizeImage: " +
        this.resizeImage.toString();
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
                  onPressed: () => addItemToCart(selectedCloth),
                  child: RichText(
                    text: TextSpan(
                      children: [
                        WidgetSpan(
                          child: Icon(Icons.shopping_bag),
                        ),
                        WidgetSpan(
                          child: Text(
                            ' Ajouter au panier',
                            style: TextStyle(fontSize: 20),
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

class ShoppingCartPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _ShoppingCartPageState();
}

class _ShoppingCartPageState extends State<ShoppingCartPage> {
  int nombreDArticle = 0;
  double total = 0;

  Future<bool> initClothList() async {
    //if (_cartCloth.length > 0) {
    //}
    await firestoreInstance
        .collection("users/" + currentUsersUID + "/cart")
        .get()
        .then((querySnapshot) {
      _cartCloth.clear();
      nombreDArticle = 0;
      total = 0;
      log("----");
      querySnapshot.docs.forEach((result) {
        print(result);
        log(result.get("title"));
        log(result.get("size"));
        log(result.get("price").toString());
        log(result.get("imageSrc"));
        log(result.get("category"));
        log(result.get("brand"));
        log(result.get("resizeImage").toString());
        _cartCloth.add(Cloth(
            result.get("title").toString(),
            result.get("size").toString(),
            result.get("price") * 1.0,
            result.get("imageSrc").toString(),
            result.get("category").toString(),
            result.get("brand").toString(),
            result.get("resizeImage")));
        total += result.get("price") * 1.0;
        nombreDArticle++;
      });
      log(_cartCloth.toString());
    });
    return true;
  }

  Widget buildItemCard(Cloth c) {
    return Container(
      child: ListTile(
        title: Text(c.title),
        subtitle: Text("Taille : " +
            c.size +
            " \n" +
            c.brand +
            "\n" +
            c.price.toStringAsFixed(2) +
            " € "),
        isThreeLine: true,
        leading: Image(
          alignment: Alignment.center,
          image: NetworkImage(c.imageSrc),
          height: 600,
          width: 60,
        ),
        trailing: IconButton(
            icon: Icon(Icons.highlight_off),
            onPressed: () => print("remove it pleeeeease!")),
        onTap: () => {selectCloth(c), goToClothDetailedPage(context)},
      ),
      decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.black26))),
    );
  }

  Widget buildInfoRaw() {
    return Container(
        child: ListTile(
      title: Text(
          "Nombre d'articles : " +
              nombreDArticle.toString() +
              "\nTotal : " +
              total.toStringAsFixed(2) +
              " €",
          style: TextStyle(fontSize: 20),
          textAlign: TextAlign.center),
    ));
  }

  Widget title() {
    return Container(
      child: ListTile(
        title: Text("Votre panier",
            style: TextStyle(/*fontWeight: FontWeight.bold, */ fontSize: 28),
            textAlign: TextAlign.center),
      ),
      decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.black26))),
    );
  }

  Widget buildAllItem() {
    List<Widget> cards = <Widget>[];
    double i = 0;
    cards.add(title());
    _cartCloth.forEach((element) {
      cards.add(buildItemCard(element));
      i++;
      log(i.toString());
    });
    cards.add(buildInfoRaw());
    if (_cartCloth.length < 1) {
      return Container(
          alignment: Alignment.center,
          child: Text(
            "Votre panier est vide.",
            style: TextStyle(fontSize: 22, color: Colors.grey),
          ));
    }
    return ListView(
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
            log("ShoppingCartPage");
            return DefaultTabController(
                length: 4,
                child: Scaffold(
                  appBar: AppBar(
                    title: Text("MIAGED"),
                    automaticallyImplyLeading: false,
                  ),
                  body: clothList,
                  bottomNavigationBar: buttonNavigation(1, context),
                ));
          } else {
            Widget clothList;
            //initClothList();
            clothList = buildAllItem();
            log("ShoppingCartPage");
            return Scaffold(
              appBar: AppBar(
                title: Text("MIAGED"),
                automaticallyImplyLeading: false,
              ),
              body: Container(
                alignment: Alignment.center,
                child: CircularProgressIndicator(),
              ),
              bottomNavigationBar: buttonNavigation(1, context),
            );
          }
        },
      );
}

void goToLoginPage() {}

void goToUserPage() {}
