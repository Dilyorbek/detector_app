import 'dart:io';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';

class SingleShotPage extends StatefulWidget {
  @override
  _SingleShotPageState createState() => _SingleShotPageState();
}

class _SingleShotPageState extends State<SingleShotPage> {
  static const platform = const MethodChannel('francium.tech/tensorflow');
  ImagePicker picker  = ImagePicker();

  PickedFile _image;

  double _imageWidth;
  double _imageHeight;
  bool _busy = false;

  List _recognitions;

  @override
  void initState() {
    super.initState();
    _busy = true;

    loadModel().then((val) {
      setState(() {
        _busy = false;
      });
    });
  }

  closeModel() async {
    final String result = await platform.invokeMethod('closeModel');
    print(result);
  }

  Future<void> loadModel() async {
    closeModel();
    try {
      final String result = await platform.invokeMethod('loadModel');
      print(result);
    } on PlatformException catch (e) {
      print("Failed to load the model");
    }
  }

  selectFromImagePicker() async {
    var image = await picker.getImage(source: ImageSource.gallery);
    if (image == null) return;
    setState(() {
      _busy = true;
    });
    predictImage(image);
  }

  selectFromCamera() async {

    var image = await picker.getImage(source: ImageSource.camera);
    if (image == null) return;
    setState(() {
      _busy = true;
    });
    predictImage(image);
  }

  predictImage(PickedFile image) async {
    if (image == null) return;

    await _runDetection(image);

    // FileImage(image).resolve(ImageConfiguration()).addListener((ImageStreamListener((ImageInfo info, bool _) {
    //       setState(() {
    //         _imageWidth = info.image.width.toDouble();
    //         _imageHeight = info.image.height.toDouble();
    //       });
    //     })));

    setState(() {
      _image = image;
      _busy = false;
    });
  }

  Future<void> _runDetection(PickedFile image) async {
    try {
      print("Running detection... ${image.path}");
      var results = await platform.invokeMethod('detectObject', {'image': image.path});

      print(results);
    } finally {
      print("Detection complete!");
    }
  }

  // List<Widget> renderBoxes(Size screen) {
  //   if (_recognitions == null) return [];
  //   if (_imageWidth == null || _imageHeight == null) return [];
  //
  //   double factorX = screen.width;
  //   double factorY = _imageHeight / _imageHeight * screen.width;
  //
  //   Color blue = Colors.red;
  //
  //   return _recognitions.map((re) {
  //     return Positioned(
  //         left: re["rect"]["x"] * factorX,
  //         top: re["rect"]["y"] * factorY,
  //         width: re["rect"]["w"] * factorX,
  //         height: re["rect"]["h"] * factorY,
  //         child: ((re["confidenceInClass"] > 0.50))
  //             ? Container(
  //                 decoration: BoxDecoration(
  //                     border: Border.all(
  //                   color: blue,
  //                   width: 3,
  //                 )),
  //                 child: Text(
  //                   "${re["detectedClass"]} ${(re["confidenceInClass"] * 100).toStringAsFixed(0)}%",
  //                   style: TextStyle(
  //                     background: Paint()..color = blue,
  //                     color: Colors.white,
  //                     fontSize: 15,
  //                   ),
  //                 ),
  //               )
  //             : Container());
  //   }).toList();
  // }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;

    List<Widget> stackChildren = [];

    stackChildren.add(Positioned(
      top: 0.0,
      left: 0.0,
      width: size.width,
      child: _image == null ? Text("No Image Selected") : Image.file(File(_image.path)),
    ));

    //stackChildren.addAll(renderBoxes(size));

    if (_busy) {
      stackChildren.add(Center(
        child: CircularProgressIndicator(),
      ));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Object detection"),
        backgroundColor: Colors.red,
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.image),
        backgroundColor: Colors.red,
        tooltip: "Pick Image from gallery",
        onPressed: selectFromImagePicker,
      ),
      body: Stack(
        children: stackChildren,
      ),
    );
  }
}
