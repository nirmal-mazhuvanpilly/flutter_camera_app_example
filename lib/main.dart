import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_image/flutter_native_image.dart';
// import 'package:path/path.dart' as path;
// import 'package:path_provider/path_provider.dart';

void main() {
  // Ensure that plugin services are initialized so that 'availableCameras'
  // can be called before 'runApp()'
  WidgetsFlutterBinding.ensureInitialized();

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
                builder: (context) => TakePictureScreen(),
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

    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;

    final paintHeight = size.height;
    final paintWidth = size.width;
    print("Paint Height : $paintHeight & Paint Width : $paintWidth");
    print("Height : $height & Width : $width");

    Offset center = Offset(size.width / 2, size.height / 2);

    print(center);

    canvas.drawCircle(center, 5, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}

// A screen that allows users to take a picture.
class TakePictureScreen extends StatefulWidget {
  @override
  _TakePictureScreenState createState() => _TakePictureScreenState();
}

class _TakePictureScreenState extends State<TakePictureScreen> {
  var _availableCamera;
  var _selectedCamera;
  CameraController _cameraController;
  Future<void> _initializeControllerFuture;
  GlobalKey _keyValue = GlobalKey();

  static double dx = 0;
  static double dy = 0;
  static double dh = 0;
  static double dw = 0;

  //Function to get Camera
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

  _getPosition() {
    RenderBox box = _keyValue.currentContext.findRenderObject();
    Offset position = box.localToGlobal(Offset.zero);
    double x = position.dx;
    double y = position.dy;

    setState(() {
      dx = x;
      dy = y;
      dh = box.size.height;
      dw = box.size.width;
      print("dx : $dx , dy : $dy , dh : $dh , dw : $dw");
    });
  }

  _afterLayout(_) {
    _getPosition();
  }

  // Function to toggle Camera
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

  final appBar = AppBar(
    // You must wait until the controller is initialized before displaying the
    // camera preview. Use a FutureBuilder to display a loading spinner until the
    // controller has finished initializing.
    title: const Text("Take a Picture"),
  );

  // Toogle Camera Button Widget
  Widget toogleCameraBtn(BuildContext context) {
    return Align(
      alignment: Alignment.bottomRight,
      child: IconButton(
        icon: Icon(Icons.camera_front),
        onPressed: _toggleCamera,
      ),
    );
  }

  // Focus Border Widget
  Widget focusBorder(BuildContext context) {
    return Stack(
      children: <Widget>[
        Center(
          child: Container(
            key: _keyValue,
            margin: const EdgeInsets.all(10),
            height: 250,
            width: double.infinity,
            decoration: BoxDecoration(
              // color: Colors.yellow,
              border: Border.all(
                color: Colors.yellow,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
        //To Display origin of center
        CustomPaint(
          painter: Origin(context: context),
          child: Container(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar,
      body: Stack(
        children: <Widget>[
          FutureBuilder<void>(
            future: _initializeControllerFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                // If the Future is complete, display the preview.
                //Used Stack to Use Focus Border in CameraPreview
                return CameraPreview(_cameraController);
              } else {
                return Center(
                  // Otherwise, display a loading indicator.
                  child: CupertinoActivityIndicator(),
                );
              }
            },
          ),
          focusBorder(context),
          toogleCameraBtn(context),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton(
        //background color
        backgroundColor: Colors.white,
        // Provide an onPressed callback.
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

            //Crop Image
            //Using flutter native image package

            // ImageProperties properties =
            //     await FlutterNativeImage.getImageProperties(image.path);

            // final imgHeight = properties.height;
            // final imgWidth = properties.width;

            double width = MediaQuery.of(context).size.width;
            double height = MediaQuery.of(context).size.height -
                appBar.preferredSize.height;

            final xCord = (width / 2).round();
            final yCord = (height / 2).round();

            // final cropWidth = (width * .90).round();

            print("X : $xCord , Y : $yCord");

            final croppedImage =
                await FlutterNativeImage.cropImage(image.path, 0, 0, 600, 300);

            // If the picture was taken, display it on a new screen.
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => DisplayPictureScreen(
                  // Pass the automatically generated path to
                  // the DisplayPictureScreen widget.
                  // pass the cropped file path
                  imagePath: croppedImage.path,
                ),
              ),
            );
          } catch (e) {
            // If an error occurs, log the error to the console.
            print(e);
          }
        },
        child: const Icon(Icons.camera_alt),
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
              child: Container(
                color: Colors.white,
                height: 250,
                width: double.infinity,
                margin: const EdgeInsets.all(10),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.file(
                    File(imagePath),
                    fit: BoxFit.contain,
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
                    Navigator.of(context).pop();
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
