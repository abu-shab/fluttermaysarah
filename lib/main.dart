import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:photo_view/photo_view.dart';
import 'package:path_drawing/path_drawing.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:xml/xml.dart' as xml;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('Interactive World Map'),
        ),
        body: CountryTap(),
      ),
    );
  }
}

class CountryTap extends StatefulWidget {
  @override
  _CountryTapState createState() => _CountryTapState();
}

class _CountryTapState extends State<CountryTap> {
  final _infoKey = GlobalKey();
  Map<String, Path> countryPaths = {};
  Map<String, String> countryInfo = {};
  PhotoViewController controller = PhotoViewController();
  double _scaleFactor = 1.0;

  @override
  void initState() {
    super.initState();
    loadSvgData();
    loadCountryInfo();
  }

  Future<void> loadSvgData() async {
    try {
      final svgString = await rootBundle.loadString('assets/world.svg');
      final svgDocument = xml.parse(svgString);
      final paths = svgDocument.findAllElements('path');
      for (var element in paths) {
        var id = element.getAttribute('id');
        if (id != null) {
          final pathData = element.getAttribute('d') ?? '';
          final path = parseSvgPathData(pathData);
          countryPaths[id] = path;
          print('Loaded path for country ID: $id');
        }
      }
    } catch (e) {
      print('Error loading SVG data: $e');
    }
  }

  Future<void> loadCountryInfo() async {

    countryInfo = {
      'CA': 'Canada\nPopulation: 38 million\nCapital: Ottawa',
      'US': 'United States of America\nPopulation: 331 million\nCapital: Washington, D.C.',
      'AF': 'Afghanistan\nPopulation: 38 million\nCapital: Kabul',
      'AL': 'Albania\nPopulation: 2.8 million\nCapital: Tirana',
      'AE': 'United Arab Emirates\nPopulation: 9.9 million\nCapital: Abu Dhabi',

    };
    print('Country info loaded');
  }

  void _zoomIn() {
    setState(() {
      _scaleFactor += 0.1;
      controller.scale = _scaleFactor;
    });
  }

  void _zoomOut() {
    setState(() {
      if (_scaleFactor > 0.1) {
        _scaleFactor -= 0.1;
        controller.scale = _scaleFactor;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        PhotoView.customChild(
          controller: controller,
          child: GestureDetector(
            onTapUp: (details) {
              final screenPosition = details.localPosition;
              final transformationController = controller.position;
              final scale = controller.scale;

              final Offset translation = transformationController ?? Offset.zero;
              final double scaleFactor = scale ?? 1.0;


              final svgX = (screenPosition.dx - translation.dx) / scaleFactor;
              final svgY = (screenPosition.dy - translation.dy) / scaleFactor;

              print('Tapped at screen coordinates: ($svgX, $svgY)');

              String? countryId = detectCountry(svgX, svgY);
              if (countryId != null) {
                String countryDetails = countryInfo[countryId] ?? 'No information available';
                print('Country detected: $countryId');
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text('Country Information'),
                      content: Text('You tapped on: $countryDetails'),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: Text('OK'),
                        ),
                      ],
                    );
                  },
                );
              } else {
                print('No country found at these coordinates.');
              }
            },
            child: SvgPicture.asset(
              'assets/world.svg',
              key: _infoKey,
              fit: BoxFit.contain,
            ),
          ),
          backgroundDecoration: BoxDecoration(color: Colors.white),
          minScale: PhotoViewComputedScale.contained * 1,
          maxScale: PhotoViewComputedScale.covered * 2,
        ),
        Positioned(
          bottom: 20,
          right: 20,
          child: Column(
            children: [
              FloatingActionButton(
                onPressed: _zoomIn,
                child: Icon(Icons.zoom_in),
              ),
              SizedBox(height: 10),
              FloatingActionButton(
                onPressed: _zoomOut,
                child: Icon(Icons.zoom_out),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String? detectCountry(double x, double y) {
    print('Checking country for coordinates: ($x, $y)');
    for (var id in countryPaths.keys) {
      var path = countryPaths[id];
      if (path != null && path.contains(Offset(x, y))) {
        print('Detected country ID: $id');
        return id;
      }
    }
    return null;
  }
}
