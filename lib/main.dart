import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_image/flutter_native_image.dart';
import 'package:image/image.dart' as img;
import 'package:native_device_orientation/native_device_orientation.dart';

void main() {
  // Ensure that plugin services are initialized so that 'availableCameras'
  // can be called before 'runApp()'
  WidgetsFlutterBinding.ensureInitialized();

  //Setting PreferredOrientation to Portrait
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitDown,
    DeviceOrientation.portraitUp,
  ]);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Camera HomePage"),
      ),
      body: Center(
        //Click to Open Camera
        child: RaisedButton(
          child: const Text("Open Camera"),
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => TakePicture(),
              ),
            );
          },
        ),
      ),
    );
  }
}

//Custom Class to get Centre Point
class Origin extends CustomPainter {
  final BuildContext context;
  Origin({
    this.context,
  });
  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()
      ..color = Colors.red[400]
      ..strokeWidth = 2
      ..style = PaintingStyle.fill
      ..strokeCap = StrokeCap.round;

    Offset center = Offset(size.width / 2, size.height / 2);
    // print(center);

    canvas.drawCircle(center, 5, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}

// A screen that allows users to take a picture.
class TakePicture extends StatefulWidget {
  @override
  _TakePictureState createState() => _TakePictureState();
}

class _TakePictureState extends State<TakePicture> {
  bool useSensor = true;

  var _availableCamera;

  var _selectedCamera;

  CameraController _cameraController;

  Future<void> _initializeControllerFuture;

  GlobalKey _focusKeyValue = GlobalKey();

  GlobalKey _pointerKeyValue = GlobalKey();

  double dx = 0;
  double dy = 0;
  double dh = 0;
  double dw = 0;

  double dxPointer = 0;
  double dyPointer = 0;
  double dhPointer = 0;
  double dwPointer = 0;

  _getCamera() async {
    // Get the list of available cameras.
    _availableCamera = await availableCameras();
    print(availableCameras);

    // Get a specific camera from the list of available cameras.
    _selectedCamera = _availableCamera.first;
    print(_selectedCamera);

    // To display the current output from the Camera,
    // create a CameraController.
    _cameraController = CameraController(
        // Get a specific camera from the list of available cameras.
        _selectedCamera,
        // Define the resolution to use.
        ResolutionPreset.high);

    // Next, initialize the controller. This returns a Future.
    _initializeControllerFuture = _cameraController.initialize();
  }

  _getPositionofFocusBorder() {
    RenderBox box = _focusKeyValue.currentContext.findRenderObject();
    Offset position = box.localToGlobal(Offset.zero);
    double x = position.dx;
    double y = position.dy;

    setState(() {
      dx = x;
      dy = y;
      dh = box.size.height;
      dw = box.size.width;
      print("FocusBorder Details == dx : $dx , dy : $dy , dh : $dh , dw : $dw");
    });
  }

  _getPositionofPointer() {
    RenderBox box = _pointerKeyValue.currentContext.findRenderObject();
    Offset position = box.localToGlobal(Offset.zero);
    double x = position.dx;
    double y = position.dy;

    setState(() {
      dxPointer = x;
      dyPointer = y;
      dhPointer = box.size.height;
      dwPointer = box.size.width;
      print(
          "Pointer Details == dx : $dxPointer , dy : $dyPointer , dh : $dhPointer , dw : $dwPointer");
    });
  }

  _afterLayout(_) {
    _getPositionofFocusBorder();
    _getPositionofPointer();
  }

  _toggleCamera() {
    setState(() {
      _selectedCamera = _selectedCamera == _availableCamera.first
          ? _availableCamera.elementAt(1)
          : _availableCamera.elementAt(0);
      _cameraController =
          CameraController(_selectedCamera, ResolutionPreset.high);
      _initializeControllerFuture = _cameraController.initialize();
    });
  }

  Future<File> rotateToRight(String imagePath) async {
    final originalFile = File(imagePath);
    List<int> imageBytes = await originalFile.readAsBytes();
    final originalImage = img.decodeImage(imageBytes);

    img.Image fixedImage;

    fixedImage = img.copyRotate(originalImage, 90);

    print("***Block***");
    print("Fixed image Height : ${fixedImage.height}");
    print("Fixed image Width : ${fixedImage.width}");

    // Here you can select whether you'd like to save it as png
    // or jpg with some compression
    // I choose jpg with 100% quality
    final fixedFile =
        await originalFile.writeAsBytes(img.encodeJpg(fixedImage));

    return fixedFile;
  }

  Future<File> rotateToLeft(String imagePath) async {
    final originalFile = File(imagePath);
    List<int> imageBytes = await originalFile.readAsBytes();
    final originalImage = img.decodeImage(imageBytes);

    img.Image fixedImage;

    fixedImage = img.copyRotate(originalImage, -90);

    print("***Block***");
    print("Fixed image Height : ${fixedImage.height}");
    print("Fixed image Width : ${fixedImage.width}");

    // Here you can select whether you'd like to save it as png
    // or jpg with some compression
    // I choose jpg with 100% quality
    final fixedFile =
        await originalFile.writeAsBytes(img.encodeJpg(fixedImage));

    return fixedFile;
  }

  Future<File> cropImage(BuildContext context, String imagePath) async {
    // To get Screen size
    final screenSize = MediaQuery.of(context).size;
    // To get Status bar size
    final statusBarSize = MediaQuery.of(context).padding.top;

    // To get Screen width & height
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;

    print("Screen Height : $screenHeight");
    print("Screen Width : $screenWidth");
    print("Status Bar Height : $statusBarSize");

    // To get Image properties
    ImageProperties properties =
        await FlutterNativeImage.getImageProperties(imagePath);

    // To get Image height and width
    int imageWidth = properties.width;
    int imageHeight = properties.height;

    print("imageWidth:$imageWidth");
    print("imageHeight:$imageHeight");

    // To get xOffset,yOffset,widthOffset,heightOffset
    int xOffset = ((dx * imageWidth) / screenWidth).round();
    int yOffset = ((dy * imageHeight) / screenHeight).round();
    int widthOffset = ((dw * imageWidth) / screenWidth).round();
    int heightOffset = ((dh * imageHeight) / screenHeight).round();

    print(
        "xOffset:$xOffset , yOffset:$yOffset , widthOffset:$widthOffset , heightOffset:$heightOffset  ");

    final croppedImage = await FlutterNativeImage.cropImage(
      imagePath,
      xOffset,
      yOffset,
      widthOffset,
      heightOffset,
    );

    return croppedImage;
  }

  @override
  void initState() {
    // Flutter Framework has a convenient API to request a callback method to be executed once a frame rendering is complete.
    // This method is:
    // WidgetsBinding.instance.addPostFrameCallback.
    WidgetsBinding.instance.addPostFrameCallback(_afterLayout);
    super.initState();

    //Function to get Camera
    _getCamera();
  }

  @override
  void dispose() {
    // Dispose of the controller when the widget is disposed.
    _cameraController.dispose();
    super.dispose();
  }

  Widget closeCameraBtn(BuildContext context) {
    return CircleAvatar(
      backgroundColor: Colors.white,
      child: IconButton(
          icon: Icon(Icons.close),
          onPressed: () {
            Navigator.of(context).pop();
          }),
    );
  }

  Widget toggleCameraBtn(BuildContext context) {
    return CircleAvatar(
      backgroundColor: Colors.white,
      child: IconButton(
        icon: Icon(Icons.linked_camera_rounded),
        onPressed: _toggleCamera,
      ),
    );
  }

  Widget takeImageBtn(BuildContext context) {
    return CircleAvatar(
      backgroundColor: Colors.white,
      child: IconButton(
        icon: Icon(Icons.camera_alt),
        onPressed: () async {
          // Take the Picture in a try / catch block. If anything goes wrong,
          // catch the error.
          try {
            // Ensure that the camera is initialized.
            await _initializeControllerFuture;

            // Attempt to take a picture and get the file `image`
            // where it was saved.
            final image = await _cameraController.takePicture();
            print(image.path);

            // Rotate Image Right
            final rotateFile = await rotateToRight(image.path);

            //Crop Image
            final cropFile = await cropImage(context, rotateFile.path);

            //Rotate Image Left
            final rotateLeft = await rotateToLeft(cropFile.path);

            // If the picture was taken and cropped, display it on a new screen.
            await Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => DisplayPictureScreen(
                  // Pass the automatically generated path to
                  // the DisplayPictureScreen widget.
                  // pass the cropped file path
                  imagePath: rotateLeft.path,
                ),
              ),
            );
          } catch (e) {
            // If an error occurs, log the error to the console.
            print(e);
          }
        },
      ),
    );
  }

  Widget focusBorder(BuildContext context) {
    return Stack(
      children: <Widget>[
        Center(
          child: Container(
            key: _focusKeyValue,
            height: MediaQuery.of(context).size.height * .30,
            width: MediaQuery.of(context).size.width * .95,
            decoration: BoxDecoration(
              // color: Colors.yellow,
              border: Border.all(
                color: Colors.yellow,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),

        //To Display origin of center in Red Color
        CustomPaint(
          key: _pointerKeyValue,
          painter: Origin(context: context),
          child: Container(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: <Widget>[
          FutureBuilder<void>(
            future: _initializeControllerFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                // If the Future is complete, display the preview.
                //Used Stack to Use Focus Border in CameraPreview
                return Container(
                  height: double.infinity,
                  width: double.infinity,
                  child: CameraPreview(_cameraController),
                );
              } else {
                return Container();
              }
            },
          ),
          focusBorder(context),
          //Use flutter native_device_orientation package to use NativeDeviceOrientationReader
          NativeDeviceOrientationReader(
            // Set useSensor to true to get NativeDeviceOrientation
            useSensor: useSensor,
            builder: (context) {
              final orientation =
                  NativeDeviceOrientationReader.orientation(context);
              print('Received new orientation: $orientation');

              if (orientation == NativeDeviceOrientation.portraitUp) {
                return Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.all(25.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        closeCameraBtn(context),
                        takeImageBtn(context),
                        toggleCameraBtn(context),
                      ],
                    ),
                  ),
                );
              } else {
                return Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.all(25.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        closeCameraBtn(context),
                        toggleCameraBtn(context),
                      ],
                    ),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}

// A widget that displays the picture taken by the user.
class DisplayPictureScreen extends StatelessWidget {
  final String imagePath;

  DisplayPictureScreen({
    @required this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // The image is stored as a file on the device. Use the 'Image.file'
        // constructor with the given path to display the image.
        title: const Text("Display the Picture"),
      ),
      body: Container(
        height: double.infinity,
        width: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Flexible(
              flex: 1,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  color: Colors.white,
                  height: MediaQuery.of(context).size.height * .30,
                  width: MediaQuery.of(context).size.width * .95,
                  child: Image.file(
                    File(imagePath),
                    fit: BoxFit.fill,
                  ),
                ),
              ),
            ),
            SizedBox(height: 25),
            Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                //Button to Retake Camera
                //Close current context
                IconButton(
                  icon: Icon(Icons.camera_alt),
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (context) => TakePicture(),
                      ),
                    );
                  },
                ),
                Text("Retake"),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
