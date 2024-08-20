import 'package:flutter/material.dart';
import 'package:wide_color_tool/wide_color_tool.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WideColor Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'WideColor Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  WideColor _color1 = WideColor.fromRGB(255, 0, 0);
  WideColor _color2 = WideColor.fromRGB(0, 0, 255);
  WideColor _mixedColor = WideColor.fromRGB(127, 0, 127);

  void _mixRgbColors() {
    setState(() {
      _mixedColor = _color1.mix(_color2, source: ColorSource.rgb);
    });
  }

  void _mixHsvColors() {
    setState(() {
      _mixedColor = _color1.mix(_color2, source: ColorSource.hsv);
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
          bottom: TabBar(
            tabs: [
              Tab(text: 'Color Mix'),
              Tab(text: 'Conversions'),
              Tab(text: 'Contrast'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildColorMixTab(),
            _buildConversionsTab(),
            _buildContrastTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildColorMixTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildColorBox(_color1),
              _buildColorBox(_color2),
            ],
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: _mixRgbColors,
            child: Text('Mix RGB Colors'),
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: _mixHsvColors,
            child: Text('Mix HSV Colors'),
          ),
          SizedBox(height: 20),
          _buildColorBox(_mixedColor),
          Text(
            'Mixed Color: ${_mixedColor.string}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildConversionsTab() {
    final cmyk = _color1.cmyk;
    final rgb = cmyk.toColor();
    print('${rgb.red}, ${rgb.green}, ${rgb.blue}');
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          _buildColorBox(_color1),
          SizedBox(height: 20),
          Text('RGB: (${_color1.red}, ${_color1.green}, ${_color1.blue})'),
          Text(
              'HSV: (${_color1.hue}, ${_color1.saturationV.toStringAsFixed(2)}, ${_color1.value.toStringAsFixed(2)})'),
          Text(
              'HSL: (${_color1.hue}, ${_color1.saturationL.toStringAsFixed(2)}, ${_color1.light.toStringAsFixed(2)})'),
          Text(
              'CMYK: (${_color1.cyan.toStringAsFixed(2)}, ${_color1.magenta.toStringAsFixed(2)}, ${_color1.yellow.toStringAsFixed(2)}, ${_color1.black.toStringAsFixed(2)})'),
        ],
      ),
    );
  }

  Widget _buildContrastTab() {
    WideColor backgroundColor = WideColor.fromRGB(240, 240, 240);
    WideColor textColor = WideColor.fromRGB(50, 50, 50);
    num contrast = backgroundColor.contrast(textColor);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildColorBox(backgroundColor),
              _buildColorBox(textColor),
            ],
          ),
          SizedBox(height: 20),
          Text('Contrast Ratio: ${contrast.toStringAsFixed(2)}'),
          SizedBox(height: 20),
          Container(
            color: backgroundColor.color,
            padding: EdgeInsets.all(20),
            child: Text(
              'Sample Text',
              style: TextStyle(color: textColor.color, fontSize: 24),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorBox(WideColor color) {
    return Container(
      width: 100,
      height: 100,
      color: color.color,
    );
  }
}
