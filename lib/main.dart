import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

void main() => runApp(ExchangeRateApp());

class ExchangeRateApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Exchange Rates',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: ExchangeRateScreen(),
    );
  }
}

class ExchangeRateScreen extends StatefulWidget {
  @override
  _ExchangeRateScreenState createState() => _ExchangeRateScreenState();
}

class _ExchangeRateScreenState extends State<ExchangeRateScreen> {
  List rates = [];
  bool isLoading = false;

  Future<void> fetchRates() async {
    final url = Uri.parse(
        'http://192.168.100.23:500/api/taux/');
    try {
      final response = await http.get(url).timeout(Duration(seconds: 30));
      ;
      setState(() {
        isLoading =
            true;
      });

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        print('Réponse API : ${response.body}');
        setState(() {
          rates = data;
          isLoading = false;
        });

      } else {
        print('Erreur serveur : ${response.statusCode}');
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print('Erreur de connexion : $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> refreshRates() async {
  setState(() {
    isLoading = true;
  });

  try {
    final response = await http.post(
      Uri.parse('http://192.168.100.23:500/api/taux/refresh'),
    );

    if (response.statusCode == 200) {
      //print('Taux actualisés avec succès');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Taux actualisés avec succès")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur lors de l'actualisation")),
      );
    }
    // Recharger les taux après actualisation
    await fetchRates();
  } catch (e) {
    //print('Erreur lors de l\'actualisation : $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Erreur de connexion")),
    );
  } finally {
    setState(() {
      isLoading = false;
    });
  }
}

  @override
  void initState() {
    super.initState();
    fetchRates();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(child: Text('Taux de Change')),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : rates.isEmpty
              ? Center(child: Text('Aucun taux disponible.'))
              : ListView.builder(
                  itemCount: rates.length,
                  itemBuilder: (context, index) {
                    final rate = rates[index];
                    final updateDate = DateTime.parse(rate['updateDate']);
                    final formattedDate =
                        DateFormat('yyyy-MM-dd HH:mm:ss').format(updateDate);
                    return Card(
                      margin: EdgeInsets.all(8.0),
                      child: Column(
                        children: [
                          ListTile(
                            title: Text(rate['site']),
                            subtitle: Text(rate['rate']),
                          ),
                          Text("mise à jour le: $formattedDate")
                        ],
                      ),
                    );
                  },
                ),
                floatingActionButton: FloatingActionButton(
                onPressed: isLoading
                    ? null
                    : () async {
                        await refreshRates();
                      },
                child: isLoading
                    ? CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      )
                : Container(
                    child: Column(
                      children: [
                        Container(
                          child: Icon(Icons.refresh),
                        ),
                        Container(
                          child: Text("Refresh"),
                        ),
                      ],
                    ),
                  ),
          ),
              );
            }
}
