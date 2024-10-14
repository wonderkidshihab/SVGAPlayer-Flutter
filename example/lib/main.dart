import 'package:flutter/material.dart';
import 'package:svgaplayer_3/svgaplayer_flutter.dart';
import 'package:svgaplayer_flutter_example/sample.dart';

import 'constants.dart';

void main() => runApp(ExampleApp());

class ExampleApp extends StatelessWidget {
  const ExampleApp({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.dark(),
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  HomeScreen({
    super.key,
  });

  /// Callback for register dynamic items.
  final dynamicSamples = <String, void Function(MovieEntity entity)>{
    "kingset.svga": (entity) => entity.dynamicItem
      ..setText(
        TextPainter(
          text: TextSpan(
            text: "Hello, World!",
            style: TextStyle(
              fontSize: 28,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        "banner",
      )
    // ..setImageWithUrl(
    //     "https://github.com/PonyCui/resources/blob/master/svga_replace_avatar.png?raw=true",
    //     "99")
    // ..setDynamicDrawer((canvas, frameIndex) {
    //   canvas.drawRect(Rect.fromLTWH(0, 0, 88, 88),
    //       Paint()..color = Colors.red); // draw by yourself.
    // }, "banner"),
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('SVGA Flutter Samples'),
      ),
      body: ListView.separated(
        itemCount: samples.length,
        separatorBuilder: (_, __) => Divider(),
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(samples[index].first),
            subtitle: Text(samples[index].last),
            onTap: () => _goToSample(
              context,
              samples[index],
            ),
          );
        },
      ),
    );
  }

  void _goToSample(context, List<String> sample) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) {
          return SVGASampleScreen(
            name: sample.first,
            image: sample.last,
            dynamicCallback: dynamicSamples[sample.first],
          );
        },
      ),
    );
  }
}

