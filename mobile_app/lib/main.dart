import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

final colorMap = {
  'blue': Colors.blue,
  'green': Colors.green,
  'yellow': Colors.yellow,
  'red': Colors.red
};

void main() {
  runApp(HighlightsApp());
}

void _resetDatabase() async {
  final collection = Firestore.instance.collection('votes');
  collection.getDocuments().then((query) => query.documents.forEach((doc) {
        if (doc.data.containsKey('votes')) {
          Firestore.instance
              .document('votes/${doc.documentID}')
              .setData({'votes': 0});
        }
      }));
}

class HighlightsApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamProvider<QuerySnapshot>(
      builder: (context) => Firestore.instance.collection('votes').snapshots(),
      child: MaterialApp(
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: HighlightsPage(),
      ),
    );
  }
}

class HighlightsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: Votes()));
  }
}

class Votes extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<QuerySnapshot>(builder: (context, snapshot, _) {
      if (snapshot?.documents != null) {
        return Column(
          children: [
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 5,
                mainAxisSpacing: 5,
                children: snapshot.documents.map<Widget>((d) {
                  final color = d.documentID;
                  final votes = d['votes'] as num;
                  return Card(
                    color: colorMap[color],
                    child: Center(
                        child: Text('$votes', style: TextStyle(fontSize: 34))),
                  );
                }).toList(),
              ),
            ),
            ResetVotes(),
          ],
        );
      } else {
        return Text('No data');
      }
    });
  }
}

class ResetVotes extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FlatButton(
      child: Text('Reset Database'),
      onPressed: () => _resetDatabase(),
    );
  }
}
