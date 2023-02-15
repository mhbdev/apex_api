import 'package:apex_api/apex_api.dart';
import 'package:apex_api/cipher/models/key_pair.dart';
import 'package:flutter/material.dart';

GlobalKey<NavigatorState> navKey = GlobalKey<NavigatorState>();

void main() {
  ApexApi.init();

  runApp(
    const RootRestorationScope(
      restorationId: 'root',
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navKey,
      builder: (context, child) {
        return ApiWrapper(
          config: const ApiConfig(
            'https://api.apexteam.net/k/faam/handler.php',
            languageCode: 'FA',
            privateVersion: 2,
            publicVersion: 2,
            useMocks: false,
            webKey: KeyPair(
                "jsGqL9HsDxGhtpFPpMSayS+Y2eGupAvncNVphSqdGbk=", """-----BEGIN PUBLIC KEY-----
MIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEAwcTpqcXvQcPaq2JiWh2C
PvSc5aLdtdI2riqLnlFrmD0W0xEcDMTLkahUVyIecEjiR22wLa2F7chz6pNJqSdR
F7ImMgmp/fkGnmmAUqXDy3bRfXuj38GZuq53/1HaA+X+stuyrNBM4Om81875Zlj0
Zm9IReHfWe1HrikGzEV+x9oBHtJewQ2CL6+vcUkqj1zmmZVM8oKHid1HEL6NHrKH
6SARYpuVa2G82ctNyRrPr7HJI12+G7xopdQiLQZVBhnx2Gd2n+nCgqibAVvPnXkR
g2ghaiRHmoSGXFv+veWd/w9iQA+oqiM7CGYkGTyHC6MfI5EivVtXDkk7ftGZaFEU
i3tJ34dE3ODxbuSQkHrJGg1OuqRiStfYQwBHkO0q8qCsG2v505fL52FDLrFr1uvk
VNvheZxL3ASVr9+Om+Y1OFrWIQl3bv2kVJPEyqG2AJHrIQ71K+K8Wrkpf1LRhwHk
7G71jZ5L5HGgQ6ntNDFm6EnKf35HDWaRJ4o6OhWQClhHm+i52Toi3+jL6QTstA5S
qj0u+WAuXMHncViblYecWNQI9WplFvpjlbUPPQ398l96KzjUU2ONZDJstfXyNAVx
iSmkf58aI1ZIkB5e9a0mCDa/0eDFm0bHEFHU9XbyZ8qjyphevWMb7vQAQbcYzZTP
9V5BXD29o5GXWIrxqDQhovkCAwEAAQ==
-----END PUBLIC KEY-----"""),
          ),
          navKey: navKey,
          loginStepHandler: print,
          messageHandler: (request, v) {
            showDialog(
              context: navKey.currentContext!,
              useRootNavigator: true,
              builder: (context) => AlertDialog(
                  title: Text(request.action.toString()),
                  content: Text('${v.success.toString()} ${request.isPrivate}')),
            );
          },
          child: child!,
        );
      },
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final res = await context.http.post(
            SimpleRequest(5, isPublic: true),
            response: FetchProvinces.fromJson,
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
