import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:contacts_service/contacts_service.dart';
import 'package:http/http.dart' as http;

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
      MethodChannel('com.example.incoming_call/calls');

  String _calls = 'Calls: unknown.';
  List data;
  final String url = "https://ankaranakliyat.web.tr/rehber/api/customer/create.php";

  // @override
  // initState() {
  //   super.initState();
  //   // Add listeners to this class

  // }

  /// http request
  Future<String> getSWData(String postBody) async {
    var res = await http
        .post(url, body: postBody, headers: {"Accept": "application/json"});

    setState(() {
      var resBody = json.decode(res.body);
      data = resBody;
    });

    return "Success!";
  }

  /// /http

  Future<void> _getCalls() async {
    String calls;
    bool success2 = false;
    try {
      final String result = await methodChannel.invokeMethod('getCalls');
      calls = result;
      success2 = true;
    } catch (e) {
      //on PlatformException {
      calls = 'Failed to get calls. ';
      _showDialog("Hata",
          "Aramaları alırken hata oluştu. Arama kaydına erişim yetkilerini kontrol edin");
    }
    if (success2) {
      try {
        await addContactIfNotExist(calls);
        print("rehbere kaydedildi");
        _showDialog("Başarılı", "Numaralar rehbere kaydedildi");
      } catch (e) {
        print("rehbere kaydedilemedi hata: \n" + e.toString());
        _showDialog("Hata", "Rehbere kaydederken hata oluştu");
      }
    }
    setState(() {
      _calls = calls;
      print(_calls);
    });
  }

  Future<void> addContactIfNotExist(String telNum) async {
    List<String> nums = telNum.split(",").toList();
    var contacts;
    Contact cnt;
    String customers = "";
    if (nums.length > 0) {
      for (var n in nums) {
        contacts = await ContactsService.getContactsForPhone(n);

        if (contacts.length == 0) {
          cnt = new Contact();
          cnt.givenName = "Musteri" + DateTime.now().toString();
          cnt.phones = [Item(label: "mobile", value: n)];

          customers += "{ \"name\":\"" + cnt.givenName + "\",";
          customers += " \"number\":" + n.toString() + ",";
          customers += " \"category_id\":1},";

          try {
            ContactsService.addContact(cnt);
          } catch (e) {
            print("hata: Rehbere kaydedilemedi! \n");
            _showDialog("Hata", "Rehbere kaydederken hata oluştu");
          }
        }
      }

      customers = "[" + customers.substring(0, customers.length - 1) + "]";

      try {
        await getSWData(customers);
        print("veritabanına kaydedildi");
        _showDialog("Bilgi", "Veritabanına kaydedildi");
        // print(customers);
      } catch (e) {
        print("veritabanına kaydedilemedi hata: \n" + e.toString());
        _showDialog("Hata", "Veritabanına kaydedilemedi");
      }
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
            itemCount: data == null ? 0 : data.length,
            scrollDirection: Axis.vertical,
            shrinkWrap: true,
            itemBuilder: (BuildContext context, int index) {
              return Container(
                child: Center(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Card(
                        child: Container(
                            padding: EdgeInsets.all(15.0),
                            child: Row(
                              children: <Widget>[
                                Text(data[index]["message"],
                                    style: TextStyle(
                                        fontSize: 12.0, color: Colors.black87)),
                              ],
                            )),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _getCalls,
        tooltip: 'Kaydet',
        child: Icon(Icons.save),
      ),
    );
  }
}
