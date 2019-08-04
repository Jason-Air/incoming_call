import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:contacts_service/contacts_service.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: PlatformChannel(),
    );
  }
}

class PlatformChannel extends StatefulWidget {
  @override
  _PlatformChannelState createState() => _PlatformChannelState();
}

class _PlatformChannelState extends State<PlatformChannel> {
  static const MethodChannel methodChannel =
      MethodChannel('com.arayan.incoming_call/calls');

  var _calls;
  List data;
  final String url = "https://ankaranakliyat.web.tr/rehber/api/customer/create.php";
  //final String url = "http://10.0.2.2/api/customer/create.php";

  @override
  initState() {
    super.initState();
    _getCalls();
    // Add listeners to this class
  }

  /// http request
  Future<void> getSWData(postBody) async {
    if (postBody.length > 0) {
      postBody = jsonEncode(postBody); //postBody.toString();
      print(postBody);
      var res = await http
          .post(url, body: postBody, headers: {"Accept": "application/json"});

      setState(() {
        var resBody = json.decode(res.body);
        data = resBody;
        _showDialog("Kaydedildi",
            data.length.toString() + " adet numara veritabanına kaydedildi");
      });
    }else{
      _showDialog("Kayıt Yok", "Kaydedilecek numara yok");
    }

    //return "Success!";
  }

  /// /http

  Future<void> _getCalls() async {
    String calls;
    try {
      final String result = await methodChannel.invokeMethod('getCalls');
      calls = result;
      print("calls: " + calls);
    } catch (e) {
      calls = 'Failed to get calls. ';
      _showDialog("Hata",
          "Aramaları alırken hata oluştu. Arama kaydına erişim yetkilerini kontrol edin");
    }
    setState(() {
      _calls = jsonDecode(calls);
      print("_calls " + jsonEncode(_calls));
    });
  }

  Future<void> addContactIfNotExist(String telNum) async {
    List<String> nums = telNum.split(",").toList();
    var contacts;
    Contact cnt;
    String customers = "";
    print("nums: " + nums.toString());
    if (nums.length > 0) {
      for (var n in nums) {
        contacts = await ContactsService.getContactsForPhone(n);

        if (contacts.length == 0) {
          cnt = new Contact();
          cnt.givenName = "Musteri " + DateTime.now().toString();
          cnt.phones = [Item(label: "mobile", value: n)];

          customers += "{ \"name\":\"" + cnt.givenName + "\",";
          customers += " \"number\":" + n.toString() + ",";
          customers += " \"category_id\":1},";

          try {
            ContactsService.addContact(cnt);
          } catch (e) {
            print("hata: Rehbere kaydedilemedi! \n" + e.toString());
            _showDialog("Hata", "Rehbere kaydederken hata oluştu");
          }
        }
      }

      customers = "[" + customers.substring(0, customers.length - 1) + "]";

      // try {
      //   await getSWData(customers);
      //   print("veritabanına kaydedildi");
      //   _showDialog("Bilgi", "Veritabanına kaydedildi");
      //   // print(customers);
      // } catch (e) {
      //   print("veritabanına kaydedilemedi hata: \n" + e.toString());
      //   _showDialog("Hata", "Veritabanına kaydedilemedi");
      // }
    } else {
      // popup yeni numara bulunamadı
      _showDialog("Bilgi", "Yeni numara bulunamadı");
    }
  }

  void _showDialog(String title, String message) {
    // flutter defined function
    showDialog(
      context: context,
      builder: (BuildContext context) {
        // return object of type Dialog
        return AlertDialog(
          title: new Text(title),
          content: new Text(message),
          actions: <Widget>[
            // usually buttons at the bottom of the dialog
            new FlatButton(
              child: new Text("Kapat"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void saveToCloud() {
    final record = Record.fromMap(_calls);
    record.reference.setData(_calls);
  }

  @override
  Widget build(BuildContext context) {
    //bool rehbereKaydet = true, vtKaydet = true;
    return Scaffold(
      appBar: AppBar(
        title: Text("Arayan Numaralar"),
        backgroundColor: Colors.deepPurpleAccent,
      ),
      body: Column(
        children: <Widget>[
          ListView.builder(
            itemCount: _calls == null ? 0 : _calls.length,
            scrollDirection: Axis.vertical,
            shrinkWrap: true,
            itemBuilder: (BuildContext context, int index) {
              final item = _calls[index];
              return Dismissible(
                  key: Key(item["name"]),
                  direction: DismissDirection.endToStart,
                  onDismissed: (direction) {
                    setState(() {
                      _calls.removeAt(index);
                    });

                    //  snackbar.
                    Scaffold.of(context).showSnackBar(SnackBar(
                        content: Text(item["name"] + " listeden çıkarıldı")));
                  },
                  // Show a red background as the item is swiped away.
                  background: Container(
                      color: Colors.red,
                      child: Padding(
                        child: Text(
                          "Sil",
                          style: TextStyle(color: Colors.white, fontSize: 20),
                          textAlign: TextAlign.right,
                        ),
                        padding: EdgeInsets.all(22.0),
                      )),
                  child: ListTile(
                    title: Text(item["name"]),
                    subtitle: Text(item["number"]),
                  ));
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          getSWData(_calls);
        }, //()=>print("düğmeye basıldı"),//saveToCloud, //(){addContactIfNotExist(_calls);},
        tooltip: 'Kaydet',
        child: Icon(Icons.save),
      ),
    );
  }
}

class Record {
  final String name;
  final String number;
  final int categoryId;
  final DocumentReference reference;

  Record.fromMap(Map<String, dynamic> map, {this.reference})
      : assert(map['name'] != null),
        assert(map['number'] != null),
        assert(map['category_id'] != null),
        name = map['name'],
        number = map['number'],
        categoryId = map['category_id'];

  Record.fromSnapshot(DocumentSnapshot snapshot)
      : this.fromMap(snapshot.data, reference: snapshot.reference);

  @override
  String toString() => "Record<$name:$number:$categoryId>";
}
