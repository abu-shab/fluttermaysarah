import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'dart:async';
import 'package:flutter/services.dart' show rootBundle;
import 'package:xml/xml.dart' as xml;
import 'package:photo_view/photo_view.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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
  Map<String, String> countryPaths = {};
  PhotoViewController controller = PhotoViewController();

  @override
  void initState() {
    super.initState();
    loadSvgData();
  }

  Future<void> loadSvgData() async {
    final svgString = await rootBundle.loadString('assets/world.svg');
    final svgDocument = xml.parse(svgString);
    final paths = svgDocument.findAllElements('path');
    for (var element in paths) {
      var id = element.getAttribute('id');
      if (id != null) {
        countryPaths[id] = element.getAttribute('d') ?? '';
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PhotoView.customChild(
      controller: controller,
      child: GestureDetector(
        onTapUp: (details) {
          final screenPosition = details.localPosition;
          final svgPosition = controller.position;
          final scale = controller.scale;

          // Ensure that svgPosition and scale are not null, provide fallback values if they are
          final double posX = svgPosition.dx ?? 0.0;
          final double posY = svgPosition.dy ?? 0.0;
          final double currentScale = scale ?? 1.0;  // Default to 1.0 if scale is null

          // Now perform the calculation using non-nullable values
          final svgX = (screenPosition.dx - posX) / currentScale;
          final svgY = (screenPosition.dy - posY) / currentScale;

          // Use svgX, svgY to check against the 'countryPaths' data
          String? countryId = detectCountry(svgX, svgY);
          if (countryId != null) {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: Text('Country Information'),
                  content: Text('You tapped on: $countryId'),
                );
              },
            );
          }
        },
        child: SvgPicture.asset(
          'assets/world.svg',
          key: _infoKey,
          fit: BoxFit.contain,
        ),
      ),
      backgroundDecoration: BoxDecoration(color: Colors.white),
      minScale: PhotoViewComputedScale.contained * 0.8,
      maxScale: PhotoViewComputedScale.covered * 2,
    );
  }


  String? detectCountry(double x, double y) {
    for (var id in countryPaths.keys) {
      var pathData = countryPaths[id];
      // Check if pathData is not null before proceeding
      if (pathData != null && checkPointInPath(x, y, pathData)) {
        return id;  // Return the country ID if the point is inside the path
      }
    }
    return null;  // Return null if no country is found
  }

  bool checkPointInPath(double x, double y, String pathData) {
    // This method should be implemented with an actual geometry library
    // For example, using a Dart port of the 'point-in-polygon' algorithm or an external API call
    return false; // Placeholder return
  }

}
