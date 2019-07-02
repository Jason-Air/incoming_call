import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:contacts_service/contacts_service.dart';

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
    }
    if (success2) {
      try {
        await addContactIfNotExist(calls);
      } catch (e) {
        print("hata: \n" + e.toString());
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

    for (var n in nums) {
      contacts = await ContactsService.getContactsForPhone(n);

      if (contacts.length == 0) {
        cnt = new Contact();
        cnt.givenName = "Musteri" + DateTime.now().toString();
        cnt.phones = [Item(label: "mobile", value: n)];

        try {
          ContactsService.addContact(cnt);
        } catch (e) {
          print("hata: Rehbere kaydedilemedi! \n");
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(_calls, key: const Key('Calls label')),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: RaisedButton(
                  child: const Text('Refresh'),
                  onPressed: _getCalls,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
