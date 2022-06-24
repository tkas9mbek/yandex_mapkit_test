import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:yandex_mapkit/yandex_mapkit.dart';

String generateRandomString(int len) {
  var r = Random();
  const chars = 'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
  return List.generate(len, (index) => chars[r.nextInt(chars.length)]).join();
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

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
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final Completer<YandexMapController> _completer = Completer();
  late YandexMapController _controller;
  final _mapObjects = <MapObject>[];
  final _animation = const MapAnimation(
    type: MapAnimationType.smooth,
    duration: 2,
  );
  final points = <Point>[
    const Point(
      latitude: 42.8758,
      longitude: 74.6052,
    ),
    const Point(
      latitude: 42.8411,
      longitude: 74.6366,
    ),
    const Point(
      latitude: 42.8481,
      longitude: 74.6306,
    ),
    const Point(
      latitude: 42.8517,
      longitude: 74.5503,
    ),
  ];

  void _moveCameraToCurrentPosition() {
    _controller.moveCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: points.first,
          zoom: 12,
        ),
      ),
      animation: _animation,
    );
  }

  void _updateMap(VoidCallback update) {
    update.call();

    setState(() {});
    Future.delayed(const Duration(milliseconds: 250), () {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Column(
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: YandexMap(
              modelsEnabled: true,
              zoomGesturesEnabled: true,
              mode2DEnabled: true,
              nightModeEnabled: Theme.of(context).brightness == Brightness.dark,
              onMapCreated: (controller) {
                _completer.complete(controller);
                _controller = controller;
                _controller.toggleUserLayer(visible: true);
                _moveCameraToCurrentPosition();
              },
              mapObjects: _mapObjects,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ElevatedButton(
                onPressed: () async {
                  final resultWithSession = YandexDriving.requestRoutes(
                    points: [
                      RequestPoint(
                        point: points[1],
                        requestPointType: RequestPointType.wayPoint,
                      ),
                      RequestPoint(
                        point: points.last,
                        requestPointType: RequestPointType.wayPoint,
                      ),
                    ],
                    drivingOptions: const DrivingOptions(
                      routesCount: 1,
                      avoidTolls: true,
                    ),
                  );

                  final result = await resultWithSession.result;
                  final route = result.routes!.asMap().values.toList().first;

                  for (var i = 5; i < route.geometry.length; i += 5) {
                    final geometry = route.geometry.sublist(i - 5, i);

                    _updateMap(() {
                      _mapObjects.add(
                        PolylineMapObject(
                          mapId: MapObjectId('#polyline#${generateRandomString(10)}'),
                          polyline: Polyline(points: geometry),
                          strokeColor: Colors.primaries[Random().nextInt(Colors.primaries.length)],
                        ),
                      );
                    });
                  }
                },
                child: const Text('Polylines'),
              ),
              ElevatedButton(
                onPressed: () {
                  _updateMap(() {
                    _mapObjects.add(PlacemarkMapObject(
                      opacity: 1,
                      mapId: MapObjectId('#placemark${generateRandomString(10)}'),
                      point: points[1],
                      icon: PlacemarkIcon.single(
                        PlacemarkIconStyle(
                          image: BitmapDescriptor.fromAssetImage('images/dot.png'),
                          scale: 0.5,
                        ),
                      ),
                    ));
                  });
                },
                child: const Text('Placemarks'),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ElevatedButton(
                onPressed: () {
                  _updateMap(() {
                    _mapObjects.add(CircleMapObject(
                      mapId: MapObjectId('circle#${generateRandomString(10)}'),
                      circle: Circle(
                        center: points.first,
                        radius: 5000,
                      ),
                      fillColor: Colors.blue.withOpacity(0.3),
                    ));
                  });
                },
                child: const Text('Circle'),
              ),
              ElevatedButton(
                onPressed: () {
                  _updateMap(() {
                    _mapObjects.clear();
                  });
                },
                child: const Text('Clear'),
              ),
            ],
          ),
          const SizedBox(
            height: 20,
          ),
          Row(
            children: [
              Center(
                  child: Text(
                'Map Object length: ${_mapObjects.length}',
              ))
            ],
          ),
        ],
      ),
    );
  }
}
