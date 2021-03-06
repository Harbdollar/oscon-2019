import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart' as blue;
import 'package:mobile_app/bluetooth_intermediary_pages.dart';
import 'package:mobile_app/support_widgets.dart';
import 'package:mobile_app/support_widgets_coding.dart';
import 'package:mobile_app/votes.dart';
import 'package:provider/provider.dart';
import 'package:mobile_app/bluetooth_state.dart';
import 'dart:convert';

class BluetoothPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
        builder: (_) => Bluetooth(),
        child: Consumer<Bluetooth>(builder:
            (BuildContext context, Bluetooth bluetoothState, Widget child) {
          switch (bluetoothState.currentState) {
            case BleAppState.invalid:
              return Text('This device does not support bluetooth.');
            case BleAppState.failedToConnect:
              return FailedToConnect();
            case BleAppState.connected:
              return LightControl();
            case BleAppState.searching:
              return ScanningPage();
          }
        }));
  }
}

class LightControl extends StatefulWidget {
  LightControl({this.useBluetooth = true});
  final useBluetooth;

  @override
  _LightControlState createState() => _LightControlState();
}

class _LightControlState extends State<LightControl> {
  final int offSignal = 0x4e;

  final Map<String, int> colorCodeMap = {
    'blue': AsciiCodec().encode('b')[0],
    'green': AsciiCodec().encode('g')[0],
    'red': AsciiCodec().encode('r')[0],
    'yellow': AsciiCodec().encode('y')[0],
  };

  final int lightSpill = AsciiCodec().encode('l')[0];
  final int sparkle = AsciiCodec().encode('s')[0];
  final int rainbow = AsciiCodec().encode('o')[0];
  final int twinkle = AsciiCodec().encode('t')[0];
  final int meteorFall = AsciiCodec().encode('e')[0];
  final int runningLights = AsciiCodec().encode('n')[0];
  final int march = AsciiCodec().encode('m')[0];
  final int breathe = AsciiCodec().encode('h')[0];
  final int fire = AsciiCodec().encode('f')[0];
  final int bouncingBalls = AsciiCodec().encode('a')[0];

  String _currentColor;

  void updateMostPopularColor(Bluetooth bluetooth, QuerySnapshot snapshot) {
    if (snapshot?.documents != null) {
      String mostPopularColor;
      // Find the highest scoring Color currently.
      snapshot.documents
          .where((d) => colorMap.containsKey(d.documentID))
          .fold<int>(-1, (int curValue, DocumentSnapshot d) {
        String color = d.documentID;
        var votes = d['votes'] as num;

        if (votes > curValue && votes > 0) {
          curValue = votes;
          mostPopularColor = color;
        }
        return curValue;
      });
      if (mostPopularColor != _currentColor) {
        _currentColor = mostPopularColor;
        bluetooth?.sendMessage(colorCodeMap[_currentColor]);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // A hack to allow us to develop without connecting to a bluetooth device
    // in case of
    var bluetooth =
        widget.useBluetooth ? Provider.of<Bluetooth>(context) : null;

    return Consumer<QuerySnapshot>(
        builder: (context, snapshot, constColumn) {
          updateMostPopularColor(bluetooth, snapshot);
          return constColumn;
        },
        child: SafeArea(
          child: Theme(
            data: ThemeData(
                textTheme: TextTheme(
                    body1: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ))),
            child: GridView.count(
              padding: const EdgeInsets.all(10),
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              children: <Widget>[
                OnOffSwitch(
                  onPressed: (bool value) {
                    if (value) {
                      bluetooth?.sendMessage(offSignal);
                    } else {
                      bluetooth?.sendMessage(lightSpill);
                    }
                  },
                ),
                RainbowButton(
                  text: 'Rainbow',
                  onPressed: () => bluetooth?.sendMessage(rainbow),
                ),
                MarchButton(
                  buttonText: 'March',
                  onPressed: () => bluetooth?.sendMessage(march),
                ),
                SparkleButton(
                  text: 'Sparkle',
                  onPressed: () => bluetooth?.sendMessage(sparkle),
                ),
                ShimmerButton(
                  text: 'Running Lights',
                  onPressed: () => bluetooth?.sendMessage(runningLights),
                ),
                TwinkleButton(
                  text: 'Twinkle',
                  onPressed: () => bluetooth?.sendMessage(twinkle),
                ),
                FireButton(
                  text: 'Fire',
                  onPressed: () => bluetooth?.sendMessage(fire),
                ),
                FadingButton(
                  text: 'Breathe',
                  onPressed: () => bluetooth?.sendMessage(breathe),
                ),
                ColorFillButton(
                    text: 'Color Fill',
                    onPressed: () => bluetooth?.sendMessage(lightSpill)),
                BouncingBallButton(
                  onPressed: () => bluetooth?.sendMessage(bouncingBalls),
                ),
                MeteorButton(
                  text: 'Meteor Rain',
                  onPressed: () => bluetooth?.sendMessage(meteorFall),
                ),
              ],
            ),
          ),
        ));
  }

  @override
  void dispose() {
    if (widget.useBluetooth) Provider.of<Bluetooth>(context).disconnect();
    super.dispose();
  }
}

class AvailableDevices extends StatelessWidget {
  AvailableDevices(this.availableBLEDevices);
  final Map<blue.DeviceIdentifier, blue.ScanResult> availableBLEDevices;
  @override
  Widget build(BuildContext context) {
    return ListView(
        children: availableBLEDevices.values
            .where((result) => result.device.name.length > 0)
            .map<Widget>((result) => ListTile(
                  title: Text(result.device.name),
                  subtitle: Text(result.device.id.toString()),
                  onTap: () => Provider.of<Bluetooth>(context)
                      .connectToDevice(result.device),
                ))
            .toList()
              ..add(IconButton(
                icon: Icon(Icons.refresh),
                onPressed: () => Provider.of<Bluetooth>(context)
                    .setMode(BleAppState.searching),
              )));
  }
}
