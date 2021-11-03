import 'dart:async';
import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:firebase_core/firebase_core.dart'; // new
import 'package:firebase_auth/firebase_auth.dart'; // new
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_restart/flutter_restart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart'; // new

import 'src/authentication.dart'; // new
import 'src/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() {
  //Firebase.initializeApp();
  runApp((MyApp()));
}

Cloth selectedCloth = Cloth("", "", 0, "", "", "", false);
String currentUsersUID = "";
FirebaseFirestore firestoreInstance = FirebaseFirestore.instance;
List _cloth = <Cloth>[];
List _cartCloth = <Cloth>[];
UserProfile currentUserProfile = UserProfile("", "", "", "", "", "", "");
bool logged = false;
User? currentUser;

void selectCloth(Cloth c) {
  selectedCloth = c;
}

void goToLoginPage(BuildContext c) {
  /*Navigator.push(
    c,
    MaterialPageRoute(builder: (context) => MyApp()),
  );*/
  Navigator.pushAndRemoveUntil(
      c, MaterialPageRoute(builder: (context) => MyApp()), (route) => false);
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

void goToUserProfilPage(BuildContext c) {
  Navigator.push(
    c,
    MaterialPageRoute(builder: (context) => UserProfilPage()),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MIAGED',
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: [
        Locale('en', ''), // English, no country code
        Locale('fr', 'FR'), // France, country code
      ],
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
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
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 15, 8, 8),
          child: TextFormField(
            controller: _textLogin,
            decoration: InputDecoration(
                border: OutlineInputBorder(), labelText: "Login"),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextFormField(
            controller: _textPassword,
            obscureText: true,
            decoration: InputDecoration(
                border: OutlineInputBorder(), labelText: "Password"),
          ),
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
      currentUser = FirebaseAuth.instance.currentUser;
      final uid = currentUser!.uid;
      currentUsersUID = uid.toString();
//      currentUser.setUserProfileValues(currentUsersUID, u.get("email"), u.password, birthday, address, postalCode, city)
      log("uid: " + currentUsersUID);
      loggedIn = true;
      _cloth.clear();
      goToClothListPage(context);
      getCurrentUsersDataFromFirestore();
      //log("nice tu es connecté");
    } /*on FirebaseAuthException */ catch (e) {
      log('Failed with error code: ${e}');
      loggedIn = false;
      log("dsl tu n'as pas mis le bon email et/ou le bon mot de passe");
    }
  }
}

void updateUsersData(String password, String birthday, String address,
    String postalCode, String city, bool passwordChanged) {
  FirebaseFirestore.instance.collection("users").doc(currentUsersUID).update({
    'password': password,
    'birthday': birthday,
    'address': address,
    'postalCode': postalCode,
    'city': city
  });
  if (passwordChanged) {
    currentUser!.updatePassword(password).then((_) {
      log("Successfully changed password");
    }).catchError((error) {
      log("Password can't be changed" + error.toString());
      //This might happen, when the wrong password is in, the user isn't found, or if the user hasn't logged in recently.
    });
  }
}

void getCurrentUsersDataFromFirestore() {
  FirebaseFirestore.instance
      .collection("users")
      .doc(currentUsersUID)
      .get()
      .then((DocumentSnapshot documentSnapshot) {
    if (documentSnapshot.exists) {
      log('Document exists on the database');
      currentUserProfile = UserProfile(
          currentUsersUID,
          documentSnapshot.get("email"),
          documentSnapshot.get("password"),
          documentSnapshot.get("birthday"),
          documentSnapshot.get("address"),
          documentSnapshot.get("postalCode"),
          documentSnapshot.get("city"));
      //print(currentUser.toString());
    }
  });
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
    await firestoreInstance.collection("cloths").get().then((querySnapshot) {
      if (_cloth.length > 0) {
        _cloth.clear();
      }
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
      //log(_cloth.toString());
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
      //log(i.toString());
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
        //log(i.toString());
      }
      if (cat == "Hauts") {
        if (element.category == "Chemises" ||
            element.category == "T-Shirt" ||
            element.category == "Pull" ||
            element.category == "Pull à capuche" ||
            element.category == "Crop-top") {
          cards.add(buildItemCard(element));
          i++;
          //log(i.toString());
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
          goToUserProfilPage(context);
        }
      });
}

class Cloth {
  String id = "";
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

class UserProfile {
  String uid;
  String email;
  String password;
  String birthday;
  String address;
  String postalCode;
  String city;

  UserProfile(this.uid, this.email, this.password, this.birthday, this.address,
      this.postalCode, this.city);

  @override
  String toString() {
    // TODO: implement toString
    return "uid: " +
        uid +
        "email: " +
        email +
        "\npassword: " +
        password +
        "\nbirthday: " +
        birthday +
        "\naddress: " +
        address +
        "\npostalCode: " +
        postalCode +
        "\ncity: " +
        city;
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
                  onPressed: //() => addItemToCart(selectedCloth),
                      () => showDialog<String>(
                            context: context,
                            builder: (BuildContext context) => AlertDialog(
                              title: const Text('Ajouter au panier'),
                              content: const Text(
                                  'Souhaitez-vous ajouter cet article à votre panier ?'),
                              actions: <Widget>[
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, 'Cancel'),
                                  child: const Text('Non'),
                                ),
                                TextButton(
                                  onPressed: () => {
                                    Navigator.pop(context, 'OK'),
                                    addItemToCart(selectedCloth)
                                  },
                                  child: const Text('Oui'),
                                ),
                              ],
                            ),
                          ),
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

  void removeItem(Cloth c) {
    firestoreInstance
        .collection("users/" + currentUsersUID + "/cart")
        .doc(c.id)
        .delete();
    setState(() {});
  }

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
      //log("----");
      querySnapshot.docs.forEach((result) {
        print("doc's id: " + result.id.toString());
        /*print(result);
        log(result.get("title"));
        log(result.get("size"));
        log(result.get("price").toString());
        log(result.get("imageSrc"));
        log(result.get("category"));
        log(result.get("brand"));
        log(result.get("resizeImage").toString());*/
        Cloth c = Cloth(
            result.get("title").toString(),
            result.get("size").toString(),
            result.get("price") * 1.0,
            result.get("imageSrc").toString(),
            result.get("category").toString(),
            result.get("brand").toString(),
            result.get("resizeImage"));
        c.id = result.id.toString();
        _cartCloth.add(c);
        total += result.get("price") * 1.0;
        nombreDArticle++;
      });
      //log(_cartCloth.toString());
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
            onPressed: () => /*print("remove it pleeeeease!")*/ removeItem(c)),
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
        "\nNombre d'articles : " +
            nombreDArticle.toString() +
            "\nTotal : " +
            total.toStringAsFixed(2) +
            " €",
        style: TextStyle(fontSize: 20),
        textAlign: TextAlign.center,
      ),
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

class UserProfilPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _UserProfilPageState();
}

class _UserProfilPageState extends State<UserProfilPage> {
  TextEditingController _password =
      TextEditingController(text: currentUserProfile.password);
  TextEditingController _birthday =
      TextEditingController(text: currentUserProfile.birthday);
  TextEditingController _address =
      TextEditingController(text: currentUserProfile.address);
  TextEditingController _postalCode =
      TextEditingController(text: currentUserProfile.postalCode);
  TextEditingController _city =
      TextEditingController(text: currentUserProfile.city);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("MIAGED"),
        automaticallyImplyLeading: false,
      ),
      body: Container(
          child: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(30, 15, 30, 4),
            child: TextFormField(
              initialValue: currentUserProfile.email,
              enabled: false,
              decoration: InputDecoration(labelText: "Login"),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(30, 4, 30, 4),
            child: TextFormField(
                controller: _password,
                readOnly: true,
                obscureText: true,
                decoration: InputDecoration(labelText: "Mot de passe"),
                onTap: () {
                  //String s = "avant";
                  showDialog(
                      context: context,
                      builder: (BuildContext context) => AlertDialog(
                            title: Text("Changer de mot de passe"),
                            content: //Container(
                                changePasswordForm(context),
                            actions: <Widget>[
                              TextButton(
                                onPressed: () =>
                                    Navigator.pop(context, 'Cancel'),
                                child: const Text('Annuler'),
                              ),
                              TextButton(
                                onPressed: () => {
                                  //log(s),
                                  //changeColor = !changeColor,
                                  checkNewPassword(),
                                  if (changePassword)
                                    {
                                      Navigator.pop(context, 'OK'),
                                      /*_currentPassword.text = "",
                                      _newPassword.text = "",
                                      _newPasswordVerification.text = "",*/
                                    }
                                  else
                                    {
                                      showDialog(
                                          context: context,
                                          builder: (BuildContext context) =>
                                              AlertDialog(
                                                  title: Text("Erreur"),
                                                  content: Text(
                                                      changePasswordErrorMessage,
                                                      style: TextStyle(
                                                          color: Colors.red))))
                                    }
                                },
                                child: const Text('Modifier'),
                              ),
                            ],
                          ));
                }),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(30, 4, 30, 4),
            child: TextFormField(
                readOnly: true,
                controller: _birthday,
                decoration: InputDecoration(labelText: "Anniversaire"),
                onTap: () {
                  _selectDate(context, _birthday);
                }),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(30, 4, 30, 4),
            child: TextFormField(
              controller: _address,
              decoration: InputDecoration(labelText: "Adresse"),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(30, 4, 30, 4),
            child: TextFormField(
                controller: _postalCode,
                decoration: InputDecoration(labelText: "Code postal"),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(30, 4, 30, 4),
            child: TextFormField(
              controller: _city,
              decoration: InputDecoration(labelText: "Ville"),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(70, 16, 70, 0),
            child: ElevatedButton(
              child: const Text('Valider'),
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all<Color>(Colors.red),
              ),
              onPressed: () {
                //() => print("watt ze phoque!?");
                showDialog<String>(
                  context: context,
                  builder: (BuildContext context) => AlertDialog(
                    content: const Text(
                        'Voulez-vous vraiment modifier vos données ?'),
                    actions: <Widget>[
                      TextButton(
                        onPressed: () => Navigator.pop(context, 'Cancel'),
                        child: const Text('Non'),
                      ),
                      TextButton(
                        onPressed: () => {
                          Navigator.pop(context, 'OK'),
                          updateUsersData(
                              _password.text,
                              _birthday.text,
                              _address.text,
                              _postalCode.text,
                              _city.text,
                              changePassword)
                        },
                        child: const Text('Oui'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(70, 16, 70, 0),
            child: ElevatedButton(
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all<Color>(Colors.black),
              ),
              onPressed: () {
                showDialog<String>(
                  context: context,
                  builder: (BuildContext context) => AlertDialog(
                    content:
                        const Text('Voulez-vous vraiment vous déconnecter ?'),
                    actions: <Widget>[
                      TextButton(
                        onPressed: () => Navigator.pop(context, 'Cancel'),
                        child: const Text('Non'),
                      ),
                      TextButton(
                        onPressed: () => {
                          Navigator.pop(context, 'OK'),
                          logout(context),
                        },
                        child: const Text('Oui'),
                      ),
                    ],
                  ),
                );
              },
              child: const Text('Se déconnecter'),
            ),
          ),
        ],
      )),
      bottomNavigationBar: buttonNavigation(2, context),
    );
  }

  TextEditingController _currentPassword = TextEditingController();
  TextEditingController _newPassword = TextEditingController();
  TextEditingController _newPasswordVerification = TextEditingController();
  String changePasswordErrorMessage = "";

  bool changePassword = false;

  void checkNewPassword() {
    changePassword = _password.text == _currentPassword.text &&
        _newPassword.text == _newPasswordVerification.text;
    if (_currentPassword.text == "") {
      changePasswordErrorMessage =
          "Veuillez remplir les trois champs de saisie.";
    } else if (_password.text != _currentPassword.text) {
      changePasswordErrorMessage = "Mot de passe incorrect.";
    } else if (_newPassword.text != _newPasswordVerification.text) {
      changePasswordErrorMessage =
          "Vérifiez le texte de votre nouveau mot de passe.";
    } else if (changePassword) {
      log("c'est good !");
      _password.text = _newPassword.text;
    }
  }

  changePasswordForm(BuildContext context) {
    bool goodPassword = false;

    TextStyle currentPasswordFieldStyle = TextStyle();
    return Container(
        height: 250,
        width: 500,
        child: ListView(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(5, 2, 5, 2),
            child: TextFormField(
              obscureText: true,
              controller: _currentPassword,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter some text';
                }
                return null;
              },
              decoration: InputDecoration(
                labelText: "Entrez le mot de passe actuel",
                labelStyle: currentPasswordFieldStyle,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(5, 2, 5, 2),
            child: TextFormField(
              obscureText: true,
              controller: _newPassword,
              decoration: InputDecoration(
                  labelText: "Indiquer le nouveau mot de passe"),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(5, 2, 5, 2),
            child: TextFormField(
              obscureText: true,
              controller: _newPasswordVerification,
              decoration: InputDecoration(
                  labelText: "Confirmer le nouveau mot de passe"),
            ),
          ),
        ]));
  }
}

//DateTime selectedDate = DateTime.now();

_selectDate(BuildContext context, TextEditingController t) async {
  final DateTime? selectedDate = await showDatePicker(
    confirmText: 'Modifier',
    context: context,
    locale: const Locale("fr", "FR"),
    initialEntryMode: DatePickerEntryMode.calendarOnly,
    initialDate: DateTime(
        DateTime.now().year - 18, DateTime.now().month, DateTime.now().day),
    firstDate: DateTime(1950, 1, 1),
    lastDate: DateTime(
        DateTime.now().year - 18, DateTime.now().month, DateTime.now().day),
    initialDatePickerMode: DatePickerMode.year,
    helpText: "Date d'anniversaire", // Can be used as title
    cancelText: 'Annuler',
  );
  if (selectedDate != null) {
    t.text = selectedDate.day.toString() +
        "/" +
        selectedDate.month.toString() +
        "/" +
        selectedDate.year.toString();
  }
}

Future<void> logout(BuildContext c) async {
  await FirebaseAuth.instance.signOut().then((value) => null);
  selectedCloth = Cloth("", "", 0, "", "", "", false);
  _cloth = [];
  currentUsersUID = "";
  currentUserProfile = UserProfile("", "", "", "", "", "", "");
  //FlutterRestart.restartApp();
  goToLoginPage(c);
}
